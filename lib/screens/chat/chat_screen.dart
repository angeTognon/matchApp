import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amical_club/providers/auth_provider.dart';
import 'package:amical_club/providers/chat_provider.dart';
import 'package:amical_club/models/conversation.dart';
import 'package:amical_club/models/message.dart';
import 'package:amical_club/models/chat_user.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Conversation? _conversation;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    // Arrêter la mise à jour automatique des messages
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.stopMessageUpdates();
    
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Charger les messages
    chatProvider.loadMessages(widget.conversationId, authProvider);
    
    // Marquer les messages comme lus
    chatProvider.markMessagesAsRead(widget.conversationId, authProvider);
    
    // Récupérer les informations de la conversation
    _conversation = chatProvider.getConversationById(widget.conversationId);
    
    // Démarrer la mise à jour automatique des messages
    chatProvider.startMessageUpdates(authProvider);
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final message = _messageController.text.trim();
      _messageController.clear();
    _isSending = true;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Trouver l'ID du destinataire
    final otherUserId = _conversation?.otherUser.id;
    if (otherUserId == null) {
      _isSending = false;
      return;
    }

    final success = await chatProvider.sendMessage(
      receiverId: otherUserId,
      message: message,
      authProvider: authProvider,
    );

    _isSending = false;

    if (success) {
      // Faire défiler vers le bas
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chatProvider.errorMessage ?? 'Erreur lors de l\'envoi du message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _conversation != null
            ? Row(
          children: [
                  _buildTeamAvatarForHeader(_conversation!.otherUser),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _conversation!.otherUser.name,
                      style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
              )
            : const Text('Chat'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading && chatProvider.messages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    chatProvider.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMessages,
                    child: const Text('Réessayer'),
          ),
        ],
      ),
            );
          }

          return Column(
        children: [
              // Liste des messages
          Expanded(
                child: chatProvider.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun message',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Envoyez votre premier message',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: chatProvider.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatProvider.messages[index];
                          return _buildMessageBubble(context, message);
                        },
                      ),
              ),
              
              // Zone de saisie
              _buildMessageInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, Message message) {
    final isMyMessage = message.isMyMessage;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMyMessage 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage) ...[
            _buildTeamAvatarForMessage(message.sender),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMyMessage
                    ? Colors.green
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isMyMessage 
                      ? const Radius.circular(20) 
                      : const Radius.circular(4),
                  bottomRight: isMyMessage 
                      ? const Radius.circular(4) 
                      : const Radius.circular(20),
                ),
                border: !isMyMessage 
                    ? Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMyMessage
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(
                      color: isMyMessage
                          ? Colors.white.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isMyMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: message.sender.avatar != null && 
                  message.sender.avatar!.isNotEmpty
                  ? NetworkImage(message.sender.avatar!)
                  : null,
              child: message.sender.avatar == null || 
                  message.sender.avatar!.isEmpty
                  ? Text(
                      message.sender.name.isNotEmpty 
                          ? message.sender.name[0].toUpperCase() 
                          : '?',
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
            ),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Tapez votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                      ),
                      maxLines: null,
              textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
          const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamAvatarForHeader(ChatUser user) {
    // Priorité 1: Logo d'équipe (si disponible)
    if (user.teams != null && user.teams!.isNotEmpty) {
      final teamWithLogo = user.teams!.firstWhere(
        (team) => team.logo != null && team.logo!.isNotEmpty,
        orElse: () => user.teams!.first,
      );
      
      if (teamWithLogo.logo != null && teamWithLogo.logo!.isNotEmpty) {
        return CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(teamWithLogo.logo!),
          onBackgroundImageError: (exception, stackTrace) {
            // En cas d'erreur de chargement de l'image, afficher l'avatar utilisateur
          },
          child: null,
        );
      }
    }
    
    // Priorité 2: Avatar de l'utilisateur
    if (user.avatar != null && user.avatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(user.avatar!),
        onBackgroundImageError: (exception, stackTrace) {
          // En cas d'erreur, afficher les initiales
        },
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 14),
        ),
      );
    }
    
    // Fallback: afficher les initiales
    return CircleAvatar(
      radius: 16,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTeamAvatarForMessage(ChatUser user) {
    // Priorité 1: Logo d'équipe (si disponible)
    if (user.teams != null && user.teams!.isNotEmpty) {
      final teamWithLogo = user.teams!.firstWhere(
        (team) => team.logo != null && team.logo!.isNotEmpty,
        orElse: () => user.teams!.first,
      );
      
      if (teamWithLogo.logo != null && teamWithLogo.logo!.isNotEmpty) {
        return CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(teamWithLogo.logo!),
          onBackgroundImageError: (exception, stackTrace) {
            // En cas d'erreur de chargement de l'image, afficher l'avatar utilisateur
          },
          child: null,
        );
      }
    }
    
    // Priorité 2: Avatar de l'utilisateur
    if (user.avatar != null && user.avatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(user.avatar!),
        onBackgroundImageError: (exception, stackTrace) {
          // En cas d'erreur, afficher les initiales
        },
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 12),
        ),
      );
    }
    
    // Fallback: afficher les initiales
    return CircleAvatar(
      radius: 16,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}