import 'dart:convert';
import 'package:amical_club/models/team.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Pour FilteringTextInputFormatter
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:amical_club/providers/auth_provider.dart';
import 'package:amical_club/providers/theme_provider.dart';
import 'package:amical_club/services/api_service.dart';
import 'package:amical_club/constant.dart';
import 'package:amical_club/widgets/app_logo.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTeamIndex = 0;
  bool _notifications = true;
  int _matchesRefreshKey = 0; // Clé pour forcer le refresh

  // Récupérer tous les matchs terminés de toutes les équipes de l'utilisateur
  Future<List<Map<String, dynamic>>> _getAllCompletedMatches(AuthProvider authProvider) async {
    List<Map<String, dynamic>> allMatches = [];
    
    try {
      // Pour chaque équipe de l'utilisateur, récupérer les matchs terminés
      for (var team in authProvider.currentCoach!.teams) {
        final response = await ApiService.getPublicTeam(
          token: authProvider.token!,
          teamId: team.id,
        );
        
        if (response['success'] == true && response['data'] != null) {
          final teamData = response['data'];
          final completedMatches = teamData['completed_matches'] as List<dynamic>? ?? [];
          
          // Ajouter les matchs avec le nom de l'équipe
          for (var match in completedMatches) {
            allMatches.add({
              ...match,
              'team_name': teamData['name'], // Ajouter le nom de l'équipe
            });
          }
        }
      }
      
      // Trier par date décroissante
      allMatches.sort((a, b) {
        final dateA = DateTime.tryParse(a['match_date'] ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['match_date'] ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
      
      // Limiter à 15 matchs
      return allMatches.take(15).toList();
    } catch (e) {
      print('Erreur lors de la récupération des matchs terminés: $e');
      return [];
    }
  }

  Widget _buildMatchResult(String opponent, String score, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            opponent,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.titleMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Text(
                score,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Afficher un indicateur de chargement si en cours
            if (authProvider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Chargement...'),
                  ],
                ),
              );
            }

            // Vérifier si l'utilisateur est authentifié
            if (!authProvider.isAuthenticated) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Non authentifié'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => context.go('/auth/login'),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
              );
            }

            final coach = authProvider.currentCoach;
            if (coach == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_off, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text('Données utilisateur non disponibles'),
                    const SizedBox(height: 8),
                    if (authProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          authProvider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vérifiez votre connexion internet ou reconnectez-vous.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            await authProvider.checkAuthentication();
                          },
                          child: const Text('Réessayer'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () {
                            authProvider.logout();
                            context.go('/auth/login');
                          },
                          child: const Text('Se reconnecter'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              // appBar: AppBar(
              //   title: const Text('Profil'),
              //   backgroundColor: Theme.of(context).colorScheme.primary,
              //   foregroundColor: Colors.white,
              //   actions: [
              //     IconButton(
              //       icon: const Icon(Icons.refresh),
              //       onPressed: () async {
              //         await authProvider.checkAuthentication();
              //       },
              //       tooltip: 'Actualiser',
              //     ),
              //   ],
              // ),
              body: SingleChildScrollView(
              child: Column(
                children: [
                  // En-tête avec logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const AppLogoSmall(),
                        const SizedBox(width: 12),
                        const Text(
                          'Mon Profil',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () async {
                            await authProvider.checkAuthentication();
                          },
                          tooltip: 'Actualiser',
                        ),
                      ],
                    ),
                  ),
                  // Section profil coach
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              backgroundImage: coach.avatar != null && coach.avatar!.isNotEmpty
                                  ? NetworkImage('$baseUrl/${coach.avatar}')
                                  : null,
                              child: coach.avatar == null || coach.avatar!.isEmpty
                                  ? Text(
                                      coach.name.isNotEmpty ? coach.name[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Entraîneur: ${coach.name}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (coach.licenseNumber.isNotEmpty)
                        Text(
                            'Licence FFF: ${coach.licenseNumber}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (coach.licenseNumber.isNotEmpty) const SizedBox(height: 2),
                        if (coach.experience.isNotEmpty)
                        Text(
                            coach.experience + ' ans d\'expériences',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${coach.teams.length} équipe${coach.teams.length > 1 ? 's' : ''} dans ${coach.totalClubs} club${coach.totalClubs > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (coach.location.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                            const SizedBox(width: 5),
                            Text(
                                coach.location,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Boutons d'action
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: TextButton.icon(
                                        onPressed: () => context.push('/edit-profile'),
                                        icon: Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.primary),
                                        label: Text(
                                          'Modifier le profil',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 1,
                                        ),
                                      ),
                                      child: TextButton.icon(
                                        onPressed: () => context.push('/my-matches'),
                                        icon: Icon(Icons.sports_soccer, size: 16, color: Theme.of(context).colorScheme.primary),
                                        label: Text(
                                          'Mes matchs',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Nouveau bouton pour les demandes
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.orange,
                                    width: 1,
                                  ),
                                ),
                                child: TextButton.icon(
                                  onPressed: () => context.push('/match-requests'),
                                  icon: const Icon(Icons.mail_outline, size: 16, color: Colors.orange),
                                  label: const Text(
                                    'Demandes de match',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Section équipes
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child:                                                   Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                            'Mes équipes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => context.push('/create-team'),
                                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                                  label: const Text(
                                    'Ajouter',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: coach.teams.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                      Icon(
                                        Icons.groups_outlined,
                                        size: 48,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                      const SizedBox(height: 12),
                                        Text(
                                        'Aucune équipe',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          color: Theme.of(context).textTheme.titleMedium?.color,
                                        ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                        'Créez votre première équipe',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () => context.push('/create-team'),
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Créer ma première équipe'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: coach.teams.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final team = entry.value;
                                      return Container(
                                        width: 200,
                                        margin: EdgeInsets.only(
                                          right: index < coach.teams.length - 1 ? 15 : 0,
                                        ),
                                  child: InkWell(
                                    onTap: () {
                                                    setState(() => _selectedTeamIndex = index);
                                      
                                    },
                                    child: Container(
                                            height: 140, // Hauteur minimale pour toutes les cartes
                                      decoration: BoxDecoration(
                                              color: _selectedTeamIndex == index
                                                  ? Theme.of(context).brightness == Brightness.light
                                                      ? Colors.white
                                                      : Theme.of(context).colorScheme.surface
                                                  : Theme.of(context).brightness == Brightness.light
                                                      ? Colors.grey.shade50
                                                      : Theme.of(context).colorScheme.surface,
                                              borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                                color: _selectedTeamIndex == index
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Theme.of(context).brightness == Brightness.light
                                                        ? Colors.grey.shade300
                                                        : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                          width: 2,
                                        ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _selectedTeamIndex == index
                                                      ? Theme.of(context).brightness == Brightness.light
                                                          ? Colors.grey.shade400.withOpacity(0.3)
                                                          : Theme.of(context).colorScheme.primary.withOpacity(0.3)
                                                      : Theme.of(context).brightness == Brightness.light
                                                          ? Colors.grey.shade300.withOpacity(0.3)
                                                          : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                  blurRadius: _selectedTeamIndex == index ? 12 : 6,
                                                  offset: _selectedTeamIndex == index 
                                                      ? const Offset(0, 6) 
                                                      : const Offset(0, 2),
                                                ),
                                              ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Header avec actions
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Row(
                                                    children: [
                                                      // Logo de l'équipe ou icône par défaut
                                                      Container(
                                                        width: 36,
                                                        height: 36,
                                                        decoration: BoxDecoration(
                                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: team.logo != null && team.logo!.isNotEmpty
                                                            ? ClipRRect(
                                                                borderRadius: BorderRadius.circular(10),
                                                                child: Image.network(
                                                                  '$baseUrl/${team.logo}',
                                                                  fit: BoxFit.cover,
                                                                  errorBuilder: (context, error, stackTrace) {
                                                                    return Icon(
                                                                      Icons.sports_soccer,
                                                                      size: 20,
                                                                      color: Theme.of(context).colorScheme.primary,
                                                                    );
                                                                  },
                                                                ),
                                                              )
                                                            : Icon(
                                                                Icons.sports_soccer,
                                                                size: 20,
                                                                color: Theme.of(context).colorScheme.primary,
                                                              ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      // Informations du club
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                              Text(
                                                              team.clubName,
                                                style: TextStyle(
                                                                fontSize: 13,
                                                                fontWeight: FontWeight.w600,
                                                  color: Theme.of(context).textTheme.titleMedium?.color,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              team.name,
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                                color: Theme.of(context).textTheme.titleLarge?.color,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      // Menu d'actions
                                                      PopupMenuButton<String>(
                                                        icon: Icon(
                                                          Icons.more_vert,
                                                          color: Theme.of(context).textTheme.bodyMedium?.color,
                                                        ),
                                                        onSelected: (value) {
                                                          if (value == 'edit') {
                                                            context.push('/edit-team/${team.id}');
                                                          } else if (value == 'delete') {
                                                            _showDeleteTeamDialog(context, team);
                                                          }
                                                        },
                                                        itemBuilder: (context) => [
                                                          PopupMenuItem(
                                                            value: 'edit',
                                                            child: Row(
                                                              children: [
                                                                Icon(Icons.edit, size: 18, color: Theme.of(context).colorScheme.primary),
                                                                const SizedBox(width: 8),
                                                                const Text('Modifier'),
                                                              ],
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            value: 'delete',
                                                            child: Row(
                                                              children: [
                                                                const Icon(Icons.delete, size: 18, color: Colors.red),
                                                                const SizedBox(width: 8),
                                                                const Text('Supprimer'),
                                                              ],
                                                ),
                                              ),
                                            ],
                                          ),
                                                    ],
                                                  ),
                                                ),
                                                // Contenu principal (cliquable pour sélectionner)
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() => _selectedTeamIndex = index);
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          // Badges catégorie et niveau
                                                          Row(
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                decoration: BoxDecoration(
                                                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  border: Border.all(
                                                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  team.category,
                                            style: TextStyle(
                                                                    fontSize: 11,
                                                                    fontWeight: FontWeight.w500,
                                                                    color: Theme.of(context).colorScheme.secondary,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(width: 8),
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.orange.withOpacity(0.2),
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  border: Border.all(
                                                                    color: Colors.orange.withOpacity(0.4),
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  team.level,
                                            style: TextStyle(
                                                                    fontSize: 11,
                                                                    fontWeight: FontWeight.w500,
                                              color: Colors.orange,
                                                                  ),
                                            ),
                                                              ),
                                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                                                    ),
                                                                  ),
                                                                ],
                                            ),
                                          ),
                                  ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  

                  // Informations équipe
                  if (coach.teams.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Informations - ${coach.teams[_selectedTeamIndex].name}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                                child: Column(
                                  children: [
                                    Icon(Icons.business, color: Theme.of(context).textTheme.titleMedium?.color, size: 24),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Club',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      coach.teams[_selectedTeamIndex].clubName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).textTheme.titleMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                children: [
                                    Icon(Icons.groups, color: Theme.of(context).textTheme.titleMedium?.color, size: 24),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Catégorie',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      coach.teams[_selectedTeamIndex].category,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).textTheme.titleMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.emoji_events, color: Theme.of(context).textTheme.titleMedium?.color, size: 24),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Niveau',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      coach.teams[_selectedTeamIndex].level,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).textTheme.titleMedium?.color,
                                      ),
                                    ),
                                ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Derniers matchs
                  if (coach.teams.isNotEmpty && coach.teams[_selectedTeamIndex].recentMatches.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Derniers matchs - ${coach.teams[_selectedTeamIndex].name}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 15),
                          ...coach.teams[_selectedTeamIndex].recentMatches.map((match) => 
                            _buildMatchResult(match.opponent, match.score, match.result.color)
                          ),
                      ],
                    ),
                  ),

                  // Section Matchs en cours (confirmés)
                  _buildConfirmedMatchesSection(context, authProvider),
                  
                  // Section des derniers matchs terminés
                  _buildCompletedMatchesSection(context, authProvider),

                  // Paramètres
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paramètres',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return ListTile(
                              leading: Icon(Icons.dark_mode, color: Theme.of(context).textTheme.bodyMedium?.color),
                              title: Text(
                                'Mode sombre',
                                style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.titleMedium?.color),
                              ),
                              trailing: Switch(
                                value: themeProvider.isDarkMode,
                                onChanged: (value) => themeProvider.toggleTheme(),
                                activeColor: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          },
                        ),
                        
                        ListTile(
                          leading: Icon(Icons.notifications, color: Theme.of(context).textTheme.bodyMedium?.color),
                          title: Text(
                            'Notifications',
                            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.titleMedium?.color),
                          ),
                          trailing: Switch(
                            value: _notifications,
                            onChanged: (value) => setState(() => _notifications = value),
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        
                        ListTile(
                          leading: Icon(Icons.security, color: Theme.of(context).textTheme.bodyMedium?.color),
                          title: Text(
                            'Confidentialité & Permissions',
                            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.titleMedium?.color),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                          onTap: () => context.push('/settings/privacy'),
                        ),
                        
                        ListTile(
                          leading: Icon(Icons.share, color: Theme.of(context).textTheme.bodyMedium?.color),
                          title: Text(
                            'Partager l\'application',
                            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.titleMedium?.color),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                          onTap: () {},
                        ),
                        
                        const SizedBox(height: 20),
                        
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: Text(
                            'Se déconnecter',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () async {
                            await authProvider.logout();
                            if (mounted) context.go('/auth/login');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteTeamDialog(BuildContext context, Team team) {
    bool _isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    _isDeleting ? Icons.hourglass_empty : Icons.warning,
                    color: _isDeleting ? Colors.orange : Colors.red,
                    size: 28
                  ),
                  const SizedBox(width: 10),
                  Text(_isDeleting ? 'Suppression en cours...' : 'Supprimer l\'équipe'),
                ],
              ),
              content: _isDeleting
                ? const Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text('Suppression en cours...'),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Êtes-vous sûr de vouloir supprimer l\'équipe :'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              team.clubName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            Text(
                              '${team.category} - ${team.level}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '⚠️ Cette action est irréversible et supprimera également tous les matchs associés à cette équipe.',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              actions: _isDeleting
                ? [] // Pas de boutons pendant la suppression
                : [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() => _isDeleting = true);

                        try {
                          final authProvider = Provider.of<AuthProvider>(dialogContext, listen: false);
                          final success = await authProvider.deleteTeam(team.id);

                          if (success) {
                            Navigator.of(context).pop(); // Fermer le dialog
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Équipe "${team.name}" supprimée avec succès'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } else {
                            setState(() => _isDeleting = false); // Remettre l'état initial
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(authProvider.errorMessage ?? 'Erreur lors de la suppression'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => _isDeleting = false); // Remettre l'état initial
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Supprimer'),
                    ),
                  ],
            );
          },
        );
      },
    );
  }

  Widget _buildConfirmedMatchesSection(BuildContext context, AuthProvider authProvider) {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey('confirmed_matches_$_matchesRefreshKey'), // Clé unique pour les matchs confirmés
      future: ApiService.getConfirmedMatches(token: authProvider.token!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!['success'] != true) {
          return const SizedBox.shrink(); // Ne rien afficher si erreur
        }

        final matches = snapshot.data!['data']['matches'] as List<dynamic>;
        
        if (matches.isEmpty) {
          return const SizedBox.shrink(); // Ne rien afficher si pas de matchs
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Matchs en cours',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${matches.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              ...matches.map((matchData) => _buildConfirmedMatchCard(context, matchData, authProvider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfirmedMatchCard(BuildContext context, Map<String, dynamic> matchData, AuthProvider authProvider) {
    final hasScore = matchData['score'] != null && matchData['score'].toString().isNotEmpty;
    final homeConfirmed = matchData['home_confirmed'] == true || matchData['home_confirmed'] == 1;
    final awayConfirmed = matchData['away_confirmed'] == true || matchData['away_confirmed'] == 1;
    final bothConfirmed = matchData['both_confirmed'] == true || matchData['both_confirmed'] == 1;
    final isHost = matchData['type'] == 'confirmed'; // Si type='confirmed', c'est l'hôte
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          // Bandeau vert
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  'Match confirmé',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${matchData['team_name']} vs ${matchData['opponent']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (matchData['category'] != null) ...[
                                Text(
                                  matchData['category'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                if (matchData['level'] != null) ...[
                                  const Text(' • '),
                                  Text(
                                    matchData['level'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (hasScore)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getResultColor(matchData['result']).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          matchData['score'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getResultColor(matchData['result']),
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                
                // Date et lieu
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                    const SizedBox(width: 8),
                    Text(
                      matchData['date_formatted'] ?? matchData['date'],
                      style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    const SizedBox(width: 15),
                    Icon(Icons.access_time, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                    const SizedBox(width: 8),
                    Text(
                      matchData['time_formatted'] ?? matchData['time'],
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
                        matchData['location'] ?? '',
                        style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // BOUTON EN BAS de la carte - TOUJOURS VISIBLE
          const Divider(height: 1),
          
          Padding(
            padding: const EdgeInsets.all(15),
            child: SizedBox(
              width: double.infinity,
              child: () {
                // Si les 2 ont confirmé
                if (bothConfirmed) {
                  if (isHost && !hasScore) {
                    return ElevatedButton.icon(
                      onPressed: () => _showCompleteMatchDetailsDialog(context, matchData, authProvider),
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: const Text('Ajouter les détails'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    );
                  } else if (isHost && hasScore) {
                    return OutlinedButton.icon(
                      onPressed: () => _showCompleteMatchDetailsDialog(context, matchData, authProvider),
                      icon: const Icon(Icons.edit, size: 20),
                      label: const Text('Modifier les détails'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    );
                  } else {
                    // Pour l'équipe adverse après validation
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Validé • En attente des détails',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }
                }
                
                // Si vous avez déjà confirmé
                final youConfirmed = (isHost && homeConfirmed) || (!isHost && awayConfirmed);
                if (youConfirmed) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.hourglass_empty, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'En attente de l\'autre équipe',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }
                
                // Bouton par défaut pour confirmer
                return ElevatedButton.icon(
                  onPressed: () => _confirmMatchCompletion(context, matchData, authProvider),
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: const Text('Match terminé'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                );
              }(),
            ),
          ),
        ], // Fermeture de children du Column
      ),
    );
  }

  Color _getResultColor(String? result) {
    switch (result) {
      case 'win':
        return Colors.green;
      case 'draw':
        return Colors.orange;
      case 'loss':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Fonction pour mettre à jour le résultat automatiquement selon les scores
  void _updateResultFromScores(String homeScore, String awayScore, StateSetter setDialogState, String Function() getSelectedResult, void Function(String) setSelectedResult) {
    final home = int.tryParse(homeScore) ?? 0;
    final away = int.tryParse(awayScore) ?? 0;
    
    String newResult;
    if (home > away) {
      newResult = 'win';
    } else if (home < away) {
      newResult = 'loss';
    } else {
      newResult = 'draw';
    }
    
    setDialogState(() {
      setSelectedResult(newResult);
    });
  }

  // Fonction pour obtenir l'icône du résultat
  IconData _getResultIcon(String? result) {
    switch (result) {
      case 'win':
        return Icons.emoji_events;
      case 'draw':
        return Icons.handshake;
      case 'loss':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.help_outline;
    }
  }

  // Fonction pour obtenir le texte du résultat
  String _getResultText(String? result, String teamName) {
    switch (result) {
      case 'win':
        return 'Victoire de $teamName';
      case 'draw':
        return 'Match nul';
      case 'loss':
        return 'Défaite de $teamName';
      default:
        return 'Résultat à déterminer';
    }
  }

  // Fonction pour valider le nombre de buts d'un buteur
  String? _validateScorerGoals(int scorerGoals, int teamScore) {
    if (scorerGoals > teamScore) {
      return 'Max: $teamScore';
    }
    return null;
  }

  // Fonction pour calculer le total des buts d'une équipe
  int _calculateTotalGoals(List<Map<String, dynamic>> scorers) {
    return scorers.fold(0, (total, scorer) => total + (scorer['goals'] as int? ?? 0));
  }

  // Fonction pour vérifier si on peut ajouter un buteur
  bool _canAddScorer(List<Map<String, dynamic>> scorers, int teamScore) {
    final totalGoals = _calculateTotalGoals(scorers);
    return totalGoals < teamScore;
  }

  // Section des derniers matchs terminés
  Widget _buildCompletedMatchesSection(BuildContext context, AuthProvider authProvider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('completed_matches_$_matchesRefreshKey'), // Clé unique pour les matchs terminés
      future: _getAllCompletedMatches(authProvider),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Erreur lors du chargement des matchs terminés: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final matches = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Derniers matchs - Mon équipe',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 15),
              // Afficher les vrais matchs terminés
              if (matches.isEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Nom de l'équipe adverse
                      Expanded(
                        child: Text(
                          'Équipe à déterminer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      
                      // Point orange comme dans la première image
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...matches.map((matchData) => _buildCompletedMatchCard(context, matchData)).toList(),
            ],
          ),
        );
      },
    );
  }

  // Carte pour un match terminé
  Widget _buildCompletedMatchCard(BuildContext context, Map<String, dynamic> matchData) {
    final opponent = matchData['opponent'] ?? 'Adversaire';
    final score = matchData['score'] ?? '0-0';
    final result = matchData['result'] ?? 'draw';
    
    // Déterminer la couleur selon le résultat
    Color resultColor;
    switch (result) {
      case 'win':
        resultColor = Colors.green;
        break;
      case 'loss':
        resultColor = Colors.red;
        break;
      case 'draw':
      default:
        resultColor = Colors.orange;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Nom de l'équipe adverse
          Expanded(
            child: Text(
              opponent,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          
          // Score à l'extrême droite
          Text(
            score,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: resultColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmMatchCompletion(BuildContext context, Map<String, dynamic> matchData, AuthProvider authProvider) async {
    // Dialogue de confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Match terminé ?'),
        content: Text(
          'Confirmez-vous que le match ${matchData['team_name']} vs ${matchData['opponent']} est terminé ?\n\n'
          'L\'autre équipe devra également confirmer avant de pouvoir ajouter les détails.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Appeler l'API
    final response = await ApiService.confirmMatchCompletion(
      token: authProvider.token!,
      matchId: matchData['id'].toString(),
    );

    if (context.mounted) {
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _matchesRefreshKey++; // Forcer le rechargement complet
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _showCompleteMatchDetailsDialog(BuildContext context, Map<String, dynamic> matchData, AuthProvider authProvider) {
    // Parse existing score if available
    String homeScore = '';
    String awayScore = '';
    if (matchData['score'] != null && matchData['score'].toString().isNotEmpty) {
      final scoreParts = matchData['score'].toString().split('-');
      if (scoreParts.length == 2) {
        homeScore = scoreParts[0].trim();
        awayScore = scoreParts[1].trim();
      }
    }
    
    final homeScoreController = TextEditingController(text: homeScore);
    final awayScoreController = TextEditingController(text: awayScore);
    final manOfMatchController = TextEditingController(text: matchData['man_of_match']);
    final summaryController = TextEditingController(text: matchData['match_summary']);
    final notesController = TextEditingController(text: matchData['notes']);
    
    String selectedResult = matchData['result'] == 'confirmed' ? 'win' : matchData['result'];
    List<Map<String, dynamic>> homeScorers = [];
    List<Map<String, dynamic>> awayScorers = [];

    // Charger les buteurs existants si disponibles
    if (matchData['home_scorers'] != null) {
      try {
        homeScorers = List<Map<String, dynamic>>.from(json.decode(matchData['home_scorers']));
      } catch (e) {
        // Ignore
      }
    }
    if (matchData['away_scorers'] != null) {
      try {
        awayScorers = List<Map<String, dynamic>>.from(json.decode(matchData['away_scorers']));
      } catch (e) {
        // Ignore
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Détails du match'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info du match
                Text(
                  '${matchData['team_name']} vs ${matchData['opponent']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // Score final avec deux champs séparés
                const Text('Score final *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Score équipe locale (gauche)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            matchData['team_name'] ?? 'Votre équipe',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: homeScoreController,
                            decoration: const InputDecoration(
                              labelText: 'Score',
                              hintText: '0',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Uniquement des chiffres
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            onChanged: (value) => _updateResultFromScores(homeScoreController.text, awayScoreController.text, setDialogState, () => selectedResult, (newResult) => selectedResult = newResult),
                          ),
                        ],
                      ),
                    ),
                    
                    // Séparateur
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child: const Text(
                        'VS',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                    
                    // Score équipe adverse (droite)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            matchData['opponent'] ?? 'Adversaire',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: awayScoreController,
                            decoration: const InputDecoration(
                              labelText: 'Score',
                              hintText: '0',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Uniquement des chiffres
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            onChanged: (value) => _updateResultFromScores(homeScoreController.text, awayScoreController.text, setDialogState, () => selectedResult, (newResult) => selectedResult = newResult),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 15),
                
                // Résultat automatique
                const Text('Résultat:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getResultColor(selectedResult).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getResultColor(selectedResult)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getResultIcon(selectedResult),
                        color: _getResultColor(selectedResult),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getResultText(selectedResult, matchData['team_name'] ?? 'Votre équipe'),
                        style: TextStyle(
                          color: _getResultColor(selectedResult),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 15),
                
                // Buteurs
                Text(
                  'Buteurs - ${matchData['team_name']}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...homeScorers.asMap().entries.map((entry) {
                  int index = entry.key;
                  var scorer = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Nom Prénom',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (value) => homeScorers[index]['name'] = value,
                            controller: TextEditingController(text: scorer['name']),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Buts',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              errorText: _validateScorerGoals(
                                int.tryParse(scorer['goals'].toString()) ?? 0,
                                int.tryParse(homeScoreController.text) ?? 0,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Uniquement des chiffres
                            onChanged: (value) {
                              final goals = int.tryParse(value) ?? 0;
                              homeScorers[index]['goals'] = goals;
                              setDialogState(() {}); // Rafraîchir pour afficher l'erreur
                            },
                            controller: TextEditingController(text: scorer['goals'].toString()),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => setDialogState(() => homeScorers.removeAt(index)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                // Bouton "Ajouter un buteur" pour l'équipe locale
                Builder(
                  builder: (context) {
                    final isHomeTeamLosing = selectedResult == 'loss';
                    final isDraw = selectedResult == 'draw';
                    final homeTeamScore = int.tryParse(homeScoreController.text) ?? 0;
                    final canAddHomeScorer = _canAddScorer(homeScorers, homeTeamScore);
                    final isDisabled = isHomeTeamLosing || isDraw || !canAddHomeScorer;
                    
                    String buttonText;
                    if (isHomeTeamLosing) {
                      buttonText = 'Équipe perdante - Pas de buteurs';
                    } else if (isDraw) {
                      buttonText = 'Match nul - Pas de buteurs';
                    } else if (!canAddHomeScorer) {
                      final totalGoals = _calculateTotalGoals(homeScorers);
                      buttonText = 'Total atteint ($totalGoals/$homeTeamScore)';
                    } else {
                      buttonText = 'Ajouter un buteur';
                    }
                    
                    return TextButton.icon(
                      onPressed: isDisabled ? null : () => setDialogState(() => homeScorers.add({'name': '', 'goals': 1})),
                      icon: Icon(
                        Icons.add_circle, 
                        color: isDisabled ? Colors.grey : Colors.blueAccent,
                      ),
                      label: Text(
                        buttonText,
                        style: TextStyle(
                          color: isDisabled ? Colors.grey : Colors.blueAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: isDisabled ? Colors.grey.withOpacity(0.1) : Colors.blueAccent.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 15),
                
                Text(
                  'Buteurs - ${matchData['opponent']}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...awayScorers.asMap().entries.map((entry) {
                  int index = entry.key;
                  var scorer = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Nom Prénom',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (value) => awayScorers[index]['name'] = value,
                            controller: TextEditingController(text: scorer['name']),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Buts',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              errorText: _validateScorerGoals(
                                int.tryParse(scorer['goals'].toString()) ?? 0,
                                int.tryParse(awayScoreController.text) ?? 0,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Uniquement des chiffres
                            onChanged: (value) {
                              final goals = int.tryParse(value) ?? 0;
                              awayScorers[index]['goals'] = goals;
                              setDialogState(() {}); // Rafraîchir pour afficher l'erreur
                            },
                            controller: TextEditingController(text: scorer['goals'].toString()),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => setDialogState(() => awayScorers.removeAt(index)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                // Bouton "Ajouter un buteur" pour l'équipe adverse
                Builder(
                  builder: (context) {
                    final isAwayTeamLosing = selectedResult == 'win';
                    final isDraw = selectedResult == 'draw';
                    final awayTeamScore = int.tryParse(awayScoreController.text) ?? 0;
                    final canAddAwayScorer = _canAddScorer(awayScorers, awayTeamScore);
                    final isDisabled = isAwayTeamLosing || isDraw || !canAddAwayScorer;
                    
                    String buttonText;
                    if (isAwayTeamLosing) {
                      buttonText = 'Équipe perdante - Pas de buteurs';
                    } else if (isDraw) {
                      buttonText = 'Match nul - Pas de buteurs';
                    } else if (!canAddAwayScorer) {
                      final totalGoals = _calculateTotalGoals(awayScorers);
                      buttonText = 'Total atteint ($totalGoals/$awayTeamScore)';
                    } else {
                      buttonText = 'Ajouter un buteur';
                    }
                    
                    return TextButton.icon(
                      onPressed: isDisabled ? null : () => setDialogState(() => awayScorers.add({'name': '', 'goals': 1})),
                      icon: Icon(
                        Icons.add_circle, 
                        color: isDisabled ? Colors.grey : Colors.blueAccent,
                      ),
                      label: Text(
                        buttonText,
                        style: TextStyle(
                          color: isDisabled ? Colors.grey : Colors.blueAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: isDisabled ? Colors.grey.withOpacity(0.1) : Colors.blueAccent.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 15),
                
                // Homme du match
                TextField(
                  controller: manOfMatchController,
                  decoration: const InputDecoration(
                    labelText: 'Homme du match (optionnel)',
                    border: OutlineInputBorder(),
                    hintText: 'Nom Prénom',
                    prefixIcon: Icon(Icons.star),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Résumé du match
                TextField(
                  controller: summaryController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Résumé du match (optionnel)',
                    border: OutlineInputBorder(),
                    hintText: 'Décrivez le déroulement du match...',
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Notes
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optionnel)',
                    border: OutlineInputBorder(),
                    hintText: 'Autres informations...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (homeScoreController.text.isEmpty || awayScoreController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez entrer les scores des deux équipes'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Construire le score au format "X-Y"
                final score = '${homeScoreController.text}-${awayScoreController.text}';

                final response = await ApiService.addMatchDetails(
                  token: authProvider.token!,
                  matchId: matchData['id'].toString(),
                  score: score,
                  result: selectedResult,
                  homeScorers: homeScorers.where((s) => s['name'].toString().isNotEmpty).toList(),
                  awayScorers: awayScorers.where((s) => s['name'].toString().isNotEmpty).toList(),
                  manOfMatch: manOfMatchController.text.isNotEmpty ? manOfMatchController.text : null,
                  matchSummary: summaryController.text.isNotEmpty ? summaryController.text : null,
                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                );

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  
                  if (response['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response['message']),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() {
                      _matchesRefreshKey++; // Forcer le rechargement complet
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response['message']),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

}