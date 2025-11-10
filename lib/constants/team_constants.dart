/// Constantes pour les équipes
class TeamConstants {
  // Catégories d'équipes disponibles
  static const List<String> categories = [
    'U7',
    'U9',
    'U11',
    'U13',
    'U15',
    'U17',
    'U19',
    'Séniors',
    'Vétérans',
    'Féminines',
  ];

  // Niveaux d'équipes disponibles
  static const List<String> levels = [
    'Loisir',
    'Départemental',
    'Régional',
    'National',
    'Championnat',
    'Coupe',
  ];

  // Vérifier si une catégorie est valide
  static bool isValidCategory(String category) {
    return categories.contains(category);
  }

  // Vérifier si un niveau est valide
  static bool isValidLevel(String level) {
    return levels.contains(level);
  }

  // Normaliser une catégorie (gérer les variations)
  static String? normalizeCategory(String? category) {
    if (category == null || category.isEmpty) return null;
    
    // Gérer les variations courantes
    final normalized = category.trim();
    
    // Gérer "Seniors" vs "Séniors"
    if (normalized.toLowerCase() == 'seniors') return 'Séniors';
    
    // Gérer "Veterans" vs "Vétérans"
    if (normalized.toLowerCase() == 'veterans') return 'Vétérans';
    
    // Gérer "Feminines" vs "Féminines"
    if (normalized.toLowerCase() == 'feminines') return 'Féminines';
    
    // Si la catégorie existe déjà, la retourner
    if (categories.contains(normalized)) return normalized;
    
    return null;
  }

  // Normaliser un niveau
  static String? normalizeLevel(String? level) {
    if (level == null || level.isEmpty) return null;
    
    final normalized = level.trim();
    
    // Gérer "Departemental" vs "Départemental"
    if (normalized.toLowerCase() == 'departemental') return 'Départemental';
    
    // Gérer "Regional" vs "Régional"
    if (normalized.toLowerCase() == 'regional') return 'Régional';
    
    // Si le niveau existe déjà, le retourner
    if (levels.contains(normalized)) return normalized;
    
    return null;
  }
}
