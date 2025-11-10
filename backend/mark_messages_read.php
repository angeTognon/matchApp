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

// Récupérer les données POST
$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Données manquantes'
    ]);
    exit;
}

$conversationId = isset($input['conversation_id']) ? (int)$input['conversation_id'] : null;
$messageIds = isset($input['message_ids']) ? $input['message_ids'] : [];

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

    $userId = $payload['user_id'];

    // Vérifier que l'utilisateur fait partie de cette conversation
    if ($conversationId) {
        $checkStmt = $pdo->prepare("
            SELECT id FROM amicalclub_conversations 
            WHERE id = ? AND (user1_id = ? OR user2_id = ?)
        ");
        $checkStmt->execute([$conversationId, $userId, $userId]);
        
        if (!$checkStmt->fetch()) {
            http_response_code(403);
            echo json_encode([
                'success' => false,
                'message' => 'Accès non autorisé à cette conversation'
            ]);
            exit;
        }
    }

    $updatedCount = 0;

    if ($conversationId && empty($messageIds)) {
        // Marquer tous les messages de la conversation comme lus
        $stmt = $pdo->prepare("
            UPDATE amicalclub_messages 
            SET is_read = TRUE, read_at = NOW() 
            WHERE conversation_id = ? AND receiver_id = ? AND is_read = FALSE
        ");
        $stmt->execute([$conversationId, $userId]);
        $updatedCount = $stmt->rowCount();

        // Marquer les notifications comme lues
        $notifStmt = $pdo->prepare("
            UPDATE amicalclub_chat_notifications 
            SET is_read = TRUE 
            WHERE user_id = ? AND conversation_id = ? AND is_read = FALSE
        ");
        $notifStmt->execute([$userId, $conversationId]);

    } elseif (!empty($messageIds)) {
        // Marquer des messages spécifiques comme lus
        $placeholders = str_repeat('?,', count($messageIds) - 1) . '?';
        $stmt = $pdo->prepare("
            UPDATE amicalclub_messages 
            SET is_read = TRUE, read_at = NOW() 
            WHERE id IN ($placeholders) AND receiver_id = ? AND is_read = FALSE
        ");
        $params = array_merge($messageIds, [$userId]);
        $stmt->execute($params);
        $updatedCount = $stmt->rowCount();

        // Marquer les notifications correspondantes comme lues
        $notifStmt = $pdo->prepare("
            UPDATE amicalclub_chat_notifications 
            SET is_read = TRUE 
            WHERE user_id = ? AND message_id IN ($placeholders) AND is_read = FALSE
        ");
        $notifParams = array_merge([$userId], $messageIds);
        $notifStmt->execute($notifParams);
    }

    echo json_encode([
        'success' => true,
        'message' => 'Messages marqués comme lus',
        'updated_count' => $updatedCount
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la mise à jour des messages',
        'error' => $e->getMessage()
    ]);
}
?>
