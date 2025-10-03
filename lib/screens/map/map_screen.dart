import 'package:flutter/material.dart';
import 'package:amical_club/config/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _selectedTeamId;
  bool _showList = false;

  final List<Map<String, dynamic>> _teamsOnMap = [
    {
      'id': '1',
      'name': 'FC Provence',
      'category': 'Séniors',
      'level': 'Départemental',
      'distance': '3.2 km',
      'coordinates': {'x': 0.3, 'y': 0.4},
    },
    {
      'id': '2',
      'name': 'Olympic Marseille Amateur',
      'category': 'U19',
      'level': 'Régional',
      'distance': '5.8 km',
      'coordinates': {'x': 0.6, 'y': 0.3},
    },
    {
      'id': '3',
      'name': 'AS Toulon',
      'category': 'Vétérans',
      'level': 'Loisir',
      'distance': '12.4 km',
      'coordinates': {'x': 0.7, 'y': 0.7},
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selectedTeam = _teamsOnMap.firstWhere(
      (team) => team['id'] == _selectedTeamId,
      orElse: () => {},
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Carte des équipes'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            onPressed: () => setState(() => _showList = !_showList),
            icon: Icon(_showList ? Icons.map : Icons.list),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Carte simulée
          Container(
            width: double.infinity,
            height: double.infinity,
            color: AppTheme.surfaceColor,
            child: Stack(
              children: [
                // Grille de fond pour simuler une carte
                ...List.generate(20, (i) {
                  return Positioned(
                    left: (i % 5) * (MediaQuery.of(context).size.width / 5),
                    top: (i ~/ 5) * (MediaQuery.of(context).size.height / 4),
                    child: Container(
                      width: MediaQuery.of(context).size.width / 5,
                      height: MediaQuery.of(context).size.height / 4,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
                      ),
                    ),
                  );
                }),

                // Marqueurs d'équipes
                ..._teamsOnMap.map((team) {
                  final isSelected = _selectedTeamId == team['id'];
                  return Positioned(
                    left: team['coordinates']['x'] * (MediaQuery.of(context).size.width - 80),
                    top: team['coordinates']['y'] * (MediaQuery.of(context).size.height * 0.6),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTeamId = team['id']),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.successColor : AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.location_on, size: 20, color: Colors.white),
                      ),
                    ),
                  );
                }).toList(),

                // Marqueur utilisateur
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.5 - 15,
                  top: MediaQuery.of(context).size.height * 0.3,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.navigation, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Popup équipe sélectionnée
          if (selectedTeam.isNotEmpty) ...[
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedTeam['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${selectedTeam['category']} • ${selectedTeam['level']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      'À ${selectedTeam['distance']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.borderColor),
                              foregroundColor: AppTheme.textPrimary,
                            ),
                            child: const Text('Voir profil'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            child: const Text('Contacter'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Liste overlay
          if (_showList) ...[
            Container(
              color: AppTheme.backgroundColor,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Équipes proches',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _showList = false),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _teamsOnMap.length,
                      itemBuilder: (context, index) {
                        final team = _teamsOnMap[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: ListTile(
                            onTap: () {
                              setState(() {
                                _selectedTeamId = team['id'];
                                _showList = false;
                              });
                            },
                            title: Text(
                              team['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${team['category']} • ${team['level']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            trailing: Text(
                              team['distance'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Contrôles de carte
          Positioned(
            right: 20,
            bottom: 100,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.my_location, color: Colors.white),
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