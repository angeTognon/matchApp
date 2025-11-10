class ChatTeam {
  final String id;
  final String name;
  final String? logo;

  ChatTeam({
    required this.id,
    required this.name,
    this.logo,
  });

  factory ChatTeam.fromJson(Map<String, dynamic> json) {
    return ChatTeam(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      logo: json['logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
    };
  }
}

class ChatUser {
  final String id;
  final String name;
  final String? avatar;
  final String? email;
  final List<ChatTeam>? teams;

  ChatUser({
    required this.id,
    required this.name,
    this.avatar,
    this.email,
    this.teams,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      email: json['email'],
      teams: json['teams'] != null 
          ? (json['teams'] as List).map((team) => ChatTeam.fromJson(team)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'email': email,
      'teams': teams?.map((team) => team.toJson()).toList(),
    };
  }

  ChatUser copyWith({
    String? id,
    String? name,
    String? avatar,
    String? email,
    List<ChatTeam>? teams,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      email: email ?? this.email,
      teams: teams ?? this.teams,
    );
  }

  @override
  String toString() {
    return 'ChatUser(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
