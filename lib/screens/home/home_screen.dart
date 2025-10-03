import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amical_club/providers/match_provider.dart';
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
  Map<String, String> _filters = {
    'category': '',
    'level': '',
    'distance': '',
    'gender': '',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                          onChanged: (value) => setState(() {}),
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
            Container(
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
                              '12',
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
                              '47',
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
            ),
            
            Expanded(
              child: Consumer<MatchProvider>(
                builder: (context, matchProvider, child) {
                  final filteredMatches = matchProvider.matches.where((match) {
                    final searchQuery = _searchController.text.toLowerCase();
                    return match.teamName.toLowerCase().contains(searchQuery) ||
                           match.location.toLowerCase().contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredMatches.length,
                    itemBuilder: (context, index) {
                      return MatchCard(match: filteredMatches[index]);
                    },
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
              filters: _filters,
              onApplyFilters: (filters) {
                setState(() {
                  _filters = filters;
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