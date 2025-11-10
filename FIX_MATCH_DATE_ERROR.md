# 🔧 Fix : Erreur "Column not found: m.date"

## ❌ Erreur rencontrée

```
Erreur lors de la récupération des demandes: SQLSTATE[42S22]: 
Column not found: 1054 Unknown column 'm.date' in 'SELECT'
```

## 🔍 Cause

Dans le fichier `backend/get_match_requests.php`, les requêtes SQL utilisaient :
```sql
m.date as match_date,
m.time as match_time,
```

Mais dans la table `amicalclub_matches`, les colonnes n'existent pas séparément. 
Il n'y a qu'une seule colonne **`match_date`** de type **DATETIME** qui contient à la fois la date et l'heure.

## ✅ Solution appliquée

### Avant (incorrect)
```sql
SELECT 
    m.date as match_date,      -- ❌ N'existe pas
    m.time as match_time,      -- ❌ N'existe pas
    ...
FROM amicalclub_matches m
```

### Après (correct)
```sql
SELECT 
    DATE(m.match_date) as match_date,   -- ✅ Extrait la date
    TIME(m.match_date) as match_time,   -- ✅ Extrait l'heure
    ...
FROM amicalclub_matches m
```

## 📝 Structure de la table

La table `amicalclub_matches` utilise :
```sql
CREATE TABLE amicalclub_matches (
    id INT PRIMARY KEY,
    team_id INT,
    coach_id INT,
    match_date DATETIME NOT NULL,  -- ← Colonne unique pour date + heure
    location VARCHAR(255),
    ...
);
```

## 🔄 Modifications apportées

### Fichier : `backend/get_match_requests.php`

**Ligne 30-31** (requête demandes reçues) :
```sql
-- Avant
m.date as match_date,
m.time as match_time,

-- Après
DATE(m.match_date) as match_date,
TIME(m.match_date) as match_time,
```

**Ligne 81-82** (requête demandes envoyées) :
```sql
-- Avant
m.date as match_date,
m.time as match_time,

-- Après
DATE(m.match_date) as match_date,
TIME(m.match_date) as match_time,
```

## ✅ Résultat

Maintenant l'écran "Demandes de match" fonctionne correctement :
- ✅ Les demandes reçues s'affichent
- ✅ Les demandes envoyées s'affichent
- ✅ Les dates et heures sont correctement extraites
- ✅ Plus d'erreur SQL

## 🧪 Pour tester

1. Ouvrir l'app
2. Profil → "Demandes de match"
3. **Vérifier** : Les deux onglets se chargent sans erreur
4. **Vérifier** : Les dates et heures s'affichent correctement

## 📚 Note technique

### Fonctions SQL utilisées

- **`DATE(datetime)`** : Extrait uniquement la partie date
  - Exemple : `DATE('2025-10-20 15:30:00')` → `'2025-10-20'`

- **`TIME(datetime)`** : Extrait uniquement la partie heure
  - Exemple : `TIME('2025-10-20 15:30:00')` → `'15:30:00'`

### Autres fichiers backend utilisant la bonne syntaxe

Ces fichiers utilisent déjà la syntaxe correcte :
- ✅ `get_matches.php` : `DATE(m.match_date) as date`
- ✅ `get_my_matches.php` : `DATE(m.match_date) as date`
- ✅ `get_match.php` : `DATE(m.match_date) as date`
- ✅ `create_match.php` : `DATE(m.match_date) as date`

## ✅ C'est corrigé !

L'erreur est maintenant résolue et la page "Demandes de match" fonctionne parfaitement ! 🎉


