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

if (!$data || !isset($data['team_id'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Données manquantes'
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

$teamId = (int)$data['team_id'];

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

    // Vérifier que l'équipe appartient à l'utilisateur
    $stmt = $pdo->prepare("SELECT id FROM amicalclub_teams WHERE id = ? AND coach_id = ?");
    $stmt->execute([$teamId, $coachId]);
    if (!$stmt->fetch()) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Vous n\'avez pas le droit de modifier cette équipe'
        ]);
        exit;
    }

    // Préparer les données à mettre à jour
    $updateFields = [];
    $updateValues = [];

    $allowedFields = [
        'name', 'club_name', 'category', 'level', 'location', 
        'description', 'founded', 'home_stadium', 'achievements'
    ];

    foreach ($allowedFields as $field) {
        if (isset($data[$field])) {
            $updateFields[] = "$field = ?";
            $updateValues[] = htmlspecialchars($data[$field], ENT_QUOTES, 'UTF-8');
        }
    }

    // Gérer le logo séparément (pas besoin de htmlspecialchars)
    if (isset($data['logo'])) {
        $updateFields[] = "logo = ?";
        $updateValues[] = $data['logo'];
    }

    if (empty($updateFields)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Aucune donnée à mettre à jour'
        ]);
        exit;
    }

    // Ajouter l'ID de l'équipe pour la clause WHERE
    $updateValues[] = $teamId;

    // Exécuter la mise à jour
    $sql = "UPDATE amicalclub_teams SET " . implode(', ', $updateFields) . " WHERE id = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($updateValues);

    // Récupérer l'équipe mise à jour
    $stmt = $pdo->prepare("SELECT * FROM amicalclub_teams WHERE id = ?");
    $stmt->execute([$teamId]);
    $updatedTeam = $stmt->fetch();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Équipe mise à jour avec succès',
        'data' => $updatedTeam
    ]);

} catch (\PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la mise à jour de l\'équipe',
        'error' => $e->getMessage()
    ]);
}
?>
