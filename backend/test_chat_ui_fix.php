<?php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Test de la correction de l'interface de chat ===\n";

try {
    // 1. Vérifier que les messages ont bien des informations sender/receiver
    echo "1. Vérification des messages dans la base de données...\n";
    
    $stmt = $pdo->query("
        SELECT 
            m.id,
            m.sender_id,
            m.receiver_id,
            m.message,
            s.name as sender_name,
            r.name as receiver_name
        FROM amicalclub_messages m
        JOIN amicalclub_users s ON m.sender_id = s.id
        JOIN amicalclub_users r ON m.receiver_id = r.id
        ORDER BY m.created_at DESC
        LIMIT 5
    ");
    
    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($messages)) {
        echo "❌ Aucun message trouvé dans la base de données\n";
        exit;
    }
    
    echo "✅ Messages trouvés: " . count($messages) . "\n\n";
    
    foreach ($messages as $msg) {
        echo "📝 Message ID: {$msg['id']}\n";
        echo "   👤 Expéditeur: {$msg['sender_name']} (ID: {$msg['sender_id']})\n";
        echo "   👥 Destinataire: {$msg['receiver_name']} (ID: {$msg['receiver_id']})\n";
        echo "   💬 Message: " . substr($msg['message'], 0, 50) . "...\n";
        echo "\n";
    }
    
    // 2. Simuler la réponse JSON de l'API get_messages
    echo "2. Simulation de la réponse JSON...\n";
    
    $formattedMessages = [];
    foreach ($messages as $msg) {
        $formattedMessages[] = [
            "id" => $msg["id"],
            "conversation_id" => 7, // ID de conversation de test
            "sender" => [
                "id" => $msg["sender_id"],
                "name" => $msg["sender_name"],
                "avatar" => null,
            ],
            "receiver" => [
                "id" => $msg["receiver_id"],
                "name" => $msg["receiver_name"],
                "avatar" => null,
            ],
            "message" => $msg["message"],
            "type" => "text",
            "file_url" => null,
            "is_read" => false,
            "created_at" => date("Y-m-d H:i:s"),
            "read_at" => null,
        ];
    }
    
    echo "📤 Réponse JSON simulée:\n";
    echo json_encode([
        "success" => true,
        "messages" => $formattedMessages
    ], JSON_PRETTY_PRINT) . "\n";
    
    // 3. Instructions pour tester
    echo "\n3. Instructions pour tester l'interface:\n";
    echo "✅ Les messages de l'expéditeur doivent être:\n";
    echo "   - Alignés à droite\n";
    echo "   - Fond vert\n";
    echo "   - Texte blanc\n";
    echo "\n✅ Les messages du destinataire doivent être:\n";
    echo "   - Alignés à gauche\n";
    echo "   - Fond gris\n";
    echo "   - Texte sombre\n";
    echo "   - Avatar visible à gauche\n";
    
    echo "\n✅ Correction de l'interface de chat terminée !\n";
    echo "📱 Testez maintenant l'écran de chat dans l'application.\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "📍 Fichier: " . $e->getFile() . "\n";
    echo "📍 Ligne: " . $e->getLine() . "\n";
}
?>
