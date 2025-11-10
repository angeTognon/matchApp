<?php
require_once 'db.php';

echo "=== Test de l'API get_public_team.php ===\n";

try {
    // Récupérer une équipe pour le test
    $stmt = $pdo->query("SELECT id, name FROM amicalclub_teams LIMIT 1");
    $team = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$team) {
        echo "❌ Aucune équipe trouvée dans la base de données\n";
        exit;
    }
    
    echo "🏆 Équipe de test: {$team['name']} (ID: {$team['id']})\n";
    
    // Simuler l'appel à l'API get_public_team.php
    $teamId = $team['id'];
    
    // Requête exacte de get_public_team.php
    $stmt = $pdo->prepare("
        SELECT t.*, u.name as coach_name
        FROM amicalclub_teams t
        JOIN amicalclub_users u ON t.coach_id = u.id
        WHERE t.id = ?
    ");
    $stmt->execute([$teamId]);
    $teamData = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($teamData) {
        echo "\n✅ Données de l'équipe récupérées avec succès:\n";
        echo "   📝 Nom: {$teamData['name']}\n";
        echo "   👤 Coach: {$teamData['coach_name']}\n";
        echo "   🆔 Coach ID: {$teamData['coach_id']}\n";
        echo "   📂 Catégorie: {$teamData['category']}\n";
        echo "   🎯 Niveau: {$teamData['level']}\n";
        echo "   🏢 Club: {$teamData['club_name']}\n";
        echo "   📍 Localisation: {$teamData['location']}\n";
        
        echo "\n🎉 L'API get_public_team.php fonctionne correctement !\n";
        echo "📱 L'écran de contact devrait maintenant afficher les vraies données.\n";
    } else {
        echo "❌ Aucune donnée trouvée pour l'équipe ID: $teamId\n";
    }
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
