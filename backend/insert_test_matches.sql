-- Script pour insérer des matchs de test avec votre structure existante
-- À exécuter après avoir vérifié que les tables existent

-- Insérer quelques matchs de test
INSERT INTO amicalclub_matches (team_id, opponent, match_date, location, notes, result) VALUES
(1, 'Équipe Adversaire 1', '2024-01-20 15:00:00', 'Stade Municipal, Marseille', 'Match amical - Terrain en excellent état', 'pending'),
(1, 'Équipe Adversaire 2', '2024-01-25 14:30:00', 'Complexe Sportif, Aix-en-Provence', 'Championnat départemental', 'pending'),
(2, 'Équipe Adversaire 3', '2024-01-22 16:00:00', 'Stade des Alpilles, Arles', 'Coupe régionale', 'pending'),
(2, 'Équipe Adversaire 4', '2024-01-28 15:30:00', 'Terrain Municipal, Aubagne', 'Match de préparation', 'pending');

-- Note: Remplacez les team_id (1, 2) par les vrais IDs de vos équipes
-- Vous pouvez vérifier les IDs avec: SELECT id, name FROM amicalclub_teams;
