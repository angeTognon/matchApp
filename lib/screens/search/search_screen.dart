import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _activeFilter = 'Toutes';

  final List<String> _filters = [
    'Toutes', 'Séniors', 'U19', 'U17', 'Vétérans', 'Masculin', 'Féminin', 'Mixte'
  ];

  final List<Map<String, dynamic>> _sampleTeams = [
    {
      'id': '1',
      'name': 'FC Provence',
      'category': 'Séniors',
      'level': 'Départemental',
      'location': 'Aix-en-Provence',
      'distance': '3.2 km',
      'lastActive': '2 heures',
    },
    {
      'id': '2',
      'name': 'Olympic Marseille Amateur',
      'category': 'U19',
      'level': 'Régional',
      'location': 'Marseille Centre',
      'distance': '5.8 km',
      'lastActive': '1 jour',
    },
    {
      'id': '3',
      'name': 'AS Toulon',
      'category': 'Vétérans',
      'level': 'Loisir',
      'location': 'Toulon Est',
      'distance': '12.4 km',
      'lastActive': '3 heures',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTeams = _sampleTeams.where((team) {
      final searchQuery = _searchController.text.toLowerCase();
      final matchesSearch = team['name'].toLowerCase().contains(searchQuery) ||
                          team['location'].toLowerCase().contains(searchQuery);
      final matchesFilter = _activeFilter == 'Toutes' || team['category'] == _activeFilter;
      
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header avec recherche
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rechercher des Équipes',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _searchController,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    decoration: InputDecoration(
                      hintText: 'Nom d\'équipe, ville, catégorie...',
                      hintStyle: TextStyle(color: Theme.of(context).hintColor),
                      prefixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ],
              ),
            ),

            // Filtres
            Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isActive = _activeFilter == filter;
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isActive,
                      onSelected: (selected) {
                        setState(() => _activeFilter = filter);
                      },
                      backgroundColor: Theme.of(context).cardColor,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isActive ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Header résultats
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredTeams.length} équipe${filteredTeams.length > 1 ? 's' : ''} trouvée${filteredTeams.length > 1 ? 's' : ''}',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.map, size: 16, color: Theme.of(context).colorScheme.primary),
                    label: Text(
                      'Voir sur la carte',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Liste des équipes
            Expanded(
              child: filteredTeams.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredTeams.length,
                      itemBuilder: (context, index) {
                        final team = filteredTeams[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            children: [
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
                                          team['name'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).textTheme.titleMedium?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              team['category'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                              ),
                                            ),
                                            Text(' • ', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                                            Text(
                                              team['level'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                                            const SizedBox(width: 5),
                                            Text(
                                              team['location'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                              ),
                                            ),
                                            Text(
                                              ' • ${team['distance']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).textTheme.bodySmall?.color,
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
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Actif il y a ${team['lastActive']}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => context.push('/team/${team['id']}'),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Theme.of(context).dividerColor),
                                        foregroundColor: Theme.of(context).textTheme.titleMedium?.color,
                                      ),
                                      child: const Text('Voir profil'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => context.push('/contact/${team['id']}'),
                                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                      label: const Text('Contacter'),
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
                          Icon(Icons.search_off, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
                          const SizedBox(height: 15),
                          Text(
                            'Aucune équipe trouvée',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Essayez de modifier vos critères de recherche',
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