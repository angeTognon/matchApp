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

// Récupérer les données JSON de la requête
$data = json_decode(file_get_contents('php://input'), true);

if (!$data || empty($data['name'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Le nom de l\'équipe est obligatoire'
    ]);
    exit;
}

// Validation de l'année de création si fournie
if (isset($data['founded']) && !empty($data['founded'])) {
    $founded = trim($data['founded']);
    if (!preg_match('/^\d{4}$/', $founded) || $founded < 1800 || $founded > 2100) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'L\'année de création doit être au format YYYY (4 chiffres entre 1800 et 2100)'
        ]);
        exit;
    }
}

try {
    // Vérifier le token JWT
    error_log("Vérification du token JWT dans create_team.php: " . $token);
    $payload = verify_jwt($token);
    error_log("Payload JWT: " . json_encode($payload));

    if (!$payload) {
        error_log("Token JWT invalide dans create_team.php");
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Token invalide ou expiré'
        ]);
        exit;
    }

    $coachId = $payload['user_id'];
    error_log("Coach ID extrait du token: " . $coachId);

    // Insérer la nouvelle équipe
    $stmt = $pdo->prepare("
        INSERT INTO amicalclub_teams (
            coach_id, name, club_name, category, level, location,
            description, founded, home_stadium, achievements, logo
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");

    $stmt->execute([
        $coachId,
        htmlspecialchars($data['name'], ENT_QUOTES, 'UTF-8'),
        isset($data['club_name']) ? htmlspecialchars($data['club_name'], ENT_QUOTES, 'UTF-8') : null,
        isset($data['category']) ? htmlspecialchars($data['category'], ENT_QUOTES, 'UTF-8') : null,
        isset($data['level']) ? htmlspecialchars($data['level'], ENT_QUOTES, 'UTF-8') : null,
        isset($data['location']) ? htmlspecialchars($data['location'], ENT_QUOTES, 'UTF-8') : null,
        isset($data['description']) ? htmlspecialchars($data['description'], ENT_QUOTES, 'UTF-8') : null,
        isset($data['founded']) ? htmlspecialchars($data['founded'], ENT_QUOTES, 'UTF-8') : null,
        isset($data['home_stadium']) ? htmlspecialchars($data['home_stadium'], ENT_QUOTES, 'UTF-8') : null,
        isset($data['achievements']) ? htmlspecialchars($data['achievements'], ENT_QUOTES, 'UTF-8') : null,
        isset($data['logo']) ? $data['logo'] : null,
    ]);

    $teamId = $pdo->lastInsertId();

    // Récupérer l'équipe créée avec le nom du coach
    $stmt = $pdo->prepare("
        SELECT t.*, u.name as coach_name 
        FROM amicalclub_teams t
        JOIN amicalclub_users u ON t.coach_id = u.id
        WHERE t.id = ?
    ");
    $stmt->execute([$teamId]);
    $newTeam = $stmt->fetch();

    // Récupérer toutes les équipes de l'utilisateur
    $stmt = $pdo->prepare("
        SELECT t.*, u.name as coach_name
        FROM amicalclub_teams t
        JOIN amicalclub_users u ON t.coach_id = u.id
        WHERE t.coach_id = ?
    ");
    $stmt->execute([$coachId]);
    $allTeams = $stmt->fetchAll();

    // Récupérer les données utilisateur
    $stmt = $pdo->prepare("SELECT * FROM amicalclub_users WHERE id = ?");
    $stmt->execute([$coachId]);
    $userData = $stmt->fetch();

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Équipe créée avec succès',
        'data' => [
            'team' => $newTeam,
            'user' => $userData,
            'teams' => $allTeams
        ]
    ]);

} catch (\PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la création de l\'équipe',
        'error' => $e->getMessage()
    ]);
}
?>
