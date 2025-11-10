class MatchRequest {
  final String requestId;
  final String matchId;
  final String requestStatus;
  final String? requestMessage;
  final DateTime requestDate;
  final DateTime? respondedAt;
  
  // Match info
  final DateTime matchDate;
  final String matchTime;
  final String location;
  final String? opponent;
  final String? category;
  final String? level;
  final String? gender;
  final String matchStatus;
  
  // Requesting team (pour les demandes reçues) ou My team (pour les demandes envoyées)
  final String teamId;
  final String teamName;
  final String? clubName;
  final String? teamLogo;
  final String? teamLevel;
  final String? teamCategory;
  
  // Coach info
  final String coachId;
  final String coachName;
  final String? coachEmail;
  final String? coachAvatar;
  
  // My team info (pour les demandes reçues)
  final String? myTeamId;
  final String? myTeamName;
  final String? myClubName;
  final String? myTeamLogo;

  MatchRequest({
    required this.requestId,
    required this.matchId,
    required this.requestStatus,
    this.requestMessage,
    required this.requestDate,
    this.respondedAt,
    required this.matchDate,
    required this.matchTime,
    required this.location,
    this.opponent,
    this.category,
    this.level,
    this.gender,
    required this.matchStatus,
    required this.teamId,
    required this.teamName,
    this.clubName,
    this.teamLogo,
    this.teamLevel,
    this.teamCategory,
    required this.coachId,
    required this.coachName,
    this.coachEmail,
    this.coachAvatar,
    this.myTeamId,
    this.myTeamName,
    this.myClubName,
    this.myTeamLogo,
  });

  factory MatchRequest.fromJson(Map<String, dynamic> json, {bool isReceived = true}) {
    if (isReceived) {
      // Demandes reçues
      return MatchRequest(
        requestId: json['request_id']?.toString() ?? '',
        matchId: json['match_id']?.toString() ?? '',
        requestStatus: json['request_status'] ?? 'pending',
        requestMessage: json['request_message'],
        requestDate: DateTime.tryParse(json['request_date'] ?? '') ?? DateTime.now(),
        respondedAt: json['responded_at'] != null ? DateTime.tryParse(json['responded_at']) : null,
        matchDate: DateTime.tryParse(json['match_date'] ?? '') ?? DateTime.now(),
        matchTime: json['match_time'] ?? '',
        location: json['location'] ?? '',
        opponent: json['opponent'],
        category: json['category'] ?? json['requesting_team_category'],
        level: json['level'] ?? json['requesting_team_level'],
        gender: json['gender'],
        matchStatus: json['match_status'] ?? 'pending',
        teamId: json['requesting_team_id']?.toString() ?? '',
        teamName: json['requesting_team_name'] ?? '',
        clubName: json['requesting_club_name'],
        teamLogo: json['requesting_team_logo'],
        teamLevel: json['requesting_team_level'],
        teamCategory: json['requesting_team_category'],
        coachId: json['requesting_coach_id']?.toString() ?? '',
        coachName: json['requesting_coach_name'] ?? '',
        coachEmail: json['requesting_coach_email'],
        coachAvatar: json['requesting_coach_avatar'],
        myTeamId: json['my_team_id']?.toString(),
        myTeamName: json['my_team_name'],
        myClubName: json['my_club_name'],
        myTeamLogo: json['my_team_logo'],
      );
    } else {
      // Demandes envoyées
      return MatchRequest(
        requestId: json['request_id']?.toString() ?? '',
        matchId: json['match_id']?.toString() ?? '',
        requestStatus: json['request_status'] ?? 'pending',
        requestMessage: json['request_message'],
        requestDate: DateTime.tryParse(json['request_date'] ?? '') ?? DateTime.now(),
        respondedAt: json['responded_at'] != null ? DateTime.tryParse(json['responded_at']) : null,
        matchDate: DateTime.tryParse(json['match_date'] ?? '') ?? DateTime.now(),
        matchTime: json['match_time'] ?? '',
        location: json['location'] ?? '',
        opponent: json['opponent'],
        category: json['category'] ?? json['host_team_category'],
        level: json['level'] ?? json['host_team_level'],
        gender: json['gender'],
        matchStatus: json['match_status'] ?? 'pending',
        teamId: json['host_team_id']?.toString() ?? '',
        teamName: json['host_team_name'] ?? '',
        clubName: json['host_club_name'],
        teamLogo: json['host_team_logo'],
        teamLevel: json['host_team_level'],
        teamCategory: json['host_team_category'],
        coachId: json['host_coach_id']?.toString() ?? '',
        coachName: json['host_coach_name'] ?? '',
        coachEmail: json['host_coach_email'],
        coachAvatar: json['host_coach_avatar'],
        myTeamId: json['my_team_id']?.toString(),
        myTeamName: json['my_team_name'],
        myClubName: json['my_club_name'],
        myTeamLogo: json['my_team_logo'],
      );
    }
  }

  String get statusDisplay {
    switch (requestStatus) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'rejected':
        return 'Refusée';
      default:
        return requestStatus;
    }
  }

  String get formattedDate {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${matchDate.day} ${months[matchDate.month - 1]} ${matchDate.year}';
  }

  String get formattedTime {
    return matchTime.substring(0, 5); // HH:MM
  }
}
