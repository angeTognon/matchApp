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

    $coachId = $payload['user_id'];

    // Récupérer l'équipe
    $stmt = $pdo->prepare("
        SELECT t.*, u.name as coach_name
        FROM amicalclub_teams t
        JOIN amicalclub_users u ON t.coach_id = u.id
        WHERE t.id = ? AND t.coach_id = ?
    ");
    $stmt->execute([$teamId, $coachId]);
    $team = $stmt->fetch();

    if (!$team) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Équipe non trouvée'
        ]);
        exit;
    }

    // Récupérer les matchs de l'équipe
    $stmt = $pdo->prepare("
        SELECT * FROM amicalclub_matches 
        WHERE team_id = ? 
        ORDER BY match_date DESC
    ");
    $stmt->execute([$teamId]);
    $matches = $stmt->fetchAll();

    // Calculer les statistiques
    $totalMatches = count($matches);
    $wins = 0;
    $draws = 0;
    $losses = 0;
    $goalsScored = 0;
    $goalsConceded = 0;

    foreach ($matches as $match) {
        if ($match['result'] === 'win') $wins++;
        elseif ($match['result'] === 'draw') $draws++;
        elseif ($match['result'] === 'loss') $losses++;

        // Parser le score pour calculer les buts
        if ($match['score']) {
            $scores = explode('-', $match['score']);
            if (count($scores) === 2) {
                $goalsScored += (int)$scores[0];
                $goalsConceded += (int)$scores[1];
            }
        }
    }

    $team['statistics'] = [
        'matches' => $totalMatches,
        'wins' => $wins,
        'draws' => $draws,
        'losses' => $losses,
        'goalsScored' => $goalsScored,
        'goalsConceded' => $goalsConceded,
    ];

    $team['recent_matches'] = array_slice($matches, 0, 5);

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
