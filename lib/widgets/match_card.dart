import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amical_club/models/match.dart';

class MatchCard extends StatelessWidget {
  final Match match;

  const MatchCard({super.key, required this.match});

  String _getStatusText() {
    if (match.createdBy == 'me') {
      switch (match.status) {
        case MatchStatus.available:
          return 'En attente d\'adversaire';
        case MatchStatus.pending:
          return 'Demande reçue';
        case MatchStatus.confirmed:
          return 'Match confirmé';
        case MatchStatus.requestsReceived:
          return '${match.requestsCount} demande${match.requestsCount > 1 ? 's' : ''} reçue${match.requestsCount > 1 ? 's' : ''}';
        case MatchStatus.finished:
          return 'Terminé ${match.homeScore}-${match.awayScore}';
        default:
          return match.status.displayName;
      }
    } else {
      switch (match.status) {
        case MatchStatus.requestsSent:
          return 'Demande envoyée';
        case MatchStatus.finished:
          return 'Terminé ${match.homeScore}-${match.awayScore}';
        default:
          return match.status.displayName;
      }
    }
  }

  void _handleCardPress(BuildContext context) {
    if (match.status == MatchStatus.finished) {
      context.push('/match/${match.id}/score');
    } else if (match.createdBy == 'me' && match.requestsCount > 0) {
      context.push('/match/${match.id}/requests');
    } else {
      context.push('/match/${match.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec nom équipe et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.teamName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.groups, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                          const SizedBox(width: 5),
                          Text(
                            match.category,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.emoji_events, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                          const SizedBox(width: 5),
                          Text(
                            match.level,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: match.status.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Détails du match
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                const SizedBox(width: 8),
                Text(
                  '${match.date.day}/${match.date.month}/${match.date.year}',
                  style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
                const SizedBox(width: 15),
                Icon(Icons.access_time, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                const SizedBox(width: 8),
                Text(
                  match.time,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.location,
                    style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ),
                Text(
                  '• ${match.distance}',
                  style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleCardPress(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      foregroundColor: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    child: const Text('Voir détails'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/contact/${match.id}'),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Contacter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}