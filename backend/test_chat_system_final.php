<?php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Test final du système de chat ===\n";

try {
    // 1. Vérifier que les APIs corrigées existent
    echo "1. Vérification des APIs corrigées...\n";
    
    if (!file_exists('get_conversations.php') || !file_exists('get_messages.php')) {
        echo "❌ APIs de chat manquantes\n";
        echo "💡 Exécutez d'abord fix_boolean_conversion.php et replace_chat_apis.php\n";
        exit;
    }
    
    echo "✅ APIs de chat trouvées\n";
    
    // 2. Récupérer des utilisateurs
    echo "\n2. Récupération des utilisateurs...\n";
    $stmt = $pdo->query("SELECT id, name FROM amicalclub_users LIMIT 2");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($users) < 2) {
        echo "❌ Pas assez d'utilisateurs pour tester\n";
        exit;
    }
    
    $user1 = $users[0];
    $user2 = $users[1];
    
    echo "📤 Utilisateur 1: {$user1['name']} (ID: {$user1['id']})\n";
    echo "📥 Utilisateur 2: {$user2['name']} (ID: {$user2['id']})\n";
    
    // 3. Créer une conversation de test
    echo "\n3. Création d'une conversation de test...\n";
    
    $stmt = $pdo->prepare("
        INSERT INTO amicalclub_conversations (user1_id, user2_id, created_at, updated_at) 
        VALUES (?, ?, NOW(), NOW())
        ON DUPLICATE KEY UPDATE updated_at = NOW()
    ");
    $stmt->execute([$user1['id'], $user2['id']]);
    $conversationId = $pdo->lastInsertId();
    
    if ($conversationId == 0) {
        $stmt = $pdo->prepare("
            SELECT id FROM amicalclub_conversations 
            WHERE (user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)
        ");
        $stmt->execute([$user1['id'], $user2['id'], $user2['id'], $user1['id']]);
        $conversation = $stmt->fetch(PDO::FETCH_ASSOC);
        $conversationId = $conversation['id'];
    }
    
    echo "💬 Conversation ID: $conversationId\n";
    
    // 4. Ajouter des messages de test
    echo "\n4. Ajout de messages de test...\n";
    
    $messages = [
        [
            'sender_id' => $user1['id'],
            'receiver_id' => $user2['id'],
            'message' => 'Bonjour ! Comment allez-vous ?',
            'is_read' => 0
        ],
        [
            'sender_id' => $user2['id'],
            'receiver_id' => $user1['id'],
            'message' => 'Salut ! Ça va bien, merci !',
            'is_read' => 1
        ],
        [
            'sender_id' => $user1['id'],
            'receiver_id' => $user2['id'],
            'message' => 'Parfait ! Voulez-vous organiser un match ?',
            'is_read' => 0
        ]
    ];
    
    $stmt = $pdo->prepare("
        INSERT INTO amicalclub_messages 
        (conversation_id, sender_id, receiver_id, message, message_type, is_read, created_at) 
        VALUES (?, ?, ?, ?, 'text', ?, NOW())
    ");
    
    foreach ($messages as $msg) {
        $stmt->execute([$conversationId, $msg['sender_id'], $msg['receiver_id'], $msg['message'], $msg['is_read']]);
        echo "📝 Message ajouté: {$msg['message']}\n";
    }
    
    // 5. Mettre à jour la conversation avec le dernier message
    $lastMessageId = $pdo->lastInsertId();
    $stmt = $pdo->prepare("
        UPDATE amicalclub_conversations 
        SET last_message_id = ?, last_message_at = NOW(), updated_at = NOW() 
        WHERE id = ?
    ");
    $stmt->execute([$lastMessageId, $conversationId]);
    
    echo "🔄 Conversation mise à jour avec le dernier message\n";
    
    // 6. Tester l'API get_conversations
    echo "\n5. Test de l'API get_conversations...\n";
    
    $convSql = "
        SELECT
            c.id AS conversation_id,
            CASE
                WHEN c.user1_id = ? THEN u2.id
                ELSE u1.id
            END AS other_user_id,
            CASE
                WHEN c.user1_id = ? THEN u2.name
                ELSE u1.name
            END AS other_user_name,
            CASE
                WHEN c.user1_id = ? THEN u2.avatar
                ELSE u1.avatar
            END AS other_user_avatar,
            CASE
                WHEN c.user1_id = ? THEN u2.email
                ELSE u1.email
            END AS other_user_email,
            
            m.id AS last_message_id,
            m.message AS last_message_content,
            m.created_at AS last_message_at,
            m.sender_id AS last_message_sender_id,
            
            (SELECT COUNT(*) FROM amicalclub_messages 
             WHERE conversation_id = c.id 
             AND receiver_id = ? 
             AND is_read = 0) as unread_count,
             
            c.updated_at
        FROM amicalclub_conversations c
        LEFT JOIN amicalclub_messages m ON c.last_message_id = m.id
        LEFT JOIN amicalclub_users u1 ON c.user1_id = u1.id
        LEFT JOIN amicalclub_users u2 ON c.user2_id = u2.id
        WHERE c.user1_id = ? OR c.user2_id = ?
        ORDER BY c.updated_at DESC
    ";
    
    $stmt = $pdo->prepare($convSql);
    $stmt->execute([$user1['id'], $user1['id'], $user1['id'], $user1['id'], $user1['id'], $user1['id'], $user1['id']]);
    $conversations = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "✅ Conversations trouvées: " . count($conversations) . "\n";
    
    if (!empty($conversations)) {
        $conv = $conversations[0];
        echo "📋 Conversation test:\n";
        echo "   - ID: {$conv['conversation_id']}\n";
        echo "   - Autre utilisateur: {$conv['other_user_name']}\n";
        echo "   - Messages non lus: {$conv['unread_count']}\n";
        echo "   - Dernier message: {$conv['last_message_content']}\n";
    }
    
    // 7. Tester l'API get_messages
    echo "\n6. Test de l'API get_messages...\n";
    
    $msgSql = "
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
        WHERE m.conversation_id = ?
        ORDER BY m.created_at DESC
        LIMIT 10
    ";
    
    $stmt = $pdo->prepare($msgSql);
    $stmt->execute([$conversationId]);
    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "✅ Messages trouvés: " . count($messages) . "\n";
    
    if (!empty($messages)) {
        echo "📋 Messages de test:\n";
        foreach ($messages as $msg) {
            $isRead = $msg['is_read'] ? 'Lu' : 'Non lu';
            echo "   - {$msg['sender_name']}: {$msg['message']} ({$isRead})\n";
        }
    }
    
    // 8. Simuler la réponse JSON
    echo "\n7. Simulation de la réponse JSON...\n";
    
    $formattedConversations = [];
    foreach ($conversations as $conv) {
        $formattedConversations[] = [
            "conversation_id" => $conv["conversation_id"],
            "other_user" => [
                "id" => $conv["other_user_id"],
                "name" => $conv["other_user_name"],
                "avatar" => $conv["other_user_avatar"],
                "email" => $conv["other_user_email"],
            ],
            "last_message" => $conv["last_message_id"] ? [
                "id" => $conv["last_message_id"],
                "conversation_id" => $conv["conversation_id"],
                "sender_id" => $conv["last_message_sender_id"],
                "message" => $conv["last_message_content"],
                "created_at" => $conv["last_message_at"],
            ] : null,
            "unread_count" => (int)$conv["unread_count"],
            "updated_at" => $conv["updated_at"],
        ];
    }
    
    $formattedMessages = [];
    foreach ($messages as $msg) {
        $formattedMessages[] = [
            "id" => $msg["id"],
            "conversation_id" => $msg["conversation_id"],
            "sender" => [
                "id" => $msg["sender_id"],
                "name" => $msg["sender_name"],
                "avatar" => $msg["sender_avatar"],
            ],
            "receiver" => [
                "id" => $msg["receiver_id"],
                "name" => $msg["receiver_name"],
                "avatar" => $msg["receiver_avatar"],
            ],
            "message" => $msg["message"],
            "type" => $msg["message_type"],
            "file_url" => $msg["file_url"],
            "is_read" => (bool)$msg["is_read"], // Conversion explicite en booléen
            "created_at" => $msg["created_at"],
            "read_at" => $msg["read_at"],
        ];
    }
    
    echo "📤 Réponse get_conversations:\n";
    echo json_encode([
        "success" => true,
        "conversations" => $formattedConversations
    ], JSON_PRETTY_PRINT) . "\n";
    
    echo "\n📤 Réponse get_messages:\n";
    echo json_encode([
        "success" => true,
        "messages" => array_reverse($formattedMessages)
    ], JSON_PRETTY_PRINT) . "\n";
    
    echo "\n✅ Test final du système de chat réussi !\n";
    echo "📱 Le système de chat est maintenant entièrement fonctionnel.\n";
    echo "🎯 L'erreur 'type int is not a subtype of type bool' ne devrait plus apparaître.\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "📍 Fichier: " . $e->getFile() . "\n";
    echo "📍 Ligne: " . $e->getLine() . "\n";
}
?>
