import 'package:flutter/material.dart';
import 'package:amical_club/models/coach.dart';
import 'package:amical_club/models/team.dart';

class AuthProvider extends ChangeNotifier {
  Coach? _currentCoach;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  Coach? get currentCoach => _currentCoach;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Mock successful login
    _currentCoach = Coach(
      id: '1',
      name: 'Jean Dupont',
      location: 'Marseille, Bouches-du-Rhône',
      licenseNumber: 'FFF-123456',
      experience: '8 ans',
      teams: [
        Team(
          id: '1',
          name: 'FC Marseille Jeunes',
          clubName: 'FC Marseille',
          coachName: 'Jean Dupont',
          category: 'U17',
          level: 'Départemental',
          location: 'Marseille',
          distance: '0 km',
          recentMatches: [
            MatchResult(
              opponent: 'AS Cannes U17',
              score: '3-1',
              result: MatchResultType.win,
              date: DateTime.now().subtract(const Duration(days: 7)),
            ),
            MatchResult(
              opponent: 'FC Nice U17',
              score: '2-2',
              result: MatchResultType.draw,
              date: DateTime.now().subtract(const Duration(days: 14)),
            ),
          ],
        ),
        Team(
          id: '2',
          name: 'Olympic Provence Séniors',
          clubName: 'Olympic Provence',
          coachName: 'Jean Dupont',
          category: 'Séniors',
          level: 'Régional',
          location: 'Provence',
          distance: '0 km',
          recentMatches: [
            MatchResult(
              opponent: 'FC Aix Séniors',
              score: '2-1',
              result: MatchResultType.win,
              date: DateTime.now().subtract(const Duration(days: 3)),
            ),
          ],
        ),
      ],
    );

    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> register(Map<String, String> userData) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentCoach = null;
    _isAuthenticated = false;
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
}