import 'package:amical_club/models/team.dart';
import 'package:amical_club/constants/team_constants.dart';

class TeamCreationHelper {
  // Utiliser les constantes centralisées
  static List<String> get availableCategories => TeamConstants.categories;
  static List<String> get availableLevels => TeamConstants.levels;

  // Validation des données d'équipe
  static Map<String, String> validateTeamData({
    required String name,
    String? clubName,
    String? category,
    String? level,
    String? location,
    String? description,
    String? founded,
    String? homeStadium,
    String? achievements,
  }) {
    Map<String, String> errors = {};

    // Validation du nom (obligatoire)
    if (name.trim().isEmpty) {
      errors['name'] = 'Le nom de l\'équipe est obligatoire';
    } else if (name.trim().length < 2) {
      errors['name'] = 'Le nom doit contenir au moins 2 caractères';
    }

    // Validation de l'année de création
    if (founded != null && founded.isNotEmpty) {
      if (!RegExp(r'^\d{4}$').hasMatch(founded)) {
        errors['founded'] = 'L\'année doit contenir 4 chiffres';
      } else {
        final year = int.tryParse(founded);
        if (year == null || year < 1800 || year > 2100) {
          errors['founded'] = 'Année invalide (1800-2100)';
        }
      }
    }

    // Validation de la catégorie
    if (category != null && category.isNotEmpty) {
      final normalized = TeamConstants.normalizeCategory(category);
      if (normalized == null) {
        errors['category'] = 'Catégorie invalide';
      }
    }

    // Validation du niveau
    if (level != null && level.isNotEmpty) {
      final normalized = TeamConstants.normalizeLevel(level);
      if (normalized == null) {
        errors['level'] = 'Niveau invalide';
      }
    }

    return errors;
  }

  // Générer des suggestions de noms d'équipe
  static List<String> generateTeamNameSuggestions(String clubName) {
    if (clubName.isEmpty) return [];
    
    return [
      '$clubName Jeunes',
      '$clubName Séniors',
      '$clubName U17',
      '$clubName U19',
      '$clubName Féminines',
      '$clubName Vétérans',
    ];
  }

  // Vérifier si une équipe est complète
  static bool isTeamComplete(Team team) {
    return team.name.isNotEmpty &&
           team.category.isNotEmpty &&
           team.level.isNotEmpty &&
           team.location.isNotEmpty;
  }

  // Obtenir le pourcentage de complétion d'une équipe
  static double getTeamCompletionPercentage(Team team) {
    int completedFields = 0;
    int totalFields = 8; // Nom, club, catégorie, niveau, localisation, description, année, stade

    if (team.name.isNotEmpty) completedFields++;
    if (team.clubName.isNotEmpty) completedFields++;
    if (team.category.isNotEmpty) completedFields++;
    if (team.level.isNotEmpty) completedFields++;
    if (team.location.isNotEmpty) completedFields++;
    if (team.description != null && team.description!.isNotEmpty) completedFields++;
    if (team.founded != null && team.founded!.isNotEmpty) completedFields++;
    if (team.homeStadium != null && team.homeStadium!.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }
}
