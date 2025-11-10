import 'package:amical_club/constant.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:amical_club/providers/auth_provider.dart';
import 'package:amical_club/providers/match_provider.dart';
import 'package:amical_club/models/match.dart';
import 'package:amical_club/services/api_service.dart';
import 'package:amical_club/widgets/match_card.dart';

class MyMatchesScreen extends StatefulWidget {
  const MyMatchesScreen({super.key});

  @override
  State<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends State<MyMatchesScreen> {
  List<Match> _myMatches = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyMatches();
  }

  Future<void> _loadMyMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.token == null) {
        setState(() {
          _errorMessage = 'Non authentifié';
        });
        return;
      }

      // Essayer d'abord l'API getMyMatches si elle existe
      try {
        final response = await ApiService.getMyMatches(token: authProvider.token!);
        if (response['success'] == true) {
          final List<dynamic> matchesData = response['data']['matches'];
          setState(() {
            _myMatches = matchesData.map((json) => Match.fromJson(json)).toList();
          });
          return;
        }
      } catch (e) {
        print('⚠️ API getMyMatches non disponible, utilisation de getMatches: $e');
      }

      // Fallback: Utiliser l'API getMatches existante et filtrer côté client
      // Essayer différents statuts pour récupérer tous les matchs
      List<dynamic> allMatchesData = [];
      
      for (String status in ['pending', 'available', 'confirmed', 'finished']) {
        try {
          final response = await ApiService.getMatches(
            token: authProvider.token!,
            status: status,
            limit: 100,
          );
          
          if (response['success'] == true) {
            final List<dynamic> matches = response['data']['matches'];
            allMatchesData.addAll(matches);
            print('🔍 DEBUG: Statut $status: ${matches.length} matchs');
          }
        } catch (e) {
          print('🔍 DEBUG: Erreur pour statut $status: $e');
        }
      }
      
      print('🔍 DEBUG: Total matchs récupérés (tous statuts): ${allMatchesData.length}');

      if (allMatchesData.isEmpty) {
        print('🔍 DEBUG: Aucun match trouvé dans la base de données');
        setState(() {
          _myMatches = [];
        });
        return;
      }
        
      // Filtrer pour ne garder que les matchs du coach connecté
      final coach = authProvider.currentCoach;
      if (coach != null) {
        final myTeamIds = coach.teams.map((team) => team.id).toList();
        print('🔍 DEBUG: Mes équipes IDs: $myTeamIds');
        print('🔍 DEBUG: Coach: ${coach.name}, Nombre d\'équipes: ${coach.teams.length}');
        
        // Debug: afficher les team_id de tous les matchs
        for (var match in allMatchesData) {
          print('🔍 DEBUG: Match ${match['id']} - team_id: ${match['team_id']} (type: ${match['team_id'].runtimeType}) - team_name: ${match['team_name']}');
        }
        
        final myMatchesData = allMatchesData.where((matchData) {
          final matchTeamId = matchData['team_id'];
          // Convertir en string pour la comparaison
          final matchTeamIdStr = matchTeamId.toString();
          final isMyMatch = myTeamIds.contains(matchTeamIdStr);
          print('🔍 DEBUG: Match ${matchData['id']} - team_id: $matchTeamId (str: $matchTeamIdStr), isMyMatch: $isMyMatch');
          return isMyMatch;
        }).toList();
        
        print('🔍 DEBUG: Matchs filtrés: ${myMatchesData.length}');
        
        setState(() {
          _myMatches = myMatchesData.map((json) => Match.fromJson(json)).toList();
        });
      } else {
        print('🔍 DEBUG: Coach null');
        setState(() {
          _myMatches = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMatch(String matchId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final response = await ApiService.deleteMatch(
        token: authProvider.token!,
        matchId: matchId,
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        // Recharger la liste
        await _loadMyMatches();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(Match match) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer le match'),
          content: Text('Êtes-vous sûr de vouloir supprimer le match "${match.teamName}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMatch(match.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Matchs'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyMatches,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMyMatches,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _myMatches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun match publié',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Publiez votre premier match pour commencer !',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/create-match'),
                            icon: const Icon(Icons.add),
                            label: const Text('Publier un match'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMyMatches,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _myMatches.length,
                        itemBuilder: (context, index) {
                          final match = _myMatches[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => context.go('/match/${match.id}'),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // En-tête avec logo et informations de base
                                    Row(
                                      children: [
                                        // Logo de l'équipe
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          child: match.teamLogo != null && match.teamLogo!.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(25),
                                                  child: Image.network(
                                                    '$baseUrl}/${match.teamLogo}',
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Icon(
                                                        Icons.sports_soccer,
                                                        color: Theme.of(context).colorScheme.primary,
                                                        size: 24,
                                                      );
                                                    },
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.sports_soccer,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  size: 24,
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Informations de l'équipe
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                match.teamName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                match.clubName,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Badge de statut
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(match.status),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _getStatusText(match.status),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Informations du match
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${match.date} à ${match.time}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            match.location,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${match.category} - ${match.level}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // Actions
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => context.go('/edit-match/${match.id}'),
                                          icon: const Icon(Icons.edit, size: 18),
                                          label: const Text('Modifier'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () => _showDeleteDialog(match),
                                          icon: const Icon(Icons.delete, size: 18),
                                          label: const Text('Supprimer'),
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/create-match'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau match'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Color _getStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.available:
        return Colors.orange;
      case MatchStatus.pending:
        return Colors.blue;
      case MatchStatus.confirmed:
        return Colors.green;
      case MatchStatus.finished:
        return Colors.grey;
      case MatchStatus.requestsSent:
        return Colors.purple;
      case MatchStatus.requestsReceived:
        return Colors.teal;
    }
  }

  String _getStatusText(MatchStatus status) {
    switch (status) {
      case MatchStatus.available:
        return 'Disponible';
      case MatchStatus.pending:
        return 'En attente';
      case MatchStatus.confirmed:
        return 'Confirmé';
      case MatchStatus.finished:
        return 'Terminé';
      case MatchStatus.requestsSent:
        return 'Demande envoyée';
      case MatchStatus.requestsReceived:
        return 'Demandes reçues';
    }
  }
}
