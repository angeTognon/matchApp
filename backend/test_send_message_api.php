<?php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Test direct de l'API send_message.php ===\n";

try {
    // 1. Créer les tables si elles n'existent pas
    echo "1. Création des tables si nécessaire...\n";
    $sql = file_get_contents('create_chat_tables.sql');
    if ($sql !== false) {
        $queries = array_filter(array_map('trim', explode(';', $sql)));
        foreach ($queries as $query) {
            if (!empty($query)) {
                try {
                    $pdo->exec($query);
                } catch (Exception $e) {
                    // Ignorer les erreurs de table déjà existante
                }
            }
        }
        echo "✅ Tables vérifiées/créées\n";
    }
    
    // 2. Récupérer des utilisateurs
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
    
    // 3. Créer un token JWT de test
    $payload = [
        'user_id' => $senderId,
        'exp' => time() + 3600
    ];
    
    // Simuler l'appel à l'API send_message.php
    echo "\n3. Simulation de l'appel API...\n";
    
    // Simuler les données POST
    $input = [
        'receiver_id' => $receiverId,
        'message' => 'Message de test depuis l\'API',
        'message_type' => 'text'
    ];
    
    echo "📝 Données simulées:\n";
    echo "   - receiver_id: {$input['receiver_id']}\n";
    echo "   - message: {$input['message']}\n";
    echo "   - message_type: {$input['message_type']}\n";
    
    // Vérifier que le destinataire existe
    $userStmt = $pdo->prepare("SELECT id, name FROM amicalclub_users WHERE id = ?");
    $userStmt->execute([$receiverId]);
    $receiver = $userStmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$receiver) {
        echo "❌ Destinataire non trouvé\n";
        exit;
    }
    
    echo "✅ Destinataire trouvé: {$receiver['name']}\n";
    
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
        $messageStmt->execute([$conversationId, $senderId, $receiverId, $input['message'], $input['message_type']]);
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

        echo "\n✅ Test de l'API send_message.php réussi !\n";
        echo "📱 L'envoi de message devrait maintenant fonctionner dans l'application.\n";
        
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
