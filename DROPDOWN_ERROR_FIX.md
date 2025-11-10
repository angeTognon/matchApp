# Correction de l'erreur Dropdown

## 🐛 Problème identifié

```
There should be exactly one item with [DropdownButton]'s value: Seniors.
Either zero or 2 or more [DropdownMenuItem]s were detected with the same value
```

### **Cause**
Incohérence entre les valeurs dans la base de données et les valeurs dans le dropdown :
- Base de données : `"Seniors"` (sans accent)
- Dropdown Flutter : `"Séniors"` (avec accent)

## ✅ Solutions implémentées

### 1. **Création de constantes centralisées**
Fichier : `lib/constants/team_constants.dart`

```dart
class TeamConstants {
  static const List<String> categories = [
    'U7', 'U9', 'U11', 'U13', 'U15', 'U17', 'U19',
    'Séniors', 'Vétérans', 'Féminines'
  ];

  static const List<String> levels = [
    'Loisir', 'Départemental', 'Régional', 
    'National', 'Championnat', 'Coupe'
  ];
}
```

### 2. **Fonction de normalisation**
Gère les variations courantes :
- `"Seniors"` → `"Séniors"` ✅
- `"Veterans"` → `"Vétérans"` ✅
- `"Feminines"` → `"Féminines"` ✅
- `"Departemental"` → `"Départemental"` ✅
- `"Regional"` → `"Régional"` ✅

### 3. **Mise à jour de l'écran d'édition**
- Utilisation des constantes centralisées
- Normalisation automatique des valeurs
- Vérification de la validité avant affichage

### 4. **Script SQL de normalisation**
Fichier : `backend/normalize_team_data.sql`

```sql
UPDATE `amicalclub_teams` SET `category` = 'Séniors' 
WHERE LOWER(`category`) = 'seniors';

UPDATE `amicalclub_teams` SET `level` = 'Départemental' 
WHERE LOWER(`level`) = 'departemental';
```

## 🔧 Fichiers modifiés

### **Créés :**
- ✅ `lib/constants/team_constants.dart` - Constantes centralisées
- ✅ `backend/normalize_team_data.sql` - Script de normalisation

### **Modifiés :**
- ✅ `lib/screens/team/edit_team_screen.dart` - Utilisation des constantes
- ✅ `lib/utils/team_creation_helper.dart` - Utilisation des constantes

## 🚀 Comment corriger les données existantes

### **Option 1 : Via phpMyAdmin**
1. Ouvrir phpMyAdmin
2. Sélectionner la base de données
3. Onglet "SQL"
4. Copier-coller le contenu de `normalize_team_data.sql`
5. Exécuter

### **Option 2 : Via ligne de commande**
```bash
mysql -u votre_utilisateur -p votre_base < backend/normalize_team_data.sql
```

## 🎯 Valeurs standards à utiliser

### **Catégories :**
- ✅ U7, U9, U11, U13, U15, U17, U19
- ✅ Séniors (avec accent)
- ✅ Vétérans (avec accent)
- ✅ Féminines (avec accent)

### **Niveaux :**
- ✅ Loisir
- ✅ Départemental (avec accent)
- ✅ Régional (avec accent)
- ✅ National
- ✅ Championnat
- ✅ Coupe

## ✨ Prévention future

1. **Toujours utiliser** `TeamConstants.categories` et `TeamConstants.levels`
2. **Normaliser les données** avec `TeamConstants.normalizeCategory()` et `TeamConstants.normalizeLevel()`
3. **Exécuter le script SQL** de normalisation après import de données
4. **Utiliser les dropdowns** pour éviter les erreurs de saisie

Le problème est maintenant résolu ! 🎉
