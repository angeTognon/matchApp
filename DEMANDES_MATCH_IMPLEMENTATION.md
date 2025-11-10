# ✅ Système complet de gestion des demandes de match

## 🎯 Fonctionnalités implémentées

### 1. **Visualisation des demandes** 📋
Un système complet avec deux onglets :

#### Onglet "Reçues" 
- Affiche les demandes faites par d'autres équipes pour VOS matchs
- Badge avec le nombre de demandes en attente
- Boutons "Accepter" / "Refuser" pour chaque demande
- Mise à jour en temps réel

#### Onglet "Envoyées"
- Affiche les demandes que VOUS avez faites pour des matchs d'autres
- Statut de chaque demande (En attente, Acceptée, Refusée)
- Historique complet

### 2. **Gestion des demandes** ⚙️
- **Accepter une demande** : Le match est confirmé, autres demandes refusées automatiquement
- **Refuser une demande** : La demande est archivée
- **Pull-to-refresh** : Actualiser la liste en glissant vers le bas
- **Dialogues de confirmation** : Pour éviter les clics accidentels

### 3. **Accès rapide** 🚀
- Nouveau bouton "Demandes de match" dans le profil
- Design orange pour le différencier des autres options
- Icône mail pour indiquer les messages/demandes

---

## 📁 Fichiers créés

### Backend PHP (2 fichiers)

#### 1. **`backend/get_match_requests.php`**
Récupère les demandes de match selon le type.

**Paramètres :**
- `type` : 'received' ou 'sent'
- `token` : JWT pour l'authentification

**Retourne :**
- Liste complète des demandes avec infos match et équipes
- Dates formatées
- Statuts des demandes

**Exemples de données retournées :**

```json
{
  "success": true,
  "data": {
    "requests": [
      {
        "request_id": "1",
        "match_id": "5",
        "request_status": "pending",
        "request_message": "Bonjour, notre équipe est intéressée...",
        "match_date": "2025-10-20",
        "match_time": "15:00:00",
        "location": "Stade Municipal",
        "category": "U17",
        "level": "Régional",
        "requesting_team_name": "FC Lions",
        "requesting_club_name": "Club Sportif Lions",
        "requesting_coach_name": "Jean Dupont"
      }
    ],
    "type": "received",
    "total": 3
  }
}
```

#### 2. **`backend/respond_match_request.php`**
Permet de répondre à une demande (accepter ou refuser).

**Paramètres :**
- `request_id` : ID de la demande
- `action` : 'accept' ou 'reject'
- `token` : JWT pour l'authentification

**Actions :**
- **Accept** : Confirme le match, refuse les autres demandes
- **Reject** : Archive la demande

**Sécurité :**
- Vérifie que l'utilisateur est propriétaire du match
- Vérifie que la demande est en attente
- Transaction SQL pour garantir la cohérence

### Frontend Flutter (3 fichiers)

#### 3. **`lib/models/match_request.dart`**
Modèle de données pour une demande de match.

**Propriétés :**
- Infos sur la demande (ID, statut, message, dates)
- Infos sur le match (date, heure, lieu, catégorie, niveau)
- Infos sur l'équipe (nom, club, logo)
- Infos sur le coach (nom, email, avatar)

**Méthodes utiles :**
- `statusDisplay` : Texte formaté du statut
- `formattedDate` : Date formatée (ex: "15 Oct 2025")
- `formattedTime` : Heure formatée (ex: "15:00")

#### 4. **`lib/screens/match/match_requests_screen.dart`**
Écran principal de gestion des demandes.

**Fonctionnalités :**
- Onglets "Reçues" / "Envoyées"
- Liste avec cartes détaillées
- Boutons d'action pour les demandes reçues
- Pull-to-refresh
- Gestion des états (loading, empty, error)
- Dialogues de confirmation

**Design :**
- Badge sur l'onglet "Reçues" avec le nombre de demandes en attente
- Couleurs de statut (Orange = En attente, Vert = Acceptée, Rouge = Refusée)
- Avatar des équipes
- Informations complètes sur chaque match

#### 5. **Modifications de `lib/services/api_service.dart`**
Ajout de 2 nouvelles méthodes :

