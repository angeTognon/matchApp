import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:amical_club/providers/match_provider.dart';

class MatchScoreScreen extends StatefulWidget {
  final String matchId;

  const MatchScoreScreen({super.key, required this.matchId});

  @override
  State<MatchScoreScreen> createState() => _MatchScoreScreenState();
}

class _MatchScoreScreenState extends State<MatchScoreScreen> {
  final _homeScoreController = TextEditingController();
  final _awayScoreController = TextEditingController();
  final _notesController = TextEditingController();
  List<TextEditingController> _homeScorersControllers = [TextEditingController()];
  List<TextEditingController> _awayScorersControllers = [TextEditingController()];

  @override
  void dispose() {
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    _notesController.dispose();
    for (var controller in _homeScorersControllers) {
      controller.dispose();
    }
    for (var controller in _awayScorersControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateScorers() {
    final homeGoals = int.tryParse(_homeScoreController.text) ?? 0;
    final awayGoals = int.tryParse(_awayScoreController.text) ?? 0;

    // Ajuster les contrôleurs pour l'équipe domicile
    while (_homeScorersControllers.length < homeGoals) {
      _homeScorersControllers.add(TextEditingController());
    }
    while (_homeScorersControllers.length > homeGoals && _homeScorersControllers.length > 1) {
      _homeScorersControllers.removeLast().dispose();
    }

    // Ajuster les contrôleurs pour l'équipe extérieure
    while (_awayScorersControllers.length < awayGoals) {
      _awayScorersControllers.add(TextEditingController());
    }
    while (_awayScorersControllers.length > awayGoals && _awayScorersControllers.length > 1) {
      _awayScorersControllers.removeLast().dispose();
    }

    setState(() {});
  }

  Future<void> _saveScore() async {
    final homeScore = _homeScoreController.text;
    final awayScore = _awayScoreController.text;

    if (homeScore.isEmpty || awayScore.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir les scores des deux équipes')),
      );
      return;
    }

    final homeGoals = int.tryParse(homeScore) ?? -1;
    final awayGoals = int.tryParse(awayScore) ?? -1;

    if (homeGoals < 0 || awayGoals < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir des scores valides')),
      );
      return;
    }

    final homeScorers = _homeScorersControllers
        .map((controller) => controller.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    
    final awayScorers = _awayScorersControllers
        .map((controller) => controller.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (homeScorers.length != homeGoals) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le nombre de buteurs domicile (${homeScorers.length}) ne correspond pas au score ($homeGoals)')),
      );
      return;
    }

    if (awayScorers.length != awayGoals) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le nombre de buteurs extérieur (${awayScorers.length}) ne correspond pas au score ($awayGoals)')),
      );
      return;
    }

    final matchProvider = Provider.of<MatchProvider>(context, listen: false);
    await matchProvider.updateMatchScore(
      widget.matchId,
      homeScore,
      awayScore,
      homeScorers,
      awayScorers,
      _notesController.text,
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Score enregistré ! 🎉'),
          content: Text('Score final : $homeScore - $awayScore\n\nLes statistiques ont été mises à jour.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchProvider = Provider.of<MatchProvider>(context);
    final match = matchProvider.getMatchById(widget.matchId);

    if (match == null) {
      return const Scaffold(
        body: Center(child: Text('Match non trouvé')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saisir le score'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/main');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info du match
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Match terminé',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${match.date.day}/${match.date.month}/${match.date.year} à ${match.time} - ${match.location}',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Score final
            Text(
              'Score final',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 15),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            match.teamName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                            ),
                            child: TextField(
                              controller: _homeScoreController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                                contentPadding: EdgeInsets.zero,
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 2,
                              onChanged: (_) => _updateScorers(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Mon équipe',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                            ),
                            child: TextField(
                              controller: _awayScoreController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                                contentPadding: EdgeInsets.zero,
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 2,
                              onChanged: (_) => _updateScorers(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Buteurs équipe domicile
            if (int.tryParse(_homeScoreController.text) != null && 
                int.parse(_homeScoreController.text) > 0) ...[
              Text(
                'Buteurs - ${match.teamName}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 15),
              ..._homeScorersControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Buteur ${index + 1}',
                      prefixIcon: const Icon(Icons.sports_soccer, color: Colors.green),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
            ],

            // Buteurs équipe extérieure
            if (int.tryParse(_awayScoreController.text) != null && 
                int.parse(_awayScoreController.text) > 0) ...[
              Text(
                'Buteurs - Mon équipe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 15),
              ..._awayScorersControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Buteur ${index + 1}',
                      prefixIcon: const Icon(Icons.sports_soccer, color: Colors.green),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
            ],

            // Notes du match
            Text(
              'Notes du match (optionnel)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Commentaires sur le match, incidents, fair-play...',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 30),

            // Bouton sauvegarder
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: matchProvider.isLoading ? null : _saveScore,
                icon: const Icon(Icons.save),
                label: Text(
                  matchProvider.isLoading ? 'Enregistrement...' : 'Enregistrer le score',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}