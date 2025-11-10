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

    error_log("respond_match_request.php: Données reçues: " . json_encode($data));

    // Validation
    if (!isset($data['request_id']) || empty($data['request_id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID de la demande manquant.']);
        exit;
    }

    if (!isset($data['action']) || !in_array($data['action'], ['accept', 'reject'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Action invalide. Utilisez "accept" ou "reject".']);
        exit;
    }

    try {
        // Récupérer la demande et vérifier que l'utilisateur est le propriétaire du match
        $stmt = $pdo->prepare("
            SELECT 
                mr.*,
                m.team_id,
                m.result as match_status,
                t.coach_id
            FROM amicalclub_match_requests mr
            JOIN amicalclub_matches m ON mr.match_id = m.id
            JOIN amicalclub_teams t ON m.team_id = t.id
            WHERE mr.id = ?
        ");
        $stmt->execute([$data['request_id']]);
        $request = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$request) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Demande non trouvée.']);
            exit;
        }

        // Vérifier que l'utilisateur est bien le propriétaire du match
        if ($request['coach_id'] != $userId) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Vous n\'êtes pas autorisé à répondre à cette demande.']);
            exit;
        }

        // Vérifier que la demande est en attente
        if ($request['status'] != 'pending') {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Cette demande a déjà été traitée.']);
            exit;
        }

        $pdo->beginTransaction();

        if ($data['action'] === 'accept') {
            // Accepter la demande
            $stmt = $pdo->prepare("
                UPDATE amicalclub_match_requests 
                SET status = 'accepted', responded_at = NOW() 
                WHERE id = ?
            ");
            $stmt->execute([$data['request_id']]);

            // Mettre à jour le match avec l'équipe adverse confirmée
            $stmt = $pdo->prepare("
                UPDATE amicalclub_matches 
                SET result = 'confirmed', opponent = (SELECT name FROM amicalclub_teams WHERE id = ?)
                WHERE id = ?
            ");
            $stmt->execute([$request['requesting_team_id'], $request['match_id']]);
            // Rejeter toutes les autres demandes pour ce match
            $stmt = $pdo->prepare("
                UPDATE amicalclub_match_requests 
                SET status = 'rejected', responded_at = NOW() 
                WHERE match_id = ? AND id != ? AND status = 'pending'
            ");
            $stmt->execute([$request['match_id'], $data['request_id']]);

            $message = 'Demande acceptée avec succès. Le match est maintenant confirmé.';
        } else {
            // Rejeter la demande
            $stmt = $pdo->prepare("
                UPDATE amicalclub_match_requests 
                SET status = 'rejected', responded_at = NOW() 
                WHERE id = ?
            ");
            $stmt->execute([$data['request_id']]);

            $message = 'Demande rejetée.';
        }

        $pdo->commit();

        // Récupérer la demande mise à jour
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
        $stmt->execute([$data['request_id']]);
        $updatedRequest = $stmt->fetch(PDO::FETCH_ASSOC);

        echo json_encode([
            'success' => true,
            'message' => $message,
            'data' => [
                'request' => $updatedRequest,
                'action' => $data['action']
            ]
        ]);

    } catch (\PDOException $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        error_log("respond_match_request.php: Erreur PDO: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors du traitement de la demande: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
}
?>

