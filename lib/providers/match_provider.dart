import 'package:flutter/material.dart';
import 'package:amical_club/models/match.dart';

class MatchProvider extends ChangeNotifier {
  List<Match> _matches = [];
  bool _isLoading = false;

  List<Match> get matches => _matches;
  bool get isLoading => _isLoading;

  MatchProvider() {
    _loadSampleMatches();
  }

  void _loadSampleMatches() {
    _matches = [
      Match(
        id: '1',
        teamName: 'FC Marseille Amateur',
        coachName: 'Pierre Martin',
        category: 'Séniors',
        level: 'Départemental',
        date: DateTime(2025, 1, 20),
        time: '15:00',
        location: 'Marseille, Stade Municipal',
        distance: '2.5 km',
        status: MatchStatus.available,
        createdBy: 'other',
        description: 'Nous recherchons une équipe de niveau similaire pour un match amical.',
        facilities: ['Vestiaires', 'Douches', 'Parking', 'Buvette'],
      ),
      Match(
        id: '2',
        teamName: 'AS Lyon Jeunes',
        coachName: 'Marc Dubois',
        category: 'U17',
        level: 'Régional',
        date: DateTime(2025, 1, 22),
        time: '14:30',
        location: 'Lyon, Complexe Sportif',
        distance: '5.2 km',
        status: MatchStatus.available,
        createdBy: 'other',
      ),
      Match(
        id: '3',
        teamName: 'Mon Match en Attente',
        coachName: 'Jean Dupont',
        category: 'U19',
        level: 'Départemental',
        date: DateTime(2025, 1, 28),
        time: '15:30',
        location: 'Marseille, Stade Nord',
        distance: '1.2 km',
        status: MatchStatus.requestsReceived,
        createdBy: 'me',
        requestsCount: 3,
      ),
      Match(
        id: '4',
        teamName: 'FC Salon Séniors',
        coachName: 'Jean Dupont',
        category: 'Séniors',
        level: 'Départemental',
        date: DateTime(2025, 1, 18),
        time: '15:00',
        location: 'Salon-de-Provence',
        distance: '15.3 km',
        status: MatchStatus.finished,
        createdBy: 'me',
        homeScore: '2',
        awayScore: '1',
      ),
    ];
    notifyListeners();
  }

  Future<void> createMatch(Map<String, dynamic> matchData) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final newMatch = Match(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teamName: matchData['teamName'],
      coachName: 'Jean Dupont',
      category: matchData['category'],
      level: matchData['level'],
      date: DateTime.parse(matchData['date']),
      time: matchData['time'],
      location: matchData['location'],
      distance: '0 km',
      status: MatchStatus.pending,
      createdBy: 'me',
      description: matchData['notes'],
    );

    _matches.insert(0, newMatch);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateMatchScore(String matchId, String homeScore, String awayScore, 
      List<String> homeScorers, List<String> awayScorers, String notes) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

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
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMatchRequest(String matchId) async {
    final matchIndex = _matches.indexWhere((match) => match.id == matchId);
    if (matchIndex != -1) {
      _matches[matchIndex] = _matches[matchIndex].copyWith(
        status: MatchStatus.requestsSent,
      );
      notifyListeners();
    }
  }

  Match? getMatchById(String id) {
    try {
      return _matches.firstWhere((match) => match.id == id);
    } catch (e) {
      return null;
    }
  }
}