import 'package:flutter/material.dart';
import 'package:amical_club/models/match.dart';
import 'package:amical_club/services/api_service.dart';

class MatchProvider with ChangeNotifier {
  List<Match> _matches = [];
  List<Match> _filteredMatches = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, String> _filters = {
    'category': '',
    'level': '',
    'gender': '',
    'search': '',
    'distance': '',
  };

  // Getters
  List<Match> get matches => _filteredMatches;
  List<Match> get allMatches => _matches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, String> get filters => _filters;
  
  // Statistiques
  int get matchesThisMonth {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    return _matches.where((match) {
      return match.date.month == currentMonth && match.date.year == currentYear;
    }).length;
  }
  
  int get nearbyTeamsCount {
    // Compter le nombre d'équipes uniques dans les matchs
    final uniqueTeams = <String>{};
    for (var match in _matches) {
      uniqueTeams.add(match.teamName);
    }
    return uniqueTeams.length;
  }

  // Charger tous les matchs
  Future<void> loadMatches({String? token}) async {
    if (token == null) return;
    
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiService.getMatches(
        token: token,
        category: _filters['category']?.isNotEmpty == true ? _filters['category'] : null,
        level: _filters['level']?.isNotEmpty == true ? _filters['level'] : null,
        gender: _filters['gender']?.isNotEmpty == true ? _filters['gender'] : null,
        search: _filters['search']?.isNotEmpty == true ? _filters['search'] : null,
        status: 'pending',
      );

      if (response['success'] == true) {
        final List<dynamic> matchesData = response['data']['matches'];
        _matches = matchesData.map((json) => Match.fromJson(json)).toList();
        _applyFilters();
      } else {
        _setError(response['message'] ?? 'Erreur lors du chargement des matchs');
      }
    } catch (e) {
      _setError('Erreur de connexion: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Charger les détails d'un match
  Future<Match?> loadMatchDetails({required String token, required String matchId}) async {
    try {
      final response = await ApiService.getMatch(
        token: token,
        matchId: matchId,
      );

      if (response['success'] == true) {
        return Match.fromJson(response['data']['match']);
      } else {
        _setError(response['message'] ?? 'Erreur lors du chargement du match');
        return null;
      }
    } catch (e) {
      _setError('Erreur de connexion: $e');
      return null;
    }
  }

  // Faire une demande de match
  Future<bool> requestMatch({
    required String token,
    required String matchId,
    required String teamId,
    String? message,
  }) async {
    try {
      final response = await ApiService.requestMatch(
        token: token,
        matchId: matchId,
        teamId: teamId,
        message: message,
      );

      if (response['success'] == true) {
        // Mettre à jour le match local si nécessaire
        final matchIndex = _matches.indexWhere((match) => match.id == matchId);
        if (matchIndex != -1) {
          _matches[matchIndex] = _matches[matchIndex].copyWith(
            userHasRequested: true,
            status: response['data']['status'] == 'accepted' 
                ? MatchStatus.confirmed 
                : MatchStatus.requestsSent,
          );
          _applyFilters();
        }
        return true;
      } else {
        _setError(response['message'] ?? 'Erreur lors de la demande de match');
        return false;
      }
    } catch (e) {
      _setError('Erreur de connexion: $e');
      return false;
    }
  }

  // Appliquer les filtres
  void applyFilters({
    String? category,
    String? level,
    String? gender,
    String? search,
    String? distance,
  }) {
    if (category != null) _filters['category'] = category;
    if (level != null) _filters['level'] = level;
    if (gender != null) _filters['gender'] = gender;
    if (search != null) _filters['search'] = search;
    if (distance != null) _filters['distance'] = distance;

    _applyFilters();
  }

  // Réinitialiser les filtres
  void resetFilters() {
    _filters = {
      'category': '',
      'level': '',
      'gender': '',
      'search': '',
      'distance': '',
    };
    _applyFilters();
  }

  // Appliquer les filtres internes
  void _applyFilters() {
    _filteredMatches = _matches.where((match) {
      // Filtre par catégorie
      if (_filters['category']?.isNotEmpty == true && 
          match.category != _filters['category']) {
        return false;
      }

      // Filtre par niveau
      if (_filters['level']?.isNotEmpty == true && 
          match.level != _filters['level']) {
        return false;
      }

      // Filtre par genre
      if (_filters['gender']?.isNotEmpty == true && 
          match.gender != _filters['gender']) {
        return false;
      }

      // Filtre par recherche
      if (_filters['search']?.isNotEmpty == true) {
        final searchTerm = _filters['search']!.toLowerCase();
        if (!match.teamName.toLowerCase().contains(searchTerm) &&
            !match.clubName.toLowerCase().contains(searchTerm) &&
            !match.location.toLowerCase().contains(searchTerm)) {
          return false;
        }
      }

      // Filtre par distance
      if (_filters['distance']?.isNotEmpty == true) {
        final maxDistance = _parseDistance(_filters['distance']!);
        final matchDistance = _parseDistance(match.distance);
        if (matchDistance > maxDistance) {
          return false;
        }
      }

      return true;
    }).toList();

    notifyListeners();
  }
  
  // Parser la distance (ex: "5 km" -> 5.0, "12.5 km" -> 12.5)
  double _parseDistance(String distance) {
    try {
      final numString = distance.replaceAll(RegExp(r'[^0-9.]'), '').trim();
      return double.tryParse(numString) ?? 999999.0;
    } catch (e) {
      return 999999.0;
    }
  }

  // Méthodes privées
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Mettre à jour le score d'un match
  Future<bool> updateMatchScore({
    required String token,
    required String matchId,
    required String homeScore,
    required String awayScore,
    required List<String> homeScorers,
    required List<String> awayScorers,
    String? notes,
  }) async {
    try {
      final response = await ApiService.updateMatchScore(
        token: token,
        matchId: matchId,
        homeScore: homeScore,
        awayScore: awayScore,
        homeScorers: homeScorers,
        awayScorers: awayScorers,
        notes: notes,
      );

      if (response['success'] == true) {
        // Mettre à jour le match local
        final matchIndex = _matches.indexWhere((match) => match.id == matchId);
        if (matchIndex != -1) {
          _matches[matchIndex] = _matches[matchIndex].copyWith(
            homeScore: homeScore,
            awayScore: awayScore,
            homeScorers: homeScorers,
            awayScorers: awayScorers,
            notes: notes,
            status: MatchStatus.finished,
          );
          _applyFilters();
        }
        return true;
      } else {
        _setError(response['message'] ?? 'Erreur lors de la mise à jour du score');
        return false;
      }
    } catch (e) {
      _setError('Erreur de connexion: $e');
      return false;
    }
  }

  // Obtenir un match par son ID
  Match? getMatchById(String matchId) {
    try {
      return _matches.firstWhere((match) => match.id == matchId);
    } catch (e) {
      return null;
    }
  }

  // Nettoyer les données
  void clear() {
    _matches.clear();
    _filteredMatches.clear();
    _filters = {
      'category': '',
      'level': '',
      'gender': '',
      'search': '',
      'distance': '',
    };
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}