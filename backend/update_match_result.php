<?php
require_once 'db.php';
require_once 'jwt_utils.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $token = get_bearer_token();
    if (!$token || !($payload = verify_jwt($token))) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Non autorisé: Token invalide ou manquant.']);
        exit;
    }

    $userId = $payload['user_id'];
    $data = json_decode(file_get_contents('php://input'), true);

    error_log("update_match_result.php: Données reçues: " . json_encode($data));

    // Validation
    if (!isset($data['match_id']) || empty($data['match_id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID du match manquant.']);
        exit;
    }

    if (!isset($data['score']) || empty($data['score'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Score manquant.']);
        exit;
    }

    if (!isset($data['result']) || !in_array($data['result'], ['win', 'draw', 'loss'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Résultat invalide. Utilisez "win", "draw" ou "loss".']);
        exit;
    }

    try {
        // Vérifier que le match appartient à l'utilisateur
        $stmt = $pdo->prepare("
            SELECT m.*, t.coach_id
            FROM amicalclub_matches m
            JOIN amicalclub_teams t ON m.team_id = t.id
            WHERE m.id = ?
        ");
        $stmt->execute([$data['match_id']]);
        $match = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$match) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Match non trouvé.']);
            exit;
        }

        // Vérifier que l'utilisateur est le propriétaire
        if ($match['coach_id'] != $userId) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Vous n\'êtes pas autorisé à modifier ce match.']);
            exit;
        }

        // Mettre à jour le match
        $stmt = $pdo->prepare("
            UPDATE amicalclub_matches 
            SET score = ?, 
                result = ?,
                notes = ?,
                updated_at = NOW()
            WHERE id = ?
        ");
        
        $notes = isset($data['notes']) ? htmlspecialchars($data['notes'], ENT_QUOTES, 'UTF-8') : $match['notes'];
        $stmt->execute([
            $data['score'],
            $data['result'],
            $notes,
            $data['match_id']
        ]);

        // Récupérer le match mis à jour
        $stmt = $pdo->prepare("
            SELECT 
                m.*,
                t.name as team_name,
                t.club_name,
                t.logo as team_logo,
                t.category,
                t.level,
                DATE(m.match_date) as date,
                TIME(m.match_date) as time
            FROM amicalclub_matches m
            JOIN amicalclub_teams t ON m.team_id = t.id
            WHERE m.id = ?
        ");
        $stmt->execute([$data['match_id']]);
        $updatedMatch = $stmt->fetch(PDO::FETCH_ASSOC);

        echo json_encode([
            'success' => true,
            'message' => 'Score et résultat mis à jour avec succès.',
            'data' => [
                'match' => $updatedMatch
            ]
        ]);

    } catch (\PDOException $e) {
        error_log("update_match_result.php: Erreur PDO: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
}
?>

