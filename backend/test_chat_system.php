<?php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Test du système de chat ===\n";

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
    
    // Vérifier qu'il y a des utilisateurs
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM amicalclub_users");
    $userCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    echo "👥 Nombre d'utilisateurs: $userCount\n";
    
    if ($userCount >= 2) {
        // Récupérer 2 utilisateurs pour tester
        $stmt = $pdo->query("SELECT id, name FROM amicalclub_users LIMIT 2");
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        if (count($users) >= 2) {
            $user1 = $users[0];
            $user2 = $users[1];
            
            echo "🧪 Test avec utilisateurs: {$user1['name']} (ID: {$user1['id']}) et {$user2['name']} (ID: {$user2['id']})\n";
            
            // Créer une conversation de test
            $stmt = $pdo->prepare("
                INSERT INTO amicalclub_conversations (user1_id, user2_id, created_at, updated_at) 
                VALUES (?, ?, NOW(), NOW())
                ON DUPLICATE KEY UPDATE updated_at = NOW()
            ");
            $stmt->execute([$user1['id'], $user2['id']]);
            $conversationId = $pdo->lastInsertId();
            
            if ($conversationId == 0) {
                // Récupérer l'ID de la conversation existante
                $stmt = $pdo->prepare("
                    SELECT id FROM amicalclub_conversations 
                    WHERE (user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)
                ");
                $stmt->execute([$user1['id'], $user2['id'], $user2['id'], $user1['id']]);
                $conversation = $stmt->fetch(PDO::FETCH_ASSOC);
                $conversationId = $conversation['id'];
            }
            
            echo "💬 Conversation créée/récupérée: ID $conversationId\n";
            
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
                "Message de test du système de chat - " . date('Y-m-d H:i:s')
            ]);
            $messageId = $pdo->lastInsertId();
            
            echo "📝 Message de test créé: ID $messageId\n";
            
            // Mettre à jour la conversation avec le dernier message
            $stmt = $pdo->prepare("
                UPDATE amicalclub_conversations 
                SET last_message_id = ?, last_message_at = NOW(), updated_at = NOW() 
                WHERE id = ?
            ");
            $stmt->execute([$messageId, $conversationId]);
            
            echo "🔄 Conversation mise à jour avec le dernier message\n";
            
            // Créer une notification
            $stmt = $pdo->prepare("
                INSERT INTO amicalclub_chat_notifications 
                (user_id, conversation_id, message_id, created_at) 
                VALUES (?, ?, ?, NOW())
            ");
            $stmt->execute([$user2['id'], $conversationId, $messageId]);
            
            echo "🔔 Notification créée pour {$user2['name']}\n";
            
            echo "\n✅ Test du système de chat réussi !\n";
            echo "📊 Résumé:\n";
            echo "   - Conversation ID: $conversationId\n";
            echo "   - Message ID: $messageId\n";
            echo "   - Expéditeur: {$user1['name']}\n";
            echo "   - Destinataire: {$user2['name']}\n";
            
        } else {
            echo "❌ Pas assez d'utilisateurs pour tester\n";
        }
    } else {
        echo "❌ Pas assez d'utilisateurs dans la base de données (minimum 2 requis)\n";
    }
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