```dart
// Récupérer les demandes
static Future<Map<String, dynamic>> getMatchRequests({
  required String token,
  String type = 'received',
})

// Répondre à une demande
static Future<Map<String, dynamic>> respondToMatchRequest({
  required String token,
  required String requestId,
  required String action,
})
```

#### 6. **Modifications de `lib/screens/profile/profile_screen.dart`**
Ajout d'un nouveau bouton dans la section profil :

```dart
// Nouveau bouton orange "Demandes de match"
Container(
  decoration: BoxDecoration(
    color: Colors.orange.withOpacity(0.1),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.orange, width: 1),
  ),
  child: TextButton.icon(
    onPressed: () => context.push('/match-requests'),
    icon: Icon(Icons.mail_outline, size: 16, color: Colors.orange),
    label: Text('Demandes de match'),
  ),
)
```

#### 7. **Modifications de `lib/config/app_router.dart`**
Ajout de la nouvelle route :

```dart
GoRoute(
  path: '/match-requests',
  builder: (context, state) => const all_requests.MatchRequestsScreen(),
),
```

---

## 🎨 Interface utilisateur

### Écran principal
```
┌─────────────────────────────────────────────────┐
│  ← Demandes de match                            │
│  ┌──────────┬──────────┐                        │
│  │ Reçues 3 │ Envoyées │                        │
│  └──────────┴──────────┘                        │
│                                                  │
│  ┌─────────────────────────────────────────┐   │
│  │ 🏆 FC Lions              [En attente]   │   │
│  │ Club Sportif Lions                       │   │
│  │ ─────────────────────────────────────   │   │
│  │ 📅 20 Oct 2025    🕐 15:00              │   │
│  │ 📍 Stade Municipal                       │   │
│  │ U17 • Régional                           │   │
│  │                                           │   │
│  │ Message: "Bonjour, notre équipe..."      │   │
│  │                                           │   │
│  │ [Refuser]     [✓ Accepter]              │   │
│  └─────────────────────────────────────────┘   │
│                                                  │
│  [Autres demandes...]                           │
└─────────────────────────────────────────────────┘
```

### Bouton dans le profil
```
┌─────────────────────────────────────────────────┐
│  👤 Jean Dupont                                  │
│  📧 jean@example.com                            │
│                                                  │
│  [Modifier le profil]  [Mes matchs]            │
│                                                  │
│  [📧 Demandes de match]  ← NOUVEAU             │
└─────────────────────────────────────────────────┘
```

---

## 🔄 Flux de fonctionnement

### Scénario 1 : Recevoir une demande

1. **Utilisateur crée un match**
2. **Autre coach fait une demande** via "Je suis intéressé"
3. **Notification badge** apparaît sur l'onglet "Reçues"
4. **Coach ouvre "Demandes de match"**
5. **Voit la carte avec toutes les infos**
6. **Clique sur "Accepter"**
7. **Dialogue de confirmation**
8. **Match confirmé** + autres demandes refusées automatiquement

### Scénario 2 : Envoyer une demande

1. **Coach trouve un match intéressant**
2. **Clique sur "Je suis intéressé"**
3. **Demande envoyée** avec message optionnel
4. **Va dans "Demandes de match" > Onglet "Envoyées"**
5. **Voit sa demande** avec statut "En attente"
6. **Attend la réponse** du créateur du match
7. **Statut mis à jour** quand l'autre coach répond

---

## 🧪 Comment tester

### Test 1 : Créer et recevoir une demande

1. **Compte A** : Créer un match
2. **Compte B** : Trouver ce match et cliquer "Je suis intéressé"
3. **Compte A** : 
   - Aller dans Profil
   - Cliquer sur "Demandes de match"
   - Vérifier qu'on voit la demande dans "Reçues"
   - Badge "3" si 3 demandes en attente
4. **Cliquer sur "Accepter"**
5. **Vérifier** : Match confirmé, badge disparu

### Test 2 : Voir ses demandes envoyées

