import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:amical_club/providers/match_provider.dart';
import 'package:amical_club/providers/auth_provider.dart';
import 'package:amical_club/models/match.dart';
import 'package:amical_club/constant.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  Match? _match;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _loadMatchDetails();
  }

  Future<void> _loadMatchDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final matchProvider = Provider.of<MatchProvider>(context, listen: false);
    
    if (authProvider.token != null) {
      final match = await matchProvider.loadMatchDetails(
        token: authProvider.token!,
        matchId: widget.matchId,
      );
      
      if (mounted) {
        setState(() {
          _match = match;
          _isLoading = false;
          if (match == null) {
            _errorMessage = 'Match non trouvé';
          }
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Non authentifié';
      });
    }
  }

  Future<void> _handleInterest() async {
    if (_match == null) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Vérifier si c'est le match de l'utilisateur connecté
    if (_match!.isOwner == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas demander à rejoindre votre propre match !'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    setState(() => _isRequesting = true);
    
    try {
      final matchProvider = Provider.of<MatchProvider>(context, listen: false);
      
      // Utiliser la première équipe du coach pour la demande
      final coach = authProvider.currentCoach;
      if (coach == null || coach.teams.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune équipe disponible pour faire une demande'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final teamId = coach.teams.first.id;
      final success = await matchProvider.requestMatch(
        token: authProvider.token!,
        matchId: widget.matchId,
        teamId: teamId,
        message: 'Je suis intéressé par ce match',
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demande envoyée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          // Recharger les détails du match
          await _loadMatchDetails();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(matchProvider.errorMessage ?? 'Erreur lors de la demande'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  String _getButtonText() {
    if (_isRequesting) return 'Envoi en cours...';
    if (_match?.userHasRequested == true) return 'Demande envoyée';
    if (_match?.isOwner == true) return 'Votre match';
    return 'Je suis intéressé';
  }

  Color _getButtonColor() {
    if (_isRequesting) return Colors.grey;
    if (_match?.userHasRequested == true) return Colors.orange;
    if (_match?.isOwner == true) return Colors.grey;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Match non trouvé',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    final match = _match!;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // App Bar avec image de fond
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Contenu overlay
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Row(
                            children: [
                              // Logo de l'équipe
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: match.teamLogo != null && match.teamLogo!.isNotEmpty
                                      ? Image.network(
                                          '$baseUrl/${match.teamLogo}',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.sports_soccer,
                                              size: 30,
                                              color: Theme.of(context).colorScheme.primary,
                                            );
                                          },
                                        )
                                      : Icon(
                                          Icons.sports_soccer,
                                          size: 30,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      match.teamName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 3,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'Entraîneur: ${match.coachName}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(0, 1),
                                            blurRadius: 3,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Badge de statut
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: match.status.color,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  match.status.displayName,
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
                      ],
                    ),
                  ),
                ),
              ),

              // Contenu principal
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Informations principales du match
                    _buildMatchInfoCard(context, match),
                    
                    const SizedBox(height: 20),
                    
                    // Informations de l'équipe
                    _buildTeamInfoCard(context, match),
                    
                    const SizedBox(height: 20),
                    
                    // Équipements disponibles
                    if (match.facilities != null && match.facilities!.isNotEmpty)
                      _buildFacilitiesCard(context, match),
                    
                    const SizedBox(height: 20),
                    
                    // Description
                    if (match.description != null && match.description!.isNotEmpty)
                      _buildDescriptionCard(context, match),
                    
                    const SizedBox(height: 100), // Espace pour le bouton fixe
                  ],
                ),
              ),
            ],
          ),
          
          // Bouton d'action fixe
          floatingActionButton: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: FloatingActionButton.extended(
              onPressed: _match?.userHasRequested == true || _isRequesting || _match?.isOwner == true ? null : _handleInterest,
              backgroundColor: _getButtonColor(),
              foregroundColor: Colors.white,
              icon: Icon(_isRequesting ? Icons.hourglass_empty : Icons.favorite),
              label: Text(
                _getButtonText(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
  }

  // Widget pour les informations principales du match
  Widget _buildMatchInfoCard(BuildContext context, Match match) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Informations du match',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Date et heure
            _buildInfoRow(
              context,
              Icons.calendar_today,
              'Date',
              '${match.date.day}/${match.date.month}/${match.date.year}',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.access_time,
              'Heure',
              match.time,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.location_on,
              'Lieu',
              match.location,
              subtitle: match.stadium,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.groups,
              'Catégorie',
              match.category,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.emoji_events,
              'Niveau',
              match.level,
            ),
            if (match.gender != null && match.gender!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                Icons.person,
                'Genre',
                match.gender!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget pour les informations de l'équipe
  Widget _buildTeamInfoCard(BuildContext context, Match match) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Équipe organisatrice',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                // Logo de l'équipe
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: match.teamLogo != null && match.teamLogo!.isNotEmpty
                        ? Image.network(
                            '$baseUrl/${match.teamLogo}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.sports_soccer,
                                size: 30,
                                color: Theme.of(context).colorScheme.primary,
                              );
                            },
                          )
                        : Icon(
                            Icons.sports_soccer,
                            size: 30,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.teamName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        match.clubName ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            match.coachName,
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour les équipements
  Widget _buildFacilitiesCard(BuildContext context, Match match) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.checklist,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Équipements disponibles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${match.facilities?.length ?? 0}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: (match.facilities ?? []).map((facility) {
                  final facilityIcon = _getFacilityIcon(facility);
                  
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 64) / 2.3, // Largeur fixe pour 2 colonnes
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green.withOpacity(0.1),
                              Colors.green.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // S'adapte au contenu
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    facilityIcon,
                                    color: Colors.green,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 12,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              facility,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getFacilityDescription(facility),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fonction pour obtenir l'icône appropriée pour chaque équipement
  IconData _getFacilityIcon(String facility) {
    switch (facility.toLowerCase()) {
      case 'vestiaires':
        return Icons.dry_cleaning;
      case 'douches':
        return Icons.shower;
      case 'parking':
        return Icons.local_parking;
      case 'éclairage':
        return Icons.lightbulb;
      case 'tribunes':
        return Icons.chair;
      case 'buvette':
        return Icons.local_drink;
      case 'médecin':
        return Icons.medical_services;
      case 'arbitre':
        return Icons.sports;
      case 'ballons':
        return Icons.sports_soccer;
      case 'chasubles':
        return Icons.checkroom;
      default:
        return Icons.check_circle;
    }
  }

  // Fonction pour obtenir la description de chaque équipement
  String _getFacilityDescription(String facility) {
    switch (facility.toLowerCase()) {
      case 'vestiaires':
        return 'Vestiaires disponibles';
      case 'douches':
        return 'Douches après le match';
      case 'parking':
        return 'Parking gratuit';
      case 'éclairage':
        return 'Éclairage du terrain';
      case 'tribunes':
        return 'Tribunes pour spectateurs';
      case 'buvette':
        return 'Buvette sur place';
      case 'médecin':
        return 'Médecin présent';
      case 'arbitre':
        return 'Arbitre fourni';
      case 'ballons':
        return 'Ballons fournis';
      case 'chasubles':
        return 'Chasubles disponibles';
      default:
        return 'Équipement disponible';
    }
  }

  // Widget pour la description
  Widget _buildDescriptionCard(BuildContext context, Match match) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              match.description!,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper pour les lignes d'information
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {String? subtitle}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}