import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  String _requestStatus = 'none'; // none, pending, accepted, rejected

  final Map<String, dynamic> _matchDetails = {
    '1': {
      'id': '1',
      'teamName': 'FC Marseille Amateur',
      'coachName': 'Pierre Martin',
      'category': 'Séniors',
      'level': 'Départemental',
      'date': '2025-01-20',
      'time': '15:00',
      'location': 'Marseille, Stade Municipal',
      'address': '123 Avenue du Stade, 13001 Marseille',
      'distance': '2.5 km',
      'status': 'En attente',
      'description': 'Nous recherchons une équipe de niveau similaire pour un match amical. Terrain en excellent état, vestiaires disponibles.',
      'facilities': ['Vestiaires', 'Douches', 'Parking', 'Buvette'],
    }
  };

  Future<void> _handleInterest() async {
    setState(() => _requestStatus = 'pending');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demande envoyée !'),
        content: const Text('Votre demande de participation a été envoyée à l\'équipe organisatrice.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Simulate response after 3 seconds
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  final responses = ['accepted', 'rejected'];
                  final randomResponse = responses[DateTime.now().millisecond % 2];
                  setState(() => _requestStatus = randomResponse);
                  
                  if (randomResponse == 'accepted') {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Demande acceptée ! 🎉'),
                        content: const Text('Votre demande a été acceptée. Le match est maintenant confirmé !'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Super !'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Demande refusée'),
                        content: const Text('Votre demande n\'a pas été retenue cette fois.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    switch (_requestStatus) {
      case 'pending':
        return 'Demande en cours...';
      case 'accepted':
        return 'Match confirmé !';
      case 'rejected':
        return 'Demande refusée';
      default:
        return 'Je suis intéressé';
    }
  }

  Color _getButtonColor() {
    switch (_requestStatus) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = _matchDetails[widget.matchId] ?? _matchDetails['1'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du match'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header équipe
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).cardColor,
                    child: Icon(Icons.groups, color: Theme.of(context).textTheme.titleLarge?.color),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match['teamName'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        Text(
                          'Entraîneur: ${match['coachName']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.groups, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                            const SizedBox(width: 5),
                            Text(
                              match['category'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.emoji_events, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                            const SizedBox(width: 5),
                            Text(
                              match['level'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      match['status'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Informations du match
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations du match',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 20, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).textTheme.titleMedium?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              match['date'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).textTheme.titleMedium?.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 20, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Heure',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).textTheme.titleMedium?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              match['time'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).textTheme.titleMedium?.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on, size: 20, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Lieu',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).textTheme.titleMedium?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    match['location'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).textTheme.titleMedium?.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  Text(
                                    match['address'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  Text(
                                    'À ${match['distance']} de vous',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    match['description'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Équipements disponibles
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Équipements disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: (match['facilities'] as List<String>).map((facility) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: Colors.green),
                            const SizedBox(width: 6),
                            Text(
                              facility,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/contact/${widget.matchId}'),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Contacter'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  foregroundColor: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _requestStatus == 'none' ? _handleInterest : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getButtonColor(),
                ),
                child: Text(_getButtonText()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}