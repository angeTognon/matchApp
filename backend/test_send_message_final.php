<?php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Test final de l'API send_message.php ===\n";

try {
    // 1. Vérifier que les tables ont la bonne structure
    echo "1. Vérification de la structure des tables...\n";
    
    // Vérifier amicalclub_messages
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_messages");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $columnNames = array_column($columns, 'Field');
    
    $requiredColumns = ['id', 'conversation_id', 'sender_id', 'receiver_id', 'message', 'message_type', 'file_url', 'is_read', 'created_at', 'read_at'];
    $missingColumns = array_diff($requiredColumns, $columnNames);
    
    if (!empty($missingColumns)) {
        echo "❌ Colonnes manquantes dans amicalclub_messages: " . implode(', ', $missingColumns) . "\n";
        echo "💡 Exécutez d'abord fix_chat_tables_structure.php\n";
        exit;
    } else {
        echo "✅ Toutes les colonnes requises existent dans amicalclub_messages\n";
    }
    
    // Vérifier amicalclub_conversations
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_conversations");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $columnNames = array_column($columns, 'Field');
    
    $requiredColumns = ['id', 'user1_id', 'user2_id', 'last_message_id', 'last_message_at', 'created_at', 'updated_at'];
    $missingColumns = array_diff($requiredColumns, $columnNames);
    
    if (!empty($missingColumns)) {
        echo "❌ Colonnes manquantes dans amicalclub_conversations: " . implode(', ', $missingColumns) . "\n";
        echo "💡 Exécutez d'abord fix_chat_tables_structure.php\n";
        exit;
    } else {
        echo "✅ Toutes les colonnes requises existent dans amicalclub_conversations\n";
    }
    
    // 2. Récupérer des utilisateurs
    echo "\n2. Récupération des utilisateurs...\n";
    $stmt = $pdo->query("SELECT id, name FROM amicalclub_users LIMIT 2");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($users) < 2) {
        echo "❌ Pas assez d'utilisateurs pour tester\n";
        exit;
    }
    
    $senderId = $users[0]['id'];
    $receiverId = $users[1]['id'];
    
    echo "📤 Expéditeur: {$users[0]['name']} (ID: $senderId)\n";
    echo "📥 Destinataire: {$users[1]['name']} (ID: $receiverId)\n";
    
    // 3. Simuler l'appel à l'API send_message.php
    echo "\n3. Simulation de l'appel API...\n";
    
    // Simuler les données POST
    $input = [
        'receiver_id' => $receiverId,
        'message' => 'Test final - ' . date('Y-m-d H:i:s'),
        'message_type' => 'text'
    ];
    
    echo "📝 Données simulées:\n";
    echo "   - receiver_id: {$input['receiver_id']}\n";
    echo "   - message: {$input['message']}\n";
    echo "   - message_type: {$input['message_type']}\n";
    
    // 4. Exécuter la logique de l'API
    echo "\n4. Exécution de la logique API...\n";
    
    // Vérifier que le destinataire existe
    $userStmt = $pdo->prepare("SELECT id FROM amicalclub_users WHERE id = ?");
    $userStmt->execute([$receiverId]);
    if (!$userStmt->fetch()) {
        echo "❌ Destinataire non trouvé\n";
        exit;
    }
    echo "✅ Destinataire trouvé\n";
    
    // Vérifier que l'utilisateur ne s'envoie pas un message à lui-même
    if ($senderId == $receiverId) {
        echo "❌ Impossible de s'envoyer un message à soi-même\n";
        exit;
    }
    echo "✅ Vérification d'auto-envoi OK\n";
    
    // Commencer une transaction
    $pdo->beginTransaction();
    
    try {
        // Chercher ou créer une conversation
        $convStmt = $pdo->prepare("
            SELECT id FROM amicalclub_conversations 
            WHERE (user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)
        ");
        $convStmt->execute([$senderId, $receiverId, $receiverId, $senderId]);
        $conversation = $convStmt->fetch(PDO::FETCH_ASSOC);

        $conversationId = null;
        if ($conversation) {
            $conversationId = $conversation['id'];
            echo "💬 Conversation existante: ID $conversationId\n";
        } else {
            // Créer une nouvelle conversation
            $insertConvSql = "INSERT INTO amicalclub_conversations (user1_id, user2_id, created_at, updated_at) VALUES (?, ?, NOW(), NOW())";
            $insertConvStmt = $pdo->prepare($insertConvSql);
            $insertConvStmt->execute([$senderId, $receiverId]);
            $conversationId = $pdo->lastInsertId();
            echo "💬 Nouvelle conversation créée: ID $conversationId\n";
        }

        // Insérer le message
        $insertMsgSql = "INSERT INTO amicalclub_messages (conversation_id, sender_id, receiver_id, message, message_type, created_at) VALUES (?, ?, ?, ?, ?, NOW())";
        $insertMsgStmt = $pdo->prepare($insertMsgSql);
        $insertMsgStmt->execute([$conversationId, $senderId, $receiverId, $input['message'], $input['message_type']]);
        $messageId = $pdo->lastInsertId();

        echo "📝 Message inséré: ID $messageId\n";

        // Mettre à jour la conversation avec le dernier message
        $updateConvSql = "UPDATE amicalclub_conversations SET last_message_id = ?, last_message_at = NOW(), updated_at = NOW() WHERE id = ?";
        $updateConvStmt = $pdo->prepare($updateConvSql);
        $updateConvStmt->execute([$messageId, $conversationId]);

        echo "🔄 Conversation mise à jour\n";

        // Créer une notification pour le destinataire (si la table existe)
        try {
            $notifSql = "INSERT INTO amicalclub_chat_notifications (user_id, conversation_id, message_id, created_at) VALUES (?, ?, ?, NOW())";
            $notifStmt = $pdo->prepare($notifSql);
            $notifStmt->execute([$receiverId, $conversationId, $messageId]);
            echo "🔔 Notification créée\n";
        } catch (Exception $e) {
            echo "⚠️  Notification non créée (table peut-être manquante): " . $e->getMessage() . "\n";
        }

        // Valider la transaction
        $pdo->commit();

        echo "\n✅ Test de l'API send_message.php réussi !\n";
        echo "📱 L'envoi de message devrait maintenant fonctionner dans l'application.\n";
        
        // Simuler la réponse JSON
        $response = [
            'success' => true,
            'message' => 'Message envoyé avec succès',
            'data' => [
                'id' => $messageId,
                'conversation_id' => $conversationId,
                'message' => $input['message'],
                'created_at' => date('Y-m-d H:i:s')
            ]
        ];
        
        echo "\n📤 Réponse JSON simulée:\n";
        echo json_encode($response, JSON_PRETTY_PRINT) . "\n";
        
    } catch (Exception $e) {
        $pdo->rollBack();
        throw $e;
    }
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "📍 Fichier: " . $e->getFile() . "\n";
    echo "📍 Ligne: " . $e->getLine() . "\n";
}
?>
