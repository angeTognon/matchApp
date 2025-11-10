-- Script pour insérer des matchs terminés d'exemple
-- Remplacez les IDs par les vrais IDs de votre base de données

-- Exemple de matchs terminés pour tester la section "Derniers matchs"
-- Assurez-vous que les team_id correspondent à vos vraies équipes

INSERT INTO amicalclub_matches (
    team_id, 
    coach_id, 
    opponent, 
    score, 
    result, 
    match_date, 
    location, 
    notes,
    home_scorers,
    away_scorers,
    man_of_match,
    match_summary
) VALUES 
-- Match 1: Victoire
(1, 1, 'AS Cannes U17', '3-1', 'win', '2024-01-15 15:00:00', 'Stade Municipal', 'Excellent match, belle victoire', 
'[{"name":"Jean Dupont","goals":2},{"name":"Pierre Martin","goals":1}]', 
'[{"name":"Paul Durand","goals":1}]', 
'Jean Dupont', 
'Match dominé par notre équipe dès le début. Jean Dupont a marqué un doublé décisif.'),

-- Match 2: Match nul
(1, 1, 'FC Nice U17', '2-2', 'draw', '2024-01-10 15:00:00', 'Stade Municipal', 'Match équilibré, résultat correct',
'[{"name":"Marc Leroy","goals":1},{"name":"Thomas Bernard","goals":1}]',
'[{"name":"Lucas Moreau","goals":1},{"name":"Antoine Petit","goals":1}]',
'Marc Leroy',
'Match très disputé avec des occasions des deux côtés. Égalité méritée.'),

-- Match 3: Défaite
(1, 1, 'OM Academy U17', '1-4', 'loss', '2024-01-05 15:00:00', 'Stade Municipal', 'Difficile match, équipe adverse très forte',
'[{"name":"David Rousseau","goals":1}]',
'[{"name":"Kevin Blanc","goals":2},{"name":"Nicolas Rouge","goals":1},{"name":"Sébastien Vert","goals":1}]',
'Kevin Blanc',
'Notre équipe a eu du mal à s\'imposer face à une équipe très technique. Leçon à retenir.'),

-- Match 4: Victoire récente
(1, 1, 'Olympique Lyon U17', '2-0', 'win', '2024-01-20 15:00:00', 'Stade Municipal', 'Belle victoire à domicile',
'[{"name":"Alexandre Noir","goals":1},{"name":"Julien Blanc","goals":1}]',
'[]',
'Alexandre Noir',
'Victoire méritée avec une défense solide et des attaquants efficaces.'),

-- Match 5: Défaite récente
(1, 1, 'Stade Rennais U17', '0-2', 'loss', '2024-01-18 15:00:00', 'Stade Municipal', 'Journée sans, pas de réussite',
'[]',
'[{"name":"Maxime Jaune","goals":1},{"name":"Romain Bleu","goals":1}]',
'Maxime Jaune',
'Notre équipe n\'a pas réussi à marquer malgré plusieurs occasions. Défense à revoir.');

-- Note: Ajustez les team_id et coach_id selon votre base de données
-- Vous pouvez vérifier vos IDs avec:
-- SELECT id, name FROM amicalclub_teams;
-- SELECT id, name FROM amicalclub_users;
