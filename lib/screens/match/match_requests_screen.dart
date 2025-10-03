import 'package:flutter/material.dart';

class MatchRequestsScreen extends StatefulWidget {
  final String matchId;

  const MatchRequestsScreen({super.key, required this.matchId});

  @override
  State<MatchRequestsScreen> createState() => _MatchRequestsScreenState();
}

class _MatchRequestsScreenState extends State<MatchRequestsScreen> {
  List<Map<String, dynamic>> _requests = [
    {
      'id': 'req-1',
      'teamId': 'team-1',
      'teamName': 'AS Cannes',
      'coachName': 'Michel Leblanc',
      'category': 'Séniors',
      'level': 'Départemental',
      'location': 'Cannes',
      'distance': '45 km',
      'message': 'Bonjour, notre équipe serait intéressée par votre proposition de match.',
      'requestedAt': '2025-01-15 14:30',
      'recentMatches': [
        {'opponent': 'FC Nice', 'score': '2-1', 'result': 'win'},
        {'opponent': 'AS Monaco', 'score': '1-3', 'result': 'loss'},
        {'opponent': 'OGC Nice', 'score': '0-0', 'result': 'draw'},
      ],
    },
    {
      'id': 'req-2',
      'teamId': 'team-2',
      'teamName': 'FC Nice Amateur',
      'coachName': 'Laurent Moreau',
      'category': 'Séniors',
      'level': 'Départemental',
      'location': 'Nice',
      'distance': '32 km',
      'message': 'Salut ! Votre créneau nous convient parfaitement.',
      'requestedAt': '2025-01-15 16:45',
      'recentMatches': [
        {'opponent': 'AS Cannes', 'score': '3-0', 'result': 'win'},
        {'opponent': 'FC Antibes', 'score': '2-2', 'result': 'draw'},
        {'opponent': 'US Monaco', 'score': '1-0', 'result': 'win'},
      ],
    },
  ];

  void _handleAcceptRequest(String requestId, String teamName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le match'),
        content: Text('Voulez-vous confirmer le match avec $teamName ? Les autres demandes seront automatiquement refusées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _requests.clear());
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Match confirmé ! 🎉'),
                  content: Text('Le match avec $teamName est maintenant confirmé.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _handleRejectRequest(String requestId, String teamName) {
    setState(() {
      _requests.removeWhere((req) => req['id'] == requestId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Demande de $teamName refusée')),
    );
  }

  Color _getResultColor(String result) {
    switch (result) {
      case 'win':
        return Colors.green;
      case 'draw':
        return Colors.orange;
      case 'loss':
        return Colors.red;
      default:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Demandes reçues'),
            Text(
              '${_requests.length} demande${_requests.length > 1 ? 's' : ''} en attente',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: _requests.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final request = _requests[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header équipe
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            child: Icon(Icons.groups, color: Theme.of(context).textTheme.titleMedium?.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request['teamName'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).textTheme.titleMedium?.color,
                                  ),
                                ),
                                Text(
                                  'Entraîneur: ${request['coachName']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      request['category'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                    Text(' • ', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                                    Text(
                                      request['level'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                    Text(' • ', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                                    Text(
                                      request['distance'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            request['requestedAt'],
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Message
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Message de l\'équipe :',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).textTheme.titleMedium?.color,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              request['message'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Derniers matchs (scores uniquement)
                      Text(
                        'Derniers résultats',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...request['recentMatches'].map<Widget>((match) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                match['opponent'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.titleMedium?.color,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    match['score'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _getResultColor(match['result']),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getResultColor(match['result']),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 15),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _handleRejectRequest(request['id'], request['teamName']),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Refuser'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.chat_bubble_outline, size: 16),
                              label: const Text('Discuter'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Theme.of(context).dividerColor),
                                foregroundColor: Theme.of(context).textTheme.titleMedium?.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleAcceptRequest(request['id'], request['teamName']),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Accepter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(height: 15),
                  Text(
                    'Aucune demande',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Les demandes de participation à vos matchs apparaîtront ici',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}