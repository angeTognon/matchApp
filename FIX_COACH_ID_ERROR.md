# 🔧 Fix : Erreur "Column not found: m.coach_id"

## 🐛 Problème rencontré

Lorsque vous cliquez sur le bouton "Je suis intéressé" sur un match, vous obtenez l'erreur :

```
Erreur lors de la création de la demande: SQLSTATE[42S22]: 
Column not found: 1054 Unknown column 'm.coach_id' in 'ON'
```

## 🔍 Cause

La table `amicalclub_matches` dans votre base de données **ne contient pas la colonne `coach_id`** qui est pourtant nécessaire pour :
- Identifier qui a créé le match
- Vérifier qu'un utilisateur ne fait pas une demande pour son propre match
- Récupérer les informations du coach dans les requêtes

## ✅ Solution

### Option 1 : Via phpMyAdmin (Recommandé - Plus simple)

1. **Ouvrir phpMyAdmin**
2. **Sélectionner votre base de données**
3. **Cliquer sur l'onglet "SQL"**
4. **Copier-coller ce code** :

```sql
-- Ajouter la colonne coach_id
ALTER TABLE amicalclub_matches 
ADD COLUMN coach_id INT NOT NULL AFTER team_id;

-- Remplir la colonne avec les bonnes valeurs
UPDATE amicalclub_matches m
JOIN amicalclub_teams t ON m.team_id = t.id
SET m.coach_id = t.coach_id;

-- Ajouter la clé étrangère
ALTER TABLE amicalclub_matches 
ADD CONSTRAINT fk_matches_coach 
FOREIGN KEY (coach_id) REFERENCES amicalclub_users(id) ON DELETE CASCADE;

-- Ajouter l'index
ALTER TABLE amicalclub_matches 
ADD INDEX idx_coach (coach_id);
```

5. **Cliquer sur "Exécuter"**

### Option 2 : Via le fichier SQL fourni

1. **Ouvrir phpMyAdmin**
2. **Sélectionner votre base de données**
3. **Cliquer sur "Importer"**
4. **Sélectionner le fichier** : `backend/add_coach_id_to_matches.sql`
5. **Cliquer sur "Exécuter"**

### Option 3 : Via ligne de commande (Pour utilisateurs avancés)

```bash
mysql -u votre_utilisateur -p votre_base_de_donnees < backend/add_coach_id_to_matches.sql
```

## ✅ Vérification

Après avoir exécuté le script, vérifiez que tout fonctionne :

1. **Dans phpMyAdmin** :
   - Allez dans la table `amicalclub_matches`
   - Vérifiez que la colonne `coach_id` existe
   - Vérifiez que toutes les lignes ont une valeur dans `coach_id`

2. **Dans l'application** :
   - Ouvrez un match
   - Cliquez sur "Je suis intéressé"
   - L'erreur ne devrait plus apparaître

## 📊 Structure attendue

Après la correction, la table `amicalclub_matches` doit avoir cette structure :

```
id               INT (Primary Key)
team_id          INT
coach_id         INT  ← AJOUTÉ
date             DATE
time             TIME
location         VARCHAR(255)
stadium          VARCHAR(255)
category         VARCHAR(50)
level            VARCHAR(50)
gender           VARCHAR(20)
description      TEXT
notes            TEXT
auto_validation  BOOLEAN
status           ENUM
confirmed_team_id INT
home_score       VARCHAR(10)
away_score       VARCHAR(10)
home_scorers     TEXT
away_scorers     TEXT
created_at       TIMESTAMP
updated_at       TIMESTAMP
```

## 🔄 Explication de la correction

### Pourquoi cette colonne est nécessaire ?

La colonne `coach_id` stocke l'ID du coach qui a créé le match. C'est important pour :

1. **Éviter les auto-demandes** : Un coach ne peut pas faire une demande pour son propre match
2. **Afficher les informations du coach** : Nom, avatar, etc.
3. **Gérer les permissions** : Seul le créateur peut modifier/supprimer le match

### Comment sont remplies les valeurs ?

```sql
UPDATE amicalclub_matches m
JOIN amicalclub_teams t ON m.team_id = t.id
SET m.coach_id = t.coach_id
```

Cette requête copie le `coach_id` de la table `amicalclub_teams` vers `amicalclub_matches` pour tous les matchs existants, car l'équipe qui crée un match appartient forcément au coach qui l'a créé.

## 🚨 Important

- **Faites une sauvegarde** de votre base de données avant d'exécuter la migration (recommandé)
- **Tous les matchs existants** seront automatiquement mis à jour avec le bon `coach_id`
- **Les futurs matchs** créés via l'API incluront automatiquement le `coach_id`

## 📝 Fichiers concernés

- **Backend** : `backend/request_match.php` (ligne 39)
- **Migration** : `backend/add_coach_id_to_matches.sql` (nouveau fichier créé)
- **Schéma** : `backend/create_tables.sql` (déjà correct)

## ✅ Après la correction

Une fois la migration exécutée, l'application fonctionnera correctement :
- ✅ Bouton "Je suis intéressé" fonctionne
- ✅ Pas d'erreur SQL
- ✅ Les demandes de match sont créées correctement
- ✅ Validation automatique fonctionne (si activée)


