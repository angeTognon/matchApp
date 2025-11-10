# 🎯 Guide rapide : Matchs en cours

## ✅ Nouvelle fonctionnalité ajoutée !

Une section **"Matchs en cours"** apparaît maintenant dans votre profil pour gérer vos matchs confirmés.

---

## 📍 Où la trouver ?

1. **Ouvrir l'app**
2. **Onglet "Profil"** (en bas)
3. **Scroller vers le bas**
4. **Section "Matchs en cours (X)"** ← Apparaît automatiquement

---

## 🎯 Qu'est-ce qu'elle affiche ?

### Vos matchs confirmés :
- ✅ Matchs que vous avez créés et dont vous avez accepté une demande
- ✅ Matchs pour lesquels votre demande a été acceptée
- ✅ Badge vert avec le nombre total

### Pour chaque match :
- 🏆 **Votre équipe vs Équipe adverse**
- 📅 **Date et heure** du match
- 📍 **Lieu** du match
- 🎯 **Score** (si déjà saisi)
- 📝 **Bouton d'action** selon l'état

---

## ⚽ Ajouter un score

### Pour un match passé :

1. **Trouver le match** dans "Matchs en cours"
2. **Cliquer sur "Ajouter le score"**
3. **Remplir le dialogue** :
   - Score : `3-1`, `2-2`, etc.
   - Résultat : Victoire / Match nul / Défaite
   - Notes : Commentaires (optionnel)
4. **Cliquer "Enregistrer"**

### Résultat :
- ✅ Score affiché sur la carte
- ✅ Couleur selon résultat :
  - 🟢 Vert = Victoire
  - 🟠 Orange = Match nul  
  - 🔴 Rouge = Défaite
- ✅ Match peut passer dans "Matchs récents"

---

## 📊 Cycle de vie d'un match

```
1. Création
   └─> Accueil (badge "Disponible")
   
2. Demande reçue
   └─> Accueil (badge orange "X demandes")
   
3. Demande acceptée
   └─> Profil → Matchs en cours
       (badge vert "Match confirmé")
   
4. Match joué + Score ajouté
   └─> Profil → Matchs récents
       (score affiché avec couleur)
```

---

## 🎨 Exemples visuels

### Match en cours (futur)
```
┌──────────────────────────────────┐
│ ✓ Match confirmé            🟢  │
├──────────────────────────────────┤
│ FC Lions vs FC Tigers            │
│ U17 • Régional                   │
│ 📅 25 Oct  🕐 15:00             │
│ 📍 Stade Municipal               │
│                                  │
│ (Pas de bouton - match futur)   │
└──────────────────────────────────┘
```

### Match passé (sans score)
```
┌──────────────────────────────────┐
│ ✓ Match confirmé            🟢  │
├──────────────────────────────────┤
│ FC Lions vs FC Tigers            │
│ U17 • Régional                   │
│ 📅 15 Oct  🕐 15:00             │
│ 📍 Stade Municipal               │
│                                  │
│ [Ajouter le score]              │
└──────────────────────────────────┘
```

### Match avec score (victoire)
```
┌──────────────────────────────────┐
│ ✓ Match confirmé            🟢  │
├──────────────────────────────────┤
│ FC Lions vs FC Tigers   3-1 🟢  │
│ U17 • Régional                   │
│ 📅 15 Oct  🕐 15:00             │
│ 📍 Stade Municipal               │
│                                  │
│ [Modifier le score]             │
└──────────────────────────────────┘
```

---

## ⚠️ Important : Exécuter le SQL

**Avant de tester**, exécutez dans phpMyAdmin :

```sql
ALTER TABLE amicalclub_matches 
MODIFY COLUMN result ENUM('win', 'draw', 'loss', 'pending', 'confirmed') DEFAULT 'pending';
```

Fichier : `backend/add_confirmed_status.sql`

---

## ✅ Résumé

Maintenant vous avez :
- ✅ **Accueil** : Matchs disponibles (pending)
- ✅ **Profil → Matchs en cours** : Matchs confirmés ← NOUVEAU
- ✅ **Profil → Matchs récents** : Matchs terminés avec scores
- ✅ **Demandes de match** : Gestion des demandes

**Cycle complet de gestion des matchs !** 🎊

