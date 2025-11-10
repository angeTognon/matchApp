-- Test des contraintes sur le champ 'founded'
-- Ces requêtes doivent échouer (années invalides)

-- Test 1: Année trop courte (2 chiffres)
INSERT INTO `amicalclub_teams` (coach_id, name, founded) VALUES (1, 'Test Team 1', '83');

-- Test 2: Année trop longue (5 chiffres)
INSERT INTO `amicalclub_teams` (coach_id, name, founded) VALUES (1, 'Test Team 2', '19834');

-- Test 3: Année avec des lettres
INSERT INTO `amicalclub_teams` (coach_id, name, founded) VALUES (1, 'Test Team 3', '198a');

-- Test 4: Année trop ancienne
INSERT INTO `amicalclub_teams` (coach_id, name, founded) VALUES (1, 'Test Team 4', '1799');

-- Test 5: Année trop récente
INSERT INTO `amicalclub_teams` (coach_id, name, founded) VALUES (1, 'Test Team 5', '2101');

-- Test 6: Année vide (doit passer)
INSERT INTO `amicalclub_teams` (coach_id, name, founded) VALUES (1, 'Test Team 6', '');

-- Test 7: Année NULL (doit passer)
INSERT INTO `amicalclub_teams` (coach_id, name, founded) VALUES (1, 'Test Team 7', NULL);

-- Test 8: Année valide (doit passer)
INSERT INTO `amicalclub_teams` (coach_id, name, founded) VALUES (1, 'Test Team 8', '1983');

-- Nettoyer les tests
DELETE FROM `amicalclub_teams` WHERE name LIKE 'Test Team%';
