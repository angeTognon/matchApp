<?php
require_once 'db.php';

header('Content-Type: application/json');

try {
    echo "=== DEBUG MATCHES ===\n\n";
    
    // 1. Vérifier la structure de la table
    echo "1. Structure de la table amicalclub_matches:\n";
    $stmt = $pdo->query("DESCRIBE amicalclub_matches");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($columns as $column) {
        echo "   - {$column['Field']}: {$column['Type']}\n";
    }
    
    // 2. Compter les matchs
    echo "\n2. Nombre de matchs en base:\n";
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM amicalclub_matches");
    $count = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "   Total: " . $count['total'] . "\n";
    
    // 3. Lister les équipes disponibles
    echo "\n3. Équipes disponibles:\n";
    $stmt = $pdo->query("SELECT id, name, coach_id FROM amicalclub_teams LIMIT 5");
    $teams = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($teams as $team) {
        echo "   - ID: {$team['id']}, Nom: {$team['name']}, Coach: {$team['coach_id']}\n";
    }
    
    // 4. Si aucun match, en insérer un
    if ($count['total'] == 0 && !empty($teams)) {
        echo "\n4. Aucun match trouvé. Insertion d'un match de test...\n";
        
        $teamId = $teams[0]['id'];
        $stmt = $pdo->prepare("
            INSERT INTO amicalclub_matches (team_id, opponent, match_date, location, notes, result) 
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $teamId,
            'Équipe Test',
            '2025-01-20 15:00:00',
            'Stade Test, Paris',
            'Match de test pour debug',
            'pending'
        ]);
        
        $matchId = $pdo->lastInsertId();
        echo "   Match de test inséré avec ID: $matchId\n";
    }
    
    // 5. Lister les matchs existants
    echo "\n5. Matchs existants:\n";
    $stmt = $pdo->query("
        SELECT 
            m.id, m.team_id, m.opponent, m.match_date, m.location, m.result,
            t.name as team_name, u.name as coach_name
        FROM amicalclub_matches m
        LEFT JOIN amicalclub_teams t ON m.team_id = t.id
        LEFT JOIN amicalclub_users u ON t.coach_id = u.id
        ORDER BY m.match_date DESC
        LIMIT 5
    ");
    $matches = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($matches as $match) {
        echo "   - ID: {$match['id']}, Équipe: {$match['team_name']}, Date: {$match['match_date']}, Lieu: {$match['location']}, Statut: {$match['result']}\n";
    }
    
    // 6. Tester la requête get_match.php
    if (!empty($matches)) {
        $testMatchId = $matches[0]['id'];
        echo "\n6. Test de la requête get_match.php pour l'ID $testMatchId:\n";
        
        $stmt = $pdo->prepare("
            SELECT 
                m.*,
                t.name as team_name,
                t.club_name,
                t.logo as team_logo,
                u.name as coach_name,
                u.location as coach_location,
                u.avatar as coach_avatar,
                DATE(m.match_date) as date,
                TIME(m.match_date) as time,
                m.result as status
            FROM amicalclub_matches m
            JOIN amicalclub_teams t ON m.team_id = t.id
            JOIN amicalclub_users u ON t.coach_id = u.id
            WHERE m.id = ?
        ");
        $stmt->execute([$testMatchId]);
        $testMatch = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($testMatch) {
            echo "   ✅ Match trouvé: {$testMatch['team_name']} - {$testMatch['date']} {$testMatch['time']}\n";
        } else {
            echo "   ❌ Match non trouvé avec l'ID $testMatchId\n";
        }
    }
    
    echo "\n=== FIN DEBUG ===\n";
    
} catch (Exception $e) {
    echo "Erreur: " . $e->getMessage() . "\n";
}
?>
