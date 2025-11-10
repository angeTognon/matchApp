import 'package:amical_club/models/chat_user.dart';

enum MessageType {
  text,
  image,
  file,
}

class Message {
  final String id;
  final String conversationId;
  final ChatUser sender;
  final ChatUser receiver;
  final String message;
  final MessageType type;
  final String? fileUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final bool isMyMessage;

  Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.receiver,
    required this.message,
    required this.type,
    this.fileUrl,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.isMyMessage,
  });

  factory Message.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final senderId = json['sender']?['id']?.toString() ?? '';
    final isMyMessage = currentUserId != null && senderId == currentUserId;
    
    return Message(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      sender: ChatUser.fromJson(json['sender'] ?? {}),
      receiver: ChatUser.fromJson(json['receiver'] ?? {}),
      message: json['message'] ?? '',
      type: _parseMessageType(json['type']),
      fileUrl: json['file_url'],
      isRead: (json['is_read'] == 1 || json['is_read'] == true),
      readAt: json['read_at'] != null 
          ? DateTime.tryParse(json['read_at']) 
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isMyMessage: isMyMessage,
    );
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'text':
      default:
        return MessageType.text;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender': sender.toJson(),
      'receiver': receiver.toJson(),
      'message': message,
      'type': type.name,
      'file_url': fileUrl,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_my_message': isMyMessage,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    ChatUser? sender,
    ChatUser? receiver,
    String? message,
    MessageType? type,
    String? fileUrl,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    bool? isMyMessage,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      message: message ?? this.message,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      isMyMessage: isMyMessage ?? this.isMyMessage,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, sender: ${sender.name}, message: $message, isMyMessage: $isMyMessage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
