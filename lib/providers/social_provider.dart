import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fina/services/firebase_service.dart';
import 'package:fina/providers/settings_provider.dart';

class Connection {
  final String uid;
  final String name;
  final Map<String, dynamic>? lastData;

  Connection({required this.uid, required this.name, this.lastData});

  Connection copyWith({Map<String, dynamic>? lastData, String? name}) {
    return Connection(
      uid: uid,
      name: name ?? this.name,
      lastData: lastData ?? this.lastData,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
  };

  factory Connection.fromJson(Map<String, dynamic> json) => Connection(
    uid: json['uid'],
    name: json['name'],
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

  SocialNotifier(this._prefs) : super(SocialState(connections: [])) {
    _loadFromPrefs();
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

  Future<bool> addConnection(String uid, String name) async {
    if (state.connections.any((e) => e.uid == uid)) return false;

    final newConnection = Connection(uid: uid, name: name);
    state = state.copyWith(connections: [...state.connections, newConnection]);
    await _saveToPrefs();
    refreshConnection(uid);
    return true;
  }

  Future<void> removeConnection(String uid) async {
    state = state.copyWith(
      connections: state.connections.where((e) => e.uid != uid).toList(),
    );
    await _saveToPrefs();
  }

  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true);
    for (final conn in state.connections) {
      await refreshConnection(conn.uid);
    }
    state = state.copyWith(isLoading: false);
  }

  Future<void> refreshConnection(String uid) async {
    final data = await FirebaseService().fetchSnapshot(uid);
    if (data != null) {
      state = state.copyWith(
        connections: state.connections.map((e) {
          if (e.uid == uid) {
            // Update name if present in shared data
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
