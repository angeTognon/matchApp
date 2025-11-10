import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:amical_club/providers/search_provider.dart';
import 'package:amical_club/models/team.dart';
import 'package:amical_club/constant.dart';
import 'package:amical_club/widgets/app_logo.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    searchProvider.searchTeams(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<SearchProvider>(
          builder: (context, searchProvider, child) {
            return Column(
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
                      Row(
                        children: [
                          const AppLogoSmall(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Rechercher des Équipes',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _searchController,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        decoration: InputDecoration(
                          hintText: 'Nom d\'équipe, ville, catégorie...',
                          hintStyle: TextStyle(color: Theme.of(context).hintColor),
                          prefixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.bodyMedium?.color),
                          suffixIcon: searchProvider.isLoading
                              ? Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.all(14),
                                  child: const CircularProgressIndicator(strokeWidth: 2),
                                )
                              : null,
                        ),
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
                  child: searchProvider.isLoadingFilters
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          itemCount: searchProvider.categories.length,
                          itemBuilder: (context, index) {
                            final filter = searchProvider.categories[index];
                            final isActive = searchProvider.selectedCategory == filter;

                            return Container(
                              margin: const EdgeInsets.only(right: 10),
                              child: FilterChip(
                                label: Text(filter),
                                selected: isActive,
                                onSelected: (selected) {
                                  searchProvider.filterByCategory(filter);
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
                        '${searchProvider.filteredTeams.length} équipe${searchProvider.filteredTeams.length > 1 ? 's' : ''} trouvée${searchProvider.filteredTeams.length > 1 ? 's' : ''}',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Implémenter la vue carte
                        },
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

                // Gestion des états
                if (searchProvider.isLoading)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Chargement des équipes...'),
                        ],
                      ),
                    ),
                  )
                else if (searchProvider.errorMessage != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              searchProvider.errorMessage!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => searchProvider.loadTeams(),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (searchProvider.filteredTeams.isEmpty && _searchController.text.isNotEmpty)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey),
                          SizedBox(height: 15),
                          Text(
                            'Aucune équipe trouvée',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Essayez de modifier vos critères de recherche',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Liste des équipes
                  Expanded(
                    child: searchProvider.filteredTeams.isNotEmpty
                        ? ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: searchProvider.filteredTeams.length,
                            itemBuilder: (context, index) {
                              final team = searchProvider.filteredTeams[index];
                              return _buildTeamCard(team);
                            },
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey),
                                SizedBox(height: 15),
                                Text(
                                  'Recherchez des équipes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Tapez un nom d\'équipe ou une ville',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTeamCard(Team team) {
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
                backgroundImage: team.logo != null && team.logo!.isNotEmpty
                    ? NetworkImage('$baseUrl/${team.logo}')
                    : null,
                child: team.logo == null || team.logo!.isEmpty
                    ? Icon(Icons.groups, color: Theme.of(context).textTheme.titleMedium?.color)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
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
                          team.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        Text(' • ', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                        Text(
                          team.level,
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
                          team.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        Text(
                          ' • ${team.distance}',
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
                    'Actif récemment',
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
                  onPressed: () => context.push('/team/${team.id}'),
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
                  onPressed: () => context.push('/contact/${team.id}'),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Contacter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
