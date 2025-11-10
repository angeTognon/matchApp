<?php
require_once 'db.php';
require_once 'jwt_utils.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $token = get_bearer_token();
    if (!$token || !($payload = verify_jwt($token))) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Non autorisé: Token invalide ou manquant.']);
        exit;
    }

    $userId = $payload['user_id'];

    try {
        // Récupérer tous les matchs confirmés de l'utilisateur
        $sql = "
            SELECT 
                m.id,
                m.match_date,
                DATE(m.match_date) as date,
                TIME(m.match_date) as time,
                m.location,
                m.opponent,
                m.score,
                m.result,
                m.notes,
                m.home_confirmed,
                m.away_confirmed,
                m.both_confirmed,
                m.home_scorers,
                m.away_scorers,
                m.man_of_match,
                m.yellow_cards,
                m.red_cards,
                m.match_summary,
                
                t.id as team_id,
                t.name as team_name,
                t.club_name,
                t.logo as team_logo,
                t.category,
                t.level,
                
                'confirmed' as type
                
            FROM amicalclub_matches m
            JOIN amicalclub_teams t ON m.team_id = t.id
            WHERE t.coach_id = ? AND m.result = 'confirmed'
            
            UNION ALL
            
            SELECT 
                m.id,
                m.match_date,
                DATE(m.match_date) as date,
                TIME(m.match_date) as time,
                m.location,
                host_team.name as opponent,
                m.score,
                m.result,
                m.notes,
                m.home_confirmed,
                m.away_confirmed,
                m.both_confirmed,
                m.home_scorers,
                m.away_scorers,
                m.man_of_match,
                m.yellow_cards,
                m.red_cards,
                m.match_summary,
                
                my_team.id as team_id,
                my_team.name as team_name,
                my_team.club_name,
                my_team.logo as team_logo,
                my_team.category,
                my_team.level,
                
                'opponent' as type
                
            FROM amicalclub_match_requests mr
            JOIN amicalclub_matches m ON mr.match_id = m.id
            JOIN amicalclub_teams my_team ON mr.requesting_team_id = my_team.id
            JOIN amicalclub_teams host_team ON m.team_id = host_team.id
            WHERE my_team.coach_id = ? AND mr.status = 'accepted' AND m.result = 'confirmed'
            
            ORDER BY match_date ASC
        ";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$userId, $userId]);
        $matches = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Formater les données
        foreach ($matches as &$match) {
            $match['date_formatted'] = date('d/m/Y', strtotime($match['date']));
            $match['time_formatted'] = date('H:i', strtotime($match['time']));
            $match['is_past'] = strtotime($match['match_date']) < time();
        }

        echo json_encode([
            'success' => true,
            'message' => 'Matchs confirmés récupérés avec succès.',
            'data' => [
                'matches' => $matches,
                'total' => count($matches)
            ]
        ]);

    } catch (\PDOException $e) {
        error_log("get_confirmed_matches.php: Erreur PDO: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la récupération des matchs: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
}
?>

