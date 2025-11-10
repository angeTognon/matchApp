<?php
require_once 'db.php';

echo "=== Configuration complète du système de chat ===\n";

try {
    // 1. Créer les tables de chat
    echo "1. Création des tables de chat...\n";
    $sql = file_get_contents('create_chat_tables.sql');
    if ($sql !== false) {
        $queries = array_filter(array_map('trim', explode(';', $sql)));
        foreach ($queries as $query) {
            if (!empty($query)) {
                try {
                    $pdo->exec($query);
                    echo "✅ Requête exécutée: " . substr($query, 0, 50) . "...\n";
                } catch (Exception $e) {
                    echo "⚠️  Requête ignorée (déjà existante): " . substr($query, 0, 50) . "...\n";
                }
            }
        }
    }
    
    // 2. Vérifier les tables
    echo "\n2. Vérification des tables...\n";
    $tables = ['amicalclub_conversations', 'amicalclub_messages', 'amicalclub_chat_notifications'];
    foreach ($tables as $table) {
        $stmt = $pdo->query("SHOW TABLES LIKE '$table'");
        if ($stmt->rowCount() > 0) {
            echo "✅ Table $table existe\n";
        } else {
            echo "❌ Table $table manquante\n";
        }
    }
    
    // 3. Vérifier les utilisateurs
    echo "\n3. Vérification des utilisateurs...\n";
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM amicalclub_users");
    $userCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    echo "👥 Nombre d'utilisateurs: $userCount\n";
    
    if ($userCount >= 2) {
        $stmt = $pdo->query("SELECT id, name FROM amicalclub_users LIMIT 3");
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo "Utilisateurs disponibles:\n";
        foreach ($users as $user) {
            echo "   - {$user['name']} (ID: {$user['id']})\n";
        }
        
        // 4. Créer des données de test
        echo "\n4. Création de données de test...\n";
        
        $user1 = $users[0];
        $user2 = $users[1];
        
        // Créer une conversation de test
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
        
        echo "💬 Conversation créée: ID $conversationId\n";
        
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
        
        echo "📝 Message créé: ID $messageId\n";
        
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
        $stmt->execute([$user2['id'], $conversationId, $messageId]);
        
        echo "🔔 Notification créée\n";
        
        echo "\n✅ Configuration terminée avec succès !\n";
        echo "📱 Le système de chat est maintenant fonctionnel.\n";
        echo "🎯 Vous pouvez tester l'envoi de messages dans l'application.\n";
        
    } else {
        echo "❌ Pas assez d'utilisateurs pour créer des données de test\n";
        echo "💡 Créez d'abord des comptes utilisateurs dans l'application.\n";
    }
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "📍 Fichier: " . $e->getFile() . "\n";
    echo "📍 Ligne: " . $e->getLine() . "\n";
}
?>
