<?php
// Script de debug pour voir les matchs d'un coach
require_once 'db.php';
require_once 'jwt_utils.php';

header('Content-Type: application/json');

try {
    $pdo = get_db_connection();
    
    // Récupérer tous les matchs avec les détails des équipes
    $stmt = $pdo->prepare("
        SELECT 
            m.*,
            t.name as team_name,
            t.club_name,
            t.coach_id,
            u.name as coach_name
        FROM amicalclub_matches m
        JOIN amicalclub_teams t ON m.team_id = t.id
        JOIN amicalclub_users u ON t.coach_id = u.id
        ORDER BY m.match_date DESC
    ");
    
    $stmt->execute();
    $matches = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'total_matches' => count($matches),
        'matches' => $matches
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
