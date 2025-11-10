-- Script pour ajouter des équipements à un match existant
-- À exécuter sur votre base de données

-- D'abord, ajouter la colonne facilities si elle n'existe pas
ALTER TABLE amicalclub_matches 
ADD COLUMN IF NOT EXISTS facilities TEXT NULL;

-- Ensuite, ajouter des équipements de test à un match existant
UPDATE amicalclub_matches 
SET facilities = '["Vestiaires", "Douches", "Parking", "Éclairage", "Tribunes"]'
WHERE id = (SELECT id FROM amicalclub_matches LIMIT 1);
