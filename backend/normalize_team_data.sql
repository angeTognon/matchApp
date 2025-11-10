-- Script pour normaliser les données d'équipes existantes
-- Ce script corrige les variations de catégories et niveaux

-- Normaliser les catégories
UPDATE `amicalclub_teams` SET `category` = 'Séniors' WHERE LOWER(`category`) = 'seniors';
UPDATE `amicalclub_teams` SET `category` = 'Vétérans' WHERE LOWER(`category`) = 'veterans';
UPDATE `amicalclub_teams` SET `category` = 'Féminines' WHERE LOWER(`category`) = 'feminines';

-- Normaliser les niveaux
UPDATE `amicalclub_teams` SET `level` = 'Départemental' WHERE LOWER(`level`) = 'departemental';
UPDATE `amicalclub_teams` SET `level` = 'Régional' WHERE LOWER(`level`) = 'regional';

-- Vérifier les données après normalisation
SELECT id, name, category, level FROM `amicalclub_teams`;

-- Afficher les valeurs uniques pour vérification
SELECT DISTINCT category FROM `amicalclub_teams` ORDER BY category;
SELECT DISTINCT level FROM `amicalclub_teams` ORDER BY level;
