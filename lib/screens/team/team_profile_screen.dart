import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeamProfileScreen extends StatelessWidget {
  final String teamId;

  const TeamProfileScreen({super.key, required this.teamId});

  final Map<String, dynamic> _teamDetails = const {
    '1': {
      'id': '1',
      'name': 'FC Provence',
      'coachName': 'Marc Dubois',
      'category': 'Séniors',
      'level': 'Départemental',
      'location': 'Aix-en-Provence',
      'distance': '3.2 km',
      'lastActive': '2 heures',
      'description': 'Club fondé en 1983, nous privilégions le fair-play et la convivialité. Notre équipe senior évolue en championnat départemental et recherche régulièrement des matchs amicaux pour progresser.',
      'founded': '1983',
      'homeStadium': 'Stade Municipal d\'Aix-en-Provence',
      'statistics': {
        'matches': 18,
        'wins': 11,
        'draws': 4,
        'losses': 3,
        'goalsScored': 42,
        'goalsConceded': 23,
      },
      'achievements': [
        'Champion Départemental 2023',
        'Finaliste Coupe Régionale 2022',
        'Fair-play Award 2024'
      ],
    }
  };

  Widget _buildStatCard(BuildContext context, String value, String label, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final team = _teamDetails[teamId] ?? _teamDetails['1'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil de l\'équipe'),
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
                    radius: 40,
                    backgroundColor: Theme.of(context).cardColor,
                    child: Icon(Icons.groups, size: 40, color: Theme.of(context).textTheme.titleMedium?.color),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team['name'],
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        Text(
                          'Entraîneur: ${team['coachName']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              team['category'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            Text(' • ', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                            Text(
                              team['level'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                            const SizedBox(width: 5),
                            Text(
                              team['location'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            Text(
                              ' • ${team['distance']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Actif il y a ${team['lastActive']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // À propos
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À propos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    team['description'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Informations
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations',
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
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text('Fondé en', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                        const Spacer(),
                        Text(
                          team['founded'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.titleMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.stadium, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Stade', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                              Text(
                                team['homeStadium'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.titleMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Statistiques
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistiques',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 15),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.2,
                    children: [
                      _buildStatCard(context, '${team['statistics']['matches']}', 'Matchs', Theme.of(context).textTheme.titleMedium?.color ?? Colors.black),
                      _buildStatCard(context, '${team['statistics']['wins']}', 'Victoires', Colors.green),
                      _buildStatCard(context, '${team['statistics']['draws']}', 'Nuls', Colors.orange),
                      _buildStatCard(context, '${team['statistics']['losses']}', 'Défaites', Colors.red),
                      _buildStatCard(context, '${team['statistics']['goalsScored']}', 'Buts marqués', Theme.of(context).colorScheme.primary),
                      _buildStatCard(context, '${team['statistics']['goalsConceded']}', 'Buts encaissés', Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ],
              ),
            ),

            // Palmarès
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Palmarès',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ...team['achievements'].map<Widget>((achievement) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            achievement,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
            Container(
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.phone, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/contact/${team['id']}'),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Contacter l\'équipe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}