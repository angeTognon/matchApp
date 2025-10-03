class Chat {
  final String id;
  final String teamName;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final String? avatar;
  final bool online;
  final List<ChatMessage> messages;

  Chat({
    required this.id,
    required this.teamName,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    this.avatar,
    required this.online,
    this.messages = const [],
  });
}

class ChatMessage {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });
}