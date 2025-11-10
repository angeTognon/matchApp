import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amical_club/services/permission_service.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> with WidgetsBindingObserver {
  Map<String, bool> _permissions = {
    'camera': false,
    'location': false,
    'microphone': false,
    'notifications': false,
  };

  Map<String, bool> _privacy = {
    'profileVisible': true,
    'showOnlineStatus': true,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissions();
    _loadPrivacySettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Recharger les permissions quand l'app revient au premier plan
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPermissions();
    }
  }

  // Charger l'état actuel des permissions
  Future<void> _loadPermissions() async {
    try {
      final statuses = await PermissionService.checkAllPermissions();
      if (mounted) {
        setState(() {
          _permissions = statuses;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des permissions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Charger les paramètres de confidentialité
  Future<void> _loadPrivacySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _privacy['profileVisible'] = prefs.getBool('profileVisible') ?? true;
          _privacy['showOnlineStatus'] = prefs.getBool('showOnlineStatus') ?? true;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des paramètres: $e');
    }
  }

  // Sauvegarder les paramètres de confidentialité
  Future<void> _savePrivacySetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  // Gérer le changement d'une permission
  Future<void> _handlePermissionChange(String key, bool newValue) async {
    final permission = PermissionService.getPermission(key);
    final permissionName = PermissionService.getPermissionName(key);
    final reason = PermissionService.getPermissionReason(key);

    if (newValue) {
      // L'utilisateur veut activer la permission
      await PermissionService.requestPermission(
        permission,
        context: context,
        permissionName: permissionName,
        reason: reason,
      );
      
      // Recharger l'état actuel
      await _loadPermissions();
    } else {
      // L'utilisateur veut désactiver la permission
      await PermissionService.revokePermission(context, permissionName);
      
      // Recharger l'état actuel après un délai
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadPermissions();
    }
  }

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
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
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
                    'Gérez les autorisations accordées à l\'application. Les permissions sont vérifiées en temps réel.',
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
                    description: 'Pour prendre des photos de profil et de logo',
                    value: _permissions['camera']!,
                    onChanged: (value) => _handlePermissionChange('camera', value),
                    isSystemPermission: true,
                  ),
                  _buildPermissionItem(
                    icon: Icons.location_on,
                    title: 'Localisation',
                    description: 'Pour trouver des équipes proches de vous',
                    value: _permissions['location']!,
                    onChanged: (value) => _handlePermissionChange('location', value),
                    isSystemPermission: true,
                  ),
                  _buildPermissionItem(
                    icon: Icons.mic,
                    title: 'Microphone',
                    description: 'Pour les appels vocaux avec les coachs',
                    value: _permissions['microphone']!,
                    onChanged: (value) => _handlePermissionChange('microphone', value),
                    isSystemPermission: true,
                  ),
                  _buildPermissionItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    description: 'Pour recevoir les alertes de matchs',
                    value: _permissions['notifications']!,
                    onChanged: (value) => _handlePermissionChange('notifications', value),
                    isSystemPermission: true,
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
                  const SizedBox(height: 8),
                  Text(
                    'Gérez vos paramètres de confidentialité.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildPermissionItem(
                    icon: Icons.visibility,
                    title: 'Profil visible',
                    description: 'Permettre aux autres de voir votre profil',
                    value: _privacy['profileVisible']!,
                    onChanged: (value) {
                      setState(() => _privacy['profileVisible'] = value);
                      _savePrivacySetting('profileVisible', value);
                    },
                    isSystemPermission: false,
                  ),
                  _buildPermissionItem(
                    icon: Icons.public,
                    title: 'Statut en ligne',
                    description: 'Afficher quand vous êtes connecté',
                    value: _privacy['showOnlineStatus']!,
                    onChanged: (value) {
                      setState(() => _privacy['showOnlineStatus'] = value);
                      _savePrivacySetting('showOnlineStatus', value);
                    },
                    isSystemPermission: false,
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
    bool isSystemPermission = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).dividerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon, 
              size: 20, 
              color: value 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    if (isSystemPermission) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Système',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.4,
                  ),
                ),
                if (isSystemPermission && value)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Autorisé',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
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