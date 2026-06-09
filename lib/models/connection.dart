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
        // Persist lastData so it survives app restarts
        if (lastData != null) 'lastData': lastData,
      };

  factory Connection.fromJson(Map<String, dynamic> json) => Connection(
        uid: json['uid'],
        name: json['name'],
        id: json['id'],
        status: json['status'] ?? 'accepted',
        isIncoming: json['isIncoming'] ?? false,
        lastData: json['lastData'] != null
            ? Map<String, dynamic>.from(json['lastData'])
            : null,
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
