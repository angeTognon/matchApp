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
  });
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
}