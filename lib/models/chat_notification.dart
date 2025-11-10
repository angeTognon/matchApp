import 'package:amical_club/models/message.dart';
import 'package:amical_club/models/chat_user.dart';

class ChatNotification {
  final String id;
  final String conversationId;
  final String messageId;
  final bool isRead;
  final DateTime createdAt;
  final Message message;
  final ChatUser sender;
  final ChatUser otherUser;

  ChatNotification({
    required this.id,
    required this.conversationId,
    required this.messageId,
    required this.isRead,
    required this.createdAt,
    required this.message,
    required this.sender,
    required this.otherUser,
  });

  factory ChatNotification.fromJson(Map<String, dynamic> json) {
    return ChatNotification(
      id: json['notification_id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      messageId: json['message_id']?.toString() ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      message: Message.fromJson(json['message'] ?? {}),
      sender: ChatUser.fromJson(json['sender'] ?? {}),
      otherUser: ChatUser.fromJson(json['other_user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': id,
      'conversation_id': conversationId,
      'message_id': messageId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'message': message.toJson(),
      'sender': sender.toJson(),
      'other_user': otherUser.toJson(),
    };
  }

  ChatNotification copyWith({
    String? id,
    String? conversationId,
    String? messageId,
    bool? isRead,
    DateTime? createdAt,
    Message? message,
    ChatUser? sender,
    ChatUser? otherUser,
  }) {
    return ChatNotification(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      messageId: messageId ?? this.messageId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      message: message ?? this.message,
      sender: sender ?? this.sender,
      otherUser: otherUser ?? this.otherUser,
    );
  }

  @override
  String toString() {
    return 'ChatNotification(id: $id, sender: ${sender.name}, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
