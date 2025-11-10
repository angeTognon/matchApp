<?php
require_once 'db.php';

try {
    echo "=== Vérification des tables de chat ===\n";
    
    // Vérifier que les tables existent
    $tables = ['amicalclub_conversations', 'amicalclub_messages', 'amicalclub_chat_notifications'];
    foreach ($tables as $table) {
        $stmt = $pdo->query("SHOW TABLES LIKE '$table'");
        if ($stmt->rowCount() > 0) {
            echo "✅ Table $table existe\n";
            
            // Compter les enregistrements
            $countStmt = $pdo->query("SELECT COUNT(*) as count FROM $table");
            $count = $countStmt->fetch(PDO::FETCH_ASSOC)['count'];
            echo "   📊 Nombre d'enregistrements: $count\n";
        } else {
            echo "❌ Table $table manquante\n";
        }
    }
    
    // Vérifier les utilisateurs
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM amicalclub_users");
    $userCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    echo "\n👥 Nombre d'utilisateurs: $userCount\n";
    
    if ($userCount >= 2) {
        $stmt = $pdo->query("SELECT id, name FROM amicalclub_users LIMIT 3");
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo "Utilisateurs disponibles:\n";
        foreach ($users as $user) {
            echo "- ID: {$user['id']}, Nom: {$user['name']}\n";
        }
    }
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
