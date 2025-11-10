<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'jwt_utils.php';
require_once 'db.php';

try {
    // Récupérer le token
    $headers = getallheaders();
    $token = null;
    
    if (isset($headers['Authorization'])) {
        $authHeader = $headers['Authorization'];
        if (preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
            $token = $matches[1];
        }
    }
    
    if (!$token) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Token manquant']);
        exit;
    }
    
    // Vérifier le token
    $payload = verify_jwt($token);
    if (!$payload) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Token invalide']);
        exit;
    }
    
    $coach_id = $payload['user_id'];
    
    // Récupérer les données
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        echo json_encode(['success' => false, 'message' => 'Données invalides']);
        exit;
    }
    
    $match_id = $input['match_id'] ?? null;
    $location = $input['location'] ?? '';
    $notes = $input['notes'] ?? '';
    $facilities = $input['facilities'] ?? [];
    
    if (!$match_id) {
        echo json_encode(['success' => false, 'message' => 'ID du match manquant']);
        exit;
    }
    
    // Vérifier que le match appartient au coach
    $pdo = get_db_connection();
    
    $stmt = $pdo->prepare("
        SELECT m.id, t.coach_id 
        FROM amicalclub_matches m 
        JOIN amicalclub_teams t ON m.team_id = t.id 
        WHERE m.id = ? AND t.coach_id = ?
    ");
    $stmt->execute([$match_id, $coach_id]);
    $match = $stmt->fetch();
    
    if (!$match) {
        echo json_encode(['success' => false, 'message' => 'Match non trouvé ou non autorisé']);
        exit;
    }
    
    // Mettre à jour le match
    $facilities_json = json_encode($facilities);
    
    $stmt = $pdo->prepare("
        UPDATE amicalclub_matches 
        SET location = ?, notes = ?, facilities = ?, updated_at = CURRENT_TIMESTAMP 
        WHERE id = ?
    ");
    
    $result = $stmt->execute([$location, $notes, $facilities_json, $match_id]);
    
    if ($result) {
        echo json_encode([
            'success' => true,
            'message' => 'Match mis à jour avec succès',
            'data' => [
                'id' => $match_id,
                'location' => $location,
                'notes' => $notes,
                'facilities' => $facilities
            ]
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour']);
    }
    
} catch (Exception $e) {
    error_log("Erreur simple_update_match: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur serveur: ' . $e->getMessage()
    ]);
}
?>
