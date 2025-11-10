# ✅ Badges de statut sur l'écran d'accueil

## 🎯 Fonctionnalité ajoutée

Les cartes de match sur l'accueil affichent maintenant **visuellement** le statut du match pour que tout le monde puisse voir en un coup d'œil :
- ✅ Si le match a des demandes en attente
- ✅ Combien de demandes il a reçues
- ✅ Si le match est déjà confirmé/pris

---

## 🎨 Interface améliorée

### Match sans demande (disponible)
```
┌─────────────────────────────────────────────┐
│ 🏆 FC Lions              [Disponible]      │
│ U17 • Régional                              │
│                                             │
│ 📅 20 Oct 2025    🕐 15:00                 │
│ 📍 Stade Municipal • 5 km                  │
│                                             │
│ [Voir détails]    [Contacter]             │
└─────────────────────────────────────────────┘
```

### Match avec 3 demandes en attente ⚡ NOUVEAU
```
┌─────────────────────────────────────────────┐
│ ⏳ 3 demandes en attente              🟠   │ ← BANDEAU ORANGE
├─────────────────────────────────────────────┤
│ 🏆 FC Lions              [Disponible]  📧3 │ ← BADGE ORANGE
│ U17 • Régional                              │
│                                             │
│ 📅 20 Oct 2025    🕐 15:00                 │
│ 📍 Stade Municipal • 5 km                  │
│                                             │
│ [Voir détails]    [Contacter]             │
└─────────────────────────────────────────────┘
```

### Match confirmé ✅ NOUVEAU
```
┌─────────────────────────────────────────────┐
│ ✓ Match confirmé avec FC Tigers       🟢   │ ← BANDEAU VERT
├─────────────────────────────────────────────┤
│ 🏆 FC Lions              [Confirmé]        │
│ U17 • Régional                              │
│                                             │
│ 📅 20 Oct 2025    🕐 15:00                 │
│ 📍 Stade Municipal • 5 km                  │
│                                             │
│ [Voir détails]    [Contacter]             │
└─────────────────────────────────────────────┘
```

---

## 🎨 Éléments visuels ajoutés

### 1. Bandeau d'information en haut
- 🟠 **Orange** : Match avec demandes en attente
  - Texte : "3 demandes en attente"
  - Icône : ⏳ Pending
  
- 🟢 **Vert** : Match confirmé
  - Texte : "✓ Match confirmé avec [Nom équipe]"
  - Icône : ✓ Check circle

### 2. Badge compteur de demandes
- Position : En haut à droite de la carte
- Couleur : Orange 🟠
- Icône : 📧 Mail
- Texte : Nombre de demandes
- Visible uniquement si `requestsCount > 0`

### 3. Badge de statut (déjà existant, amélioré)
- Position : En haut à droite sous le compteur
- Couleur : Selon le statut
- Texte : Statut du match

---

## 📝 Fichiers modifiés

### 1. **`backend/get_matches.php`**

#### Modifications SQL (ligne 70-75)
```php
// Avant
COUNT(mr.id) as requests_count,

// Après
COUNT(DISTINCT CASE WHEN mr.status = 'pending' THEN mr.id END) as requests_count,
COUNT(DISTINCT CASE WHEN mr.status = 'accepted' THEN mr.id END) as accepted_count,
m.opponent  // ← Ajouté pour afficher l'équipe confirmée
```

#### Modification du JOIN (ligne 79)
```php
// Avant
LEFT JOIN amicalclub_match_requests mr ON m.id = mr.match_id AND mr.status = 'pending'

// Après
LEFT JOIN amicalclub_match_requests mr ON m.id = mr.match_id
```

**Pourquoi ?** Pour compter toutes les demandes (pending et accepted), pas seulement les pending.

### 2. **`lib/widgets/match_card.dart`**

#### Ajout du bandeau d'information (ligne 62-97)
```dart
// Bandeau en haut de la carte
if (hasPendingRequests || isConfirmed)
  Container(
    // Fond orange si demandes, vert si confirmé
    color: isConfirmed ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
    child: Row(
      children: [
        Icon(...),
        Text(...), // Message clair
      ],
    ),
  )
```

