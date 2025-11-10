-- Script de migration pour ajouter la colonne coach_id manquante
-- À exécuter sur votre base de données MySQL

-- Ajouter la colonne coach_id à amicalclub_matches si elle n'existe pas
ALTER TABLE amicalclub_matches 
ADD COLUMN IF NOT EXISTS coach_id INT NOT NULL AFTER team_id;

-- Ajouter la clé étrangère si elle n'existe pas
-- Note: Si la colonne vient d'être créée, vous devrez peut-être d'abord
-- mettre à jour les valeurs de coach_id en copiant depuis amicalclub_teams

-- Mettre à jour les valeurs de coach_id basées sur team_id
UPDATE amicalclub_matches m
JOIN amicalclub_teams t ON m.team_id = t.id
SET m.coach_id = t.coach_id
WHERE m.coach_id IS NULL OR m.coach_id = 0;

-- Ajouter la contrainte de clé étrangère (si elle n'existe pas déjà)
-- ALTER TABLE amicalclub_matches 
-- ADD CONSTRAINT fk_matches_coach 
-- FOREIGN KEY (coach_id) REFERENCES amicalclub_users(id) ON DELETE CASCADE;

-- Ajouter l'index si il n'existe pas
-- ALTER TABLE amicalclub_matches 
-- ADD INDEX idx_coach (coach_id);

-- Vérifier que tout est OK
SELECT COUNT(*) as total_matches, 
       COUNT(coach_id) as matches_with_coach 
FROM amicalclub_matches;


