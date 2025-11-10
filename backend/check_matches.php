<?php
require_once 'db.php';

try {
    echo "=== Vérification des équipes ===\n";
    $stmt = $pdo->query('SELECT id, name, coach_id FROM amicalclub_teams LIMIT 5');
    $teams = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($teams as $team) {
        echo "ID: {$team['id']}, Nom: {$team['name']}, Coach ID: {$team['coach_id']}\n";
    }
    
    echo "\n=== Vérification des matchs ===\n";
    $stmt = $pdo->query('SELECT id, team_id, opponent, score, result, match_date FROM amicalclub_matches WHERE score IS NOT NULL AND score != "" LIMIT 5');
    $matches = $stmt->fetchAll(PDO::FETCH_ASSOC);
    if (empty($matches)) {
        echo "Aucun match terminé trouvé dans la base de données.\n";
    } else {
        foreach ($matches as $match) {
            echo "ID: {$match['id']}, Team: {$match['team_id']}, Opponent: {$match['opponent']}, Score: {$match['score']}, Result: {$match['result']}\n";
        }
    }
    
    echo "\n=== Tous les matchs (avec ou sans score) ===\n";
    $stmt = $pdo->query('SELECT id, team_id, opponent, score, result, match_date FROM amicalclub_matches LIMIT 10');
    $allMatches = $stmt->fetchAll(PDO::FETCH_ASSOC);
    if (empty($allMatches)) {
        echo "Aucun match trouvé dans la base de données.\n";
    } else {
        foreach ($allMatches as $match) {
            $score = $match['score'] ?: 'Pas de score';
            echo "ID: {$match['id']}, Team: {$match['team_id']}, Opponent: {$match['opponent']}, Score: {$score}, Result: {$match['result']}\n";
        }
    }
    
} catch (Exception $e) {
    echo "Erreur: " . $e->getMessage() . "\n";
}
?>
