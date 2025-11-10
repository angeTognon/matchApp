# ✅ Section "Matchs en cours" dans le profil

## 🎯 Fonctionnalité ajoutée

Une nouvelle section **"Matchs en cours"** apparaît automatiquement dans votre profil quand vous avez des matchs confirmés (acceptés).

---

## 📱 Interface

### Vue dans le profil

```
┌─────────────────────────────────────────────────┐
│  Profil                                          │
│  ├── Info coach                                  │
│  ├── [Modifier profil] [Mes matchs]            │
│  ├── [📧 Demandes de match]                     │
│  ├── Mes équipes                                 │
│  ├── Matchs récents                              │
│  │                                               │
│  ├── 🆕 Matchs en cours (2) ← NOUVEAU           │
│  │   ┌─────────────────────────────────────┐  │
│  │   │ ✓ Match confirmé               🟢   │  │
│  │   ├─────────────────────────────────────┤  │
│  │   │ FC Lions vs FC Tigers                │  │
│  │   │ U17 • Régional            3-1  🟢   │  │
│  │   │ 📅 20 Oct  🕐 15:00                 │  │
│  │   │ 📍 Stade Municipal                   │  │
│  │   │ [Modifier le score]                  │  │
│  │   └─────────────────────────────────────┘  │
│  │   ┌─────────────────────────────────────┐  │
│  │   │ ✓ Match confirmé               🟢   │  │
│  │   ├─────────────────────────────────────┤  │
│  │   │ AS Monaco vs Real Madrid             │  │
│  │   │ Séniors • National                   │  │
│  │   │ 📅 25 Oct  🕐 14:30                 │  │
│  │   │ 📍 Complexe Sportif                 │  │
│  │   │ [Ajouter le score]                  │  │
│  │   └─────────────────────────────────────┘  │
│  │                                               │
│  └── Paramètres                                  │
└─────────────────────────────────────────────────┘
```

---

## ✨ Fonctionnalités

### 1. **Affichage automatique**
- La section apparaît seulement si vous avez des matchs confirmés
- Badge vert avec le nombre de matchs en cours
- Design cohérent avec le reste de l'interface

### 2. **Informations complètes**
- **Équipes** : Votre équipe vs Équipe adverse
- **Catégorie et niveau** : Affichés si disponibles
- **Date et heure** : Formatées proprement
- **Lieu** : Localisation du match
- **Score** : Affiché s'il a été saisi (avec couleur selon résultat)

### 3. **Gestion du score** 🎯

#### Pour les matchs futurs :
- Pas de bouton (on attend que le match soit joué)

#### Pour les matchs passés SANS score :
- **Bouton bleu "Ajouter le score"**
- Cliquer → Dialogue s'ouvre
- Saisir : Score, Résultat (Victoire/Nul/Défaite), Notes
- Valider → Score enregistré

#### Pour les matchs passés AVEC score :
- **Score affiché** avec couleur :
  - 🟢 Vert = Victoire
  - 🟠 Orange = Match nul
  - 🔴 Rouge = Défaite
- **Bouton "Modifier le score"** pour corriger

---

## 🔄 Dialogue d'ajout de score

```
┌─────────────────────────────────────────┐
│  Score du match                         │
│                                         │
│  FC Lions vs FC Tigers                  │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │ Score (ex: 3-1, 2-2)            │  │
│  │ [  3-1  ]                       │  │
│  └─────────────────────────────────┘  │
│                                         │
│  Résultat:                              │
│  [✓ Victoire] [Match nul] [Défaite]   │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │ Notes (optionnel)               │  │
│  │ [Belle victoire malgré la       │  │
│  │  pluie. Bon match.]             │  │
│  └─────────────────────────────────┘  │
│                                         │
│  [Annuler]          [Enregistrer]      │
└─────────────────────────────────────────┘
```

---

## 📁 Fichiers créés

### Backend PHP (2 fichiers)

#### 1. **`backend/get_confirmed_matches.php`**
Récupère tous les matchs confirmés de l'utilisateur.

**Fonctionnalités :**
- Récupère les matchs où VOUS êtes l'hôte et qui sont confirmés
- Récupère les matchs où VOUS êtes l'adversaire (demande acceptée)
- UNION des deux pour avoir tous vos matchs
- Détecte si le match est passé ou futur

**SQL :**
```sql
-- Matchs où je suis l'hôte
SELECT m.*, t.name as team_name, ...
FROM amicalclub_matches m
JOIN amicalclub_teams t ON m.team_id = t.id
WHERE t.coach_id = ? AND m.result = 'confirmed'

UNION ALL

-- Matchs où je suis l'adversaire
SELECT m.*, my_team.name as team_name, ...
FROM amicalclub_match_requests mr
JOIN amicalclub_matches m ON mr.match_id = m.id
JOIN amicalclub_teams my_team ON mr.requesting_team_id = my_team.id
WHERE my_team.coach_id = ? AND mr.status = 'accepted' AND m.result = 'confirmed'
```

#### 2. **`backend/update_match_result.php`**
Met à jour le score et le résultat d'un match.

**Paramètres :**
- `match_id` : ID du match
- `score` : Score (ex: "3-1")
- `result` : Résultat ('win', 'draw', 'loss')
- `notes` : Notes optionnelles

**Sécurité :**
- Vérifie que l'utilisateur est propriétaire du match
- Seul le créateur peut ajouter le score

---

### Frontend Flutter

#### 3. **Modifications de `lib/services/api_service.dart`**

