import 'package:flutter/material.dart';
import 'dart:io';
import 'package:amical_club/models/coach.dart';
import 'package:amical_club/models/team.dart';
import 'package:amical_club/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class AuthProvider extends ChangeNotifier {
  Coach? _currentCoach;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _token;
  String? _errorMessage;

  Coach? get currentCoach => _currentCoach;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get errorMessage => _errorMessage;

  // Vérifier l'authentification au démarrage
  Future<void> checkAuthentication() async {
    _isLoading = true;
    notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        final storedToken = prefs.getString('auth_token');
        final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

        debugPrint('🔍 checkAuthentication: Token stocké: ${storedToken?.substring(0, 20)}...');
        debugPrint('🔍 checkAuthentication: isLoggedIn: $isLoggedIn');

        if (storedToken != null && isLoggedIn) {
          debugPrint('🔄 checkAuthentication: Vérification du token...');
          final response = await ApiService.verifyToken(storedToken);

          debugPrint('📡 checkAuthentication: Réponse serveur: ${response['success']}');

          if (response['success'] == true) {
            _token = storedToken;
            final userData = response['data'];
            debugPrint('📦 checkAuthentication: userData reçu: $userData');

            // Convertir les équipes
            List<Team> teams = [];
            if (userData['teams'] != null && userData['teams'] is List) {
              debugPrint('👥 checkAuthentication: Conversion de ${(userData['teams'] as List).length} équipes');
              try {
                teams = (userData['teams'] as List)
                    .where((t) => t is Map<String, dynamic>)
                    .map((t) => Team.fromJson(t as Map<String, dynamic>))
                    .toList();
                debugPrint('✅ checkAuthentication: ${teams.length} équipes converties');
              } catch (e) {
                debugPrint('❌ Erreur conversion équipes: $e');
                teams = [];
              }
            }

            debugPrint('👤 checkAuthentication: Création Coach avec user: ${userData['user']}');
            _currentCoach = Coach.fromJson(userData['user'], teams);
            debugPrint('✅ checkAuthentication: Coach créé: ${_currentCoach?.name}');
            _isAuthenticated = true;
          } else {
            debugPrint('❌ checkAuthentication: Erreur serveur: ${response['message']}');
            // Ne PAS déconnecter en cas d'erreur serveur/réseau
            // Conserver l'état actuel si on a déjà un token et un login stockés
            _token = storedToken;
            _isAuthenticated = true;
          }
        } else {
          debugPrint('🔍 checkAuthentication: Pas de token ou pas connecté');
          // Pas de token ou pas connecté, nettoyer le stockage
          await _clearStoredAuth();
        }
    } catch (e) {
      debugPrint('Erreur vérification auth: $e');
      // En cas d'erreur réseau (ex: HandshakeException), ne PAS déconnecter
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('auth_token');
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      if (storedToken != null && isLoggedIn) {
        _token = storedToken;
        _isAuthenticated = true;
      } else {
        await _clearStoredAuth();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Nettoyer le stockage d'authentification
  Future<void> _clearStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.setBool('is_logged_in', false);
    _token = null;
    _isAuthenticated = false;
    _currentCoach = null;
  }

  // Sauvegarder l'état de connexion
  Future<void> _saveAuthState(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setBool('is_logged_in', true);
  }

  // Charger les conversations après la connexion
  void _loadConversationsAfterLogin() {
    // Cette méthode sera appelée par le MainScreen ou ConversationsScreen
    // pour charger les conversations après la connexion
    debugPrint('💬 AuthProvider: Prêt à charger les conversations');
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔄 AuthProvider.login: Début de la connexion');
      final response = await ApiService.login(
        email: email,
        password: password,
      );

      debugPrint('📡 AuthProvider.login: Réponse reçue: ${response['success']}');

      if (response['success'] == true) {
        final data = response['data'];
        debugPrint('📦 AuthProvider.login: Data reçue: $data');
        
        _token = data['token'];
        debugPrint('🔑 AuthProvider.login: Token: ${_token?.substring(0, 20)}...');

        // Sauvegarder l'état de connexion
        await _saveAuthState(_token!);

        // Convertir les équipes
        List<Team> teams = [];
        if (data['teams'] != null && data['teams'] is List) {
          debugPrint('👥 AuthProvider.login: Conversion de ${(data['teams'] as List).length} équipes');
          try {
            teams = (data['teams'] as List)
                .where((t) => t is Map<String, dynamic>)
                .map((t) => Team.fromJson(t as Map<String, dynamic>))
                .toList();
            debugPrint('✅ AuthProvider.login: ${teams.length} équipes converties');
          } catch (e) {
            debugPrint('❌ Erreur conversion équipes login: $e');
            teams = [];
          }
        }

        debugPrint('👤 AuthProvider.login: Création Coach avec user: ${data['user']}');
        _currentCoach = Coach.fromJson(data['user'], teams);
        debugPrint('✅ AuthProvider.login: Coach créé: ${_currentCoach?.name}');
        
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        
        // Charger les conversations après la connexion
        _loadConversationsAfterLogin();
        
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Erreur de connexion';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? location,
    String? teamName,
    String? clubName,
    String? category,
    String? level,
    String? licenseNumber,
    String? experience,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.register(
        email: email,
        password: password,
        name: name,
        location: location,
        teamName: teamName,
        clubName: clubName,
        category: category,
        level: level,
        licenseNumber: licenseNumber,
        experience: experience,
        phone: phone,
      );

      if (response['success'] == true) {
        final data = response['data'];
        _token = data['token'];

        // Sauvegarder l'état de connexion
        await _saveAuthState(_token!);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Erreur lors de l\'inscription';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'inscription: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_token != null) {
      await ApiService.logout(_token!);
    }

    // Nettoyer le stockage d'authentification
    await _clearStoredAuth();
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // Mettre à jour les données du coach (utilisé après création d'équipe)
  void updateCoachData(Coach coach) {
    _currentCoach = coach;
    _isAuthenticated = true;
    notifyListeners();
  }

  // Supprimer une équipe
  Future<bool> deleteTeam(String teamId) async {
    if (_token == null) {
      debugPrint('❌ deleteTeam: Token manquant');
      return false;
    }

    debugPrint('🔄 deleteTeam: Début suppression équipe $teamId');

    try {
      final response = await ApiService.deleteTeam(
        token: _token!,
        teamId: teamId,
      );

      debugPrint('📡 deleteTeam: Réponse API: $response');

      if (response['success'] == true) {
        debugPrint('✅ deleteTeam: Suppression réussie, rechargement des données...');
        // Recharger les données pour mettre à jour la liste des équipes
        await checkAuthentication();
        debugPrint('✅ deleteTeam: Données rechargées avec succès');
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Erreur lors de la suppression';
        debugPrint('❌ deleteTeam: Erreur API: $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression: $e';
      debugPrint('❌ deleteTeam: Exception: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String location,
    required String licenseNumber,
    required String experience,
    String? avatar,
  }) async {
    if (_token == null) {
      debugPrint('❌ updateProfile: Token manquant');
      return false;
    }

    debugPrint('🔄 updateProfile: Mise à jour du profil...');

    try {
      final response = await ApiService.updateProfile(
        token: _token!,
        name: name,
        location: location,
        licenseNumber: licenseNumber,
        experience: experience,
        avatar: avatar,
      );

      debugPrint('📡 updateProfile: Réponse API: $response');

      if (response['success'] == true) {
        debugPrint('✅ updateProfile: Profil mis à jour, rechargement des données...');
        // Recharger les données pour mettre à jour les informations du coach
        await checkAuthentication();
        debugPrint('✅ updateProfile: Données rechargées avec succès');
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Erreur lors de la mise à jour';
        debugPrint('❌ updateProfile: Erreur API: $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour: $e';
      debugPrint('❌ updateProfile: Exception: $e');
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    if (_token == null) {
      debugPrint('❌ uploadAvatar: Token manquant');
      return {
        'success': false,
        'message': 'Token manquant',
      };
    }

    debugPrint('🔄 uploadAvatar: Upload de l\'image...');
    debugPrint('📁 uploadAvatar: Taille du fichier: ${imageFile.lengthSync()} bytes');

    try {
      final response = await ApiService.uploadAvatar(
        token: _token!,
        imageFile: imageFile,
      );

      debugPrint('📡 uploadAvatar: Réponse API: $response');

      if (response['success'] == true) {
        debugPrint('✅ uploadAvatar: Image uploadée avec succès');
        return {
          'success': true,
          'data': response['data'],
          'message': response['message'],
        };
      } else {
        debugPrint('❌ uploadAvatar: Échec upload - ${response['message']}');
        return {
          'success': false,
          'message': response['message'] ?? 'Erreur lors de l\'upload',
        };
      }
    } catch (e) {
      debugPrint('❌ uploadAvatar: Exception: $e');
      return {
        'success': false,
        'message': 'Erreur lors de l\'upload: $e',
      };
    }
  }
}