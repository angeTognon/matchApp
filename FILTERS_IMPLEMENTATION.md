# Implémentation des filtres sur l'écran d'accueil

## Modifications apportées

### 1. FilterModal (`lib/widgets/filter_modal.dart`)

**Problème initial :**
- Les valeurs d'affichage ("Toutes", "Tous", "Masculin", "Féminin", etc.) étaient envoyées directement à l'API
- L'API attend soit des chaînes vides, soit des valeurs exactes de la base de données

**Solution :**
- Ajout de fonctions de conversion `_getApiValue()` et `_getDisplayValue()`
- Les valeurs "Toutes" / "Tous" sont maintenant converties en chaînes vides ('')
- Les autres valeurs sont envoyées telles quelles (U6, U8, Loisir, Départemental, Masculin, Féminin, Mixte, etc.)

### 2. MatchProvider (`lib/providers/match_provider.dart`)

**Améliorations :**
- Ajout du filtre **distance** dans la structure de filtres
- Implémentation du filtrage par distance côté client (car non supporté par le backend)
- Ajout d'une fonction `_parseDistance()` pour extraire les valeurs numériques des chaînes de distance
- Le filtre distance fonctionne avec des valeurs comme "5 km", "10 km", "25 km", "50 km"

**Logique de filtrage distance :**
```dart
// Exemple: Si le filtre est "10 km", seuls les matchs <= 10 km seront affichés
if (_filters['distance']?.isNotEmpty == true) {
  final maxDistance = _parseDistance(_filters['distance']!);
  final matchDistance = _parseDistance(match.distance);
  if (matchDistance > maxDistance) {
    return false; // Exclure ce match
  }
}
```

### 3. HomeScreen (`lib/screens/home/home_screen.dart`)

**Modification :**
- Ajout du paramètre `distance` lors de l'appel à `matchProvider.applyFilters()`
- Le filtre distance est maintenant pris en compte lors de l'application des filtres

## Filtres disponibles

### Catégorie
- Toutes (aucun filtre)
- U6, U8, U10, U12, U14, U16, U17, U19
- Séniors
- Vétérans

### Niveau
- Tous (aucun filtre)
- Loisir
- Départemental
- Régional
- National

### Genre
- Tous (aucun filtre)
- Masculin
- Féminin
- Mixte

### Distance
- Toutes (aucun filtre)
- 5 km (affiche les matchs jusqu'à 5 km)
- 10 km (affiche les matchs jusqu'à 10 km)
- 25 km (affiche les matchs jusqu'à 25 km)
- 50 km (affiche les matchs jusqu'à 50 km)

### Recherche (barre de recherche)
- Recherche par nom d'équipe, nom de club ou lieu
- Recherche en temps réel (à chaque caractère saisi)

## Fonctionnement

1. **Filtres backend (Category, Level, Gender, Search)**
   - Envoyés à l'API lors du chargement des matchs
   - Filtrage effectué au niveau de la base de données
   - Optimisé pour les grandes quantités de données

2. **Filtre client (Distance)**
   - Appliqué après réception des données depuis l'API
   - Filtrage effectué en mémoire côté Flutter
   - Permet un filtrage instantané sans appel réseau

3. **Combinaison de filtres**
   - Tous les filtres peuvent être combinés
   - Le filtrage est cumulatif (ET logique entre tous les filtres actifs)
   - Exemple: Catégorie "U17" + Niveau "Régional" + Distance "10 km" = affiche uniquement les matchs U17 de niveau régional à moins de 10 km

## Réinitialisation des filtres

Le bouton "Réinitialiser" dans le modal de filtres remet tous les filtres à leur valeur par défaut (chaînes vides), ce qui affiche tous les matchs disponibles.

## Notes techniques

- Les distances sont calculées côté backend (fonction `_calculateFakeDistance()` dans `get_matches.php`)
- Les distances générées sont: 0.5 km, 1.2 km, 2.5 km, 3.8 km, 5.1 km, 7.3 km, 9.6 km, 12.4 km, 15.7 km
- La fonction `_parseDistance()` utilise une expression régulière pour extraire les nombres des chaînes de distance
- Format reconnu: "X km" ou "X.Y km" où X et Y sont des chiffres


