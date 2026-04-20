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
      return doc.data();
    } catch (e) {
      debugPrint('Fetching snapshot failed for $uid: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchProfile(String uid) async {
    try {
      final doc = await _db.collection('profiles').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Fetching profile failed for $uid: $e');
      return null;
    }
  }
}
