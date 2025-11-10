<?php
require_once 'db.php';

try {
    echo "=== Création des tables de chat ===\n";
    
    // Lire et exécuter le script SQL
    $sql = file_get_contents('create_chat_tables.sql');
    if ($sql === false) {
        throw new Exception('Impossible de lire le fichier create_chat_tables.sql');
    }
    
    // Diviser les requêtes par point-virgule
    $queries = array_filter(array_map('trim', explode(';', $sql)));
    
    foreach ($queries as $query) {
        if (!empty($query)) {
            echo "Exécution: " . substr($query, 0, 50) . "...\n";
            $pdo->exec($query);
        }
    }
    
    echo "\n✅ Tables de chat créées avec succès !\n";
    
    // Vérifier que les tables ont été créées
    $tables = ['amicalclub_conversations', 'amicalclub_messages', 'amicalclub_chat_notifications', 'amicalclub_user_presence'];
    foreach ($tables as $table) {
        $stmt = $pdo->query("SHOW TABLES LIKE '$table'");
        if ($stmt->rowCount() > 0) {
            echo "✅ Table $table créée\n";
        } else {
            echo "❌ Table $table non trouvée\n";
        }
    }
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
