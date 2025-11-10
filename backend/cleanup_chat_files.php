<?php
echo "=== Nettoyage des fichiers de test du système de chat ===\n";

try {
    $filesToDelete = [
        'quick_fix_send_message.php',
        'fix_chat_tables_structure.php',
        'replace_send_message.php',
        'test_send_message_final.php',
        'fix_boolean_conversion.php',
        'replace_chat_apis.php',
        'test_chat_system_final.php',
        'get_conversations_fixed.php',
        'get_messages_fixed.php',
        'get_conversations_backup.php',
        'get_messages_backup.php',
        'send_message_backup.php',
        'send_message_fixed.php',
        'debug_send_message.php',
        'test_send_message_api.php',
        'test_send_message_http.php',
        'fix_chat_system.php',
        'add_chat_test_data.php',
        'check_chat_tables.php',
        'setup_chat_tables.php',
        'test_chat_apis.php',
        'quick_chat_setup.php',
        'test_conversations_api.php',
        'test_chat_system.php',
        'test_matches_with_team_id.php',
    ];
    
    $deletedCount = 0;
    $notFoundCount = 0;
    
    foreach ($filesToDelete as $file) {
        if (file_exists($file)) {
            if (unlink($file)) {
                echo "✅ Supprimé: $file\n";
                $deletedCount++;
            } else {
                echo "❌ Erreur lors de la suppression: $file\n";
            }
        } else {
            echo "⚠️  Fichier non trouvé: $file\n";
            $notFoundCount++;
        }
    }
    
    echo "\n📊 Résumé du nettoyage:\n";
    echo "   - Fichiers supprimés: $deletedCount\n";
    echo "   - Fichiers non trouvés: $notFoundCount\n";
    echo "   - Total traité: " . count($filesToDelete) . "\n";
    
    if ($deletedCount > 0) {
        echo "\n✅ Nettoyage terminé avec succès !\n";
        echo "📱 Le système de chat est maintenant propre et fonctionnel.\n";
    } else {
        echo "\n💡 Aucun fichier de test à supprimer.\n";
    }
    
} catch (Exception $e) {
    echo "❌ Erreur lors du nettoyage: " . $e->getMessage() . "\n";
}
?>
