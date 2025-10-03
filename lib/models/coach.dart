import 'package:amical_club/models/team.dart';

class Coach {
  final String id;
  final String name;
  final String location;
  final String licenseNumber;
  final String experience;
  final List<Team> teams;
  final String? avatar;

  Coach({
    required this.id,
    required this.name,
    required this.location,
    required this.licenseNumber,
    required this.experience,
    required this.teams,
    this.avatar,
  });

  Coach copyWith({
    String? id,
    String? name,
    String? location,
    String? licenseNumber,
    String? experience,
    List<Team>? teams,
    String? avatar,
  }) {
    return Coach(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      experience: experience ?? this.experience,
      teams: teams ?? this.teams,
      avatar: avatar ?? this.avatar,
    );
  }

  int get totalClubs => teams.map((team) => team.clubName).toSet().length;
}