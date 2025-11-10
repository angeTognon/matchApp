<?php
require_once 'db.php';
require_once 'jwt_utils.php';

echo "=== Test des logos d'équipes dans le chat ===\n";

try {
    // 1. Vérifier les équipes avec des logos
    echo "1. Vérification des équipes avec logos...\n";
    
    $stmt = $pdo->query("
        SELECT 
            t.id,
            t.name,
            t.logo,
            u.name as coach_name,
            CASE 
                WHEN t.logo IS NOT NULL AND t.logo != '' THEN 'Avec logo'
                ELSE 'Sans logo'
            END as logo_status
        FROM amicalclub_teams t
        JOIN amicalclub_users u ON t.coach_id = u.id
        ORDER BY t.id
    ");
    
    $teams = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "✅ Équipes trouvées: " . count($teams) . "\n\n";
    
    foreach ($teams as $team) {
        echo "🏆 Équipe: {$team['name']}\n";
        echo "   👤 Coach: {$team['coach_name']}\n";
        echo "   🖼️  Logo: {$team['logo_status']}\n";
        if ($team['logo']) {
            echo "   📁 URL: {$team['logo']}\n";
        }
        echo "\n";
    }
    
    // 2. Tester l'API get_conversations avec les logos d'équipes
    echo "2. Test de l'API get_conversations avec logos d'équipes...\n";
    
    // Simuler un token pour un utilisateur (remplacez par un vrai token)
    $token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE3MDY3ODg4MDB9.signature"; // Token d'exemple
    
    if (!$token) {
        echo "❌ Token manquant pour le test de l'API\n";
        exit;
    }
    
    try {
        $decoded = verify_jwt($token);
        if (!$decoded) {
            echo "❌ Token invalide ou expiré\n";
            exit;
        }
        $userId = $decoded['user_id'];
        
        echo "✅ Token valide pour l'utilisateur ID: $userId\n";
        
        // Tester la requête SQL directement
        $testSql = "
            SELECT 
                c.id as conversation_id,
                c.last_message_at,
                c.updated_at,
                
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
                
                -- Informations des équipes de l'autre utilisateur
                CASE 
                    WHEN c.user1_id = ? THEN GROUP_CONCAT(DISTINCT t2.id) 
                    ELSE GROUP_CONCAT(DISTINCT t1.id)
                END as other_user_team_ids,
                CASE 
                    WHEN c.user1_id = ? THEN GROUP_CONCAT(DISTINCT t2.name SEPARATOR '|') 
                    ELSE GROUP_CONCAT(DISTINCT t1.name SEPARATOR '|')
                END as other_user_team_names,
                CASE 
                    WHEN c.user1_id = ? THEN GROUP_CONCAT(DISTINCT t2.logo SEPARATOR '|') 
                    ELSE GROUP_CONCAT(DISTINCT t1.logo SEPARATOR '|')
                END as other_user_team_logos
                
            FROM amicalclub_conversations c
            LEFT JOIN amicalclub_users u1 ON c.user1_id = u1.id
            LEFT JOIN amicalclub_users u2 ON c.user2_id = u2.id
            LEFT JOIN amicalclub_teams t1 ON u1.id = t1.coach_id
            LEFT JOIN amicalclub_teams t2 ON u2.id = t2.coach_id
            WHERE c.user1_id = ? OR c.user2_id = ?
            GROUP BY c.id
            ORDER BY c.last_message_at DESC, c.updated_at DESC
        ";
        
        $testStmt = $pdo->prepare($testSql);
        $testStmt->execute([$userId, $userId, $userId, $userId, $userId, $userId, $userId, $userId]);
        $conversations = $testStmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo "✅ Conversations trouvées: " . count($conversations) . "\n\n";
        
        foreach ($conversations as $conv) {
            echo "💬 Conversation ID: {$conv['conversation_id']}\n";
            echo "   👤 Autre utilisateur: {$conv['other_user_name']} (ID: {$conv['other_user_id']})\n";
            echo "   🏆 Équipes: {$conv['other_user_team_names']}\n";
            echo "   🖼️  Logos: {$conv['other_user_team_logos']}\n\n";
        }
        
    } catch (Exception $e) {
        echo "❌ Erreur lors du test de l'API: " . $e->getMessage() . "\n";
    }
    
    // 3. Instructions pour tester
    echo "3. Instructions pour tester les logos d'équipes:\n";
    echo "✅ Fonctionnalités ajoutées:\n";
    echo "   - Logos d'équipes affichés dans la liste des conversations\n";
    echo "   - Logos d'équipes affichés dans l'en-tête du chat\n";
    echo "   - Logos d'équipes affichés à côté des messages\n";
    echo "   - Fallback vers l'avatar utilisateur si pas de logo d'équipe\n";
    echo "   - Fallback vers les initiales si pas d'avatar\n";
    
    echo "\n✅ Test des logos d'équipes terminé !\n";
    echo "📱 Testez maintenant le chat dans l'application.\n";
    echo "🖼️  Les logos d'équipes devraient s'afficher partout dans le chat.\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "📍 Fichier: " . $e->getFile() . "\n";
    echo "📍 Ligne: " . $e->getLine() . "\n";
}
?>