#### Ajout du badge compteur (ligne 135-160)
```dart
// Badge orange avec icône mail et nombre
if (match.requestsCount > 0)
  Container(
    decoration: BoxDecoration(color: Colors.orange, ...),
    child: Row(
      children: [
        Icon(Icons.mail, size: 12),
        Text('${match.requestsCount}'),
      ],
    ),
  )
```

---

## 🔄 Comportements

### Scénario 1 : Match créé (aucune demande)
```
Vue utilisateur :
- Carte normale
- Statut : "Disponible" (badge vert)
- Pas de bandeau
- Pas de badge orange
```

### Scénario 2 : 1 demande reçue
```
Vue utilisateur :
- Bandeau orange : "⏳ 1 demande en attente"
- Badge orange : "📧 1"
- Statut : "Disponible"
```

### Scénario 3 : 5 demandes reçues
```
Vue utilisateur :
- Bandeau orange : "⏳ 5 demandes en attente"
- Badge orange : "📧 5"
- Statut : "Disponible"
```

### Scénario 4 : Demande acceptée
```
Vue utilisateur :
- Bandeau vert : "✓ Match confirmé avec FC Tigers"
- Pas de badge orange
- Statut : "Confirmé" (badge bleu)
```

---

## 🎯 Avantages

### Pour les utilisateurs cherchant un match :
- ✅ Voient immédiatement si un match est populaire (beaucoup de demandes)
- ✅ Savent si un match est déjà pris
- ✅ Peuvent prioriser les matchs sans demandes
- ✅ Comprennent rapidement la disponibilité

### Pour les créateurs de match :
- ✅ Voient en un coup d'œil combien de demandes ils ont
- ✅ Savent quels matchs sont confirmés
- ✅ Badge orange attire l'attention sur les matchs avec demandes

---

## 🧪 Test visuel

### Test 1 : Match sans demande
1. Créer un match
2. Voir sur l'accueil
3. **Vérifier** : Carte normale, pas de bandeau, pas de badge orange

### Test 2 : Match avec demandes
1. Un autre coach fait une demande
2. Rafraîchir l'accueil (pull-to-refresh)
3. **Vérifier** : 
   - Bandeau orange "1 demande en attente"
   - Badge orange "📧 1"

### Test 3 : Multiple demandes
1. Plusieurs coachs font des demandes
2. Rafraîchir l'accueil
3. **Vérifier** : Badge montre le nombre correct

### Test 4 : Match confirmé
1. Accepter une demande
2. Rafraîchir l'accueil
3. **Vérifier** :
   - Bandeau vert "✓ Match confirmé avec [équipe]"
   - Pas de badge orange
   - Statut "Confirmé"

---

## ⚠️ IMPORTANT : SQL à exécuter

Pour que les matchs confirmés s'affichent correctement, exécutez d'abord :

```sql
ALTER TABLE amicalclub_matches 
MODIFY COLUMN result ENUM('win', 'draw', 'loss', 'pending', 'confirmed') DEFAULT 'pending';
```

Voir : `backend/add_confirmed_status.sql`

---

## 📊 Récapitulatif des badges

| État du match | Bandeau | Badge compteur | Badge statut |
|---------------|---------|----------------|--------------|
| Aucune demande | ❌ Aucun | ❌ Aucun | 🟢 Disponible |
| 1+ demandes | 🟠 Orange | 🟠 📧 X | 🟢 Disponible |
| Confirmé | 🟢 Vert | ❌ Aucun | 🔵 Confirmé |
| Terminé | ❌ Aucun | ❌ Aucun | ⚪ Terminé |

---

## ✅ Résultat final

L'écran d'accueil est maintenant **très informatif** :
- ✅ Badge orange pour les matchs avec demandes
- ✅ Bandeau orange indiquant le nombre de demandes
- ✅ Bandeau vert pour les matchs confirmés
- ✅ Tout le monde voit clairement l'état des matchs
- ✅ Interface professionnelle et claire

**Les utilisateurs peuvent maintenant prendre des décisions éclairées en voyant immédiatement quel match a beaucoup de concurrence !** 🎉

