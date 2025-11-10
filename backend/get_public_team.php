<?php
require_once 'db.php';
require_once 'jwt_utils.php';

// Récupérer le token depuis les headers
$headers = getallheaders();
$token = isset($headers['Authorization']) ? str_replace('Bearer ', '', $headers['Authorization']) : null;

if (!$token) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Token manquant'
    ]);
    exit;
}

// Récupérer l'ID de l'équipe depuis les paramètres
$teamId = isset($_GET['team_id']) ? (int)$_GET['team_id'] : null;

if (!$teamId) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'ID d\'équipe manquant'
    ]);
    exit;
}

try {
    // Vérifier le token JWT
    $payload = verify_jwt($token);
    if (!$payload) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Token invalide ou expiré'
        ]);
        exit;
    }

    $currentCoachId = $payload['user_id'];

    // Récupérer l'équipe (publique - n'importe quelle équipe)
    $stmt = $pdo->prepare("
        SELECT t.*, u.name as coach_name, u.email as coach_email, u.avatar as coach_avatar
        FROM amicalclub_teams t
        JOIN amicalclub_users u ON t.coach_id = u.id
        WHERE t.id = ?
    ");
    $stmt->execute([$teamId]);
    $team = $stmt->fetch();

    if (!$team) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Équipe non trouvée'
        ]);
        exit;
    }

    // Récupérer TOUS les matchs de cette équipe (pour les statistiques complètes)
    // Un match peut avoir cette équipe comme team_id (home) OU dans opponent (away via une autre équipe)
    $statsStmt = $pdo->prepare("
        SELECT 
            m.*,
            t.name as team_name,
            'home' as match_type
        FROM amicalclub_matches m
        JOIN amicalclub_teams t ON m.team_id = t.id
        WHERE m.team_id = ?
        AND m.score IS NOT NULL 
        AND m.score != ''
        
        UNION ALL
        
        SELECT 
            m.*,
            t.name as team_name,
            'away' as match_type
        FROM amicalclub_matches m
        JOIN amicalclub_teams t ON m.team_id = t.id
        JOIN amicalclub_teams target ON target.id = ?
        WHERE m.opponent = target.name
        AND m.team_id != ?
        AND m.score IS NOT NULL 
        AND m.score != ''
    ");
    $statsStmt->execute([$teamId, $teamId, $teamId]);
    $allMatches = $statsStmt->fetchAll();

    // Calculer les statistiques à partir de tous les matchs
    $totalMatches = count($allMatches);
    $wins = 0;
    $draws = 0;
    $losses = 0;
    $goalsScored = 0;
    $goalsConceded = 0;

    foreach ($allMatches as $match) {
        $matchResult = $match['result'];
        $isHome = ($match['match_type'] === 'home');
        
        // Si l'équipe est away, inverser le résultat
        if (!$isHome) {
            if ($matchResult === 'win') $matchResult = 'loss';
            elseif ($matchResult === 'loss') $matchResult = 'win';
        }
        
        if ($matchResult === 'win') $wins++;
        elseif ($matchResult === 'draw') $draws++;
        elseif ($matchResult === 'loss') $losses++;

        // Parser le score pour calculer les buts
        if ($match['score']) {
            $scores = explode('-', $match['score']);
            if (count($scores) === 2) {
                if ($isHome) {
                    $goalsScored += (int)$scores[0];
                    $goalsConceded += (int)$scores[1];
                } else {
                    $goalsScored += (int)$scores[1];
                    $goalsConceded += (int)$scores[0];
                }
            }
        }
    }

    // Récupérer les 10 derniers matchs terminés pour l'affichage
    $displayStmt = $pdo->prepare("
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
        WHERE m.team_id = ? 
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
        JOIN amicalclub_teams target ON target.id = ?
        WHERE m.opponent = target.name
        AND m.team_id != ?
        AND m.score IS NOT NULL 
        AND m.score != ''
        
        ORDER BY match_date DESC
        LIMIT 10
    ");
    $displayStmt->execute([$teamId, $teamId, $teamId]);
    $completedMatches = $displayStmt->fetchAll();

    $team['statistics'] = [
        'matches' => $totalMatches,
        'wins' => $wins,
        'draws' => $draws,
        'losses' => $losses,
        'goalsScored' => $goalsScored,
        'goalsConceded' => $goalsConceded,
    ];

    $team['completed_matches'] = $completedMatches;
    $team['is_my_team'] = ($team['coach_id'] == $currentCoachId);

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'data' => $team
    ]);

} catch (\PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la récupération de l\'équipe',
        'error' => $e->getMessage()
    ]);
}
?>
