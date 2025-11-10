import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  // Vérifier si l'utilisateur est connecté
  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final token = prefs.getString('auth_token');
    return isLoggedIn && token != null;
  }

  // Obtenir le token stocké
  static Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Nettoyer le stockage d'authentification
  static Future<void> clearAuthStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.setBool('is_logged_in', false);
  }

  // Sauvegarder l'état de connexion
  static Future<void> saveAuthState(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setBool('is_logged_in', true);
  }
}
