<?php
require_once 'db.php';

// Script de test pour vérifier les matchs en base
header('Content-Type: application/json');

try {
    // Vérifier la structure de la table
    $stmt = $pdo->query("DESCRIBE amicalclub_matches");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "Structure de la table amicalclub_matches:\n";
    foreach ($columns as $column) {
        echo "- {$column['Field']}: {$column['Type']}\n";
    }
    
    echo "\n---\n";
    
    // Compter les matchs existants
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM amicalclub_matches");
    $count = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "Nombre de matchs en base: " . $count['total'] . "\n";
    
    // Lister les matchs existants
    $stmt = $pdo->query("
        SELECT 
            m.id, m.team_id, m.opponent, m.match_date, m.location, m.result,
            t.name as team_name, u.name as coach_name
        FROM amicalclub_matches m
        LEFT JOIN amicalclub_teams t ON m.team_id = t.id
        LEFT JOIN amicalclub_users u ON t.coach_id = u.id
        ORDER BY m.match_date DESC
        LIMIT 10
    ");
    $matches = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "\nDerniers matchs:\n";
    foreach ($matches as $match) {
        echo "- ID: {$match['id']}, Équipe: {$match['team_name']}, Date: {$match['match_date']}, Lieu: {$match['location']}, Statut: {$match['result']}\n";
    }
    
    // Insérer un match de test si aucun n'existe
    if ($count['total'] == 0) {
        echo "\nAucun match trouvé. Insertion d'un match de test...\n";
        
        $stmt = $pdo->prepare("
            INSERT INTO amicalclub_matches (team_id, opponent, match_date, location, notes, result) 
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            2, // team_id (remplacez par un ID d'équipe existant)
            'Équipe Test',
            '2025-01-20 15:00:00',
            'Stade Test, Paris',
            'Match de test',
            'pending'
        ]);
        
        echo "Match de test inséré avec succès!\n";
    }
    
} catch (Exception $e) {
    echo "Erreur: " . $e->getMessage() . "\n";
}
?>
