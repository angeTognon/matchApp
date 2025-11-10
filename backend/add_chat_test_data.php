<?php
require_once 'db.php';

try {
    echo "=== Ajout de données de test pour le chat ===\n";
    
    // Vérifier que les tables existent
    $tables = ['amicalclub_conversations', 'amicalclub_messages', 'amicalclub_chat_notifications'];
    foreach ($tables as $table) {
        $stmt = $pdo->query("SHOW TABLES LIKE '$table'");
        if ($stmt->rowCount() == 0) {
            echo "❌ Table $table manquante. Création des tables d'abord...\n";
            
            // Lire et exécuter le script SQL
            $sql = file_get_contents('create_chat_tables.sql');
            if ($sql !== false) {
                $queries = array_filter(array_map('trim', explode(';', $sql)));
                foreach ($queries as $query) {
                    if (!empty($query)) {
                        $pdo->exec($query);
                    }
                }
                echo "✅ Tables créées\n";
            } else {
                echo "❌ Impossible de lire create_chat_tables.sql\n";
                exit;
            }
            break;
        }
    }
    
    // Récupérer les utilisateurs existants
    $stmt = $pdo->query("SELECT id, name FROM amicalclub_users LIMIT 5");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($users) < 2) {
        echo "❌ Pas assez d'utilisateurs pour créer des conversations de test\n";
        exit;
    }
    
    echo "👥 Utilisateurs trouvés: " . count($users) . "\n";
    
    // Créer des conversations de test
    $conversations = [
        [
            'user1_id' => $users[0]['id'],
            'user2_id' => $users[1]['id'],
            'messages' => [
                [
                    'sender_id' => $users[0]['id'],
                    'receiver_id' => $users[1]['id'],
                    'message' => 'Bonjour ! Nous sommes intéressés par votre proposition de match amical.',
                    'created_at' => date('Y-m-d H:i:s', strtotime('-2 hours'))
                ],
                [
                    'sender_id' => $users[1]['id'],
                    'receiver_id' => $users[0]['id'],
                    'message' => 'Parfait ! Quel jour vous conviendrait le mieux ?',
                    'created_at' => date('Y-m-d H:i:s', strtotime('-1 hour 30 minutes'))
                ],
                [
                    'sender_id' => $users[0]['id'],
                    'receiver_id' => $users[1]['id'],
                    'message' => 'Parfait pour dimanche à 15h !',
                    'created_at' => date('Y-m-d H:i:s', strtotime('-30 minutes'))
                ]
            ]
        ]
    ];
    
    // Ajouter une deuxième conversation si on a assez d'utilisateurs
    if (count($users) >= 3) {
        $conversations[] = [
            'user1_id' => $users[0]['id'],
            'user2_id' => $users[2]['id'],
            'messages' => [
                [
                    'sender_id' => $users[2]['id'],
                    'receiver_id' => $users[0]['id'],
                    'message' => 'Le terrain sera-t-il disponible ?',
                    'created_at' => date('Y-m-d H:i:s', strtotime('-1 day'))
                ]
            ]
        ];
    }
    
    // Ajouter une troisième conversation si on a assez d'utilisateurs
    if (count($users) >= 4) {
        $conversations[] = [
            'user1_id' => $users[1]['id'],
            'user2_id' => $users[3]['id'],
            'messages' => [
                [
                    'sender_id' => $users[3]['id'],
                    'receiver_id' => $users[1]['id'],
                    'message' => 'Merci pour le match, à bientôt !',
                    'created_at' => date('Y-m-d H:i:s', strtotime('-3 days'))
                ]
            ]
        ];
    }
    
    foreach ($conversations as $conv) {
        // Créer la conversation
        $stmt = $pdo->prepare("
            INSERT INTO amicalclub_conversations (user1_id, user2_id, created_at, updated_at) 
            VALUES (?, ?, NOW(), NOW())
            ON DUPLICATE KEY UPDATE updated_at = NOW()
        ");
        $stmt->execute([$conv['user1_id'], $conv['user2_id']]);
        $conversationId = $pdo->lastInsertId();
        
        if ($conversationId == 0) {
            // Récupérer l'ID de la conversation existante
            $stmt = $pdo->prepare("
                SELECT id FROM amicalclub_conversations 
                WHERE (user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)
            ");
            $stmt->execute([$conv['user1_id'], $conv['user2_id'], $conv['user2_id'], $conv['user1_id']]);
            $conversation = $stmt->fetch(PDO::FETCH_ASSOC);
            $conversationId = $conversation['id'];
        }
        
        echo "💬 Conversation créée/récupérée: ID $conversationId\n";
        
        // Ajouter les messages
        $lastMessageId = null;
        foreach ($conv['messages'] as $msg) {
            $stmt = $pdo->prepare("
                INSERT INTO amicalclub_messages 
                (conversation_id, sender_id, receiver_id, message, message_type, created_at) 
                VALUES (?, ?, ?, ?, 'text', ?)
            ");
            $stmt->execute([
                $conversationId, 
                $msg['sender_id'], 
                $msg['receiver_id'], 
                $msg['message'],
                $msg['created_at']
            ]);
            $lastMessageId = $pdo->lastInsertId();
            echo "📝 Message ajouté: \"{$msg['message']}\"\n";
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
        
        // Créer des notifications pour les messages non lus
        foreach ($conv['messages'] as $msg) {
            if ($msg['sender_id'] != $conv['user1_id']) {
                $stmt = $pdo->prepare("
                    INSERT INTO amicalclub_chat_notifications 
                    (user_id, conversation_id, message_id, created_at) 
                    VALUES (?, ?, ?, ?)
                    ON DUPLICATE KEY UPDATE created_at = ?
                ");
                $stmt->execute([$conv['user1_id'], $conversationId, $lastMessageId, $msg['created_at'], $msg['created_at']]);
            }
        }
    }
    
    echo "\n✅ Données de test ajoutées avec succès !\n";
    echo "📊 Résumé:\n";
    echo "   - Conversations créées: " . count($conversations) . "\n";
    echo "   - Messages ajoutés: " . array_sum(array_map(function($c) { return count($c['messages']); }, $conversations)) . "\n";
    echo "   - Notifications créées\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
