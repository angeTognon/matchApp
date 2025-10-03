import 'package:flutter/material.dart';

class Match {
  final String id;
  final String teamName;
  final String coachName;
  final String category;
  final String level;
  final DateTime date;
  final String time;
  final String location;
  final String distance;
  final MatchStatus status;
  final String createdBy;
  final int requestsCount;
  final String? description;
  final List<String>? facilities;
  final String? homeScore;
  final String? awayScore;
  final List<String>? homeScorers;
  final List<String>? awayScorers;
  final String? notes;

  Match({
    required this.id,
    required this.teamName,
    required this.coachName,
    required this.category,
    required this.level,
    required this.date,
    required this.time,
    required this.location,
    required this.distance,
    required this.status,
    required this.createdBy,
    this.requestsCount = 0,
    this.description,
    this.facilities,
    this.homeScore,
    this.awayScore,
    this.homeScorers,
    this.awayScorers,
    this.notes,
  });

  Match copyWith({
    String? id,
    String? teamName,
    String? coachName,
    String? category,
    String? level,
    DateTime? date,
    String? time,
    String? location,
    String? distance,
    MatchStatus? status,
    String? createdBy,
    int? requestsCount,
    String? description,
    List<String>? facilities,
    String? homeScore,
    String? awayScore,
    List<String>? homeScorers,
    List<String>? awayScorers,
    String? notes,
  }) {
    return Match(
      id: id ?? this.id,
      teamName: teamName ?? this.teamName,
      coachName: coachName ?? this.coachName,
      category: category ?? this.category,
      level: level ?? this.level,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      distance: distance ?? this.distance,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      requestsCount: requestsCount ?? this.requestsCount,
      description: description ?? this.description,
      facilities: facilities ?? this.facilities,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      homeScorers: homeScorers ?? this.homeScorers,
      awayScorers: awayScorers ?? this.awayScorers,
      notes: notes ?? this.notes,
    );
  }
}

enum MatchStatus {
  available,
  pending,
  confirmed,
  finished,
  requestsSent,
  requestsReceived,
}

extension MatchStatusExtension on MatchStatus {
  String get displayName {
    switch (this) {
      case MatchStatus.available:
        return 'Disponible';
      case MatchStatus.pending:
        return 'En attente';
      case MatchStatus.confirmed:
        return 'Confirmé';
      case MatchStatus.finished:
        return 'Terminé';
      case MatchStatus.requestsSent:
        return 'Demande envoyée';
      case MatchStatus.requestsReceived:
        return 'Demandes reçues';
    }
  }

  Color get color {
    switch (this) {
      case MatchStatus.available:
        return const Color(0xFF2E7D32);
      case MatchStatus.pending:
        return const Color(0xFFFFA726);
      case MatchStatus.confirmed:
        return const Color(0xFF003366);
      case MatchStatus.finished:
        return const Color(0xFF999999);
      case MatchStatus.requestsSent:
        return const Color(0xFF9C27B0);
      case MatchStatus.requestsReceived:
        return const Color(0xFF003366);
    }
  }
}