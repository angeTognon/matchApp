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

    // Récupérer les notifications non lues
    $sql = "
        SELECT 
            n.id as notification_id,
            n.conversation_id,
            n.message_id,
            n.is_read,
            n.created_at,
            
            -- Informations du message
            m.message,
            m.message_type,
            m.created_at as message_created_at,
            
            -- Informations de l'expéditeur
            sender.id as sender_id,
            sender.name as sender_name,
            sender.avatar as sender_avatar,
            
            -- Informations de l'autre utilisateur dans la conversation
            CASE 
                WHEN c.user1_id = ? THEN u2.id
                ELSE u1.id
            END as other_user_id,
            CASE 
                WHEN c.user1_id = ? THEN u2.name
                ELSE u1.name
            END as other_user_name,
            CASE 
                WHEN c.user1_id = ? THEN u2.avatar
                ELSE u1.avatar
            END as other_user_avatar
            
        FROM amicalclub_chat_notifications n
        JOIN amicalclub_messages m ON n.message_id = m.id
        JOIN amicalclub_conversations c ON n.conversation_id = c.id
        JOIN amicalclub_users sender ON m.sender_id = sender.id
        JOIN amicalclub_users u1 ON c.user1_id = u1.id
        JOIN amicalclub_users u2 ON c.user2_id = u2.id
        WHERE n.user_id = ?
        ORDER BY n.created_at DESC
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$userId, $userId, $userId, $userId]);
    $notifications = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Compter les notifications non lues
    $unreadCountStmt = $pdo->prepare("
        SELECT COUNT(*) as unread_count 
        FROM amicalclub_chat_notifications 
        WHERE user_id = ? AND is_read = FALSE
    ");
    $unreadCountStmt->execute([$userId]);
    $unreadCount = $unreadCountStmt->fetch(PDO::FETCH_ASSOC)['unread_count'];

    // Formater les données pour l'affichage
    $formattedNotifications = [];
    foreach ($notifications as $notif) {
        $formattedNotifications[] = [
            'notification_id' => $notif['notification_id'],
            'conversation_id' => $notif['conversation_id'],
            'message_id' => $notif['message_id'],
            'is_read' => (bool)$notif['is_read'],
            'created_at' => $notif['created_at'],
            'message' => [
                'id' => $notif['message_id'],
                'message' => $notif['message'],
                'type' => $notif['message_type'],
                'created_at' => $notif['message_created_at'],
            ],
            'sender' => [
                'id' => $notif['sender_id'],
                'name' => $notif['sender_name'],
                'avatar' => $notif['sender_avatar'],
            ],
            'other_user' => [
                'id' => $notif['other_user_id'],
                'name' => $notif['other_user_name'],
                'avatar' => $notif['other_user_avatar'],
            ],
        ];
    }

    echo json_encode([
        'success' => true,
        'message' => 'Notifications récupérées avec succès',
        'notifications' => $formattedNotifications,
        'unread_count' => (int)$unreadCount
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la récupération des notifications',
        'error' => $e->getMessage()
    ]);
}
?>
