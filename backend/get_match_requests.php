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
    $type = $_GET['type'] ?? 'received'; // 'received' ou 'sent'

    try {
        if ($type === 'received') {
            // Demandes reçues : matchs créés par l'utilisateur avec des demandes
            $sql = "
                SELECT 
                    mr.id as request_id,
                    mr.match_id,
                    mr.status as request_status,
                    mr.message as request_message,
                    mr.created_at as request_date,
                    mr.responded_at,
                    
                    DATE(m.match_date) as match_date,
                    TIME(m.match_date) as match_time,
                    m.location,
                    m.opponent,
                    m.result as match_status,
                    
                    requesting_team.id as requesting_team_id,
                    requesting_team.name as requesting_team_name,
                    requesting_team.club_name as requesting_club_name,
                    requesting_team.logo as requesting_team_logo,
                    requesting_team.level as requesting_team_level,
                    requesting_team.category as requesting_team_category,
                    
                    requesting_coach.id as requesting_coach_id,
                    requesting_coach.name as requesting_coach_name,
                    requesting_coach.email as requesting_coach_email,
                    requesting_coach.avatar as requesting_coach_avatar,
                    
                    my_team.id as my_team_id,
                    my_team.name as my_team_name,
                    my_team.club_name as my_club_name,
                    my_team.logo as my_team_logo,
                    my_team.category,
                    my_team.level
                    
                FROM amicalclub_match_requests mr
                JOIN amicalclub_matches m ON mr.match_id = m.id
                JOIN amicalclub_teams my_team ON m.team_id = my_team.id
                JOIN amicalclub_teams requesting_team ON mr.requesting_team_id = requesting_team.id
                JOIN amicalclub_users requesting_coach ON requesting_team.coach_id = requesting_coach.id
                JOIN amicalclub_users my_coach ON my_team.coach_id = my_coach.id
                WHERE my_coach.id = ?
                ORDER BY mr.created_at DESC
            ";
            
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$userId]);
            $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
        } else {
            // Demandes envoyées : demandes faites par l'utilisateur pour des matchs d'autres
            $sql = "
                SELECT 
                    mr.id as request_id,
                    mr.match_id,
                    mr.status as request_status,
                    mr.message as request_message,
                    mr.created_at as request_date,
                    mr.responded_at,
                    
                    DATE(m.match_date) as match_date,
                    TIME(m.match_date) as match_time,
                    m.location,
                    m.opponent,
                    m.result as match_status,
                    
                    host_team.id as host_team_id,
                    host_team.name as host_team_name,
                    host_team.club_name as host_club_name,
                    host_team.logo as host_team_logo,
                    host_team.level as host_team_level,
                    host_team.category as host_team_category,
                    
                    host_coach.id as host_coach_id,
                    host_coach.name as host_coach_name,
                    host_coach.email as host_coach_email,
                    host_coach.avatar as host_coach_avatar,
                    
                    my_team.id as my_team_id,
                    my_team.name as my_team_name,
                    my_team.club_name as my_club_name,
                    my_team.logo as my_team_logo,
                    my_team.category,
                    my_team.level
                    
                FROM amicalclub_match_requests mr
                JOIN amicalclub_matches m ON mr.match_id = m.id
                JOIN amicalclub_teams my_team ON mr.requesting_team_id = my_team.id
                JOIN amicalclub_teams host_team ON m.team_id = host_team.id
                JOIN amicalclub_users host_coach ON host_team.coach_id = host_coach.id
                WHERE my_team.coach_id = ?
                ORDER BY mr.created_at DESC
            ";
            
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$userId]);
            $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);
        }

        // Formater les données
        foreach ($requests as &$request) {
            $request['match_date_formatted'] = date('d/m/Y', strtotime($request['match_date']));
            $request['match_time_formatted'] = date('H:i', strtotime($request['match_time']));
            $request['request_date_formatted'] = date('d/m/Y H:i', strtotime($request['request_date']));
            
            if ($request['responded_at']) {
                $request['responded_at_formatted'] = date('d/m/Y H:i', strtotime($request['responded_at']));
            }
        }

        echo json_encode([
            'success' => true,
            'message' => 'Demandes récupérées avec succès.',
            'data' => [
                'requests' => $requests,
                'type' => $type,
                'total' => count($requests)
            ]
        ]);

    } catch (\PDOException $e) {
        error_log("get_match_requests.php: Erreur PDO: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la récupération des demandes: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
}
?>

