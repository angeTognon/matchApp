import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _sampleMessages = [
    {
      'id': '1',
      'text': 'Salut ! Votre équipe serait-elle disponible pour un match amical ce dimanche ?',
      'timestamp': '14:30',
      'isMe': false,
    },
    {
      'id': '2',
      'text': 'Bonjour ! Oui, nous sommes libres. À quelle heure ?',
      'timestamp': '14:31',
      'isMe': true,
    },
    {
      'id': '3',
      'text': 'Parfait ! Que pensez-vous de 15h au stade municipal ?',
      'timestamp': '14:32',
      'isMe': false,
    },
    {
      'id': '4',
      'text': 'Parfait pour dimanche à 15h !',
      'timestamp': '14:32',
      'isMe': true,
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _sampleMessages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'text': _messageController.text.trim(),
          'timestamp': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          'isMe': true,
        });
      });
      _messageController.clear();
      
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FC Provence'),
            Text(
              'En ligne',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.phone),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.videocam),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _sampleMessages.length,
              itemBuilder: (context, index) {
                final message = _sampleMessages[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: message['isMe'] 
                        ? MainAxisAlignment.end 
                        : MainAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: message['isMe'] 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: message['isMe'] 
                                ? const Radius.circular(4) 
                                : const Radius.circular(16),
                            bottomLeft: message['isMe'] 
                                ? const Radius.circular(16) 
                                : const Radius.circular(4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['text'],
                              style: TextStyle(
                                fontSize: 16,
                                color: message['isMe'] ? Colors.white : Theme.of(context).textTheme.titleMedium?.color,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message['timestamp'],
                              style: TextStyle(
                                fontSize: 10,
                                color: message['isMe'] ? Colors.white70 : Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      decoration: InputDecoration(
                        hintText: 'Tapez votre message...',
                        hintStyle: TextStyle(color: Theme.of(context).hintColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      ),
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send, color: Theme.of(context).textTheme.titleMedium?.color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}