import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _sampleChats = [
    {
      'id': '1',
      'teamName': 'FC Provence',
      'lastMessage': 'Parfait pour dimanche à 15h !',
      'timestamp': '14:32',
      'unreadCount': 2,
      'online': true,
    },
    {
      'id': '2',
      'teamName': 'Olympic Marseille Amateur',
      'lastMessage': 'Le terrain sera-t-il disponible ?',
      'timestamp': 'Hier',
      'unreadCount': 0,
      'online': false,
    },
    {
      'id': '3',
      'teamName': 'AS Toulon',
      'lastMessage': 'Merci pour le match, à bientôt !',
      'timestamp': '3 jan',
      'unreadCount': 0,
      'online': true,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = _sampleChats.where((chat) {
      final searchQuery = _searchController.text.toLowerCase();
      return chat['teamName'].toLowerCase().contains(searchQuery);
    }).toList();

    final totalUnread = _sampleChats.fold<int>(0, (sum, chat) => sum + (chat['unreadCount'] as int));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Messagerie',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (totalUnread > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$totalUnread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _searchController,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une conversation...',
                      hintStyle: TextStyle(color: Theme.of(context).hintColor),
                      prefixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ],
              ),
            ),

            // Liste des conversations
            Expanded(
              child: filteredChats.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: filteredChats.length,
                      itemBuilder: (context, index) {
                        final chat = filteredChats[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                          ),
                          child: ListTile(
                            onTap: () => context.push('/chat/${chat['id']}'),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Theme.of(context).cardColor,
                                  child: Icon(Icons.groups, color: Theme.of(context).textTheme.titleMedium?.color),
                                ),
                                if (chat['online']) ...[
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            title: Text(
                              chat['teamName'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.titleMedium?.color,
                              ),
                            ),
                            subtitle: Text(
                              chat['lastMessage'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  chat['timestamp'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (chat['unreadCount'] > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 20),
                                    child: Text(
                                      '${chat['unreadCount']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
                          const SizedBox(height: 15),
                          Text(
                            _searchController.text.isNotEmpty 
                                ? 'Aucune conversation trouvée'
                                : 'Aucune conversation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'Essayez avec un autre nom d\'équipe'
                                : 'Vos conversations avec les autres coachs apparaîtront ici',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}