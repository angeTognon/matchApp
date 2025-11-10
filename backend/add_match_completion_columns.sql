-- Script pour ajouter les colonnes de validation de fin de match
-- À exécuter dans phpMyAdmin

-- Ajouter les colonnes pour la validation à deux
ALTER TABLE amicalclub_matches 
ADD COLUMN IF NOT EXISTS home_confirmed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS away_confirmed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS both_confirmed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS home_scorers TEXT NULL COMMENT 'JSON: [{name, goals}]',
ADD COLUMN IF NOT EXISTS away_scorers TEXT NULL COMMENT 'JSON: [{name, goals}]',
ADD COLUMN IF NOT EXISTS man_of_match VARCHAR(255) NULL,
ADD COLUMN IF NOT EXISTS yellow_cards TEXT NULL COMMENT 'Noms des joueurs avec carton jaune',
ADD COLUMN IF NOT EXISTS red_cards TEXT NULL COMMENT 'Noms des joueurs avec carton rouge',
ADD COLUMN IF NOT EXISTS match_summary TEXT NULL COMMENT 'Résumé du match';

-- Vérifier les colonnes ajoutées
SELECT COLUMN_NAME, COLUMN_TYPE, COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'amicalclub_matches' 
AND COLUMN_NAME IN ('home_confirmed', 'away_confirmed', 'both_confirmed', 'home_scorers', 'away_scorers', 'man_of_match')
ORDER BY ORDINAL_POSITION;