1. **Créer une demande** pour un match
2. **Aller dans "Demandes de match"**
3. **Onglet "Envoyées"**
4. **Vérifier** qu'on voit la demande avec statut "En attente"
5. **Attendre réponse** de l'autre coach
6. **Pull-to-refresh** pour actualiser
7. **Vérifier** le changement de statut

### Test 3 : Refuser une demande

1. **Recevoir une demande**
2. **Cliquer sur "Refuser"**
3. **Confirmer** dans le dialogue
4. **Vérifier** : Statut change à "Refusée"

---

## 📊 Base de données

### Tables utilisées

#### `amicalclub_matches`
- `id` : ID du match
- `team_id` : Équipe qui crée le match
- `coach_id` : **IMPORTANT** - Coach qui crée le match
- `status` : Statut du match (available, confirmed, etc.)
- `confirmed_team_id` : Équipe confirmée pour le match

#### `amicalclub_match_requests`
- `id` : ID de la demande
- `match_id` : Match concerné
- `requesting_team_id` : Équipe qui fait la demande
- `message` : Message optionnel
- `status` : pending, accepted, rejected
- `created_at` : Date de création
- `responded_at` : Date de réponse

### Requêtes SQL importantes

#### Récupérer les demandes reçues
```sql
SELECT mr.*, m.*, 
       requesting_team.name as requesting_team_name,
       my_team.name as my_team_name
FROM amicalclub_match_requests mr
JOIN amicalclub_matches m ON mr.match_id = m.id
JOIN amicalclub_teams my_team ON m.team_id = my_team.id
JOIN amicalclub_teams requesting_team ON mr.requesting_team_id = requesting_team.id
WHERE m.coach_id = ? -- Coach connecté
ORDER BY mr.created_at DESC
```

#### Accepter une demande
```sql
-- 1. Accepter la demande
UPDATE amicalclub_match_requests 
SET status = 'accepted', responded_at = NOW() 
WHERE id = ?

-- 2. Confirmer le match
UPDATE amicalclub_matches 
SET status = 'confirmed', confirmed_team_id = ? 
WHERE id = ?

-- 3. Refuser les autres demandes
UPDATE amicalclub_match_requests 
SET status = 'rejected', responded_at = NOW() 
WHERE match_id = ? AND id != ? AND status = 'pending'
```

---

## ✅ Fonctionnalités complètes

- ✅ Backend PHP complet (2 endpoints)
- ✅ Frontend Flutter complet
- ✅ Modèle de données
- ✅ Interface avec onglets
- ✅ Bouton dans le profil
- ✅ Pull-to-refresh
- ✅ Gestion des états (loading, empty, error)
- ✅ Dialogues de confirmation
- ✅ Badges de notification
- ✅ Couleurs de statut
- ✅ Formatage des dates
- ✅ Affichage des avatars
- ✅ Messages personnalisés
- ✅ Sécurité (vérification des permissions)
- ✅ Transactions SQL
- ✅ Gestion des erreurs
- ✅ Documentation complète

---

## 🎉 Résultat final

Le système de demandes de match est maintenant **100% fonctionnel** !

**Les utilisateurs peuvent :**
- ✅ Voir toutes les demandes reçues pour leurs matchs
- ✅ Voir toutes les demandes qu'ils ont envoyées
- ✅ Accepter/Refuser les demandes en un clic
- ✅ Voir le statut en temps réel
- ✅ Accéder rapidement via le menu profil
- ✅ Avoir toutes les informations nécessaires pour décider

**Le système gère automatiquement :**
- ✅ Confirmation du match à l'acceptation
- ✅ Refus des autres demandes concurrentes
- ✅ Mise à jour des statuts
- ✅ Sécurité et permissions
- ✅ Cohérence des données

---

## 📝 Notes importantes

### Prérequis
- La colonne `coach_id` doit exister dans `amicalclub_matches`
- Exécuter `backend/add_coach_id_to_matches.sql` si nécessaire

### Améliorations futures possibles
1. **Notifications push** quand une demande est reçue/acceptée
2. **Chat intégré** pour discuter avant d'accepter
3. **Historique complet** de toutes les demandes archivées
4. **Filtres** par statut, date, catégorie
5. **Statistiques** (taux d'acceptation, etc.)


