<?php
require_once 'db.php';

echo "=== Configuration rapide du chat ===\n";

try {
    // 1. Créer les tables si elles n'existent pas
    echo "1. Création des tables...\n";
    $sql = file_get_contents('create_chat_tables.sql');
    if ($sql !== false) {
        $queries = array_filter(array_map('trim', explode(';', $sql)));
        foreach ($queries as $query) {
            if (!empty($query)) {
                $pdo->exec($query);
            }
        }
        echo "✅ Tables créées\n";
    }
    
    // 2. Vérifier les utilisateurs
    echo "\n2. Vérification des utilisateurs...\n";
    $stmt = $pdo->query("SELECT id, name FROM amicalclub_users LIMIT 3");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($users) < 2) {
        echo "❌ Pas assez d'utilisateurs. Créez d'abord des comptes utilisateurs.\n";
        exit;
    }
    
    echo "✅ Utilisateurs trouvés: " . count($users) . "\n";
    foreach ($users as $user) {
        echo "   - {$user['name']} (ID: {$user['id']})\n";
    }
    
    // 3. Créer des conversations de test
    echo "\n3. Création de conversations de test...\n";
    
    $testConversations = [
        [
            'user1' => $users[0],
            'user2' => $users[1],
            'messages' => [
                'Bonjour ! Nous sommes intéressés par votre proposition de match amical.',
                'Parfait ! Quel jour vous conviendrait le mieux ?',
                'Parfait pour dimanche à 15h !'
            ]
        ]
    ];
    
    if (count($users) >= 3) {
        $testConversations[] = [
            'user1' => $users[0],
            'user2' => $users[2],
            'messages' => [
                'Le terrain sera-t-il disponible ?'
            ]
        ];
    }
    
    foreach ($testConversations as $conv) {
        // Créer la conversation
        $stmt = $pdo->prepare("
            INSERT INTO amicalclub_conversations (user1_id, user2_id, created_at, updated_at) 
            VALUES (?, ?, NOW(), NOW())
            ON DUPLICATE KEY UPDATE updated_at = NOW()
        ");
        $stmt->execute([$conv['user1']['id'], $conv['user2']['id']]);
        $conversationId = $pdo->lastInsertId();
        
        if ($conversationId == 0) {
            $stmt = $pdo->prepare("
                SELECT id FROM amicalclub_conversations 
                WHERE (user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)
            ");
            $stmt->execute([$conv['user1']['id'], $conv['user2']['id'], $conv['user2']['id'], $conv['user1']['id']]);
            $conversation = $stmt->fetch(PDO::FETCH_ASSOC);
            $conversationId = $conversation['id'];
        }
        
        echo "💬 Conversation: {$conv['user1']['name']} ↔ {$conv['user2']['name']} (ID: $conversationId)\n";
        
        // Ajouter les messages
        $lastMessageId = null;
        $senderId = $conv['user1']['id'];
        $receiverId = $conv['user2']['id'];
        
        foreach ($conv['messages'] as $messageText) {
            $stmt = $pdo->prepare("
                INSERT INTO amicalclub_messages 
                (conversation_id, sender_id, receiver_id, message, message_type, created_at) 
                VALUES (?, ?, ?, ?, 'text', NOW())
            ");
            $stmt->execute([$conversationId, $senderId, $receiverId, $messageText]);
            $lastMessageId = $pdo->lastInsertId();
            
            echo "   📝 \"$messageText\"\n";
            
            // Alterner l'expéditeur pour simuler une vraie conversation
            $temp = $senderId;
            $senderId = $receiverId;
            $receiverId = $temp;
        }
        
        // Mettre à jour la conversation avec le dernier message
        if ($lastMessageId) {
            $stmt = $pdo->prepare("
                UPDATE amicalclub_conversations 
                SET last_message_id = ?, last_message_at = NOW(), updated_at = NOW() 
                WHERE id = ?
            ");
            $stmt->execute([$lastMessageId, $conversationId]);
        }
        
        // Créer des notifications
        $stmt = $pdo->prepare("
            INSERT INTO amicalclub_chat_notifications 
            (user_id, conversation_id, message_id, created_at) 
            VALUES (?, ?, ?, NOW())
        ");
        $stmt->execute([$conv['user2']['id'], $conversationId, $lastMessageId]);
    }
    
    echo "\n✅ Configuration terminée !\n";
    echo "📱 Vous pouvez maintenant tester l'application Flutter.\n";
    echo "🔍 Allez dans Profil → Messages pour voir les conversations.\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
