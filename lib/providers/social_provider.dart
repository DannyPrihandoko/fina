import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fina/services/firebase_service.dart';
import 'package:fina/providers/settings_provider.dart';

class Connection {
  final String uid;
  final String name;
  final String? id; // Firestore Doc ID
  final String status; // 'pending' | 'accepted'
  final bool isIncoming;
  final Map<String, dynamic>? lastData;

  Connection({
    required this.uid,
    required this.name,
    this.id,
    this.status = 'accepted',
    this.isIncoming = false,
    this.lastData,
  });

  Connection copyWith({
    Map<String, dynamic>? lastData,
    String? name,
    String? status,
    bool? isIncoming,
  }) {
    return Connection(
      uid: uid,
      name: name ?? this.name,
      id: id,
      status: status ?? this.status,
      isIncoming: isIncoming ?? this.isIncoming,
      lastData: lastData ?? this.lastData,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'id': id,
        'status': status,
        'isIncoming': isIncoming,
      };

  factory Connection.fromJson(Map<String, dynamic> json) => Connection(
        uid: json['uid'],
        name: json['name'],
        id: json['id'],
        status: json['status'] ?? 'accepted',
        isIncoming: json['isIncoming'] ?? false,
      );
}

class SocialState {
  final List<Connection> connections;
  final bool isLoading;

  SocialState({required this.connections, this.isLoading = false});

  SocialState copyWith({List<Connection>? connections, bool? isLoading}) {
    return SocialState(
      connections: connections ?? this.connections,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final socialProvider = StateNotifierProvider<SocialNotifier, SocialState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SocialNotifier(prefs);
});

class SocialNotifier extends StateNotifier<SocialState> {
  final SharedPreferences _prefs;
  static const _storageKey = 'fina_connections';
  StreamSubscription? _sub;

  SocialNotifier(this._prefs) : super(SocialState(connections: [])) {
    _loadFromPrefs();
    _initFirestoreListener();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _initFirestoreListener() {
    _sub = FirebaseService().streamRelationships().listen((snapshot) {
      final myUid = FirebaseService().currentUser?.uid;
      if (myUid == null) return;

      final List<Connection> updatedList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final fromUid = data['fromUid'];
        final toUid = data['toUid'];
        final status = data['status'] ?? 'pending';

        final isIncoming = toUid == myUid;
        final peerUid = isIncoming ? fromUid : toUid;
        final peerName = isIncoming ? data['fromName'] : data['toName'];

        updatedList.add(Connection(
          uid: peerUid,
          name: peerName,
          id: doc.id,
          status: status,
          isIncoming: isIncoming,
        ));
      }

      // Merge with local names if available (or just use Firestore names)
      state = state.copyWith(connections: updatedList);
      _saveToPrefs();
      refreshAll();
    });
  }

  void _loadFromPrefs() {
    final data = _prefs.getStringList(_storageKey);
    if (data != null) {
      final list = data.map((e) => Connection.fromJson(jsonDecode(e))).toList();
      state = state.copyWith(connections: list);
      refreshAll();
    }
  }

  Future<void> _saveToPrefs() async {
    final data = state.connections.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_storageKey, data);
  }

  Future<bool> addConnection(String uid, String name, String myName) async {
    if (state.connections.any((e) => e.uid == uid)) return false;

    // First request in Firestore
    await FirebaseService().requestRelationship(uid, myName, name);
    
    // Note: The listener will automatically update our state when the doc is created.
    return true;
  }

  Future<void> acceptConnection(String docId) async {
    await FirebaseService().updateRelationshipStatus(docId, 'accepted');
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
    final data = await FirebaseService().fetchSnapshot(uid);
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
