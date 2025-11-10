import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  // Vérifier l'état d'une permission
  static Future<bool> checkPermission(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  // Demander une permission
  static Future<bool> requestPermission(
    Permission permission, {
    required BuildContext context,
    required String permissionName,
    required String reason,
  }) async {
    // Vérifier d'abord l'état actuel
    final status = await permission.status;

    // Si déjà accordée, retourner true
    if (status.isGranted) {
      return true;
    }

    // Si refusée de façon permanente, ouvrir les paramètres
    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      final shouldOpen = await _showSettingsDialog(
        context: context,
        permissionName: permissionName,
        reason: reason,
      );
      
      if (shouldOpen) {
        await openAppSettings();
      }
      return false;
    }

    // Demander la permission
    final result = await permission.request();
    
    if (!context.mounted) return false;
    
    if (result.isGranted) {
      _showSuccessSnackBar(context, permissionName);
      return true;
    } else if (result.isDenied) {
      _showDeniedSnackBar(context, permissionName);
      return false;
    } else if (result.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(context, permissionName, reason);
      return false;
    }

    return false;
  }

  // Révoquer une permission (ouvrir les paramètres)
  static Future<void> revokePermission(
    BuildContext context,
    String permissionName,
  ) async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Désactiver $permissionName'),
        content: Text(
          'Pour désactiver cette permission, vous devez la désactiver manuellement dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );

    if (shouldOpen == true) {
      await openAppSettings();
    }
  }

  // Afficher le dialogue pour ouvrir les paramètres
  static Future<bool> _showSettingsDialog({
    required BuildContext context,
    required String permissionName,
    required String reason,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission $permissionName requise'),
        content: Text(
          'Cette permission a été refusée de façon permanente.\n\n'
          '$reason\n\n'
          'Vous devez l\'activer manuellement dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Afficher le dialogue pour permission refusée de façon permanente
  static Future<void> _showPermanentlyDeniedDialog(
    BuildContext context,
    String permissionName,
    String reason,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission $permissionName refusée'),
        content: Text(
          'Vous avez refusé cette permission de façon permanente.\n\n'
          '$reason\n\n'
          'Pour l\'activer, allez dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Paramètres'),
          ),
        ],
      ),
    );
  }

  // Afficher un message de succès
  static void _showSuccessSnackBar(BuildContext context, String permissionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Permission $permissionName accordée'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Afficher un message d'échec
  static void _showDeniedSnackBar(BuildContext context, String permissionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Permission $permissionName refusée'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Vérifier toutes les permissions à la fois
  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'camera': await checkPermission(Permission.camera),
      'location': await checkPermission(Permission.location),
      'microphone': await checkPermission(Permission.microphone),
      'notifications': await checkPermission(Permission.notification),
    };
  }

  // Obtenir la permission correspondante
  static Permission getPermission(String key) {
    switch (key) {
      case 'camera':
        return Permission.camera;
      case 'location':
        return Permission.location;
      case 'microphone':
        return Permission.microphone;
      case 'notifications':
        return Permission.notification;
      default:
        throw ArgumentError('Permission inconnue: $key');
    }
  }

  // Obtenir le nom de la permission
  static String getPermissionName(String key) {
    switch (key) {
      case 'camera':
        return 'Appareil photo';
      case 'location':
        return 'Localisation';
      case 'microphone':
        return 'Microphone';
      case 'notifications':
        return 'Notifications';
      default:
        return key;
    }
  }

  // Obtenir la raison de la permission
  static String getPermissionReason(String key) {
    switch (key) {
      case 'camera':
        return 'Cette permission est nécessaire pour prendre des photos de profil et de logo d\'équipe.';
      case 'location':
        return 'Cette permission est nécessaire pour trouver des équipes et des matchs proches de vous.';
      case 'microphone':
        return 'Cette permission est nécessaire pour les appels vocaux avec les autres coachs.';
      case 'notifications':
        return 'Cette permission est nécessaire pour recevoir les alertes de nouveaux matchs et demandes.';
      default:
        return 'Cette permission est nécessaire pour le bon fonctionnement de l\'application.';
    }
  }
}

