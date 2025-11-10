<?php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Debug de l'API send_message.php ===\n";

try {
    // 1. Vérifier que les tables existent
    echo "1. Vérification des tables...\n";
    $tables = ['amicalclub_conversations', 'amicalclub_messages', 'amicalclub_chat_notifications'];
    foreach ($tables as $table) {
        $stmt = $pdo->query("SHOW TABLES LIKE '$table'");
        if ($stmt->rowCount() > 0) {
            echo "✅ Table $table existe\n";
        } else {
            echo "❌ Table $table manquante\n";
        }
    }
    
    // 2. Vérifier les utilisateurs
    echo "\n2. Vérification des utilisateurs...\n";
    $stmt = $pdo->query("SELECT id, name FROM amicalclub_users LIMIT 3");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($users) < 2) {
        echo "❌ Pas assez d'utilisateurs pour tester\n";
        exit;
    }
    
    echo "✅ Utilisateurs trouvés: " . count($users) . "\n";
    foreach ($users as $user) {
        echo "   - {$user['name']} (ID: {$user['id']})\n";
    }
    
    // 3. Tester l'envoi de message
    echo "\n3. Test d'envoi de message...\n";
    
    $senderId = $users[0]['id'];
    $receiverId = $users[1]['id'];
    $message = "Message de test - " . date('Y-m-d H:i:s');
    
    echo "📤 Expéditeur: {$users[0]['name']} (ID: $senderId)\n";
    echo "📥 Destinataire: {$users[1]['name']} (ID: $receiverId)\n";
    echo "💬 Message: $message\n";
    
    // Créer une conversation
    $stmt = $pdo->prepare("
        INSERT INTO amicalclub_conversations (user1_id, user2_id, created_at, updated_at) 
        VALUES (?, ?, NOW(), NOW())
        ON DUPLICATE KEY UPDATE updated_at = NOW()
    ");
    $stmt->execute([$senderId, $receiverId]);
    $conversationId = $pdo->lastInsertId();
    
    if ($conversationId == 0) {
        // Récupérer l'ID existant
        $stmt = $pdo->prepare("
            SELECT id FROM amicalclub_conversations 
            WHERE (user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)
        ");
        $stmt->execute([$senderId, $receiverId, $receiverId, $senderId]);
        $conversation = $stmt->fetch(PDO::FETCH_ASSOC);
        $conversationId = $conversation['id'];
    }
    
    echo "💬 Conversation ID: $conversationId\n";
    
    // Insérer le message
    $stmt = $pdo->prepare("
        INSERT INTO amicalclub_messages 
        (conversation_id, sender_id, receiver_id, message, message_type, created_at) 
        VALUES (?, ?, ?, ?, 'text', NOW())
    ");
    $stmt->execute([$conversationId, $senderId, $receiverId, $message]);
    $messageId = $pdo->lastInsertId();
    
    echo "📝 Message ID: $messageId\n";
    
    // Mettre à jour la conversation
    $stmt = $pdo->prepare("
        UPDATE amicalclub_conversations 
        SET last_message_id = ?, last_message_at = NOW(), updated_at = NOW() 
        WHERE id = ?
    ");
    $stmt->execute([$messageId, $conversationId]);
    
    echo "🔄 Conversation mise à jour\n";
    
    // Créer une notification
    $stmt = $pdo->prepare("
        INSERT INTO amicalclub_chat_notifications 
        (user_id, conversation_id, message_id, created_at) 
        VALUES (?, ?, ?, NOW())
    ");
    $stmt->execute([$receiverId, $conversationId, $messageId]);
    
    echo "🔔 Notification créée\n";
    
    echo "\n✅ Test d'envoi de message réussi !\n";
    echo "📱 L'API send_message.php devrait maintenant fonctionner.\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "📍 Fichier: " . $e->getFile() . "\n";
    echo "📍 Ligne: " . $e->getLine() . "\n";
}
?>
