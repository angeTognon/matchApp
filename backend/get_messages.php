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

// Récupérer l'ID de la conversation depuis les paramètres
$conversationId = isset($_GET['conversation_id']) ? (int)$_GET['conversation_id'] : null;
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;

if (!$conversationId) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'ID de conversation manquant'
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

    // Vérifier que l'utilisateur fait partie de cette conversation
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

    // Calculer l'offset pour la pagination
    $offset = ($page - 1) * $limit;

    // Récupérer les messages de la conversation (version simplifiée d'abord)
    $sql = "
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
            
            -- Informations de l'expéditeur
            sender.name as sender_name,
            sender.avatar as sender_avatar,
            
            -- Informations du destinataire
            receiver.name as receiver_name,
            receiver.avatar as receiver_avatar
            
        FROM amicalclub_messages m
        JOIN amicalclub_users sender ON m.sender_id = sender.id
        JOIN amicalclub_users receiver ON m.receiver_id = receiver.id
        WHERE m.conversation_id = ?
        ORDER BY m.created_at DESC
        LIMIT ? OFFSET ?
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$conversationId, $limit, $offset]);
    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Compter le total de messages pour la pagination
    $countStmt = $pdo->prepare("SELECT COUNT(*) as total FROM amicalclub_messages WHERE conversation_id = ?");
    $countStmt->execute([$conversationId]);
    $totalMessages = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];

    // Marquer les messages comme lus
    $markReadStmt = $pdo->prepare("
        UPDATE amicalclub_messages 
        SET is_read = TRUE, read_at = NOW() 
        WHERE conversation_id = ? AND receiver_id = ? AND is_read = FALSE
    ");
    $markReadStmt->execute([$conversationId, $userId]);

    // Formater les données pour l'affichage
    $formattedMessages = [];
    foreach ($messages as $msg) {
        // Pour l'instant, on met des tableaux vides pour les équipes
        // On ajoutera les équipes plus tard avec des requêtes séparées
        $senderTeams = [];
        $receiverTeams = [];
        
        $formattedMessages[] = [
            'id' => $msg['id'],
            'conversation_id' => $msg['conversation_id'],
            'sender' => [
                'id' => $msg['sender_id'],
                'name' => $msg['sender_name'],
                'avatar' => $msg['sender_avatar'],
                'teams' => $senderTeams,
            ],
            'receiver' => [
                'id' => $msg['receiver_id'],
                'name' => $msg['receiver_name'],
                'avatar' => $msg['receiver_avatar'],
                'teams' => $receiverTeams,
            ],
            'message' => $msg['message'],
            'type' => $msg['message_type'],
            'file_url' => $msg['file_url'],
            'is_read' => (bool)$msg['is_read'],
            'read_at' => $msg['read_at'],
            'created_at' => $msg['created_at'],
            'is_my_message' => $msg['sender_id'] == $userId,
        ];
    }

    // Inverser l'ordre pour avoir les plus anciens en premier
    $formattedMessages = array_reverse($formattedMessages);

    echo json_encode([
        'success' => true,
        'message' => 'Messages récupérés avec succès',
        'messages' => $formattedMessages,
        'pagination' => [
            'current_page' => $page,
            'total_messages' => (int)$totalMessages,
            'messages_per_page' => $limit,
            'total_pages' => ceil($totalMessages / $limit),
            'has_more' => $page < ceil($totalMessages / $limit)
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la récupération des messages',
        'error' => $e->getMessage()
    ]);
}
?>
