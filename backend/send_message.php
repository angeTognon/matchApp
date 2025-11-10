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

$receiverId = isset($input['receiver_id']) ? (int)$input['receiver_id'] : null;
$message = isset($input['message']) ? trim($input['message']) : '';
$messageType = isset($input['message_type']) ? $input['message_type'] : 'text';
$fileUrl = isset($input['file_url']) ? $input['file_url'] : null;

if (!$receiverId || empty($message)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Destinataire et message requis'
    ]);
    exit;
}

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

    $senderId = $payload['user_id'];

    // Vérifier que l'utilisateur ne s'envoie pas un message à lui-même
    if ($senderId == $receiverId) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Impossible de s\'envoyer un message à soi-même'
        ]);
        exit;
    }

    // Vérifier que le destinataire existe
    $userStmt = $pdo->prepare("SELECT id, name FROM amicalclub_users WHERE id = ?");
    $userStmt->execute([$receiverId]);
    $receiver = $userStmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$receiver) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Destinataire non trouvé'
        ]);
        exit;
    }

    // Commencer une transaction
    $pdo->beginTransaction();

    try {
        // Chercher ou créer une conversation
        $convStmt = $pdo->prepare("
            SELECT id FROM amicalclub_conversations 
            WHERE (user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)
        ");
        $convStmt->execute([$senderId, $receiverId, $receiverId, $senderId]);
        $conversation = $convStmt->fetch(PDO::FETCH_ASSOC);

        if (!$conversation) {
            // Créer une nouvelle conversation
            $createConvStmt = $pdo->prepare("
                INSERT INTO amicalclub_conversations (user1_id, user2_id, created_at, updated_at) 
                VALUES (?, ?, NOW(), NOW())
            ");
            $createConvStmt->execute([$senderId, $receiverId]);
            $conversationId = $pdo->lastInsertId();
        } else {
            $conversationId = $conversation['id'];
        }

        // Insérer le message
        $messageStmt = $pdo->prepare("
            INSERT INTO amicalclub_messages 
            (conversation_id, sender_id, receiver_id, message, message_type, file_url, created_at) 
            VALUES (?, ?, ?, ?, ?, ?, NOW())
        ");
        $messageStmt->execute([$conversationId, $senderId, $receiverId, $message, $messageType, $fileUrl]);
        $messageId = $pdo->lastInsertId();

        // Mettre à jour la conversation avec le dernier message
        $updateConvStmt = $pdo->prepare("
            UPDATE amicalclub_conversations 
            SET last_message_id = ?, last_message_at = NOW(), updated_at = NOW() 
            WHERE id = ?
        ");
        $updateConvStmt->execute([$messageId, $conversationId]);

        // Créer une notification pour le destinataire
        $notifStmt = $pdo->prepare("
            INSERT INTO amicalclub_chat_notifications 
            (user_id, conversation_id, message_id, created_at) 
            VALUES (?, ?, ?, NOW())
        ");
        $notifStmt->execute([$receiverId, $conversationId, $messageId]);

        // Valider la transaction
        $pdo->commit();

        // Récupérer les informations complètes du message
        $messageInfoStmt = $pdo->prepare("
            SELECT 
                m.id,
                m.conversation_id,
                m.sender_id,
                m.receiver_id,
                m.message,
                m.message_type,
                m.file_url,
                m.is_read,
                m.read_at,
                m.created_at,
                sender.name as sender_name,
                sender.avatar as sender_avatar,
                receiver.name as receiver_name,
                receiver.avatar as receiver_avatar
            FROM amicalclub_messages m
            JOIN amicalclub_users sender ON m.sender_id = sender.id
            JOIN amicalclub_users receiver ON m.receiver_id = receiver.id
            WHERE m.id = ?
        ");
        $messageInfoStmt->execute([$messageId]);
        $messageInfo = $messageInfoStmt->fetch(PDO::FETCH_ASSOC);

        echo json_encode([
            'success' => true,
            'message' => 'Message envoyé avec succès',
            'data' => [
                'id' => $messageInfo['id'],
                'conversation_id' => $messageInfo['conversation_id'],
                'sender' => [
                    'id' => $messageInfo['sender_id'],
                    'name' => $messageInfo['sender_name'],
                    'avatar' => $messageInfo['sender_avatar'],
                ],
                'receiver' => [
                    'id' => $messageInfo['receiver_id'],
                    'name' => $messageInfo['receiver_name'],
                    'avatar' => $messageInfo['receiver_avatar'],
                ],
                'message' => $messageInfo['message'],
                'type' => $messageInfo['message_type'],
                'file_url' => $messageInfo['file_url'],
                'is_read' => (bool)$messageInfo['is_read'],
                'read_at' => $messageInfo['read_at'],
                'created_at' => $messageInfo['created_at'],
                'is_my_message' => true,
            ]
        ]);

    } catch (Exception $e) {
        $pdo->rollBack();
        throw $e;
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de l\'envoi du message',
        'error' => $e->getMessage()
    ]);
}
?>
