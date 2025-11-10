<?php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Test des APIs de chat ===\n";

try {
    // Vérifier que les tables existent
    $tables = ['amicalclub_conversations', 'amicalclub_messages', 'amicalclub_chat_notifications'];
    foreach ($tables as $table) {
        $stmt = $pdo->query("SHOW TABLES LIKE '$table'");
        if ($stmt->rowCount() > 0) {
            echo "✅ Table $table existe\n";
        } else {
            echo "❌ Table $table manquante\n";
        }
    }
    
    // Vérifier les utilisateurs
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM amicalclub_users");
    $userCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    echo "\n👥 Nombre d'utilisateurs: $userCount\n";
    
    if ($userCount >= 2) {
        $stmt = $pdo->query("SELECT id, name FROM amicalclub_users LIMIT 2");
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo "Utilisateurs pour test:\n";
        foreach ($users as $user) {
            echo "- ID: {$user['id']}, Nom: {$user['name']}\n";
        }
        
        // Tester la création d'une conversation
        $user1 = $users[0];
        $user2 = $users[1];
        
        echo "\n🧪 Test de création de conversation...\n";
        
        // Créer une conversation
        $stmt = $pdo->prepare("
            INSERT INTO amicalclub_conversations (user1_id, user2_id, created_at, updated_at) 
            VALUES (?, ?, NOW(), NOW())
            ON DUPLICATE KEY UPDATE updated_at = NOW()
        ");
        $stmt->execute([$user1['id'], $user2['id']]);
        $conversationId = $pdo->lastInsertId();
        
        if ($conversationId == 0) {
            // Récupérer l'ID existant
            $stmt = $pdo->prepare("
                SELECT id FROM amicalclub_conversations 
                WHERE (user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)
            ");
            $stmt->execute([$user1['id'], $user2['id'], $user2['id'], $user1['id']]);
            $conversation = $stmt->fetch(PDO::FETCH_ASSOC);
            $conversationId = $conversation['id'];
        }
        
        echo "✅ Conversation ID: $conversationId\n";
        
        // Ajouter un message de test
        $stmt = $pdo->prepare("
            INSERT INTO amicalclub_messages 
            (conversation_id, sender_id, receiver_id, message, message_type, created_at) 
            VALUES (?, ?, ?, ?, 'text', NOW())
        ");
        $stmt->execute([
            $conversationId, 
            $user1['id'], 
            $user2['id'], 
            "Message de test - " . date('Y-m-d H:i:s')
        ]);
        $messageId = $pdo->lastInsertId();
        
        echo "✅ Message ID: $messageId\n";
        
        // Mettre à jour la conversation
        $stmt = $pdo->prepare("
            UPDATE amicalclub_conversations 
            SET last_message_id = ?, last_message_at = NOW(), updated_at = NOW() 
            WHERE id = ?
        ");
        $stmt->execute([$messageId, $conversationId]);
        
        echo "✅ Conversation mise à jour\n";
        
        // Créer une notification
        $stmt = $pdo->prepare("
            INSERT INTO amicalclub_chat_notifications 
            (user_id, conversation_id, message_id, created_at) 
            VALUES (?, ?, ?, NOW())
        ");
        $stmt->execute([$user2['id'], $conversationId, $messageId]);
        
        echo "✅ Notification créée\n";
        
        echo "\n🎉 Test réussi ! Le système de chat est fonctionnel.\n";
        echo "📱 Vous pouvez maintenant tester l'application Flutter.\n";
        
    } else {
        echo "❌ Pas assez d'utilisateurs pour tester\n";
    }
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
