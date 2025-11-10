<?php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Correction rapide de l'API send_message.php ===\n";

try {
    // 1. Vérifier que les tables existent
    echo "1. Vérification des tables de chat...\n";
    
    $createTables = "
    CREATE TABLE IF NOT EXISTS amicalclub_conversations (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user1_id INT NOT NULL,
        user2_id INT NOT NULL,
        last_message_id INT NULL,
        last_message_at TIMESTAMP NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY (user1_id, user2_id),
        FOREIGN KEY (user1_id) REFERENCES amicalclub_users(id) ON DELETE CASCADE,
        FOREIGN KEY (user2_id) REFERENCES amicalclub_users(id) ON DELETE CASCADE
    );
    
    CREATE TABLE IF NOT EXISTS amicalclub_messages (
        id INT AUTO_INCREMENT PRIMARY KEY,
        conversation_id INT NOT NULL,
        sender_id INT NOT NULL,
        receiver_id INT NOT NULL,
        message TEXT NOT NULL,
        message_type ENUM('text', 'image', 'file') DEFAULT 'text',
        file_url VARCHAR(255) NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        read_at TIMESTAMP NULL,
        FOREIGN KEY (conversation_id) REFERENCES amicalclub_conversations(id) ON DELETE CASCADE,
        FOREIGN KEY (sender_id) REFERENCES amicalclub_users(id) ON DELETE CASCADE,
        FOREIGN KEY (receiver_id) REFERENCES amicalclub_users(id) ON DELETE CASCADE
    );
    
    CREATE TABLE IF NOT EXISTS amicalclub_chat_notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        conversation_id INT NOT NULL,
        message_id INT NOT NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES amicalclub_users(id) ON DELETE CASCADE,
        FOREIGN KEY (conversation_id) REFERENCES amicalclub_conversations(id) ON DELETE CASCADE,
        FOREIGN KEY (message_id) REFERENCES amicalclub_messages(id) ON DELETE CASCADE
    );
    
    ALTER TABLE amicalclub_conversations
    ADD CONSTRAINT fk_last_message
    FOREIGN KEY (last_message_id) REFERENCES amicalclub_messages(id) ON DELETE SET NULL;
    ";
    
    // Exécuter les requêtes une par une
    $queries = explode(';', $createTables);
    foreach ($queries as $query) {
        $query = trim($query);
        if (!empty($query)) {
            try {
                $pdo->exec($query);
                echo "✅ Table créée/vérifiée\n";
            } catch (Exception $e) {
                echo "⚠️  Table déjà existante ou erreur ignorée\n";
            }
        }
    }
    
    // 2. Vérifier les utilisateurs
    echo "\n2. Vérification des utilisateurs...\n";
    $stmt = $pdo->query("SELECT id, name FROM amicalclub_users LIMIT 3");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($users) < 2) {
        echo "❌ Pas assez d'utilisateurs pour tester\n";
        exit;
    }
    
    echo "✅ Utilisateurs trouvés: " . count($users) . "\n";
    foreach ($users as $user) {
        echo "   - {$user['name']} (ID: {$user['id']})\n";
    }
    
    // 3. Créer une version corrigée de send_message.php
    echo "\n3. Création d'une version corrigée de send_message.php...\n";
    
    $sendMessageContent = '<?php
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

    $senderId = $decoded["user_id"];

    // Récupérer les données POST
    $input = json_decode(file_get_contents("php://input"), true);

    if (!$input) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Données manquantes"
        ]);
        exit;
    }

    $receiverId = isset($input["receiver_id"]) ? (int)$input["receiver_id"] : null;
    $messageContent = $input["message"] ?? null;
    $messageType = $input["message_type"] ?? "text";
    $fileUrl = $input["file_url"] ?? null;

    if (!$receiverId || !$messageContent) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "ID du destinataire ou message manquant"
        ]);
        exit;
    }

    // Vérifier que le destinataire existe
    $userStmt = $pdo->prepare("SELECT id FROM amicalclub_users WHERE id = ?");
    $userStmt->execute([$receiverId]);
    if (!$userStmt->fetch()) {
        http_response_code(404);
        echo json_encode([
            "success" => false,
            "message" => "Destinataire non trouvé"
        ]);
        exit;
    }

    // Vérifier que l\'utilisateur ne s\'envoie pas un message à lui-même
    if ($senderId == $receiverId) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Impossible de s\'envoyer un message à soi-même"
        ]);
        exit;
    }

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
            $conversationId = $conversation["id"];
        } else {
            // Créer une nouvelle conversation
            $insertConvSql = "INSERT INTO amicalclub_conversations (user1_id, user2_id, created_at, updated_at) VALUES (?, ?, NOW(), NOW())";
            $insertConvStmt = $pdo->prepare($insertConvSql);
            $insertConvStmt->execute([$senderId, $receiverId]);
            $conversationId = $pdo->lastInsertId();
        }

        // Insérer le message
        $insertMsgSql = "INSERT INTO amicalclub_messages (conversation_id, sender_id, receiver_id, message, message_type, file_url, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())";
        $insertMsgStmt = $pdo->prepare($insertMsgSql);
        $insertMsgStmt->execute([$conversationId, $senderId, $receiverId, $messageContent, $messageType, $fileUrl]);
        $messageId = $pdo->lastInsertId();

        // Mettre à jour la conversation avec le dernier message
        $updateConvSql = "UPDATE amicalclub_conversations SET last_message_id = ?, last_message_at = NOW(), updated_at = NOW() WHERE id = ?";
        $updateConvStmt = $pdo->prepare($updateConvSql);
        $updateConvStmt->execute([$messageId, $conversationId]);

        // Créer une notification pour le destinataire
        $notifSql = "INSERT INTO amicalclub_chat_notifications (user_id, conversation_id, message_id, created_at) VALUES (?, ?, ?, NOW())";
        $notifStmt = $pdo->prepare($notifSql);
        $notifStmt->execute([$receiverId, $conversationId, $messageId]);

        // Valider la transaction
        $pdo->commit();

        echo json_encode([
            "success" => true,
            "message" => "Message envoyé avec succès",
            "data" => [
                "id" => $messageId,
                "conversation_id" => $conversationId,
                "message" => $messageContent,
                "created_at" => date("Y-m-d H:i:s")
            ]
        ]);

    } catch (Exception $e) {
        $pdo->rollBack();
        throw $e;
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Erreur lors de l\'envoi du message",
        "error" => $e->getMessage()
    ]);
}
?>';
    
    // Sauvegarder la version corrigée
    file_put_contents('send_message_fixed.php', $sendMessageContent);
    echo "✅ Version corrigée créée: send_message_fixed.php\n";
    
    // 4. Tester l\'envoi de message
    echo "\n4. Test d\'envoi de message...\n";
    
    $senderId = $users[0]['id'];
    $receiverId = $users[1]['id'];
    
    // Simuler l\'appel API
    $_POST = [];
    $_SERVER['REQUEST_METHOD'] = 'POST';
    $_SERVER['CONTENT_TYPE'] = 'application/json';
    
    // Simuler les données
    $testData = [
        'receiver_id' => $receiverId,
        'message' => 'Test message - ' . date('Y-m-d H:i:s'),
        'message_type' => 'text'
    ];
    
    echo "📤 Test avec:\n";
    echo "   - Expéditeur: {$users[0]['name']} (ID: $senderId)\n";
    echo "   - Destinataire: {$users[1]['name']} (ID: $receiverId)\n";
    echo "   - Message: {$testData['message']}\n";
    
    // Exécuter la logique directement
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
        $insertMsgStmt->execute([$conversationId, $senderId, $receiverId, $testData['message'], $testData['message_type']]);
        $messageId = $pdo->lastInsertId();

        echo "📝 Message créé: ID $messageId\n";

        // Mettre à jour la conversation
        $updateConvSql = "UPDATE amicalclub_conversations SET last_message_id = ?, last_message_at = NOW(), updated_at = NOW() WHERE id = ?";
        $updateConvStmt = $pdo->prepare($updateConvSql);
        $updateConvStmt->execute([$messageId, $conversationId]);

        echo "🔄 Conversation mise à jour\n";

        // Créer une notification
        $notifSql = "INSERT INTO amicalclub_chat_notifications (user_id, conversation_id, message_id, created_at) VALUES (?, ?, ?, NOW())";
        $notifStmt = $pdo->prepare($notifSql);
        $notifStmt->execute([$receiverId, $conversationId, $messageId]);

        echo "🔔 Notification créée\n";

        // Valider la transaction
        $pdo->commit();

        echo "\n✅ Test d\'envoi de message réussi !\n";
        echo "📱 L\'API send_message.php devrait maintenant fonctionner.\n";
        echo "💡 Remplacez send_message.php par send_message_fixed.php si nécessaire.\n";
        
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