**Nouvelles méthodes :**
```dart
// Récupérer les matchs confirmés
static Future<Map<String, dynamic>> getConfirmedMatches({
  required String token,
})

// Mettre à jour le résultat d'un match
static Future<Map<String, dynamic>> updateMatchResult({
  required String token,
  required String matchId,
  required String score,
  required String result,
  String? notes,
})
```

#### 4. **Modifications de `lib/screens/profile/profile_screen.dart`**

**Nouvelles méthodes :**
- `_buildConfirmedMatchesSection()` : Construit la section complète
- `_buildConfirmedMatchCard()` : Construit chaque carte de match
- `_getResultColor()` : Retourne la couleur selon le résultat
- `_showAddScoreDialog()` : Affiche le dialogue pour ajouter/modifier le score

**Caractéristiques :**
- FutureBuilder pour charger les données de façon asynchrone
- Affichage seulement si des matchs confirmés existent
- Boutons conditionnels selon l'état du match
- Dialogue avec ChoiceChip pour sélectionner le résultat

---

## 🎨 Design

### Carte de match confirmé (sans score)
```
┌─────────────────────────────────────────┐
│ ✓ Match confirmé                   🟢  │
├─────────────────────────────────────────┤
│ FC Lions vs FC Tigers                   │
│ U17 • Régional                          │
│ ─────────────────────────────────────   │
│ 📅 20 Oct 2025    🕐 15:00             │
│ 📍 Stade Municipal                      │
│                                         │
│ [Ajouter le score]                     │
└─────────────────────────────────────────┘
```

### Carte de match confirmé (avec score)
```
┌─────────────────────────────────────────┐
│ ✓ Match confirmé                   🟢  │
├─────────────────────────────────────────┤
│ FC Lions vs FC Tigers      3-1  🟢     │
│ U17 • Régional                          │
│ ─────────────────────────────────────   │
│ 📅 20 Oct 2025    🕐 15:00             │
│ 📍 Stade Municipal                      │
│                                         │
│ [Modifier le score]                    │
└─────────────────────────────────────────┘
```

---

## 🔄 Flux de fonctionnement

### Scénario complet :

1. **Créer un match** → Apparaît sur l'accueil (pending)
2. **Recevoir une demande** → Badge orange "1 demande"
3. **Accepter la demande** → Match passe en "confirmed"
4. **Match disparaît de l'accueil** (car plus pending)
5. **Match apparaît dans "Matchs en cours"** du profil ✅
6. **Jouer le match** (dans la vraie vie)
7. **Retourner dans l'app**
8. **Cliquer "Ajouter le score"** ✅
9. **Saisir** : Score (3-1), Résultat (Victoire), Notes
10. **Enregistrer** → Score affiché avec couleur verte ✅
11. **Match passe en "Terminé"** (result = 'win')

---

## 🧪 Comment tester

### Test 1 : Voir les matchs en cours

1. Avoir au moins un match confirmé
2. Aller dans l'onglet **Profil**
3. Scroller vers le bas
4. **Vérifier** : Section "Matchs en cours (X)" apparaît
5. **Vérifier** : Liste des matchs confirmés s'affiche

### Test 2 : Ajouter un score

1. Trouver un match passé sans score
2. Cliquer sur **"Ajouter le score"**
3. **Vérifier** : Dialogue s'ouvre
4. Saisir un score (ex: "3-1")
5. Sélectionner un résultat (ex: Victoire)
6. Ajouter des notes (optionnel)
7. Cliquer sur **"Enregistrer"**
8. **Vérifier** : 
   - Message de succès
   - Score affiché en vert
   - Bouton change en "Modifier le score"

### Test 3 : Modifier un score

1. Trouver un match avec un score
2. Cliquer sur **"Modifier le score"**
3. Modifier les informations
4. **Enregistrer**
5. **Vérifier** : Changements appliqués

---

## ⚠️ Prérequis SQL

Pour que tout fonctionne, exécutez ces deux scripts SQL :

### 1. Ajouter 'confirmed' à l'ENUM
```sql
ALTER TABLE amicalclub_matches 
MODIFY COLUMN result ENUM('win', 'draw', 'loss', 'pending', 'confirmed') DEFAULT 'pending';
```
Fichier : `backend/add_confirmed_status.sql`

---

## 📊 États des matchs

| État | Valeur `result` | Où affiché | Actions disponibles |
|------|-----------------|------------|---------------------|
| Créé | `pending` | Accueil | Recevoir demandes |
| Confirmé (futur) | `confirmed` | Matchs en cours | Attendre le match |
| Confirmé (passé) | `confirmed` | Matchs en cours | Ajouter score |
| Terminé (victoire) | `win` | Matchs récents | Modifier score |
| Terminé (nul) | `draw` | Matchs récents | Modifier score |
| Terminé (défaite) | `loss` | Matchs récents | Modifier score |

---

## ✅ Résultat final

Maintenant dans le profil :
- ✅ **Section "Matchs en cours"** apparaît automatiquement
- ✅ **Badge vert** avec le nombre de matchs
- ✅ **Cartes détaillées** pour chaque match confirmé
- ✅ **Bouton "Ajouter le score"** pour les matchs passés
- ✅ **Bouton "Modifier le score"** si score déjà saisi
- ✅ **Dialogue intuitif** avec choix Victoire/Nul/Défaite
- ✅ **Couleurs significatives** (vert/orange/rouge)
- ✅ **Notes optionnelles** pour chaque match

**Gestion complète des matchs confirmés avec suivi du score !** 🎉

