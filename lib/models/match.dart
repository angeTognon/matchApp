import 'package:flutter/material.dart';
import 'dart:convert';

class Match {
  final String id;
  final String teamId;
  final String teamName;
  final String clubName;
  final String coachName;
  final String category;
  final String level;
  final String? gender;
  final DateTime date;
  final String time;
  final String location;
  final String? stadium;
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
  final bool? autoValidation;
  final bool? isOwner;
  final bool? userHasRequested;
  final String? teamLogo;
  final String? coachAvatar;

  Match({
    required this.id,
    required this.teamId,
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
    this.clubName = '',
    this.gender,
    this.stadium,
    this.requestsCount = 0,
    this.description,
    this.facilities,
    this.homeScore,
    this.awayScore,
    this.homeScorers,
    this.awayScorers,
    this.notes,
    this.autoValidation,
    this.isOwner,
    this.userHasRequested,
    this.teamLogo,
    this.coachAvatar,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id']?.toString() ?? '',
      teamId: json['team_id']?.toString() ?? '',
      teamName: json['team_name'] ?? '',
      clubName: json['club_name'] ?? '',
      coachName: json['coach_name'] ?? '',
      category: json['category'] ?? '',
      level: json['level'] ?? '',
      gender: json['gender'],
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      time: json['time'] ?? '',
      location: json['location'] ?? '',
      stadium: json['stadium'],
      distance: json['distance'] ?? '0 km',
      status: _parseStatus(json['status']),
      createdBy: json['coach_id']?.toString() ?? '',
      requestsCount: json['requests_count'] ?? 0,
      description: json['description'],
      homeScore: json['home_score'],
      awayScore: json['away_score'],
      homeScorers: json['home_scorers'] != null 
          ? (json['home_scorers'] is String 
              ? (json['home_scorers'] as String).split(',').where((s) => s.trim().isNotEmpty).toList()
              : (json['home_scorers'] as List<dynamic>).map((e) => e.toString()).toList())
          : null,
      awayScorers: json['away_scorers'] != null 
          ? (json['away_scorers'] is String 
              ? (json['away_scorers'] as String).split(',').where((s) => s.trim().isNotEmpty).toList()
              : (json['away_scorers'] as List<dynamic>).map((e) => e.toString()).toList())
          : null,
      notes: json['notes'],
      facilities: json['facilities'] != null 
          ? (json['facilities'] is String 
              ? (json['facilities'] as String).isNotEmpty 
                  ? _parseFacilitiesString(json['facilities'] as String)
                  : null
              : (json['facilities'] as List<dynamic>).map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList())
          : null,
      autoValidation: json['auto_validation'] == 1 || json['auto_validation'] == true,
      isOwner: json['is_owner'] == 1 || json['is_owner'] == true,
      userHasRequested: json['user_has_requested'] == 1 || json['user_has_requested'] == true,
      teamLogo: json['team_logo'],
      coachAvatar: json['coach_avatar'],
    );
  }

  Match copyWith({
    String? id,
    String? teamId,
    String? teamName,
    String? clubName,
    String? coachName,
    String? category,
    String? level,
    String? gender,
    DateTime? date,
    String? time,
    String? location,
    String? stadium,
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
    bool? autoValidation,
    bool? isOwner,
    bool? userHasRequested,
    String? teamLogo,
    String? coachAvatar,
  }) {
    return Match(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      clubName: clubName ?? this.clubName,
      coachName: coachName ?? this.coachName,
      category: category ?? this.category,
      level: level ?? this.level,
      gender: gender ?? this.gender,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      stadium: stadium ?? this.stadium,
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
      autoValidation: autoValidation ?? this.autoValidation,
      isOwner: isOwner ?? this.isOwner,
      userHasRequested: userHasRequested ?? this.userHasRequested,
      teamLogo: teamLogo ?? this.teamLogo,
      coachAvatar: coachAvatar ?? this.coachAvatar,
    );
  }

  static MatchStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return MatchStatus.available;
      case 'win':
      case 'draw':
      case 'loss':
        return MatchStatus.finished;
      default:
        return MatchStatus.available;
    }
  }

  static List<String> _parseFacilitiesString(String facilitiesString) {
    try {
      // Essayer de parser comme JSON d'abord
      if (facilitiesString.startsWith('[') && facilitiesString.endsWith(']')) {
        final List<dynamic> jsonList = json.decode(facilitiesString);
        return jsonList.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      }
      // Sinon, traiter comme une chaîne séparée par des virgules
      return facilitiesString.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } catch (e) {
      // En cas d'erreur, traiter comme une chaîne séparée par des virgules
      return facilitiesString.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
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