<?php
require_once 'db.php';

echo "=== Correction de la structure des tables de chat ===\n";

try {
    // 1. Vérifier la structure actuelle des tables
    echo "1. Vérification de la structure des tables...\n";
    
    // Vérifier amicalclub_conversations
    echo "\n📋 Structure de amicalclub_conversations:\n";
    $stmt = $pdo->query("DESCRIBE amicalclub_conversations");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($columns as $column) {
        echo "   - {$column['Field']} ({$column['Type']})\n";
    }
    
    // Vérifier amicalclub_messages
    echo "\n📋 Structure de amicalclub_messages:\n";
    $stmt = $pdo->query("DESCRIBE amicalclub_messages");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($columns as $column) {
        echo "   - {$column['Field']} ({$column['Type']})\n";
    }
    
    // 2. Corriger la structure si nécessaire
    echo "\n2. Correction de la structure...\n";
    
    // Vérifier si conversation_id existe dans amicalclub_messages
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_messages LIKE 'conversation_id'");
    if ($stmt->rowCount() == 0) {
        echo "❌ Colonne conversation_id manquante dans amicalclub_messages\n";
        echo "🔧 Ajout de la colonne conversation_id...\n";
        
        $pdo->exec("ALTER TABLE amicalclub_messages ADD COLUMN conversation_id INT NOT NULL AFTER id");
        echo "✅ Colonne conversation_id ajoutée\n";
        
        // Ajouter la clé étrangère
        $pdo->exec("ALTER TABLE amicalclub_messages ADD CONSTRAINT fk_messages_conversation FOREIGN KEY (conversation_id) REFERENCES amicalclub_conversations(id) ON DELETE CASCADE");
        echo "✅ Clé étrangère ajoutée\n";
    } else {
        echo "✅ Colonne conversation_id existe déjà\n";
    }
    
    // Vérifier si sender_id existe
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_messages LIKE 'sender_id'");
    if ($stmt->rowCount() == 0) {
        echo "❌ Colonne sender_id manquante\n";
        $pdo->exec("ALTER TABLE amicalclub_messages ADD COLUMN sender_id INT NOT NULL AFTER conversation_id");
        echo "✅ Colonne sender_id ajoutée\n";
    } else {
        echo "✅ Colonne sender_id existe\n";
    }
    
    // Vérifier si receiver_id existe
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_messages LIKE 'receiver_id'");
    if ($stmt->rowCount() == 0) {
        echo "❌ Colonne receiver_id manquante\n";
        $pdo->exec("ALTER TABLE amicalclub_messages ADD COLUMN receiver_id INT NOT NULL AFTER sender_id");
        echo "✅ Colonne receiver_id ajoutée\n";
    } else {
        echo "✅ Colonne receiver_id existe\n";
    }
    
    // Vérifier si message existe
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_messages LIKE 'message'");
    if ($stmt->rowCount() == 0) {
        echo "❌ Colonne message manquante\n";
        $pdo->exec("ALTER TABLE amicalclub_messages ADD COLUMN message TEXT NOT NULL AFTER receiver_id");
        echo "✅ Colonne message ajoutée\n";
    } else {
        echo "✅ Colonne message existe\n";
    }
    
    // Vérifier si message_type existe
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_messages LIKE 'message_type'");
    if ($stmt->rowCount() == 0) {
        echo "❌ Colonne message_type manquante\n";
        $pdo->exec("ALTER TABLE amicalclub_messages ADD COLUMN message_type ENUM('text', 'image', 'file') DEFAULT 'text' AFTER message");
        echo "✅ Colonne message_type ajoutée\n";
    } else {
        echo "✅ Colonne message_type existe\n";
    }
    
    // Vérifier si file_url existe
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_messages LIKE 'file_url'");
    if ($stmt->rowCount() == 0) {
        echo "❌ Colonne file_url manquante\n";
        $pdo->exec("ALTER TABLE amicalclub_messages ADD COLUMN file_url VARCHAR(255) NULL AFTER message_type");
        echo "✅ Colonne file_url ajoutée\n";
    } else {
        echo "✅ Colonne file_url existe\n";
    }
    
    // Vérifier si is_read existe
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_messages LIKE 'is_read'");
    if ($stmt->rowCount() == 0) {
        echo "❌ Colonne is_read manquante\n";
        $pdo->exec("ALTER TABLE amicalclub_messages ADD COLUMN is_read BOOLEAN DEFAULT FALSE AFTER file_url");
        echo "✅ Colonne is_read ajoutée\n";
    } else {
        echo "✅ Colonne is_read existe\n";
    }
    
    // Vérifier si created_at existe
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_messages LIKE 'created_at'");
    if ($stmt->rowCount() == 0) {
        echo "❌ Colonne created_at manquante\n";
        $pdo->exec("ALTER TABLE amicalclub_messages ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP AFTER is_read");
        echo "✅ Colonne created_at ajoutée\n";
    } else {
        echo "✅ Colonne created_at existe\n";
    }
    
    // Vérifier si read_at existe
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_messages LIKE 'read_at'");
    if ($stmt->rowCount() == 0) {
        echo "❌ Colonne read_at manquante\n";
        $pdo->exec("ALTER TABLE amicalclub_messages ADD COLUMN read_at TIMESTAMP NULL AFTER created_at");
        echo "✅ Colonne read_at ajoutée\n";
    } else {
        echo "✅ Colonne read_at existe\n";
    }
    
    // 3. Vérifier la structure de amicalclub_conversations
    echo "\n3. Vérification de amicalclub_conversations...\n";
    
    // Vérifier si user1_id existe
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_conversations LIKE 'user1_id'");
    if ($stmt->rowCount() == 0) {
        echo "❌ Colonne user1_id manquante\n";
        $pdo->exec("ALTER TABLE amicalclub_conversations ADD COLUMN user1_id INT NOT NULL AFTER id");
        echo "✅ Colonne user1_id ajoutée\n";
    } else {
        echo "✅ Colonne user1_id existe\n";
    }
    
    // Vérifier si user2_id existe
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_conversations LIKE 'user2_id'");
    if ($stmt->rowCount() == 0) {
        echo "❌ Colonne user2_id manquante\n";
        $pdo->exec("ALTER TABLE amicalclub_conversations ADD COLUMN user2_id INT NOT NULL AFTER user1_id");
        echo "✅ Colonne user2_id ajoutée\n";
    } else {
        echo "✅ Colonne user2_id existe\n";
    }
    
    // Vérifier si last_message_id existe
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_conversations LIKE 'last_message_id'");
    if ($stmt->rowCount() == 0) {
        echo "❌ Colonne last_message_id manquante\n";
        $pdo->exec("ALTER TABLE amicalclub_conversations ADD COLUMN last_message_id INT NULL AFTER user2_id");
        echo "✅ Colonne last_message_id ajoutée\n";
    } else {
        echo "✅ Colonne last_message_id existe\n";
    }
    
    // Vérifier si last_message_at existe
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_conversations LIKE 'last_message_at'");
    if ($stmt->rowCount() == 0) {
        echo "❌ Colonne last_message_at manquante\n";
        $pdo->exec("ALTER TABLE amicalclub_conversations ADD COLUMN last_message_at TIMESTAMP NULL AFTER last_message_id");
        echo "✅ Colonne last_message_at ajoutée\n";
    } else {
        echo "✅ Colonne last_message_at existe\n";
    }
    
    // 4. Tester l'envoi de message avec la structure corrigée
    echo "\n4. Test d'envoi de message avec la structure corrigée...\n";
    
    // Récupérer des utilisateurs
    $stmt = $pdo->query("SELECT id, name FROM amicalclub_users LIMIT 2");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($users) >= 2) {
        $senderId = $users[0]['id'];
        $receiverId = $users[1]['id'];
        
        echo "📤 Test avec:\n";
        echo "   - Expéditeur: {$users[0]['name']} (ID: $senderId)\n";
        echo "   - Destinataire: {$users[1]['name']} (ID: $receiverId)\n";
        
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
            $insertMsgSql = "INSERT INTO amicalclub_messages (conversation_id, sender_id, receiver_id, message, message_type, created_at) VALUES (?, ?, ?, ?, 'text', NOW())";
            $insertMsgStmt = $pdo->prepare($insertMsgSql);
            $insertMsgStmt->execute([$conversationId, $senderId, $receiverId, 'Test message - ' . date('Y-m-d H:i:s')]);
            $messageId = $pdo->lastInsertId();

            echo "📝 Message créé: ID $messageId\n";

            // Mettre à jour la conversation
            $updateConvSql = "UPDATE amicalclub_conversations SET last_message_id = ?, last_message_at = NOW(), updated_at = NOW() WHERE id = ?";
            $updateConvStmt = $pdo->prepare($updateConvSql);
            $updateConvStmt->execute([$messageId, $conversationId]);

            echo "🔄 Conversation mise à jour\n";

            // Valider la transaction
            $pdo->commit();

            echo "\n✅ Test d'envoi de message réussi !\n";
            echo "📱 L'API send_message.php devrait maintenant fonctionner correctement.\n";
            
        } catch (Exception $e) {
            $pdo->rollBack();
            throw $e;
        }
    }
    
    // 5. Afficher la structure finale
    echo "\n5. Structure finale des tables:\n";
    
    echo "\n📋 amicalclub_conversations:\n";
    $stmt = $pdo->query("DESCRIBE amicalclub_conversations");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($columns as $column) {
        echo "   - {$column['Field']} ({$column['Type']})\n";
    }
    
    echo "\n📋 amicalclub_messages:\n";
    $stmt = $pdo->query("DESCRIBE amicalclub_messages");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($columns as $column) {
        echo "   - {$column['Field']} ({$column['Type']})\n";
    }
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "📍 Fichier: " . $e->getFile() . "\n";
    echo "📍 Ligne: " . $e->getLine() . "\n";
}
?>
