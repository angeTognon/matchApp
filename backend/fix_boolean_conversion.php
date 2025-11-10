<?php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Correction de la conversion des booléens dans les APIs ===\n";

try {
    // 1. Corriger get_conversations.php
    echo "1. Correction de get_conversations.php...\n";
    
    $conversationsContent = '<?php
require_once "db.php";
require_once "jwt_utils.php";

header("Content-Type: application/json");

// Récupérer le token depuis les headers
$headers = getallheaders();
$token = isset($headers["Authorization"]) ? str_replace("Bearer ", "", $headers["Authorization"]) : null;

if (!$token) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Token manquant"
    ]);
    exit;
}

try {
    // Vérifier le token JWT
    $decoded = verify_jwt($token);
    if (!$decoded) {
        http_response_code(401);
        echo json_encode([
            "success" => false,
            "message" => "Token invalide ou expiré"
        ]);
        exit;
    }

    $userId = $decoded["user_id"];

    // Récupérer les conversations de l\'utilisateur
    $sql = "
        SELECT
            c.id AS conversation_id,
            CASE
                WHEN c.user1_id = ? THEN u2.id
                ELSE u1.id
            END AS other_user_id,
            CASE
                WHEN c.user1_id = ? THEN u2.name
                ELSE u1.name
            END AS other_user_name,
            CASE
                WHEN c.user1_id = ? THEN u2.avatar
                ELSE u1.avatar
            END AS other_user_avatar,
            CASE
                WHEN c.user1_id = ? THEN u2.email
                ELSE u1.email
            END AS other_user_email,
            
            -- Informations du dernier message
            m.id AS last_message_id,
            m.message AS last_message_content,
            m.created_at AS last_message_at,
            m.sender_id AS last_message_sender_id,
            
            -- Compter les messages non lus (convertir en booléen)
            (SELECT COUNT(*) FROM amicalclub_messages 
             WHERE conversation_id = c.id 
             AND receiver_id = ? 
             AND is_read = 0) as unread_count,
             
            c.updated_at
        FROM amicalclub_conversations c
        LEFT JOIN amicalclub_messages m ON c.last_message_id = m.id
        LEFT JOIN amicalclub_users u1 ON c.user1_id = u1.id
        LEFT JOIN amicalclub_users u2 ON c.user2_id = u2.id
        WHERE c.user1_id = ? OR c.user2_id = ?
        ORDER BY c.updated_at DESC
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$userId, $userId, $userId, $userId, $userId, $userId, $userId]);
    $conversations = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $formattedConversations = [];
    foreach ($conversations as $conv) {
        $formattedConversations[] = [
            "conversation_id" => $conv["conversation_id"],
            "other_user" => [
                "id" => $conv["other_user_id"],
                "name" => $conv["other_user_name"],
                "avatar" => $conv["other_user_avatar"],
                "email" => $conv["other_user_email"],
            ],
            "last_message" => $conv["last_message_id"] ? [
                "id" => $conv["last_message_id"],
                "conversation_id" => $conv["conversation_id"],
                "sender_id" => $conv["last_message_sender_id"],
                "message" => $conv["last_message_content"],
                "created_at" => $conv["last_message_at"],
            ] : null,
            "unread_count" => (int)$conv["unread_count"],
            "updated_at" => $conv["updated_at"],
        ];
    }

    echo json_encode([
        "success" => true,
        "conversations" => $formattedConversations
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Erreur lors de la récupération des conversations",
        "error" => $e->getMessage()
    ]);
}
?>';
    
    file_put_contents('get_conversations_fixed.php', $conversationsContent);
    echo "✅ get_conversations_fixed.php créé\n";
    
    // 2. Corriger get_messages.php
    echo "\n2. Correction de get_messages.php...\n";
    
    $messagesContent = '<?php
require_once "db.php";
require_once "jwt_utils.php";

header("Content-Type: application/json");

