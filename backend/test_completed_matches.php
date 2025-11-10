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
    require_once 'db_connection.php';
    $pdo = getConnection();

    // Ajouter des matchs de test avec des scores
    $testMatches = [
        [
            'opponent' => 'AS Cannes U17',
            'score' => '3-1',
            'result' => 'win',
            'date' => '2024-01-15'
        ],
        [
            'opponent' => 'FC Nice U17',
            'score' => '2-2',
            'result' => 'draw',
            'date' => '2024-01-10'
        ],
        [
            'opponent' => 'OM Academy U17',
            'score' => '1-4',
            'result' => 'loss',
            'date' => '2024-01-05'
        ],
        [
            'opponent' => 'AS Monaco U17',
            'score' => '2-0',
            'result' => 'win',
            'date' => '2024-01-01'
        ],
        [
            'opponent' => 'RC Toulon U17',
            'score' => '0-1',
            'result' => 'loss',
            'date' => '2023-12-28'
        ]
    ];

    // Récupérer l'équipe de l'utilisateur
    $stmt = $pdo->prepare("SELECT id, name FROM amicalclub_teams WHERE coach_id = ? LIMIT 1");
    $stmt->execute([$coachId]);
    $team = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$team) {
        echo json_encode([
            'success' => false,
            'message' => 'Aucune équipe trouvée pour cet utilisateur'
        ]);
        exit();
    }

    // Ajouter les matchs de test
    foreach ($testMatches as $match) {
        $stmt = $pdo->prepare("
            INSERT INTO amicalclub_matches 
            (team_id, opponent, score, result, match_date, location, notes, home_confirmed, away_confirmed, both_confirmed)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $team['id'],
            $match['opponent'],
            $match['score'],
            $match['result'],
            $match['date'] . ' 15:00:00',
            'Stade de test',
            'Match de test',
            true,
            true,
            true
        ]);
    }

    echo json_encode([
        'success' => true,
        'message' => 'Matchs de test ajoutés avec succès',
        'matches_added' => count($testMatches)
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur serveur: ' . $e->getMessage()
    ]);
}
?>
