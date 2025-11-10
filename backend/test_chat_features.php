<?php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Test des fonctionnalités du chat ===\n";

try {
    // 1. Vérifier les utilisateurs avec avatars
    echo "1. Vérification des utilisateurs avec avatars...\n";
    
    $stmt = $pdo->query("
        SELECT 
            id,
            name,
            avatar,
            email
        FROM amicalclub_users
        ORDER BY id
    ");
    
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "✅ Utilisateurs trouvés: " . count($users) . "\n\n";
    
    foreach ($users as $user) {
        echo "👤 Utilisateur ID: {$user['id']}\n";
        echo "   📝 Nom: {$user['name']}\n";
        echo "   📧 Email: {$user['email']}\n";
        echo "   🖼️  Avatar: " . ($user['avatar'] ? $user['avatar'] : 'Aucun') . "\n\n";
    }
    
    // 2. Tester l'API get_conversations
    echo "2. Test de l'API get_conversations...\n";
    
    if (count($users) > 0) {
        $testUserId = $users[0]['id']; // Prendre le premier utilisateur
        
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
        
        echo "✅ Conversations trouvées: " . count($testConversations) . "\n";
        
        $totalUnread = 0;
        foreach ($testConversations as $conv) {
            $totalUnread += (int)$conv['unread_count'];
            echo "   💬 Conversation ID: {$conv['conversation_id']}\n";
            echo "   👤 Autre utilisateur: {$conv['other_user_name']} (ID: {$conv['other_user_id']})\n";
            echo "   🖼️  Avatar: " . ($conv['other_user_avatar'] ? $conv['other_user_avatar'] : 'Aucun') . "\n";
            echo "   🔢 Messages non lus: {$conv['unread_count']}\n\n";
        }
        
        echo "🔢 Total messages non lus: $totalUnread\n\n";
    }
    
    // 3. Vérifier les messages
    echo "3. Vérification des messages...\n";
    
    $stmt = $pdo->query("
        SELECT 
            m.id,
            m.conversation_id,
            m.sender_id,
            m.receiver_id,
            m.message,
            m.is_read,
            m.created_at,
            s.name as sender_name,
            s.avatar as sender_avatar,
            r.name as receiver_name,
            r.avatar as receiver_avatar
        FROM amicalclub_messages m
        JOIN amicalclub_users s ON m.sender_id = s.id
        JOIN amicalclub_users r ON m.receiver_id = r.id
        ORDER BY m.created_at DESC
        LIMIT 3
    ");
    
    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "✅ Messages trouvés: " . count($messages) . "\n\n";
    
    foreach ($messages as $msg) {
        echo "📝 Message ID: {$msg['id']}\n";
        echo "   💬 Conversation: {$msg['conversation_id']}\n";
        echo "   👤 Expéditeur: {$msg['sender_name']} (Avatar: " . ($msg['sender_avatar'] ? 'Oui' : 'Non') . ")\n";
        echo "   👥 Destinataire: {$msg['receiver_name']} (Avatar: " . ($msg['receiver_avatar'] ? 'Oui' : 'Non') . ")\n";
        echo "   💬 Message: " . substr($msg['message'], 0, 50) . "...\n";
        echo "   📖 Lu: " . ($msg['is_read'] ? 'Oui' : 'Non') . "\n\n";
    }
    
    // 4. Instructions pour tester
    echo "4. Instructions pour tester les nouvelles fonctionnalités:\n";
    echo "✅ Fonctionnalités ajoutées:\n";
    echo "   - Zone de recherche dans la page Messages\n";
    echo "   - Filtrage des conversations par nom ou contenu de message\n";
    echo "   - Affichage des avatars utilisateurs dans le chat\n";
    echo "   - Badges de messages non lus corrigés\n";
    echo "   - Fallback vers les initiales si pas d'avatar\n";
    
    echo "\n✅ Test des fonctionnalités du chat terminé !\n";
    echo "📱 Testez maintenant:\n";
    echo "   - La recherche dans la page Messages\n";
    echo "   - L'affichage des avatars dans les conversations\n";
    echo "   - Les badges de messages non lus dans la navigation\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "📍 Fichier: " . $e->getFile() . "\n";
    echo "📍 Ligne: " . $e->getLine() . "\n";
}
?>
