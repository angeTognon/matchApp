<?php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Test simple des conversations ===\n";

try {
    // Vérifier les conversations existantes
    echo "1. Vérification des conversations existantes...\n";
    
    $stmt = $pdo->query("
        SELECT 
            c.id,
            c.user1_id,
            c.user2_id,
            c.last_message_at,
            u1.name as user1_name,
            u2.name as user2_name
        FROM amicalclub_conversations c
        LEFT JOIN amicalclub_users u1 ON c.user1_id = u1.id
        LEFT JOIN amicalclub_users u2 ON c.user2_id = u2.id
        ORDER BY c.id
    ");
    
    $conversations = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "✅ Conversations trouvées: " . count($conversations) . "\n\n";
    
    foreach ($conversations as $conv) {
        echo "💬 Conversation ID: {$conv['id']}\n";
        echo "   👤 Utilisateur 1: {$conv['user1_name']} (ID: {$conv['user1_id']})\n";
        echo "   👥 Utilisateur 2: {$conv['user2_name']} (ID: {$conv['user2_id']})\n";
        echo "   ⏰ Dernier message: {$conv['last_message_at']}\n\n";
    }
    
    // Vérifier les messages
    echo "2. Vérification des messages...\n";
    
    $stmt = $pdo->query("
        SELECT 
            m.id,
            m.conversation_id,
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
        echo "   💬 Conversation: {$msg['conversation_id']}\n";
        echo "   👤 Expéditeur: {$msg['sender_name']} (ID: {$msg['sender_id']})\n";
        echo "   👥 Destinataire: {$msg['receiver_name']} (ID: {$msg['receiver_id']})\n";
        echo "   💬 Message: " . substr($msg['message'], 0, 50) . "...\n";
        echo "   ⏰ Créé: {$msg['created_at']}\n\n";
    }
    
    // Tester la requête SQL simplifiée
    echo "3. Test de la requête SQL simplifiée...\n";
    
    if (count($conversations) > 0) {
        $testUserId = $conversations[0]['user1_id']; // Prendre le premier utilisateur
        
        $sql = "
            SELECT 
                c.id as conversation_id,
                c.last_message_at,
                c.updated_at,
                
                -- Informations de l'autre utilisateur
                CASE 
                    WHEN c.user1_id = ? THEN u2.id
                    ELSE u1.id
                END as other_user_id,
                CASE 
                    WHEN c.user1_id = ? THEN u2.name
                    ELSE u1.name
                END as other_user_name,
                CASE 
                    WHEN c.user1_id = ? THEN u2.avatar
                    ELSE u1.avatar
                END as other_user_avatar,
                CASE 
                    WHEN c.user1_id = ? THEN u2.email
                    ELSE u1.email
                END as other_user_email,
                
                -- Compter les messages non lus
                (SELECT COUNT(*) FROM amicalclub_messages 
                 WHERE conversation_id = c.id 
                 AND receiver_id = ? 
                 AND is_read = FALSE) as unread_count
                
            FROM amicalclub_conversations c
            LEFT JOIN amicalclub_users u1 ON c.user1_id = u1.id
            LEFT JOIN amicalclub_users u2 ON c.user2_id = u2.id
            WHERE c.user1_id = ? OR c.user2_id = ?
            ORDER BY c.last_message_at DESC, c.updated_at DESC
        ";
        
        $testStmt = $pdo->prepare($sql);
        $testStmt->execute([$testUserId, $testUserId, $testUserId, $testUserId, $testUserId, $testUserId, $testUserId]);
        $testConversations = $testStmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo "✅ Test SQL réussi: " . count($testConversations) . " conversations trouvées\n";
        
        foreach ($testConversations as $conv) {
            echo "   💬 Conversation ID: {$conv['conversation_id']}\n";
            echo "   👤 Autre utilisateur: {$conv['other_user_name']} (ID: {$conv['other_user_id']})\n";
            echo "   📧 Email: {$conv['other_user_email']}\n";
            echo "   🔢 Messages non lus: {$conv['unread_count']}\n\n";
        }
    }
    
    echo "✅ Test simple des conversations terminé !\n";
    echo "📱 Le chat devrait maintenant fonctionner correctement.\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "📍 Fichier: " . $e->getFile() . "\n";
    echo "📍 Ligne: " . $e->getLine() . "\n";
}
?>
