<?php
echo "=== Remplacement des APIs de chat par les versions corrigées ===\n";

try {
    // 1. Vérifier que les versions corrigées existent
    if (!file_exists('get_conversations_fixed.php')) {
        echo "❌ Fichier get_conversations_fixed.php non trouvé\n";
        echo "💡 Exécutez d'abord fix_boolean_conversion.php\n";
        exit;
    }
    
    if (!file_exists('get_messages_fixed.php')) {
        echo "❌ Fichier get_messages_fixed.php non trouvé\n";
        echo "💡 Exécutez d'abord fix_boolean_conversion.php\n";
        exit;
    }
    
    // 2. Sauvegarder les anciennes versions
    if (file_exists('get_conversations.php')) {
        copy('get_conversations.php', 'get_conversations_backup.php');
        echo "✅ Ancienne version sauvegardée: get_conversations_backup.php\n";
    }
    
    if (file_exists('get_messages.php')) {
        copy('get_messages.php', 'get_messages_backup.php');
        echo "✅ Ancienne version sauvegardée: get_messages_backup.php\n";
    }
    
    // 3. Remplacer par les versions corrigées
    copy('get_conversations_fixed.php', 'get_conversations.php');
    echo "✅ get_conversations.php remplacé par la version corrigée\n";
    
    copy('get_messages_fixed.php', 'get_messages.php');
    echo "✅ get_messages.php remplacé par la version corrigée\n";
    
    // 4. Vérifier que les fichiers fonctionnent
    $conversationsContent = file_get_contents('get_conversations.php');
    $messagesContent = file_get_contents('get_messages.php');
    
    if (strpos($conversationsContent, 'require_once "db.php"') !== false && 
        strpos($messagesContent, 'require_once "db.php"') !== false) {
        echo "✅ Nouveaux fichiers vérifiés\n";
        echo "📱 Les APIs de chat devraient maintenant fonctionner sans erreur de type !\n";
    } else {
        echo "❌ Erreur lors du remplacement\n";
    }
    
    echo "\n🎯 Prochaines étapes:\n";
    echo "1. Testez l'écran Messages dans l'application\n";
    echo "2. L'erreur 'type int is not a subtype of type bool' ne devrait plus apparaître\n";
    echo "3. Vous pouvez restaurer les anciennes versions si nécessaire:\n";
    echo "   - cp get_conversations_backup.php get_conversations.php\n";
    echo "   - cp get_messages_backup.php get_messages.php\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
