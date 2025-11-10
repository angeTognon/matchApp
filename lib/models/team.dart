import 'package:flutter/material.dart';

class Team {
  final String id;
  final String name;
  final String clubName;
  final String coachName;
  final String category;
  final String level;
  final String location;
  final String distance;
  final String? logo;
  final String? lastActive;
  final String? description;
  final List<MatchResult> recentMatches;
  final String? homeStadium;
  final String? founded;
  final ContactInfo? contact;
  final List<String>? achievements;
  final Map<String, dynamic>? statistics;
  final List<Map<String, dynamic>>? completedMatches;

  Team({
    required this.id,
    required this.name,
    required this.clubName,
    required this.coachName,
    required this.category,
    required this.level,
    required this.location,
    required this.distance,
    this.logo,
    this.lastActive,
    this.description,
    this.recentMatches = const [],
    this.homeStadium,
    this.founded,
    this.contact,
    this.achievements,
    this.statistics,
    this.completedMatches,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    List<MatchResult> matches = [];
    if (json['recent_matches'] != null && json['recent_matches'] is List) {
      try {
        matches = (json['recent_matches'] as List)
            .where((m) => m is Map<String, dynamic>)
            .map((m) => MatchResult.fromJson(m as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Erreur conversion matches: $e');
        matches = [];
      }
    }

    List<String> achievementsList = [];
    if (json['achievements'] != null) {
      try {
        if (json['achievements'] is String) {
          // Si c'est une chaîne, la diviser par les retours à la ligne
          final achievementsStr = json['achievements'] as String;
          if (achievementsStr.isNotEmpty) {
            achievementsList = achievementsStr.split('\n').where((a) => a.trim().isNotEmpty).toList();
          }
        } else if (json['achievements'] is List) {
          // Si c'est déjà une liste, la convertir
          achievementsList = (json['achievements'] as List)
              .where((a) => a != null && a.toString().trim().isNotEmpty)
              .map((a) => a.toString().trim())
              .toList();
        }
      } catch (e) {
        debugPrint('Erreur conversion achievements: $e');
        achievementsList = [];
      }
    }

    return Team(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      clubName: json['club_name'] ?? '',
      coachName: json['coach_name'] ?? '',
      category: json['category'] ?? '',
      level: json['level'] ?? '',
      location: json['location'] ?? '',
      distance: '0 km', // À calculer côté client
      logo: json['logo'],
      description: json['description'],
      recentMatches: matches,
      homeStadium: json['home_stadium'],
      founded: json['founded'],
      achievements: achievementsList,
      statistics: json['statistics'],
      completedMatches: json['completed_matches'] != null 
          ? List<Map<String, dynamic>>.from(json['completed_matches'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'club_name': clubName,
      'coach_name': coachName,
      'category': category,
      'level': level,
      'location': location,
      'logo': logo,
      'description': description,
      'home_stadium': homeStadium,
      'founded': founded,
      'achievements': achievements?.join('\n'),
      'statistics': statistics,
    };
  }
}

class MatchResult {
  final String opponent;
  final String score;
  final MatchResultType result;
  final DateTime date;

  MatchResult({
    required this.opponent,
    required this.score,
    required this.result,
    required this.date,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    MatchResultType resultType;
    switch (json['result']?.toString().toLowerCase()) {
      case 'win':
        resultType = MatchResultType.win;
        break;
      case 'draw':
        resultType = MatchResultType.draw;
        break;
      case 'loss':
        resultType = MatchResultType.loss;
        break;
      default:
        resultType = MatchResultType.draw;
    }

    return MatchResult(
      opponent: json['opponent'] ?? '',
      score: json['score'] ?? '',
      result: resultType,
      date: DateTime.parse(json['match_date'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opponent': opponent,
      'score': score,
      'result': result.name,
      'match_date': date.toIso8601String(),
    };
  }
}

enum MatchResultType { win, draw, loss }

extension MatchResultTypeExtension on MatchResultType {
  Color get color {
    switch (this) {
      case MatchResultType.win:
        return const Color(0xFF2E7D32);
      case MatchResultType.draw:
        return const Color(0xFFFFA726);
      case MatchResultType.loss:
        return const Color(0xFFFF4444);
    }
  }
}

class ContactInfo {
  final String? phone;
  final String? email;

  ContactInfo({this.phone, this.email});

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      phone: json['phone'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
    };
  }
}