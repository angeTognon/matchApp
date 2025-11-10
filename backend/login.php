<?php
require_once 'db.php';
require_once 'jwt_utils.php';

// Récupérer les données JSON de la requête
$data = json_decode(file_get_contents('php://input'), true);

// Validation des données
if (empty($data['email']) || empty($data['password'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Veuillez fournir l\'email et le mot de passe'
    ]);
    exit;
}

$email = filter_var($data['email'], FILTER_SANITIZE_EMAIL);
$password = $data['password'];

// Validation email
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Adresse email invalide'
    ]);
    exit;
}

try {
    // Récupérer l'utilisateur par email
    $stmt = $pdo->prepare("SELECT * FROM amicalclub_users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    if (!$user) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Email ou mot de passe incorrect'
        ]);
        exit;
    }

    // Vérifier le mot de passe
    if (!verifyPassword($password, $user['password'])) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Email ou mot de passe incorrect'
        ]);
        exit;
    }

    // Générer un token JWT
    $headers = ['alg' => 'HS256', 'typ' => 'JWT'];
    $payload = [
        'user_id' => $user['id'], 
        'email' => $user['email'], 
        'exp' => time() + (3600 * 24 * 7) // Expire dans 7 jours
    ];
    $token = generate_jwt($headers, $payload);

    // Récupérer les équipes de l'utilisateur
    $stmt = $pdo->prepare("SELECT * FROM amicalclub_teams WHERE coach_id = ?");
    $stmt->execute([$user['id']]);
    $teams = $stmt->fetchAll();

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

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Connexion réussie',
        'data' => [
            'user' => $user,
            'teams' => $teams,
            'token' => $token
        ]
    ]);

} catch (\PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la connexion',
        'error' => $e->getMessage()
    ]);
}
?>

