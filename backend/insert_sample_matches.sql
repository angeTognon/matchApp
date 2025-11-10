-- Script pour insérer des matchs de test
-- À exécuter sur votre base de données

-- Vérifier d'abord les équipes disponibles
SELECT id, name, coach_id FROM amicalclub_teams LIMIT 5;

-- Insérer des matchs de test (remplacez les team_id par de vrais IDs)
INSERT INTO amicalclub_matches (team_id, opponent, match_date, location, notes, result) VALUES
(2, 'Équipe Adversaire 1', '2025-01-20 15:00:00', 'Stade Municipal, Paris', 'Match amical - Terrain en excellent état', 'pending'),
(2, 'Équipe Adversaire 2', '2025-01-25 14:30:00', 'Complexe Sportif, Marseille', 'Championnat départemental', 'pending'),
(7, 'Équipe Adversaire 3', '2025-01-22 16:00:00', 'Stade des Alpilles, Aix', 'Coupe régionale', 'pending'),
(7, 'Équipe Adversaire 4', '2025-01-28 15:30:00', 'Terrain Municipal, Lyon', 'Match de préparation', 'pending');

-- Vérifier les matchs insérés
SELECT 
    m.id, m.team_id, m.opponent, m.match_date, m.location, m.result,
    t.name as team_name, u.name as coach_name
FROM amicalclub_matches m
LEFT JOIN amicalclub_teams t ON m.team_id = t.id
LEFT JOIN amicalclub_users u ON t.coach_id = u.id
ORDER BY m.match_date DESC;
