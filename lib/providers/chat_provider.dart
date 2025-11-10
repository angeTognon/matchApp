import 'dart:async';
import 'package:flutter/material.dart';
import 'package:amical_club/models/conversation.dart';
import 'package:amical_club/models/message.dart';
import 'package:amical_club/models/chat_notification.dart';
import 'package:amical_club/services/api_service.dart';
import 'package:amical_club/services/notification_service.dart';
import 'package:amical_club/providers/auth_provider.dart';

class ChatProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  List<ChatNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _unreadCount = 0;
  String? _currentConversationId;
  Timer? _messageTimer;
  Timer? _conversationTimer;
  final NotificationService _notificationService = NotificationService();

  // Getters
  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  List<ChatNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;
  String? get currentConversationId => _currentConversationId;

  // Charger les conversations
  Future<void> loadConversations(AuthProvider authProvider) async {
    if (authProvider.token == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getConversations(token: authProvider.token!);
      
      if (response['success'] == true) {
        _conversations = (response['conversations'] as List)
            .map((json) => Conversation.fromJson(json))
            .toList();
        
        // Calculer le nombre total de messages non lus
        _unreadCount = _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
        
        // Debug: afficher le nombre de messages non lus
        print('🔢 ChatProvider: ${_conversations.length} conversations, $_unreadCount messages non lus');
      } else {
        _errorMessage = response['message'] ?? 'Erreur lors du chargement des conversations';
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Charger les messages d'une conversation
  Future<void> loadMessages(String conversationId, AuthProvider authProvider) async {
    if (authProvider.token == null) return;

    _currentConversationId = conversationId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getMessages(
        token: authProvider.token!,
        conversationId: conversationId,
      );
      
      if (response['success'] == true) {
        final currentUserId = authProvider.currentCoach?.id.toString();
        _messages = (response['messages'] as List)
            .map((json) => Message.fromJson(json, currentUserId: currentUserId))
            .toList();
      } else {
        _errorMessage = response['message'] ?? 'Erreur lors du chargement des messages';
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Envoyer un message
  Future<bool> sendMessage({
    required String receiverId,
    required String message,
    required AuthProvider authProvider,
    String messageType = 'text',
    String? fileUrl,
  }) async {
    if (authProvider.token == null) return false;

    try {
      final response = await ApiService.sendMessage(
        token: authProvider.token!,
        receiverId: receiverId,
        message: message,
        messageType: messageType,
        fileUrl: fileUrl,
      );
      
      if (response['success'] == true) {
        // Rafraîchir immédiatement les messages pour voir le nouveau message
        if (_currentConversationId != null) {
          await loadMessages(_currentConversationId!, authProvider);
        }
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Erreur lors de l\'envoi du message';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion: $e';
      notifyListeners();
      return false;
    }
  }

  // Marquer les messages comme lus
  Future<void> markMessagesAsRead(String conversationId, AuthProvider authProvider) async {
    if (authProvider.token == null) return;

    try {
      await ApiService.markMessagesRead(
        token: authProvider.token!,
        conversationId: conversationId,
      );
      
      // Mettre à jour l'état local
      _updateConversationReadStatus(conversationId);
      notifyListeners();
    } catch (e) {
      print('Erreur lors du marquage des messages comme lus: $e');
    }
  }

  // Charger les notifications
  Future<void> loadNotifications(AuthProvider authProvider) async {
    if (authProvider.token == null) return;

    try {
      final response = await ApiService.getChatNotifications(token: authProvider.token!);
      
      if (response['success'] == true) {
        _notifications = (response['notifications'] as List)
            .map((json) => ChatNotification.fromJson(json))
            .toList();
        _unreadCount = response['unread_count'] ?? 0;
      }
    } catch (e) {
      print('Erreur lors du chargement des notifications: $e');
    }
  }

  // Ajouter un message reçu (pour les mises à jour en temps réel)
  void addReceivedMessage(Message message) {
    if (message.conversationId == _currentConversationId) {
      _messages.add(message);
    }
    
    _updateConversationWithNewMessage(message);
    notifyListeners();
  }

  // Mettre à jour une conversation avec un nouveau message
  void _updateConversationWithNewMessage(Message message) {
    final conversationIndex = _conversations.indexWhere(
      (conv) => conv.id == message.conversationId
    );
    
    if (conversationIndex != -1) {
      final conversation = _conversations[conversationIndex];
      _conversations[conversationIndex] = conversation.copyWith(
        lastMessage: message,
        lastMessageAt: message.createdAt,
        updatedAt: DateTime.now(),
        unreadCount: message.isMyMessage ? 0 : conversation.unreadCount + 1,
      );
    }
  }

  // Mettre à jour le statut de lecture d'une conversation
  void _updateConversationReadStatus(String conversationId) {
    final conversationIndex = _conversations.indexWhere(
      (conv) => conv.id == conversationId
    );
    
    if (conversationIndex != -1) {
      final conversation = _conversations[conversationIndex];
      _conversations[conversationIndex] = conversation.copyWith(
        unreadCount: 0,
      );
    }
  }

  // Obtenir une conversation par ID
  Conversation? getConversationById(String id) {
    try {
      return _conversations.firstWhere((conv) => conv.id == id);
    } catch (e) {
      return null;
    }
  }

  // Vider les messages (quand on quitte une conversation)
  void clearMessages() {
    _messages.clear();
    _currentConversationId = null;
    notifyListeners();
  }

  // Vider les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Rafraîchir les conversations
  Future<void> refreshConversations(AuthProvider authProvider) async {
    await loadConversations(authProvider);
  }

  // Rafraîchir les messages
  Future<void> refreshMessages(AuthProvider authProvider) async {
    if (_currentConversationId != null) {
      await loadMessages(_currentConversationId!, authProvider);
    }
  }

  // Démarrer la mise à jour automatique des messages
  void startMessageUpdates(AuthProvider authProvider) {
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentConversationId != null && authProvider.token != null) {
        _checkForNewMessages(authProvider);
      }
    });
  }

  // Arrêter la mise à jour automatique des messages
  void stopMessageUpdates() {
    _messageTimer?.cancel();
    _messageTimer = null;
  }

  // Démarrer la mise à jour automatique des conversations
  void startConversationUpdates(AuthProvider authProvider) {
    _conversationTimer?.cancel();
    _conversationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (authProvider.token != null) {
        _checkForNewConversations(authProvider);
      }
    });
  }

  // Arrêter la mise à jour automatique des conversations
  void stopConversationUpdates() {
    _conversationTimer?.cancel();
    _conversationTimer = null;
  }

  // Vérifier les nouveaux messages
  Future<void> _checkForNewMessages(AuthProvider authProvider) async {
    if (_currentConversationId == null) return;

    try {
      final response = await ApiService.getMessages(
        token: authProvider.token!,
        conversationId: _currentConversationId!,
      );
      
      if (response['success'] == true) {
        final currentUserId = authProvider.currentCoach?.id.toString();
        final newMessages = (response['messages'] as List)
            .map((json) => Message.fromJson(json, currentUserId: currentUserId))
            .toList();
        
        // Vérifier s'il y a de nouveaux messages
        if (newMessages.length > _messages.length) {
          final previousCount = _messages.length;
          _messages = newMessages;
          
          // Vérifier s'il y a de nouveaux messages (pas seulement une actualisation)
          if (previousCount > 0 && newMessages.length > previousCount) {
            // Il y a de nouveaux messages, déclencher les notifications
            _handleNewMessages(newMessages.sublist(previousCount), authProvider);
          }
          
          notifyListeners();
        }
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement pour ne pas spammer
    }
  }

  // Vérifier les nouvelles conversations
  Future<void> _checkForNewConversations(AuthProvider authProvider) async {
    try {
      final response = await ApiService.getConversations(token: authProvider.token!);
      
      if (response['success'] == true) {
        final newConversations = (response['conversations'] as List)
            .map((json) => Conversation.fromJson(json))
            .toList();
        
        // Vérifier s'il y a de nouvelles conversations ou des mises à jour
        bool hasChanges = false;
        
        if (newConversations.length != _conversations.length) {
          hasChanges = true;
        } else {
          for (int i = 0; i < newConversations.length; i++) {
            if (newConversations[i].updatedAt != _conversations[i].updatedAt ||
                newConversations[i].unreadCount != _conversations[i].unreadCount) {
              hasChanges = true;
              break;
            }
          }
        }
        
        if (hasChanges) {
          _conversations = newConversations;
          _unreadCount = _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
          
          // Debug: afficher le nombre de messages non lus
          print('🔄 ChatProvider: Mise à jour - ${_conversations.length} conversations, $_unreadCount messages non lus');

      notifyListeners();
    }
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement
    }
  }

  // Gérer les nouveaux messages et déclencher les notifications
  Future<void> _handleNewMessages(List<Message> newMessages, AuthProvider authProvider) async {
    for (final message in newMessages) {
      // Ne pas notifier pour nos propres messages
      if (!message.isMyMessage) {
        try {
          await _notificationService.showNewMessageNotification(
            senderName: message.sender.name,
            message: message.message,
            conversationId: int.parse(message.conversationId),
          );
        } catch (e) {
          print('Erreur lors de l\'affichage de la notification: $e');
        }
      }
    }
  }

  // Initialiser les notifications
  Future<void> initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _conversationTimer?.cancel();
    super.dispose();
  }
}