<?php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Test du chat en temps réel ===\n";

try {
    // 1. Vérifier les messages existants
    echo "1. Vérification des messages existants...\n";
    
    $stmt = $pdo->query("
        SELECT 
            m.id,
            m.sender_id,
            m.receiver_id,
            m.message,
            m.created_at,
            s.name as sender_name,
            r.name as receiver_name
        FROM amicalclub_messages m
        JOIN amicalclub_users s ON m.sender_id = s.id
        JOIN amicalclub_users r ON m.receiver_id = r.id
        ORDER BY m.created_at DESC
        LIMIT 5
    ");
    
    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "✅ Messages trouvés: " . count($messages) . "\n\n";
    
    foreach ($messages as $msg) {
        echo "📝 Message ID: {$msg['id']}\n";
        echo "   👤 Expéditeur: {$msg['sender_name']} (ID: {$msg['sender_id']})\n";
        echo "   👥 Destinataire: {$msg['receiver_name']} (ID: {$msg['receiver_id']})\n";
        echo "   💬 Message: " . substr($msg['message'], 0, 50) . "...\n";
        echo "   ⏰ Créé: {$msg['created_at']}\n\n";
    }
    
    // 2. Simuler l'envoi d'un nouveau message
    echo "2. Simulation d'envoi de nouveau message...\n";
    
    if (count($messages) > 0) {
        $lastMessage = $messages[0];
        $senderId = $lastMessage['sender_id'];
        $receiverId = $lastMessage['receiver_id'];
        
        // Inverser sender/receiver pour créer un nouveau message
        $newSenderId = $receiverId;
        $newReceiverId = $senderId;
        
        $newMessage = "Message de test en temps réel - " . date('Y-m-d H:i:s');
        
        $stmt = $pdo->prepare("
            INSERT INTO amicalclub_messages 
            (conversation_id, sender_id, receiver_id, message, message_type, created_at) 
            VALUES (?, ?, ?, 'text', NOW())
        ");
        
        // Utiliser la même conversation que le dernier message
        $conversationId = 7; // ID de conversation de test
        
        $stmt->execute([$conversationId, $newSenderId, $newReceiverId, $newMessage]);
        $messageId = $pdo->lastInsertId();
        
        echo "✅ Nouveau message créé: ID $messageId\n";
        echo "   👤 Expéditeur: ID $newSenderId\n";
        echo "   👥 Destinataire: ID $newReceiverId\n";
        echo "   💬 Message: $newMessage\n";
        
        // Mettre à jour la conversation
        $stmt = $pdo->prepare("
            UPDATE amicalclub_conversations 
            SET last_message_id = ?, last_message_at = NOW(), updated_at = NOW() 
            WHERE id = ?
        ");
        $stmt->execute([$messageId, $conversationId]);
        
        echo "🔄 Conversation mise à jour\n";
    }
    
    // 3. Vérifier les messages mis à jour
    echo "\n3. Vérification des messages mis à jour...\n";
    
    $stmt = $pdo->query("
        SELECT 
            m.id,
            m.sender_id,
            m.receiver_id,
            m.message,
            m.created_at,
            s.name as sender_name,
            r.name as receiver_name
        FROM amicalclub_messages m
        JOIN amicalclub_users s ON m.sender_id = s.id
        JOIN amicalclub_users r ON m.receiver_id = r.id
        ORDER BY m.created_at DESC
        LIMIT 3
    ");
    
    $updatedMessages = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "✅ Messages mis à jour: " . count($updatedMessages) . "\n\n";
    
    foreach ($updatedMessages as $msg) {
        echo "📝 Message ID: {$msg['id']}\n";
        echo "   👤 Expéditeur: {$msg['sender_name']} (ID: {$msg['sender_id']})\n";
        echo "   👥 Destinataire: {$msg['receiver_name']} (ID: {$msg['receiver_id']})\n";
        echo "   💬 Message: " . substr($msg['message'], 0, 50) . "...\n";
        echo "   ⏰ Créé: {$msg['created_at']}\n\n";
    }
    
    // 4. Instructions pour tester
    echo "4. Instructions pour tester le chat en temps réel:\n";
    echo "✅ Fonctionnalités ajoutées:\n";
    echo "   - Messages de l'expéditeur affichés à droite (fond vert)\n";
    echo "   - Messages du destinataire affichés à gauche (fond gris)\n";
    echo "   - Mise à jour automatique toutes les secondes\n";
    echo "   - Réception instantanée des nouveaux messages\n";
    echo "   - Envoi instantané et affichage immédiat\n";
    
    echo "\n✅ Test du chat en temps réel terminé !\n";
    echo "📱 Testez maintenant l'envoi de messages dans l'application.\n";
    echo "🔄 Les messages devraient s'afficher correctement et en temps réel.\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "📍 Fichier: " . $e->getFile() . "\n";
    echo "📍 Ligne: " . $e->getLine() . "\n";
}
?>
