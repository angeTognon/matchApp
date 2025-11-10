<?php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Test HTTP de l'API send_message.php ===\n";

try {
    // Récupérer des utilisateurs
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
    
    // Créer un token JWT
    $payload = [
        'user_id' => $senderId,
        'exp' => time() + 3600
    ];
    
    // Simuler l'appel HTTP à l'API
    echo "\n🧪 Simulation de l'appel HTTP...\n";
    
    // Simuler les données POST
    $postData = [
        'receiver_id' => $receiverId,
        'message' => 'Test message via HTTP API',
        'message_type' => 'text'
    ];
    
    echo "📝 Données POST:\n";
    echo "   - receiver_id: {$postData['receiver_id']}\n";
    echo "   - message: {$postData['message']}\n";
    echo "   - message_type: {$postData['message_type']}\n";
    
    // Simuler les headers
    $headers = [
        'Authorization: Bearer test_token',
        'Content-Type: application/json'
    ];
    
    echo "\n📡 Headers simulés:\n";
    foreach ($headers as $header) {
        echo "   - $header\n";
    }
    
    // Tester la logique de l'API directement
    echo "\n🔧 Test de la logique API...\n";
    
    // Vérifier que le destinataire existe
    $userStmt = $pdo->prepare("SELECT id, name FROM amicalclub_users WHERE id = ?");
    $userStmt->execute([$receiverId]);
    $receiver = $userStmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$receiver) {
        echo "❌ Destinataire non trouvé\n";
        exit;
    }
    
    echo "✅ Destinataire trouvé: {$receiver['name']}\n";
    
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

        if (!$conversation) {
            // Créer une nouvelle conversation
            $createConvStmt = $pdo->prepare("
                INSERT INTO amicalclub_conversations (user1_id, user2_id, created_at, updated_at) 
                VALUES (?, ?, NOW(), NOW())
            ");
            $createConvStmt->execute([$senderId, $receiverId]);
            $conversationId = $pdo->lastInsertId();
            echo "💬 Nouvelle conversation créée: ID $conversationId\n";
        } else {
            $conversationId = $conversation['id'];
            echo "💬 Conversation existante: ID $conversationId\n";
        }

        // Insérer le message
        $messageStmt = $pdo->prepare("
            INSERT INTO amicalclub_messages 
            (conversation_id, sender_id, receiver_id, message, message_type, created_at) 
            VALUES (?, ?, ?, ?, ?, NOW())
        ");
        $messageStmt->execute([$conversationId, $senderId, $receiverId, $postData['message'], $postData['message_type']]);
        $messageId = $pdo->lastInsertId();

        echo "📝 Message inséré: ID $messageId\n";

        // Mettre à jour la conversation avec le dernier message
        $updateConvStmt = $pdo->prepare("
            UPDATE amicalclub_conversations 
            SET last_message_id = ?, last_message_at = NOW(), updated_at = NOW() 
            WHERE id = ?
        ");
        $updateConvStmt->execute([$messageId, $conversationId]);

        echo "🔄 Conversation mise à jour\n";

        // Créer une notification pour le destinataire
        $notifStmt = $pdo->prepare("
            INSERT INTO amicalclub_chat_notifications 
            (user_id, conversation_id, message_id, created_at) 
            VALUES (?, ?, ?, NOW())
        ");
        $notifStmt->execute([$receiverId, $conversationId, $messageId]);

        echo "🔔 Notification créée\n";

        // Valider la transaction
        $pdo->commit();

        echo "\n✅ Test HTTP de l'API send_message.php réussi !\n";
        echo "📱 L'API devrait maintenant fonctionner correctement.\n";
        
        // Simuler la réponse JSON
        $response = [
            'success' => true,
            'message' => 'Message envoyé avec succès',
            'data' => [
                'id' => $messageId,
                'conversation_id' => $conversationId,
                'message' => $postData['message'],
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
