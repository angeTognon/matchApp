# ⚡ GUIDE RAPIDE : Validation et détails du match

## 🎯 Comment ça marche ?

### Système en 2 étapes :

**1️⃣ Les 2 équipes confirment** que le match est terminé
**2️⃣ Le créateur ajoute** tous les détails (score, buteurs, etc.)

---

## 📝 Étape par étape

### Pour CHAQUE équipe (hôte + adversaire) :

1. **Jouer le match** (dans la vraie vie) ⚽
2. **Aller dans Profil → Matchs en cours**
3. **Trouver le match joué**
4. **Cliquer sur** "Confirmer que le match est terminé" 🟢
5. **Confirmer dans le dialogue**

### Quand 1 équipe a confirmé :
- Badge bleu : "En attente de l'équipe adverse"
- L'autre équipe voit : "L'équipe X a confirmé. À vous de confirmer"

### Quand les 2 équipes ont confirmé :
- Badge vert : "Les 2 équipes ont confirmé"
- **Seul le créateur du match** voit le bouton : "Ajouter les détails du match"

---

## 📝 Pour le créateur : Ajouter les détails

Une fois que **les 2 équipes ont confirmé** :

1. **Cliquer sur** "Ajouter les détails du match"
2. **Remplir le dialogue** :

   ### Obligatoire :
   - ✅ **Score** : 3-1, 2-2, etc.
   - ✅ **Résultat** : Victoire / Match nul / Défaite

   ### Optionnel :
   - **Buteurs - Votre équipe** :
     - Cliquer "+ Ajouter un buteur"
     - Nom : Jean Dupont
     - Buts : 2
     - Répéter pour chaque buteur
   
   - **Buteurs - Équipe adverse** :
     - Même chose pour l'autre équipe
   
   - **Homme du match** : Jean Dupont
   - **Résumé** : Description du match
   - **Notes** : Autres infos

3. **Cliquer "Enregistrer"** ✅

---

## 🎯 Résultat

### Le match affiche maintenant :
- Score avec couleur (🟢 victoire, 🟠 nul, 🔴 défaite)
- Tous les détails enregistrés
- Bouton "Modifier les détails" si besoin de corriger

---

## ⚠️ SQL À EXÉCUTER AVANT

**Dans phpMyAdmin**, exécutez les 2 scripts :

### Script 1 : Ajouter 'confirmed'
```sql
ALTER TABLE amicalclub_matches 
MODIFY COLUMN result ENUM('win', 'draw', 'loss', 'pending', 'confirmed') DEFAULT 'pending';
```

### Script 2 : Ajouter les colonnes
```sql
ALTER TABLE amicalclub_matches 
ADD COLUMN IF NOT EXISTS home_confirmed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS away_confirmed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS both_confirmed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS home_scorers TEXT NULL,
ADD COLUMN IF NOT EXISTS away_scorers TEXT NULL,
ADD COLUMN IF NOT EXISTS man_of_match VARCHAR(255) NULL,
ADD COLUMN IF NOT EXISTS match_summary TEXT NULL;
```

Ou utilisez le fichier : `backend/add_match_completion_columns.sql`

---

## 🧪 Test rapide

1. **Exécuter les 2 SQL**
2. **Avoir un match confirmé** (voir screenshot)
3. **Les 2 comptes cliquent** "Confirmer que le match est terminé"
4. **Le créateur voit** le bouton "Ajouter les détails"
5. **Remplir et enregistrer**
6. **Score affiché** avec couleur !

---

## ✅ C'est prêt !

- ✅ Validation par les 2 équipes
- ✅ Saisie complète des détails
- ✅ Buteurs avec nombre de buts
- ✅ Homme du match
- ✅ Résumé et notes
- ✅ Couleurs selon résultat

**Système professionnel et complet !** 🚀

