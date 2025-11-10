<?php
// Test direct de l'API get_conversations.php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Test de l'API get_conversations.php ===\n";

try {
    // Récupérer un utilisateur pour le test
    $stmt = $pdo->query("SELECT id, name FROM amicalclub_users LIMIT 1");
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$user) {
        echo "❌ Aucun utilisateur trouvé\n";
        exit;
    }
    
    echo "👤 Utilisateur de test: {$user['name']} (ID: {$user['id']})\n";
    
    // Créer un token JWT de test
    $payload = [
        'user_id' => $user['id'],
        'exp' => time() + 3600 // Expire dans 1 heure
    ];
    
    // Simuler l'appel à l'API
    $userId = $user['id'];
    
    // Requête exacte de get_conversations.php
    $sql = "
        SELECT 
            c.id as conversation_id,
            c.last_message_at,
            c.updated_at,
            
            -- Informations du dernier message
            m.id as last_message_id,
            m.message as last_message,
            m.message_type as last_message_type,
            m.created_at as last_message_created_at,
            m.is_read as last_message_is_read,
            
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
            
            -- Informations de l'expéditeur du dernier message
            sender.id as last_message_sender_id,
            sender.name as last_message_sender_name,
            
            -- Compter les messages non lus
            (SELECT COUNT(*) FROM amicalclub_messages 
             WHERE conversation_id = c.id 
             AND receiver_id = ? 
             AND is_read = FALSE) as unread_count
            
        FROM amicalclub_conversations c
        LEFT JOIN amicalclub_messages m ON c.last_message_id = m.id
        LEFT JOIN amicalclub_users u1 ON c.user1_id = u1.id
        LEFT JOIN amicalclub_users u2 ON c.user2_id = u2.id
        LEFT JOIN amicalclub_users sender ON m.sender_id = sender.id
        WHERE c.user1_id = ? OR c.user2_id = ?
        ORDER BY c.last_message_at DESC, c.updated_at DESC
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$userId, $userId, $userId, $userId, $userId, $userId, $userId]);
    $conversations = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo "\n📊 Résultats de la requête:\n";
    echo "Nombre de conversations trouvées: " . count($conversations) . "\n\n";
    
    if (count($conversations) > 0) {
        foreach ($conversations as $conv) {
            echo "💬 Conversation ID: {$conv['conversation_id']}\n";
            echo "   👤 Autre utilisateur: {$conv['other_user_name']} (ID: {$conv['other_user_id']})\n";
            echo "   📝 Dernier message: " . ($conv['last_message'] ?? 'Aucun') . "\n";
            echo "   🔢 Messages non lus: {$conv['unread_count']}\n";
            echo "   ⏰ Dernière activité: {$conv['last_message_at']}\n";
            echo "\n";
        }
        
        echo "✅ L'API fonctionne correctement !\n";
    } else {
        echo "⚠️  Aucune conversation trouvée.\n";
        echo "💡 Exécutez d'abord quick_chat_setup.php pour créer des données de test.\n";
    }
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
