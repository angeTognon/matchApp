-- Script pour ajouter la colonne facilities à la table amicalclub_matches
-- À exécuter sur votre base de données

ALTER TABLE amicalclub_matches 
ADD COLUMN IF NOT EXISTS facilities TEXT NULL;
