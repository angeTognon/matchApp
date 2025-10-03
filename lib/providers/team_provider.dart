import 'package:flutter/material.dart';
import 'package:amical_club/models/team.dart';

class TeamProvider extends ChangeNotifier {
  List<Team> _teams = [];
  bool _isLoading = false;

  List<Team> get teams => _teams;
  bool get isLoading => _isLoading;

  TeamProvider() {
    _loadSampleTeams();
  }

  void _loadSampleTeams() {
    _teams = [
      Team(
        id: '1',
        name: 'FC Provence',
        clubName: 'FC Provence',
        coachName: 'Marc Dubois',
        category: 'Séniors',
        level: 'Départemental',
        location: 'Aix-en-Provence',
        distance: '3.2 km',
        logo: 'https://images.pexels.com/photos/1884574/pexels-photo-1884574.jpeg',
        lastActive: '2 heures',
        description: 'Club fondé en 1985, nous privilégions le fair-play et la convivialité.',
        homeStadium: 'Stade Municipal d\'Aix-en-Provence',
        founded: '1985',
        achievements: [
          'Champion Départemental 2023',
          'Finaliste Coupe Régionale 2022',
          'Fair-play Award 2024'
        ],
        recentMatches: [
          MatchResult(
            opponent: 'AS Cannes',
            score: '3-1',
            result: MatchResultType.win,
            date: DateTime.now().subtract(const Duration(days: 7)),
          ),
          MatchResult(
            opponent: 'FC Nice',
            score: '2-2',
            result: MatchResultType.draw,
            date: DateTime.now().subtract(const Duration(days: 14)),
          ),
          MatchResult(
            opponent: 'OM Academy',
            score: '1-4',
            result: MatchResultType.loss,
            date: DateTime.now().subtract(const Duration(days: 21)),
          ),
        ],
        contact: ContactInfo(
          phone: '+33 6 98 76 54 32',
          email: 'marc.dubois@fcprovence.fr',
        ),
      ),
      Team(
        id: '2',
        name: 'Olympic Marseille Amateur',
        clubName: 'Olympic Marseille',
        coachName: 'Laurent Moreau',
        category: 'U19',
        level: 'Régional',
        location: 'Marseille Centre',
        distance: '5.8 km',
        logo: 'https://images.pexels.com/photos/114296/pexels-photo-114296.jpeg',
        lastActive: '1 jour',
        recentMatches: [
          MatchResult(
            opponent: 'FC Toulon U19',
            score: '2-0',
            result: MatchResultType.win,
            date: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ],
      ),
    ];
    notifyListeners();
  }

  Team? getTeamById(String id) {
    try {
      return _teams.firstWhere((team) => team.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshTeams() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    _loadSampleTeams();

    _isLoading = false;
    notifyListeners();
  }
}