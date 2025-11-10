<?php
require_once 'db.php';
require_once 'jwt_utils.php';

// Token de test (remplacez par un vrai token)
$testToken = 'eyJhbGciOiJIUzI1NiIs...'; // Utilisez le token de vos logs

try {
    // Vérifier le token
    $payload = verify_jwt($testToken);
    if (!$payload) {
        echo "Token invalide\n";
        exit;
    }
    
    $coachId = $payload['user_id'];
    echo "Coach ID: $coachId\n";
    
    // Récupérer les équipes de l'utilisateur
    $stmt = $pdo->prepare("SELECT id, name FROM amicalclub_teams WHERE coach_id = ?");
    $stmt->execute([$coachId]);
    $userTeams = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "Équipes de l'utilisateur:\n";
    foreach ($userTeams as $team) {
        echo "- ID: {$team['id']}, Nom: {$team['name']}\n";
    }
    
    // Vérifier les matchs HOME
    echo "\n=== Matchs HOME (équipe créatrice) ===\n";
    $stmt = $pdo->prepare("
        SELECT m.id, m.opponent, m.score, m.result, m.match_date 
        FROM amicalclub_matches m 
        JOIN amicalclub_teams t ON m.team_id = t.id 
        WHERE t.coach_id = ? AND m.score IS NOT NULL AND m.score != ''
    ");
    $stmt->execute([$coachId]);
    $homeMatches = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($homeMatches)) {
        echo "Aucun match HOME trouvé\n";
    } else {
        foreach ($homeMatches as $match) {
            echo "- Match ID: {$match['id']}, vs {$match['opponent']}, Score: {$match['score']}, Résultat: {$match['result']}\n";
        }
    }
    
    // Vérifier les matchs AWAY
    echo "\n=== Matchs AWAY (équipe adverse) ===\n";
    if (!empty($userTeams)) {
        $teamNames = array_column($userTeams, 'name');
        $placeholders = str_repeat('?,', count($teamNames) - 1) . '?';
        
        $stmt = $pdo->prepare("
            SELECT m.id, m.opponent, m.score, m.result, m.match_date 
            FROM amicalclub_matches m 
            WHERE m.opponent IN ($placeholders) AND m.score IS NOT NULL AND m.score != ''
        ");
        $stmt->execute($teamNames);
        $awayMatches = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        if (empty($awayMatches)) {
            echo "Aucun match AWAY trouvé\n";
        } else {
            foreach ($awayMatches as $match) {
                echo "- Match ID: {$match['id']}, vs {$match['opponent']}, Score: {$match['score']}, Résultat: {$match['result']}\n";
            }
        }
    }
    
    // Ajouter des matchs d'exemple si aucun n'existe
    if (empty($homeMatches) && empty($awayMatches)) {
        echo "\n=== Ajout de matchs d'exemple ===\n";
        
        if (!empty($userTeams)) {
            $team = $userTeams[0]; // Prendre la première équipe
            
            $sampleMatches = [
                ['opponent' => 'AS Cannes U17', 'score' => '3-1', 'result' => 'win', 'match_date' => '2024-01-15 15:00:00'],
                ['opponent' => 'FC Nice U17', 'score' => '2-2', 'result' => 'draw', 'match_date' => '2024-01-10 15:00:00'],
                ['opponent' => 'OM Academy U17', 'score' => '1-4', 'result' => 'loss', 'match_date' => '2024-01-05 15:00:00']
            ];
            
            $stmt = $pdo->prepare('
                INSERT INTO amicalclub_matches 
                (team_id, coach_id, opponent, score, result, match_date, location, notes) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ');
            
            foreach ($sampleMatches as $match) {
                $stmt->execute([
                    $team['id'],
                    $coachId,
                    $match['opponent'],
                    $match['score'],
                    $match['result'],
                    $match['match_date'],
                    'Stade Municipal',
                    'Match d\'exemple'
                ]);
                echo "Match ajouté: {$match['opponent']} - {$match['score']}\n";
            }
            
            echo "Matchs d'exemple ajoutés avec succès!\n";
        }
    }
    
} catch (Exception $e) {
    echo "Erreur: " . $e->getMessage() . "\n";
}
?>
