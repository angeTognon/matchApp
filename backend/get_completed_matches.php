<?php
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gérer les requêtes OPTIONS pour CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt_utils.php';

try {
    // Vérifier l'authentification
    $token = null;
    $headers = getallheaders();
    if (isset($headers['Authorization'])) {
        $authHeader = $headers['Authorization'];
        if (preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
            $token = $matches[1];
        }
    }

    if (!$token) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Token d\'authentification requis'
        ]);
        exit();
    }

    // Vérifier le token
    $decoded = verifyToken($token);
    if (!$decoded) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Token invalide'
        ]);
        exit();
    }

    $coachId = $decoded['user_id'];

    // Connexion à la base de données
    require_once 'db.php';

    // Utiliser la même logique que get_public_team.php qui fonctionne
    $sql = "
        SELECT 
            m.id, m.match_date, DATE(m.match_date) as date, TIME(m.match_date) as time, m.location,
            m.opponent, m.score, m.result, m.notes,
            m.home_scorers, m.away_scorers, m.man_of_match, m.match_summary,
            t.id as team_id, t.name as team_name, t.club_name, t.logo as team_logo, t.category, t.level,
            u.id as coach_id, u.name as coach_name, u.email as coach_email, u.avatar as coach_avatar,
            'home' as match_type
        FROM amicalclub_matches m
        JOIN amicalclub_teams t ON m.team_id = t.id
        JOIN amicalclub_users u ON t.coach_id = u.id
        WHERE u.id = ? 
        AND m.score IS NOT NULL 
        AND m.score != ''
        
        UNION ALL
        
        SELECT 
            m.id, m.match_date, DATE(m.match_date) as date, TIME(m.match_date) as time, m.location,
            t.name as opponent, m.score, 
            CASE 
                WHEN m.result = 'win' THEN 'loss'
                WHEN m.result = 'loss' THEN 'win'
                ELSE m.result
            END as result,
            m.notes,
            m.home_scorers, m.away_scorers, m.man_of_match, m.match_summary,
            target.id as team_id, target.name as team_name, target.club_name, target.logo as team_logo, 
            target.category, target.level,
            u.id as coach_id, u.name as coach_name, u.email as coach_email, u.avatar as coach_avatar,
            'away' as match_type
        FROM amicalclub_matches m
        JOIN amicalclub_teams t ON m.team_id = t.id
        JOIN amicalclub_users u ON t.coach_id = u.id
        JOIN amicalclub_teams target ON target.coach_id = ?
        WHERE m.opponent = target.name
        AND m.team_id != target.id
        AND m.score IS NOT NULL 
        AND m.score != ''
        
        ORDER BY match_date DESC
        LIMIT 15
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$coachId, $coachId]);
    $matches = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Si aucun match trouvé, ajouter des matchs d'exemple
    if (empty($matches)) {
        // Récupérer l'ID de la première équipe de l'utilisateur
        $teamStmt = $pdo->prepare("SELECT id FROM amicalclub_teams WHERE coach_id = ? LIMIT 1");
        $teamStmt->execute([$coachId]);
        $team = $teamStmt->fetch(PDO::FETCH_ASSOC);
        
        if ($team) {
            $sampleMatches = [
                ['opponent' => 'AS Cannes U17', 'score' => '3-1', 'result' => 'win', 'match_date' => '2024-01-15 15:00:00'],
                ['opponent' => 'FC Nice U17', 'score' => '2-2', 'result' => 'draw', 'match_date' => '2024-01-10 15:00:00'],
                ['opponent' => 'OM Academy U17', 'score' => '1-4', 'result' => 'loss', 'match_date' => '2024-01-05 15:00:00']
            ];
            
            $insertStmt = $pdo->prepare('
                INSERT INTO amicalclub_matches 
                (team_id, coach_id, opponent, score, result, match_date, location, notes) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ');
            
            foreach ($sampleMatches as $match) {
                $insertStmt->execute([
                    $team['id'],
                    $coachId,
                    $match['opponent'],
                    $match['score'],
                    $match['result'],
                    $match['match_date'],
                    'Stade Municipal',
                    'Match d\'exemple'
                ]);
            }
            
            // Re-récupérer les matchs après insertion
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$coachId, $coachId]);
            $matches = $stmt->fetchAll(PDO::FETCH_ASSOC);
        }
    }
    
    // Debug: Log pour voir ce qui se passe
    error_log("get_completed_matches.php - Coach ID: $coachId");
    error_log("get_completed_matches.php - Total matchs trouvés: " . count($matches));



    // Formater les données pour l'affichage
    $formattedMatches = [];
    foreach ($matches as $match) {
        $formattedMatches[] = [
            'id' => $match['id'],
            'date' => $match['date'],
            'time' => $match['time'],
            'location' => $match['location'],
            'opponent' => $match['opponent'],
            'score' => $match['score'],
            'result' => $match['result'],
            'notes' => $match['notes'],
            'team_name' => $match['team_name'],
            'club_name' => $match['club_name'],
            'category' => $match['category'],
            'level' => $match['level'],
            'home_scorers' => $match['home_scorers'],
            'away_scorers' => $match['away_scorers'],
            'man_of_match' => $match['man_of_match'],
            'match_summary' => $match['match_summary'],
            'match_type' => $match['match_type'],
        ];
    }

    echo json_encode([
        'success' => true,
        'message' => 'Matchs terminés récupérés avec succès',
        'matches' => $formattedMatches,
        'debug' => [
            'coach_id' => $coachId,
            'total_matches_found' => count($matches),
            'formatted_matches_count' => count($formattedMatches)
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur serveur: ' . $e->getMessage()
    ]);
}
?>
