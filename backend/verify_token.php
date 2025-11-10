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

try {
    // Vérifier le token JWT
    error_log("Vérification du token JWT: " . $token);
    $payload = verify_jwt($token);

    if (!$payload) {
        error_log("Token JWT invalide ou expiré");
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Token invalide ou expiré'
        ]);
        exit;
    }

    error_log("Token JWT valide, user_id: " . $payload['user_id']);

    // Récupérer les informations de l'utilisateur
    error_log("Requête utilisateur: SELECT id, name, location, license_number, experience, phone, avatar FROM amicalclub_users WHERE id = " . $payload['user_id']);
    $stmt = $pdo->prepare("SELECT id, name, location, license_number, experience, phone, avatar FROM amicalclub_users WHERE id = ?");
    $stmt->execute([$payload['user_id']]);
    $user = $stmt->fetch();
    error_log("Utilisateur trouvé: " . json_encode($user));

    if (!$user) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Utilisateur non trouvé'
        ]);
        exit;
    }

    // Récupérer les équipes de l'utilisateur
    error_log("Récupération des équipes pour user_id: " . $user['id']);
    $stmt = $pdo->prepare("SELECT * FROM amicalclub_teams WHERE coach_id = ?");
    $stmt->execute([$user['id']]);
    $teams = $stmt->fetchAll();
    error_log("Nombre d'équipes trouvées: " . count($teams));

    // Pour chaque équipe, récupérer les matchs récents
    foreach ($teams as &$team) {
        $stmt = $pdo->prepare("
            SELECT * FROM amicalclub_matches 
            WHERE team_id = ? 
            ORDER BY match_date DESC 
            LIMIT 5
        ");
        $stmt->execute([$team['id']]);
        $team['recent_matches'] = $stmt->fetchAll();
    }

    // Supprimer le mot de passe de la réponse
    unset($user['password']);

    $response = [
        'success' => true,
        'message' => 'Token valide',
        'data' => [
            'user' => $user,
            'teams' => $teams
        ]
    ];
    error_log("Réponse finale envoyée: " . json_encode($response));

    http_response_code(200);
    echo json_encode($response);

} catch (\PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la vérification du token',
        'error' => $e->getMessage()
    ]);
}
?>

