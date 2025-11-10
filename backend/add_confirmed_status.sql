-- Script pour ajouter le statut 'confirmed' à l'ENUM result
-- À exécuter dans phpMyAdmin

-- Modifier l'ENUM pour ajouter 'confirmed'
ALTER TABLE amicalclub_matches 
MODIFY COLUMN result ENUM('win', 'draw', 'loss', 'pending', 'confirmed') DEFAULT 'pending';

-- Vérifier que ça a fonctionné
SELECT COLUMN_NAME, COLUMN_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'amicalclub_matches' 
AND COLUMN_NAME = 'result';


