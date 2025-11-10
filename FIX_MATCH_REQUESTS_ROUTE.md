# 🔧 Fix : Page /match-requests n'existe pas

## ❌ Erreur rencontrée

```
La page "/match-request" n'existe pas
```

## ✅ Solution

La route correcte est **`/match-requests`** (avec un **s** à la fin).

### URLs

- ❌ **Incorrect** : `/match-request` (sans le 's')
- ✅ **Correct** : `/match-requests` (avec le 's')

---

## 🚀 Utilisation normale

Vous n'avez **pas besoin de taper l'URL manuellement**. Utilisez l'interface :

1. Ouvrir l'application
2. Onglet **"Profil"** (en bas)
3. Cliquer sur le bouton orange **"Demandes de match"** 📧

→ L'application navigue automatiquement vers `/match-requests`

---

## 🔍 Vérifications

### 1. Vérifier que le fichier existe
```bash
ls lib/screens/match/match_requests_screen.dart
```
✅ Le fichier doit exister

### 2. Vérifier la route dans app_router.dart
```dart
GoRoute(
  path: '/match-requests',  // ← Avec le 's'
  builder: (context, state) => const all_requests.MatchRequestsScreen(),
),
```

### 3. Vérifier le bouton dans profile_screen.dart
```dart
onPressed: () => context.push('/match-requests'),  // ← Avec le 's'
```

---

## 🔄 Si le problème persiste

### Étape 1 : Nettoyer le cache
```bash
cd /Users/mac/Documents/amical_club
flutter clean
flutter pub get
```

### Étape 2 : Recompiler l'application
```bash
flutter run
```

### Étape 3 : Hot restart (dans l'app)
- Appuyer sur **R** dans le terminal où l'app tourne
- Ou redémarrer complètement l'application

---

## ⚙️ Code complet de la route

Dans `lib/config/app_router.dart` :

```dart
import 'package:amical_club/screens/match/match_requests_screen.dart' as all_requests;

// Dans les routes :
GoRoute(
  path: '/match-requests',
  builder: (context, state) => const all_requests.MatchRequestsScreen(),
),
```

Dans `lib/screens/profile/profile_screen.dart` :

```dart
TextButton.icon(
  onPressed: () => context.push('/match-requests'),
  icon: const Icon(Icons.mail_outline, size: 16, color: Colors.orange),
  label: const Text('Demandes de match'),
),
```

---

## ✅ Résultat attendu

Après avoir cliqué sur le bouton "Demandes de match" :
- Page s'ouvre avec 2 onglets : "Reçues" et "Envoyées"
- Pas de message d'erreur
- Navigation fluide

---

## 🐛 Autres problèmes possibles

### Erreur : "Cannot find constructor"
**Solution** : 
```bash
flutter clean
flutter pub get
flutter run
```

### Erreur : "Column not found: m.coach_id"
**Solution** : Exécuter le script SQL
```sql
ALTER TABLE amicalclub_matches 
ADD COLUMN coach_id INT NOT NULL AFTER team_id;

UPDATE amicalclub_matches m
JOIN amicalclub_teams t ON m.team_id = t.id
SET m.coach_id = t.coach_id;
```

### Page blanche ou erreur de chargement
**Solution** : 
1. Vérifier que le token d'authentification est valide
2. Vérifier que les fichiers PHP backend sont accessibles
3. Regarder les logs dans le terminal

---

## ✅ C'est corrigé !

La route `/match-requests` (avec le 's') fonctionne correctement.

Utilisez simplement le bouton dans le profil pour y accéder ! 🎉


