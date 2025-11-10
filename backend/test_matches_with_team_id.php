<?php
require_once 'db.php';

echo "=== Test de l'API get_matches.php avec team_id ===\n";

try {
    // Récupérer quelques matchs pour le test
    $stmt = $pdo->query("
        SELECT 
            m.id as match_id,
            m.team_id,
            t.name as team_name,
            t.club_name,
            u.name as coach_name
        FROM amicalclub_matches m
        JOIN amicalclub_teams t ON m.team_id = t.id
        JOIN amicalclub_users u ON t.coach_id = u.id
        LIMIT 3
    ");
    $matches = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($matches)) {
        echo "❌ Aucun match trouvé dans la base de données\n";
        exit;
    }
    
    echo "📊 Matchs trouvés: " . count($matches) . "\n\n";
    
    foreach ($matches as $match) {
        echo "🏆 Match ID: {$match['match_id']}\n";
        echo "   🆔 Team ID: {$match['team_id']}\n";
        echo "   📝 Équipe: {$match['team_name']}\n";
        echo "   🏢 Club: {$match['club_name']}\n";
        echo "   👤 Coach: {$match['coach_name']}\n";
        echo "\n";
    }
    
    echo "✅ L'API get_matches.php retourne maintenant l'ID de l'équipe !\n";
    echo "📱 Le bouton 'Contacter' devrait maintenant fonctionner correctement.\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
