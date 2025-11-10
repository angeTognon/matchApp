# 🎨 Guide visuel : Badges de statut sur l'accueil

## ✅ Ce qui a été ajouté

Sur chaque carte de match de l'accueil, vous verrez maintenant :

### 1. **Bandeau d'information** (en haut de la carte)

#### 🟠 Orange = Demandes en attente
```
┌─────────────────────────────────────────┐
│ ⏳ 3 demandes en attente          🟠   │
├─────────────────────────────────────────┤
│ Carte du match...                       │
└─────────────────────────────────────────┘
```
**Signification** : Ce match a reçu 3 demandes qui attendent une réponse

#### 🟢 Vert = Match confirmé
```
┌─────────────────────────────────────────┐
│ ✓ Match confirmé avec FC Tigers   🟢   │
├─────────────────────────────────────────┤
│ Carte du match...                       │
└─────────────────────────────────────────┘
```
**Signification** : Ce match a déjà trouvé son adversaire

### 2. **Badge compteur** (en haut à droite)

```
┌─────────────────────────────────────────┐
│ FC Lions                    [Status] 📧3│ ← Badge orange
│ U17 • Régional                          │
└─────────────────────────────────────────┘
```
**Signification** : 3 demandes en attente pour ce match

---

## 🎯 Exemples visuels

### Exemple 1 : Match populaire
```
┌─────────────────────────────────────────────┐
│ ⏳ 5 demandes en attente              🟠   │
├─────────────────────────────────────────────┤
│ 🏆 FC Lions      [Disponible]  📧5         │
│ U17 • Régional                              │
│ 📅 20 Oct 2025  🕐 15:00                   │
│ 📍 Stade Municipal • 5 km                  │
│ [Voir détails] [Contacter]                 │
└─────────────────────────────────────────────┘
```
**Message** : "Ce match est très demandé ! 5 équipes intéressées"

### Exemple 2 : Match avec 1 demande
```
┌─────────────────────────────────────────────┐
│ ⏳ 1 demande en attente               🟠   │
├─────────────────────────────────────────────┤
│ 🏆 AS Monaco     [Disponible]  📧1         │
│ U19 • National                              │
│ 📅 25 Oct 2025  🕐 14:30                   │
│ 📍 Complexe Sportif • 12 km                │
│ [Voir détails] [Contacter]                 │
└─────────────────────────────────────────────┘
```
**Message** : "Une équipe est déjà intéressée"

### Exemple 3 : Match confirmé
```
┌─────────────────────────────────────────────┐
│ ✓ Match confirmé avec FC Tigers       🟢   │
├─────────────────────────────────────────────┤
│ 🏆 Olympique     [Confirmé]                │
│ U17 • Départemental                         │
│ 📅 22 Oct 2025  🕐 16:00                   │
│ 📍 Stade Central • 8 km                    │
│ [Voir détails] [Contacter]                 │
└─────────────────────────────────────────────┘
```
**Message** : "Ce match est déjà pris par FC Tigers"

### Exemple 4 : Match sans demande
```
┌─────────────────────────────────────────────┐
│ 🏆 Real Madrid   [Disponible]              │
│ Séniors • Loisir                            │
│ 📅 18 Oct 2025  🕐 10:00                   │
│ 📍 Terrain Municipal • 3 km                │
│ [Voir détails] [Contacter]                 │
└─────────────────────────────────────────────┘
```
**Message** : "Match libre, aucune demande pour l'instant"

---

## 🎨 Code des couleurs

| Couleur | Signification | Quand affiché |
|---------|---------------|---------------|
| 🟠 Orange | Demandes en attente | Si `requestsCount > 0` |
| 🟢 Vert | Match confirmé | Si `status == 'confirmed'` |
| 🔵 Bleu | Statut disponible | Match sans demande |
| ⚪ Gris | Match terminé | Après le match |

---

## 📊 Informations affichées

### Backend récupère :
- ✅ `requests_count` : Nombre de demandes **en attente** (status = 'pending')
- ✅ `accepted_count` : Nombre de demandes **acceptées** (normalement 0 ou 1)
- ✅ `opponent` : Nom de l'équipe adverse confirmée
- ✅ `status` / `result` : État du match (pending, confirmed, etc.)

### Frontend affiche :
- ✅ **Bandeau** : Si demandes ou confirmé
- ✅ **Badge compteur** : Nombre de demandes (📧 3)
- ✅ **Badge statut** : État actuel du match
- ✅ **Nom adversaire** : Si match confirmé

---

## 🧪 Comment tester

### Test 1 : Créer un match
1. Créer un match
2. Aller sur l'accueil
3. **Vérifier** : Carte normale, pas de badge orange

### Test 2 : Recevoir une demande
1. Avec un autre compte, faire "Je suis intéressé"
2. Retourner au premier compte
3. Rafraîchir l'accueil (pull-to-refresh)
4. **Vérifier** :
   - Bandeau orange "1 demande en attente"
   - Badge orange "📧 1"

### Test 3 : Recevoir plusieurs demandes
1. Avec 2-3 autres comptes, faire des demandes
2. Rafraîchir l'accueil
3. **Vérifier** : Badge montre "📧 3" ou "📧 5"

### Test 4 : Accepter une demande
1. Aller dans "Demandes de match"
2. Accepter une demande
3. Retourner sur l'accueil
4. Rafraîchir (pull-to-refresh)
5. **Vérifier** :
   - Bandeau vert "✓ Match confirmé avec [équipe]"
   - Plus de badge orange

---

## ⚠️ Prérequis SQL

Pour que les matchs confirmés s'affichent, exécutez :

```sql
ALTER TABLE amicalclub_matches 
MODIFY COLUMN result ENUM('win', 'draw', 'loss', 'pending', 'confirmed') DEFAULT 'pending';
```

Fichier : `backend/add_confirmed_status.sql`

---

## 💡 Avantages pour l'utilisateur

### Transparence totale
- ✅ On voit immédiatement quels matchs sont populaires
- ✅ On sait si un match est déjà pris
- ✅ On peut prioriser ses demandes
- ✅ Pas de surprise en faisant une demande

### Meilleure expérience
- ✅ Interface claire et informative
- ✅ Badges visuels intuitifs
- ✅ Couleurs significatives
- ✅ Informations en un coup d'œil

### Gestion optimisée
- ✅ Les créateurs voient le nombre de demandes
- ✅ Les demandeurs voient la concurrence
- ✅ Tout le monde prend de meilleures décisions

---

## ✅ Résultat final

L'écran d'accueil est maintenant **ultra-informatif** ! Chaque carte de match affiche clairement :
- 🟠 Combien de demandes le match a reçues
- 🟢 Si le match est déjà confirmé
- 📧 Badge visuel pour attirer l'attention
- ✓ Nom de l'équipe adverse si confirmé

**Les utilisateurs ont maintenant toutes les informations pour faire le meilleur choix !** 🎉

