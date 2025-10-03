import 'package:flutter/material.dart';
import 'package:amical_club/models/chat.dart';

class ChatProvider extends ChangeNotifier {
  List<Chat> _chats = [];
  bool _isLoading = false;

  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  int get totalUnreadCount => _chats.fold(0, (sum, chat) => sum + chat.unreadCount);

  ChatProvider() {
    _loadSampleChats();
  }

  void _loadSampleChats() {
    _chats = [
      Chat(
        id: '1',
        teamName: 'FC Provence',
        lastMessage: 'Parfait pour dimanche à 15h !',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        unreadCount: 2,
        avatar: 'https://images.pexels.com/photos/1884574/pexels-photo-1884574.jpeg',
        online: true,
        messages: [
          ChatMessage(
            id: '1',
            text: 'Salut ! Votre équipe serait-elle disponible pour un match amical ce dimanche ?',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isMe: false,
          ),
          ChatMessage(
            id: '2',
            text: 'Bonjour ! Oui, nous sommes libres. À quelle heure ?',
            timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 1)),
            isMe: true,
          ),
          ChatMessage(
            id: '3',
            text: 'Parfait ! Que pensez-vous de 15h au stade municipal ?',
            timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 2)),
            isMe: false,
          ),
          ChatMessage(
            id: '4',
            text: 'Parfait pour dimanche à 15h !',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
            isMe: true,
          ),
        ],
      ),
      Chat(
        id: '2',
        teamName: 'Olympic Marseille Amateur',
        lastMessage: 'Le terrain sera-t-il disponible ?',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 0,
        avatar: 'https://images.pexels.com/photos/114296/pexels-photo-114296.jpeg',
        online: false,
      ),
    ];
    notifyListeners();
  }

  Chat? getChatById(String id) {
    try {
      return _chats.firstWhere((chat) => chat.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> sendMessage(String chatId, String message) async {
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final newMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: message,
        timestamp: DateTime.now(),
        isMe: true,
      );

      final updatedMessages = List<ChatMessage>.from(_chats[chatIndex].messages)
        ..add(newMessage);

      _chats[chatIndex] = Chat(
        id: _chats[chatIndex].id,
        teamName: _chats[chatIndex].teamName,
        lastMessage: message,
        timestamp: DateTime.now(),
        unreadCount: _chats[chatIndex].unreadCount,
        avatar: _chats[chatIndex].avatar,
        online: _chats[chatIndex].online,
        messages: updatedMessages,
      );

      notifyListeners();
    }
  }
}