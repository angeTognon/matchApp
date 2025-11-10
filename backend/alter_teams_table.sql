-- Requête SQL pour ajouter les nouveaux champs à la table amicalclub_teams
-- À exécuter si la table existe déjà sans ces champs

-- Ajouter le champ 'founded' (année de création) avec contrainte YYYY
ALTER TABLE `amicalclub_teams` 
ADD COLUMN `founded` VARCHAR(4) DEFAULT NULL 
AFTER `logo`;

-- Ajouter une contrainte CHECK pour s'assurer que l'année est valide (4 chiffres entre 1800 et 2100)
ALTER TABLE `amicalclub_teams` 
ADD CONSTRAINT `chk_founded_year` 
CHECK (`founded` IS NULL OR (`founded` REGEXP '^[0-9]{4}$' AND `founded` >= '1800' AND `founded` <= '2100'));

-- Ajouter le champ 'home_stadium' (stade domicile)
ALTER TABLE `amicalclub_teams` 
ADD COLUMN `home_stadium` VARCHAR(255) DEFAULT NULL 
AFTER `founded`;

-- Ajouter le champ 'achievements' (palmarès)
ALTER TABLE `amicalclub_teams` 
ADD COLUMN `achievements` TEXT DEFAULT NULL 
AFTER `home_stadium`;

-- Vérifier la structure de la table après modification
-- DESCRIBE `amicalclub_teams`;
