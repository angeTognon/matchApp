<?php
require_once 'db.php';

try {
    // Récupérer toutes les équipes
    $stmt = $pdo->query('SELECT id, name, coach_id FROM amicalclub_teams ORDER BY id');
    $teams = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($teams)) {
        echo "Aucune équipe trouvée dans la base de données.\n";
        exit;
    }
    
    echo "Équipes trouvées:\n";
    foreach ($teams as $team) {
        echo "- ID {$team['id']}, Nom: {$team['name']}, Coach ID: {$team['coach_id']}\n";
    }
    
    // Vérifier s'il y a déjà des matchs terminés pour toutes les équipes
    $totalExistingMatches = 0;
    foreach ($teams as $team) {
        $stmt = $pdo->prepare('SELECT COUNT(*) as count FROM amicalclub_matches WHERE team_id = ? AND score IS NOT NULL AND score != ""');
        $stmt->execute([$team['id']]);
        $existingMatches = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
        $totalExistingMatches += $existingMatches;
        echo "Équipe {$team['name']}: {$existingMatches} match(s) terminé(s)\n";
    }
    
    if ($totalExistingMatches > 0) {
        echo "Total: {$totalExistingMatches} match(s) terminé(s) trouvé(s).\n";
    } else {
        echo "Aucun match terminé trouvé. Ajout de matchs d'exemple pour toutes les équipes...\n";
        
        // Ajouter des matchs d'exemple pour chaque équipe
        $sampleMatches = [
            [
                'opponent' => 'AS Cannes U17',
                'score' => '3-1',
                'result' => 'win',
                'match_date' => '2024-01-15 15:00:00',
                'location' => 'Stade Municipal',
                'notes' => 'Excellent match, belle victoire'
            ],
            [
                'opponent' => 'FC Nice U17',
                'score' => '2-2',
                'result' => 'draw',
                'match_date' => '2024-01-10 15:00:00',
                'location' => 'Stade Municipal',
                'notes' => 'Match équilibré, résultat correct'
            ],
            [
                'opponent' => 'OM Academy U17',
                'score' => '1-4',
                'result' => 'loss',
                'match_date' => '2024-01-05 15:00:00',
                'location' => 'Stade Municipal',
                'notes' => 'Difficile match, équipe adverse très forte'
            ]
        ];
        
        $stmt = $pdo->prepare('
            INSERT INTO amicalclub_matches 
            (team_id, coach_id, opponent, score, result, match_date, location, notes) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ');
        
        foreach ($teams as $team) {
            echo "\nAjout de matchs pour l'équipe {$team['name']}:\n";
            foreach ($sampleMatches as $match) {
                $stmt->execute([
                    $team['id'],
                    $team['coach_id'],
                    $match['opponent'],
                    $match['score'],
                    $match['result'],
                    $match['match_date'],
                    $match['location'],
                    $match['notes']
                ]);
                echo "- Match ajouté: {$match['opponent']} - {$match['score']}\n";
            }
        }
        
        echo "\nMatchs d'exemple ajoutés avec succès pour toutes les équipes!\n";
    }
    
} catch (Exception $e) {
    echo "Erreur: " . $e->getMessage() . "\n";
}
?>