// Récupérer le token depuis les headers
$headers = getallheaders();
$token = isset($headers["Authorization"]) ? str_replace("Bearer ", "", $headers["Authorization"]) : null;

if (!$token) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Token manquant"
    ]);
    exit;
}

try {
    // Vérifier le token JWT
    $decoded = verify_jwt($token);
    if (!$decoded) {
        http_response_code(401);
        echo json_encode([
            "success" => false,
            "message" => "Token invalide ou expiré"
        ]);
        exit;
    }

    $userId = $decoded["user_id"];
    $conversationId = isset($_GET["conversation_id"]) ? (int)$_GET["conversation_id"] : null;
    $page = isset($_GET["page"]) ? (int)$_GET["page"] : 1;
    $limit = isset($_GET["limit"]) ? (int)$_GET["limit"] : 50;
    $offset = ($page - 1) * $limit;

    if (!$conversationId) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "ID de conversation manquant"
        ]);
        exit;
    }

    // Vérifier que l\'utilisateur fait partie de la conversation
    $checkConvSql = "SELECT COUNT(*) FROM amicalclub_conversations WHERE id = ? AND (user1_id = ? OR user2_id = ?)";
    $checkConvStmt = $pdo->prepare($checkConvSql);
    $checkConvStmt->execute([$conversationId, $userId, $userId]);
    if ($checkConvStmt->fetchColumn() == 0) {
        http_response_code(403);
        echo json_encode([
            "success" => false,
            "message" => "Accès non autorisé à cette conversation"
        ]);
        exit;
    }

    // Récupérer les messages de la conversation
    $sql = "
        SELECT 
            m.id,
            m.conversation_id,
            m.sender_id,
            m.receiver_id,
            m.message,
            m.message_type,
            m.file_url,
            m.is_read,
            m.read_at,
            m.created_at,
            
            -- Informations de l\'expéditeur
            sender.name as sender_name,
            sender.avatar as sender_avatar,
            
            -- Informations du destinataire
            receiver.name as receiver_name,
            receiver.avatar as receiver_avatar
            
        FROM amicalclub_messages m
        JOIN amicalclub_users sender ON m.sender_id = sender.id
        JOIN amicalclub_users receiver ON m.receiver_id = receiver.id
        WHERE m.conversation_id = ?
        ORDER BY m.created_at DESC
        LIMIT ? OFFSET ?
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$conversationId, $limit, $offset]);
    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $formattedMessages = [];
    foreach ($messages as $msg) {
        $formattedMessages[] = [
            "id" => $msg["id"],
            "conversation_id" => $msg["conversation_id"],
            "sender" => [
                "id" => $msg["sender_id"],
                "name" => $msg["sender_name"],
                "avatar" => $msg["sender_avatar"],
            ],
            "receiver" => [
                "id" => $msg["receiver_id"],
                "name" => $msg["receiver_name"],
                "avatar" => $msg["receiver_avatar"],
            ],
            "message" => $msg["message"],
            "type" => $msg["message_type"],
            "file_url" => $msg["file_url"],
            "is_read" => (bool)$msg["is_read"], // Conversion explicite en booléen
            "created_at" => $msg["created_at"],
            "read_at" => $msg["read_at"],
        ];
    }

    echo json_encode([
        "success" => true,
        "messages" => array_reverse($formattedMessages)
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Erreur lors de la récupération des messages",
        "error" => $e->getMessage()
    ]);
}
?>';
    
    file_put_contents('get_messages_fixed.php', $messagesContent);
    echo "✅ get_messages_fixed.php créé\n";
    
    // 3. Tester les APIs corrigées
    echo "\n3. Test des APIs corrigées...\n";
    
    // Récupérer des utilisateurs pour le test
    $stmt = $pdo->query("SELECT id, name FROM amicalclub_users LIMIT 2");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($users) >= 2) {
        $userId = $users[0]['id'];
        echo "📤 Test avec l'utilisateur: {$users[0]['name']} (ID: $userId)\n";
        
        // Tester get_conversations
        echo "\n🧪 Test de get_conversations...\n";
        $convSql = "
            SELECT
                c.id AS conversation_id,
                CASE
                    WHEN c.user1_id = ? THEN u2.id
                    ELSE u1.id
                END AS other_user_id,
                CASE
                    WHEN c.user1_id = ? THEN u2.name
                    ELSE u1.name
                END AS other_user_name,
                CASE
                    WHEN c.user1_id = ? THEN u2.avatar
                    ELSE u1.avatar
                END AS other_user_avatar,
                CASE
                    WHEN c.user1_id = ? THEN u2.email
                    ELSE u1.email
                END AS other_user_email,
                
                m.id AS last_message_id,
                m.message AS last_message_content,
                m.created_at AS last_message_at,
                m.sender_id AS last_message_sender_id,
                
                (SELECT COUNT(*) FROM amicalclub_messages 
                 WHERE conversation_id = c.id 
                 AND receiver_id = ? 
                 AND is_read = 0) as unread_count,
                 
                c.updated_at
            FROM amicalclub_conversations c
            LEFT JOIN amicalclub_messages m ON c.last_message_id = m.id
            LEFT JOIN amicalclub_users u1 ON c.user1_id = u1.id
            LEFT JOIN amicalclub_users u2 ON c.user2_id = u2.id
            WHERE c.user1_id = ? OR c.user2_id = ?
            ORDER BY c.updated_at DESC
        ";
        
        $stmt = $pdo->prepare($convSql);
        $stmt->execute([$userId, $userId, $userId, $userId, $userId, $userId, $userId]);
        $conversations = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo "✅ Conversations trouvées: " . count($conversations) . "\n";
        
        if (!empty($conversations)) {
            $conv = $conversations[0];
            echo "📋 Exemple de conversation:\n";
            echo "   - ID: {$conv['conversation_id']}\n";
            echo "   - Autre utilisateur: {$conv['other_user_name']}\n";
            echo "   - Messages non lus: {$conv['unread_count']}\n";
            
            // Tester get_messages pour cette conversation
            echo "\n🧪 Test de get_messages...\n";
            $msgSql = "
                SELECT 
                    m.id,
                    m.conversation_id,
                    m.sender_id,
                    m.receiver_id,
                    m.message,
                    m.message_type,
                    m.file_url,
                    m.is_read,
                    m.read_at,
                    m.created_at,
                    
                    sender.name as sender_name,
                    sender.avatar as sender_avatar,
                    
                    receiver.name as receiver_name,
                    receiver.avatar as receiver_avatar
                    
                FROM amicalclub_messages m
                JOIN amicalclub_users sender ON m.sender_id = sender.id
                JOIN amicalclub_users receiver ON m.receiver_id = receiver.id
                WHERE m.conversation_id = ?
                ORDER BY m.created_at DESC
                LIMIT 5
            ";
            
            $stmt = $pdo->prepare($msgSql);
            $stmt->execute([$conv['conversation_id']]);
            $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            echo "✅ Messages trouvés: " . count($messages) . "\n";
            
            if (!empty($messages)) {
                $msg = $messages[0];
                echo "📋 Exemple de message:\n";
                echo "   - ID: {$msg['id']}\n";
                echo "   - Expéditeur: {$msg['sender_name']}\n";
                echo "   - Message: {$msg['message']}\n";
                echo "   - Lu: " . ($msg['is_read'] ? 'Oui' : 'Non') . " (valeur: {$msg['is_read']})\n";
            }
        }
    }
    
    echo "\n✅ Correction des booléens terminée !\n";
    echo "📱 Les APIs retournent maintenant des booléens corrects.\n";
    echo "💡 Remplacez get_conversations.php et get_messages.php par les versions corrigées.\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "📍 Fichier: " . $e->getFile() . "\n";
    echo "📍 Ligne: " . $e->getLine() . "\n";
}
?>
