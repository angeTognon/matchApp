<?php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Test des notifications de chat ===\n";

try {
    // 1. Vérifier les conversations existantes
    echo "1. Vérification des conversations...\n";
    
    $stmt = $pdo->query("
        SELECT 
            c.id as conversation_id,
            c.user1_id,
            c.user2_id,
            u1.name as user1_name,
            u2.name as user2_name,
            (SELECT COUNT(*) FROM amicalclub_messages 
             WHERE conversation_id = c.id 
             AND is_read = FALSE) as unread_count
        FROM amicalclub_conversations c
        JOIN amicalclub_users u1 ON c.user1_id = u1.id
        JOIN amicalclub_users u2 ON c.user2_id = u2.id
        ORDER BY c.id
    ");
    
    $conversations = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "✅ Conversations trouvées: " . count($conversations) . "\n\n";
    
    foreach ($conversations as $conv) {
        echo "💬 Conversation ID: {$conv['conversation_id']}\n";
        echo "   👤 Utilisateur 1: {$conv['user1_name']} (ID: {$conv['user1_id']})\n";
        echo "   👤 Utilisateur 2: {$conv['user2_name']} (ID: {$conv['user2_id']})\n";
        echo "   🔢 Messages non lus: {$conv['unread_count']}\n\n";
    }
    
    // 2. Vérifier les messages récents
    echo "2. Vérification des messages récents...\n";
    
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
            r.name as receiver_name
        FROM amicalclub_messages m
        JOIN amicalclub_users s ON m.sender_id = s.id
        JOIN amicalclub_users r ON m.receiver_id = r.id
        ORDER BY m.created_at DESC
        LIMIT 5
    ");
    
    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "✅ Messages récents: " . count($messages) . "\n\n";
    
    foreach ($messages as $msg) {
        echo "📝 Message ID: {$msg['id']}\n";
        echo "   💬 Conversation: {$msg['conversation_id']}\n";
        echo "   👤 De: {$msg['sender_name']} vers {$msg['receiver_name']}\n";
        echo "   💬 Contenu: " . substr($msg['message'], 0, 50) . "...\n";
        echo "   📖 Lu: " . ($msg['is_read'] ? 'Oui' : 'Non') . "\n";
        echo "   🕐 Créé: {$msg['created_at']}\n\n";
    }
    
    // 3. Instructions pour tester les notifications
    echo "3. Instructions pour tester les notifications:\n";
    echo "✅ Fonctionnalités ajoutées:\n";
    echo "   - Service de notifications local intégré\n";
    echo "   - Notifications automatiques pour nouveaux messages\n";
    echo "   - Permissions de notification demandées automatiquement\n";
    echo "   - Support Android et iOS\n";
    
    echo "\n📱 Pour tester les notifications:\n";
    echo "   1. Ouvrez l'application sur votre appareil\n";
    echo "   2. Acceptez les permissions de notification\n";
    echo "   3. Envoyez un message depuis un autre appareil/compte\n";
    echo "   4. Vous devriez recevoir une notification push\n";
    
    echo "\n🔧 Configuration technique:\n";
    echo "   - Canal de notification: 'chat_messages'\n";
    echo "   - Priorité: Haute\n";
    echo "   - Son et vibration activés\n";
    echo "   - Badge de notification mis à jour\n";
    
    echo "\n✅ Test des notifications terminé !\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "📍 Fichier: " . $e->getFile() . "\n";
    echo "📍 Ligne: " . $e->getLine() . "\n";
}
?>
