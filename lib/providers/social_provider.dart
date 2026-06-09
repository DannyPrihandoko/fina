import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fina/services/firebase_service.dart';
import 'package:fina/providers/settings_provider.dart';
import '../models/connection.dart';

export '../models/connection.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final socialProvider = StateNotifierProvider<SocialNotifier, SocialState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  return SocialNotifier(prefs, firebaseService);
});

class SocialNotifier extends StateNotifier<SocialState> {
  final SharedPreferences _prefs;
  final FirebaseService _firebaseService;
  static const _storageKey = 'fina_connections';
  StreamSubscription? _sub;

  SocialNotifier(this._prefs, this._firebaseService) : super(SocialState(connections: [])) {
    _loadFromPrefs();
    _initFirestoreListener();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _initFirestoreListener() {
    _sub = _firebaseService.streamRelationships().listen((snapshot) {
      final myUid = _firebaseService.currentUser?.uid;
      if (myUid == null) return;

      final List<Connection> updatedList = [];
      // Track which UIDs newly became 'accepted' so we can fetch their data
      final List<String> newlyAccepted = [];

      for (var data in snapshot) {
        final fromUid = data['fromUid'];
        final toUid = data['toUid'];
        final status = data['status'] ?? 'pending';

        final isIncoming = toUid == myUid;
        final peerUid = isIncoming ? fromUid : toUid;
        final peerName = isIncoming ? data['fromName'] : data['toName'];

        // FIX 1: Preserve existing lastData when rebuilding the list
        final existing = state.connections.firstWhere(
          (c) => c.uid == peerUid,
          orElse: () => Connection(uid: peerUid, name: peerName),
        );

        // Detect transition from pending → accepted
        if (existing.status == 'pending' && status == 'accepted') {
          newlyAccepted.add(peerUid);
        }

        updatedList.add(Connection(
          uid: peerUid,
          name: peerName,
          id: data['id'],
          status: status,
          isIncoming: isIncoming,
          lastData: existing.lastData, // Preserve cached data
        ));
      }

      state = state.copyWith(connections: updatedList);
      _saveToPrefs();

      // FIX 2: Fetch data for all accepted connections, prioritising newly accepted ones
      for (final uid in newlyAccepted) {
        refreshConnection(uid);
      }
      // Also refresh all other accepted connections that have no data yet
      for (final conn in updatedList) {
        if (conn.status == 'accepted' && conn.lastData == null && !newlyAccepted.contains(conn.uid)) {
          refreshConnection(conn.uid);
        }
      }
    });
  }

  void _loadFromPrefs() {
    final data = _prefs.getStringList(_storageKey);
    if (data != null) {
      // FIX 3: fromJson now restores lastData, so cached data is available immediately
      final list = data.map((e) => Connection.fromJson(jsonDecode(e))).toList();
      state = state.copyWith(connections: list);
      // Refresh accepted connections in background to get fresh data
      for (final conn in list) {
        if (conn.status == 'accepted') {
          refreshConnection(conn.uid);
        }
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final data = state.connections.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_storageKey, data);
  }

  Future<bool> addConnection(String uid, String name, String myName) async {
    if (state.connections.any((e) => e.uid == uid)) return false;

    // First request in Firestore
    await _firebaseService.requestRelationship(uid, myName, name);
    
    // Note: The listener will automatically update our state when the doc is created.
    return true;
  }

  Future<void> acceptConnection(String docId) async {
    await _firebaseService.updateRelationshipStatus(docId, 'accepted');
    // FIX 4: The Firestore listener will detect the status change and auto-fetch data.
    // No manual action needed here — listener handles it via newlyAccepted logic.
  }

  Future<void> removeConnection(String uid) async {
    // Ideally also remove from Firestore, but for now just local filter is fine 
    // or we can implement deleteRelationship in FirebaseService later.
    state = state.copyWith(
      connections: state.connections.where((e) => e.uid != uid).toList(),
    );
    await _saveToPrefs();
  }

  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true);
    for (final conn in state.connections) {
      if (conn.status == 'accepted') {
        await refreshConnection(conn.uid);
      }
    }
    state = state.copyWith(isLoading: false);
  }

  Future<void> refreshConnection(String uid) async {
    final data = await _firebaseService.fetchSnapshot(uid);
    if (data != null) {
      state = state.copyWith(
        connections: state.connections.map((e) {
          if (e.uid == uid) {
            final sharedName = data['name'] as String?;
            return e.copyWith(
              lastData: data,
              name: sharedName ?? e.name,
            );
          }
          return e;
        }).toList(),
      );
    }
  }
}
