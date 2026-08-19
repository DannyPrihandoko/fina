import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  /// `false` jika `Firebase.initializeApp()` gagal di startup. Semua method di bawah
  /// harus lewat `_authOrNull`/`_dbOrNull` (bukan `FirebaseAuth.instance`/`FirebaseFirestore.instance`
  /// langsung) supaya tidak melempar exception sinkron saat Firebase belum siap.
  bool get isFirebaseReady => Firebase.apps.isNotEmpty;
  FirebaseAuth? get _authOrNull => isFirebaseReady ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _dbOrNull => isFirebaseReady ? FirebaseFirestore.instance : null;

  User? get currentUser => _authOrNull?.currentUser;

  Future<User?> ensureLoggedIn() async {
    if (currentUser != null) return currentUser;
    final auth = _authOrNull;
    if (auth == null) return null;
    try {
      final credentials = await auth.signInAnonymously();
      return credentials.user;
    } catch (e) {
      debugPrint('Firebase Anonymous Auth failed: $e');
      return null;
    }
  }

  /// Mengembalikan `true` jika berhasil publish, `false` jika gagal — caller wajib
  /// menampilkan feedback yang sesuai ke user, jangan asumsikan selalu sukses.
  Future<bool> publishSnapshot(Map<String, dynamic> data, {String? userName}) async {
    final user = await ensureLoggedIn();
    final db = _dbOrNull;
    if (user == null || db == null) return false;

    try {
      // Create/Update Profile
      await db.collection('profiles').doc(user.uid).set({
        'uid': user.uid,
        'name': userName ?? 'User Fina',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update Snapshot
      await db.collection('snapshots').doc(user.uid).set({
        ...data,
        'uid': user.uid,
        'name': userName ?? 'User Fina', // Redundancy for easy access
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Publishing snapshot failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchSnapshot(String uid) async {
    final db = _dbOrNull;
    if (db == null) return null;
    try {
      final doc = await db.collection('snapshots').doc(uid).get();
      final data = doc.data();
      return data != null ? _sanitizeData(data) as Map<String, dynamic> : null;
    } catch (e) {
      debugPrint('Fetching snapshot failed for $uid: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchProfile(String uid) async {
    final db = _dbOrNull;
    if (db == null) return null;
    try {
      final doc = await db.collection('profiles').doc(uid).get();
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
    final db = _dbOrNull;
    if (user == null || db == null) return;

    final docId = user.uid.compareTo(targetUid) < 0
        ? '${user.uid}_$targetUid'
        : '${targetUid}_${user.uid}';

    try {
      final docRef = db.collection('relationships').doc(docId);
      final existing = await docRef.get();
      if (existing.exists && existing.data()?['status'] == 'accepted') {
        // Relasi ini sudah accepted (mis. sisi lain belum sempat hapus koneksinya).
        // Jangan ditimpa balik jadi 'pending' — cukup no-op.
        return;
      }

      await docRef.set({
        'id': docId,
        'uids': [user.uid, targetUid],
        'fromUid': user.uid,
        'toUid': targetUid,
        'fromName': myName,
        'toName': targetName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Requesting relationship failed: $e');
    }
  }

  Future<void> updateRelationshipStatus(String docId, String status) async {
    final db = _dbOrNull;
    if (db == null) return;
    try {
      await db.collection('relationships').doc(docId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Updating relationship status failed: $e');
    }
  }

  /// Menghapus dokumen relationship secara permanen di Firestore (bukan hanya di state lokal).
  Future<void> deleteRelationship(String otherUid) async {
    final user = currentUser;
    final db = _dbOrNull;
    if (user == null || db == null) return;

    final docId = user.uid.compareTo(otherUid) < 0
        ? '${user.uid}_$otherUid'
        : '${otherUid}_${user.uid}';

    try {
      await db.collection('relationships').doc(docId).delete();
    } catch (e) {
      debugPrint('Deleting relationship failed: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> streamRelationships() {
    final user = currentUser;
    final db = _dbOrNull;
    if (user == null || db == null) return const Stream.empty();

    return db
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
