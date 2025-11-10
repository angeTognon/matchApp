import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amical_club/providers/match_provider.dart';
import 'package:amical_club/providers/auth_provider.dart';
import 'package:amical_club/widgets/match_card.dart';
import 'package:amical_club/widgets/filter_modal.dart';
import 'package:amical_club/config/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _showFilterModal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final matchProvider = Provider.of<MatchProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated && authProvider.token != null) {
      await matchProvider.loadMatches(token: authProvider.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Matchs Proposés',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Rechercher une équipe ou lieu...',
                            prefixIcon: Icon(Icons.search),
                            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          ),
                          onChanged: (value) {
                            final matchProvider = Provider.of<MatchProvider>(context, listen: false);
                            matchProvider.applyFilters(search: value);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => setState(() => _showFilterModal = true),
                          icon: const Icon(Icons.filter_list, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Stats cards
            Consumer<MatchProvider>(
              builder: (context, matchProvider, child) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              children: [
                                const Icon(Icons.emoji_events, color: AppTheme.successColor, size: 20),
                                const SizedBox(height: 5),
                                Text(
                                  '${matchProvider.matchesThisMonth}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.titleLarge?.color,
                                  ),
                                ),
                                Text(
                                  'Matchs ce mois',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              children: [
                                const Icon(Icons.groups, color: AppTheme.primaryColor, size: 20),
                                const SizedBox(height: 5),
                                Text(
                                  '${matchProvider.nearbyTeamsCount}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.titleLarge?.color,
                                  ),
                                ),
                                Text(
                                  'Équipes proches',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            Expanded(
              child: Consumer<MatchProvider>(
                builder: (context, matchProvider, child) {
                  if (matchProvider.isLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Chargement des matchs...'),
                        ],
                      ),
                    );
                  }

                  if (matchProvider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            matchProvider.errorMessage!,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadMatches,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (matchProvider.matches.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aucun match disponible',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Aucun match ne correspond à vos critères',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadMatches,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: matchProvider.matches.length,
                      itemBuilder: (context, index) {
                        return MatchCard(match: matchProvider.matches[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Modal de filtres
      bottomSheet: _showFilterModal
          ? FilterModal(
              filters: Provider.of<MatchProvider>(context, listen: false).filters,
              onApplyFilters: (filters) {
                final matchProvider = Provider.of<MatchProvider>(context, listen: false);
                matchProvider.applyFilters(
                  category: filters['category'],
                  level: filters['level'],
                  gender: filters['gender'],
                  distance: filters['distance'],
                );
                setState(() {
                  _showFilterModal = false;
                });
              },
              onClose: () {
                setState(() {
                  _showFilterModal = false;
                });
              },
            )
          : null,
    );
  }
}