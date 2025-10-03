import 'package:flutter/material.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  Map<String, bool> _permissions = {
    'camera': true,
    'location': true,
    'microphone': false,
    'notifications': true,
    'contacts': false,
  };

  Map<String, bool> _privacy = {
    'profileVisible': true,
    'showOnlineStatus': true,
    'allowMessages': true,
    'shareStats': false,
    'dataCollection': true,
  };

  void _handleDataExport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter mes données'),
        content: const Text('Nous vous enverrons un fichier contenant toutes vos données par email sous 48h.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text('Cette action est irréversible. Toutes vos données seront définitivement supprimées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compte supprimé avec succès')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confidentialité & Permissions'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Permissions de l'application
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permissions de l\'application',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gérez les autorisations accordées à l\'application.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildPermissionItem(
                    icon: Icons.camera_alt,
                    title: 'Appareil photo',
                    description: 'Pour prendre des photos de profil',
                    value: _permissions['camera']!,
                    onChanged: (value) => setState(() => _permissions['camera'] = value),
                  ),
                  _buildPermissionItem(
                    icon: Icons.location_on,
                    title: 'Localisation',
                    description: 'Pour trouver des équipes proches',
                    value: _permissions['location']!,
                    onChanged: (value) => setState(() => _permissions['location'] = value),
                  ),
                  _buildPermissionItem(
                    icon: Icons.mic,
                    title: 'Microphone',
                    description: 'Pour les appels vocaux',
                    value: _permissions['microphone']!,
                    onChanged: (value) => setState(() => _permissions['microphone'] = value),
                  ),
                  _buildPermissionItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    description: 'Pour recevoir les alertes',
                    value: _permissions['notifications']!,
                    onChanged: (value) => setState(() => _permissions['notifications'] = value),
                  ),
                ],
              ),
            ),

            // Confidentialité
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confidentialité',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildPermissionItem(
                    icon: Icons.visibility,
                    title: 'Profil visible',
                    description: 'Permettre aux autres de voir votre profil',
                    value: _privacy['profileVisible']!,
                    onChanged: (value) => setState(() => _privacy['profileVisible'] = value),
                  ),
                  _buildPermissionItem(
                    icon: Icons.public,
                    title: 'Statut en ligne',
                    description: 'Afficher quand vous êtes connecté',
                    value: _privacy['showOnlineStatus']!,
                    onChanged: (value) => setState(() => _privacy['showOnlineStatus'] = value),
                  ),
                ],
              ),
            ),

            // Gestion des données
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestion des données',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  OutlinedButton.icon(
                    onPressed: _handleDataExport,
                    icon: Icon(Icons.download, color: Theme.of(context).colorScheme.primary),
                    label: const Text('Exporter mes données'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  OutlinedButton(
                    onPressed: _handleDeleteAccount,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Supprimer mon compte'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}