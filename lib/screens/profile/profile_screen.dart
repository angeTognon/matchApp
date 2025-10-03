import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:amical_club/providers/auth_provider.dart';
import 'package:amical_club/providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTeamIndex = 0;
  bool _notifications = true;

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
            final coach = authProvider.currentCoach;
            if (coach == null) return const Center(child: Text('Erreur de chargement'));

            return SingleChildScrollView(
              child: Column(
                children: [
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
                              child: const Icon(Icons.person, size: 40, color: Colors.white),
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
                          'Entraîneur: Jean Dupont',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Licence FFF: FFF-123456',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '8 ans d\'expérience',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '3 équipes dans 3 clubs',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                            const SizedBox(width: 5),
                            Text(
                              'Marseille, Bouches-du-Rhône',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.primary),
                            label: Text(
                              'Modifier le profil',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
                          child: Text(
                            'Mes équipes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedTeamIndex = 0),
                                child: Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: _selectedTeamIndex == 0 ? Theme.of(context).cardColor : Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedTeamIndex == 0 ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.business, size: 16, color: Theme.of(context).textTheme.titleMedium?.color),
                                            const SizedBox(width: 8),
                                        Text(
                                          'FC Marseille',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).textTheme.titleMedium?.color,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'FC Marseille Jeunes',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).textTheme.titleLarge?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'U17',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Départemental',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedTeamIndex = 1),
                                  child: Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: _selectedTeamIndex == 1 ? Theme.of(context).cardColor : Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedTeamIndex == 1 ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                            children: [
                                            Icon(Icons.business, size: 16, color: Theme.of(context).textTheme.titleMedium?.color),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Olympic Provence',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).textTheme.titleMedium?.color,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Olympic Provence',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).textTheme.titleLarge?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Séniors',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Régional',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
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

                  // Section Championnat
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Championnat',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Championnat Départemental U17 - Bouches-du-Rhône',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Informations équipe
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations - FC Marseille Jeunes',
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
                                      'FC Marseille',
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
                                      'U17',
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
                                      'Départemental',
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Derniers matchs - FC Marseille Jeunes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildMatchResult('AS Cannes U17', '3-1', Colors.green),
                        _buildMatchResult('FC Nice U17', '2-2', Colors.orange),
                        _buildMatchResult('OM Academy U17', '1-4', Colors.red),
                        _buildMatchResult('AS Monaco U17', '2-0', Colors.green),
                        _buildMatchResult('RC Toulon U17', '0-1', Colors.red),
                      ],
                    ),
                  ),

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
            );
          },
        ),
      ),
    );
  }
}