import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  static const String _themeKey = 'isDarkMode';

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? true; // Par défaut mode sombre
      notifyListeners();
    } catch (e) {
      // En cas d'erreur, garder le mode sombre par défaut
      _isDarkMode = true;
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      // En cas d'erreur de sauvegarde, on continue quand même
      print('Erreur lors de la sauvegarde du thème: $e');
    }
  }

  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_themeKey, _isDarkMode);
      } catch (e) {
        print('Erreur lors de la sauvegarde du thème: $e');
      }
    }
  }
}
