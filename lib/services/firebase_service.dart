import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<User?> ensureLoggedIn() async {
    if (currentUser != null) return currentUser;
    try {
      final credentials = await _auth.signInAnonymously();
      return credentials.user;
    } catch (e) {
      debugPrint('Firebase Anonymous Auth failed: $e');
      return null;
    }
  }

  Future<void> publishSnapshot(Map<String, dynamic> data, {String? userName}) async {
    final user = await ensureLoggedIn();
    if (user == null) return;

    try {
      // Create/Update Profile
      await _db.collection('profiles').doc(user.uid).set({
        'uid': user.uid,
        'name': userName ?? 'User Fina',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update Snapshot
      await _db.collection('snapshots').doc(user.uid).set({
        ...data,
        'uid': user.uid,
        'name': userName ?? 'User Fina', // Redundancy for easy access
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Publishing snapshot failed: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchSnapshot(String uid) async {
    try {
      final doc = await _db.collection('snapshots').doc(uid).get();
      final data = doc.data();
      return data != null ? _sanitizeData(data) as Map<String, dynamic> : null;
    } catch (e) {
      debugPrint('Fetching snapshot failed for $uid: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchProfile(String uid) async {
    try {
      final doc = await _db.collection('profiles').doc(uid).get();
      final data = doc.data();
      return data != null ? _sanitizeData(data) as Map<String, dynamic> : null;
    } catch (e) {
      debugPrint('Fetching profile failed for $uid: $e');
      return null;
    }
  }

  // --- RELATIONSHIP MANAGEMENT ---

  Future<void> requestRelationship(String targetUid, String myName, String targetName) async {
    final user = await ensureLoggedIn();
    if (user == null) return;

    final docId = user.uid.compareTo(targetUid) < 0 
        ? '${user.uid}_$targetUid' 
        : '${targetUid}_${user.uid}';

    try {
      await _db.collection('relationships').doc(docId).set({
        'id': docId,
        'uids': [user.uid, targetUid],
        'fromUid': user.uid,
        'toUid': targetUid,
        'fromName': myName,
        'toName': targetName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Requesting relationship failed: $e');
    }
  }

  Future<void> updateRelationshipStatus(String docId, String status) async {
    try {
      await _db.collection('relationships').doc(docId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Updating relationship status failed: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> streamRelationships() {
    final user = currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('relationships')
        .where('uids', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return _sanitizeData(data) as Map<String, dynamic>;
      }).toList();
    });
  }

  /// Helper to sanitize Firestore types (e.g. Timestamp to ISO string)
  dynamic _sanitizeData(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is Map) {
      return value.map<String, dynamic>((k, v) => MapEntry(k.toString(), _sanitizeData(v)));
    }
    if (value is List) {
      return value.map(_sanitizeData).toList();
    }
    return value;
  }
}
