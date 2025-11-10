import 'package:amical_club/models/message.dart';
import 'package:amical_club/models/chat_user.dart';

class Conversation {
  final String id;
  final ChatUser otherUser;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    required this.unreadCount,
    this.lastMessageAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['conversation_id']?.toString() ?? '',
      otherUser: ChatUser.fromJson(json['other_user'] ?? {}),
      lastMessage: json['last_message'] != null 
          ? Message.fromJson(json['last_message']) 
          : null,
      unreadCount: json['unread_count'] ?? 0,
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.tryParse(json['last_message_at']) 
          : null,
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': id,
      'other_user': otherUser.toJson(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Conversation copyWith({
    String? id,
    ChatUser? otherUser,
    Message? lastMessage,
    int? unreadCount,
    DateTime? lastMessageAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Conversation(id: $id, otherUser: ${otherUser.name}, unreadCount: $unreadCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Conversation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
