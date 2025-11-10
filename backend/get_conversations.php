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

    // Récupérer toutes les conversations de l'utilisateur (version simplifiée d'abord)
    $sql = "
        SELECT 
            c.id as conversation_id,
            c.last_message_at,
            c.updated_at,
            
            -- Informations du dernier message
            m.id as last_message_id,
            m.message as last_message,
            m.message_type as last_message_type,
            m.created_at as last_message_created_at,
            m.is_read as last_message_is_read,
            
            -- Informations de l'autre utilisateur
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
            END as other_user_avatar,
            CASE 
                WHEN c.user1_id = ? THEN u2.email
                ELSE u1.email
            END as other_user_email,
            
            -- Informations de l'expéditeur du dernier message
            sender.id as last_message_sender_id,
            sender.name as last_message_sender_name,
            
            -- Compter les messages non lus
            (SELECT COUNT(*) FROM amicalclub_messages 
             WHERE conversation_id = c.id 
             AND receiver_id = ? 
             AND is_read = FALSE) as unread_count
            
        FROM amicalclub_conversations c
        LEFT JOIN amicalclub_messages m ON c.last_message_id = m.id
        LEFT JOIN amicalclub_users u1 ON c.user1_id = u1.id
        LEFT JOIN amicalclub_users u2 ON c.user2_id = u2.id
        LEFT JOIN amicalclub_users sender ON m.sender_id = sender.id
        WHERE c.user1_id = ? OR c.user2_id = ?
        ORDER BY c.last_message_at DESC, c.updated_at DESC
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$userId, $userId, $userId, $userId, $userId, $userId, $userId]);
    $conversations = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Formater les données pour l'affichage
    $formattedConversations = [];
    foreach ($conversations as $conv) {
        // Pour l'instant, on met un tableau vide pour les équipes
        // On ajoutera les équipes plus tard avec une requête séparée
        $teams = [];
        
        $formattedConversations[] = [
            'conversation_id' => $conv['conversation_id'],
            'other_user' => [
                'id' => $conv['other_user_id'],
                'name' => $conv['other_user_name'],
                'avatar' => $conv['other_user_avatar'],
                'email' => $conv['other_user_email'],
                'teams' => $teams,
            ],
            'last_message' => [
                'id' => $conv['last_message_id'],
                'message' => $conv['last_message'],
                'type' => $conv['last_message_type'],
                'created_at' => $conv['last_message_created_at'],
                'is_read' => $conv['last_message_is_read'],
                'sender_id' => $conv['last_message_sender_id'],
                'sender_name' => $conv['last_message_sender_name'],
            ],
            'unread_count' => (int)$conv['unread_count'],
            'last_message_at' => $conv['last_message_at'],
            'updated_at' => $conv['updated_at'],
        ];
    }

    echo json_encode([
        'success' => true,
        'message' => 'Conversations récupérées avec succès',
        'conversations' => $formattedConversations
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la récupération des conversations',
        'error' => $e->getMessage()
    ]);
}
?>
