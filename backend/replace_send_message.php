<?php
echo "=== Remplacement de send_message.php par la version corrigée ===\n";

try {
    // Vérifier que la version corrigée existe
    if (!file_exists('send_message_fixed.php')) {
        echo "❌ Fichier send_message_fixed.php non trouvé\n";
        echo "💡 Exécutez d'abord quick_fix_send_message.php\n";
        exit;
    }
    
    // Sauvegarder l'ancienne version
    if (file_exists('send_message.php')) {
        copy('send_message.php', 'send_message_backup.php');
        echo "✅ Ancienne version sauvegardée: send_message_backup.php\n";
    }
    
    // Remplacer par la version corrigée
    copy('send_message_fixed.php', 'send_message.php');
    echo "✅ send_message.php remplacé par la version corrigée\n";
    
    // Vérifier que le fichier fonctionne
    $content = file_get_contents('send_message.php');
    if (strpos($content, 'require_once "db.php"') !== false) {
        echo "✅ Nouveau fichier send_message.php vérifié\n";
        echo "📱 L'API d'envoi de message devrait maintenant fonctionner !\n";
    } else {
        echo "❌ Erreur lors du remplacement\n";
    }
    
    echo "\n🎯 Prochaines étapes:\n";
    echo "1. Testez l'envoi de message dans l'application\n";
    echo "2. Si ça ne fonctionne toujours pas, vérifiez les logs d'erreur\n";
    echo "3. Vous pouvez restaurer l'ancienne version avec: cp send_message_backup.php send_message.php\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
