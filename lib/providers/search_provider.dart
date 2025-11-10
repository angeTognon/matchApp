import 'package:flutter/material.dart';
import 'package:amical_club/services/api_service.dart';
import 'package:amical_club/models/team.dart';

class SearchProvider extends ChangeNotifier {
  List<Team> _allTeams = [];
  List<Team> _filteredTeams = [];
  List<String> _categories = [];
  List<String> _levels = [];

  bool _isLoading = false;
  bool _isLoadingFilters = false;
  String? _errorMessage;

  // Getters
  List<Team> get filteredTeams => _filteredTeams;
  List<String> get categories => _categories;
  List<String> get levels => _levels;
  bool get isLoading => _isLoading;
  bool get isLoadingFilters => _isLoadingFilters;
  String? get errorMessage => _errorMessage;

  // Recherche et filtrage
  String _searchQuery = '';
  String _selectedCategory = 'Toutes';
  String _selectedLevel = 'Tous';

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedLevel => _selectedLevel;

  SearchProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    await loadTeams();
    await loadFilters();
  }

  Future<void> loadTeams() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getAllTeams();

      if (response['success'] == true) {
        final teamsData = response['data'] as List<dynamic>? ?? [];

        _allTeams = teamsData
            .where((teamData) => teamData is Map<String, dynamic>)
            .map((teamData) => Team.fromJson(teamData as Map<String, dynamic>))
            .toList();

        _filteredTeams = _allTeams;
        debugPrint('✅ SearchProvider: ${_allTeams.length} équipes chargées');
      } else {
        _errorMessage = response['message'] ?? 'Erreur lors du chargement des équipes';
        debugPrint('❌ SearchProvider: ${_errorMessage}');
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion: $e';
      debugPrint('❌ SearchProvider: Exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFilters() async {
    _isLoadingFilters = true;
    notifyListeners();

    try {
      // Récupérer les catégories depuis les équipes déjà chargées
      final categoriesSet = _allTeams.map((team) => team.category).toSet();
      _categories = ['Toutes', ...categoriesSet.where((cat) => cat.isNotEmpty)];

      // Récupérer les niveaux depuis les équipes déjà chargées
      final levelsSet = _allTeams.map((team) => team.level).toSet();
      _levels = ['Tous', ...levelsSet.where((level) => level.isNotEmpty)];

      debugPrint('✅ SearchProvider: ${_categories.length} catégories, ${_levels.length} niveaux');
    } catch (e) {
      debugPrint('❌ SearchProvider: Erreur chargement filtres: $e');
    } finally {
      _isLoadingFilters = false;
      notifyListeners();
    }
  }

  void searchTeams(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void filterByLevel(String level) {
    _selectedLevel = level;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredTeams = _allTeams.where((team) {
      // Filtre de recherche textuelle
      final matchesSearch = _searchQuery.isEmpty ||
          team.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          team.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          team.clubName.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filtre par catégorie
      final matchesCategory = _selectedCategory == 'Toutes' || team.category == _selectedCategory;

      // Filtre par niveau
      final matchesLevel = _selectedLevel == 'Tous' || team.level == _selectedLevel;

      return matchesSearch && matchesCategory && matchesLevel;
    }).toList();

    notifyListeners();
  }

  Team? getTeamById(String teamId) {
    try {
      return _allTeams.firstWhere((team) => team.id == teamId);
    } catch (e) {
      return null;
    }
  }
}
