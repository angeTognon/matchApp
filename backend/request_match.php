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

    error_log("request_match.php: Données reçues: " . json_encode($data));

    // Validation des champs obligatoires
    if (!isset($data['match_id']) || empty($data['match_id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID du match manquant.']);
        exit;
    }

    if (!isset($data['team_id']) || empty($data['team_id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID de l\'équipe manquant.']);
        exit;
    }

    try {
        // Vérifier que le match existe et est disponible
        $stmt = $pdo->prepare("
            SELECT m.*, t.name as team_name, t.coach_id, u.name as coach_name
            FROM amicalclub_matches m
            JOIN amicalclub_teams t ON m.team_id = t.id
            JOIN amicalclub_users u ON t.coach_id = u.id
            WHERE m.id = ? AND m.result = 'pending'
        ");
        $stmt->execute([$data['match_id']]);
        $match = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$match) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Match non trouvé ou non disponible.']);
            exit;
        }

        // Vérifier que l'équipe appartient à l'utilisateur
        $stmt = $pdo->prepare("SELECT id, name FROM amicalclub_teams WHERE id = ? AND coach_id = ?");
        $stmt->execute([$data['team_id'], $userId]);
        $team = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$team) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Équipe non trouvée ou non autorisée.']);
            exit;
        }

        // Vérifier que l'utilisateur ne fait pas une demande pour son propre match
        if ($match['coach_id'] == $userId) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Vous ne pouvez pas faire une demande pour votre propre match.']);
            exit;
        }

        // Vérifier qu'il n'y a pas déjà une demande en cours
        $stmt = $pdo->prepare("
            SELECT id FROM amicalclub_match_requests 
            WHERE match_id = ? AND requesting_team_id = ? AND status IN ('pending', 'accepted')
        ");
        $stmt->execute([$data['match_id'], $data['team_id']]);
        $existingRequest = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($existingRequest) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Une demande a déjà été envoyée pour ce match.']);
            exit;
        }

        // Créer la demande de match
        $stmt = $pdo->prepare("
            INSERT INTO amicalclub_match_requests (
                match_id, requesting_team_id, message, status, created_at
            ) VALUES (?, ?, ?, 'pending', NOW())
        ");

        $message = isset($data['message']) ? htmlspecialchars($data['message'], ENT_QUOTES, 'UTF-8') : '';
        $stmt->execute([$data['match_id'], $data['team_id'], $message]);

        $requestId = $pdo->lastInsertId();

        $status = 'pending';
        $message = 'Demande envoyée avec succès. Le coach recevra votre demande et pourra y répondre.';

        // Récupérer les détails de la demande créée
        $stmt = $pdo->prepare("
            SELECT 
                mr.*,
                t.name as requesting_team_name,
                t.club_name as requesting_club_name,
                u.name as requesting_coach_name
            FROM amicalclub_match_requests mr
            JOIN amicalclub_teams t ON mr.requesting_team_id = t.id
            JOIN amicalclub_users u ON t.coach_id = u.id
            WHERE mr.id = ?
        ");
        $stmt->execute([$requestId]);
        $request = $stmt->fetch(PDO::FETCH_ASSOC);

        echo json_encode([
            'success' => true,
            'message' => $message,
            'data' => [
                'request' => $request,
                'status' => $status
            ]
        ]);

    } catch (\PDOException $e) {
        error_log("request_match.php: Erreur PDO: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la création de la demande: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
}
?>
