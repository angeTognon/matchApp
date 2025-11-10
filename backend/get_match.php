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
    $matchId = $_GET['id'] ?? '';

    if (empty($matchId)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID du match manquant.']);
        exit;
    }

    try {
        // Récupérer les détails du match
        $stmt = $pdo->prepare("
            SELECT 
                m.*,
                t.name as team_name,
                t.club_name,
                t.logo as team_logo,
                t.description as team_description,
                t.home_stadium,
                t.category,
                t.level,
                u.name as coach_name,
                u.location as coach_location,
                u.avatar as coach_avatar,
                u.phone as coach_phone,
                u.license_number,
                u.experience,
                COUNT(mr.id) as requests_count,
                DATE(m.match_date) as date,
                TIME(m.match_date) as time,
                m.result as status
            FROM amicalclub_matches m
            JOIN amicalclub_teams t ON m.team_id = t.id
            JOIN amicalclub_users u ON t.coach_id = u.id
            LEFT JOIN amicalclub_match_requests mr ON m.id = mr.match_id AND mr.status = 'pending'
            WHERE m.id = ?
            GROUP BY m.id
        ");
        $stmt->execute([$matchId]);
        $match = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$match) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Match non trouvé.']);
            exit;
        }

        // Récupérer les demandes de match
        $stmt = $pdo->prepare("
            SELECT 
                mr.*,
                t.name as requesting_team_name,
                t.club_name as requesting_club_name,
                t.logo as requesting_team_logo,
                u.name as requesting_coach_name,
                u.avatar as requesting_coach_avatar
            FROM amicalclub_match_requests mr
            JOIN amicalclub_teams t ON mr.requesting_team_id = t.id
            JOIN amicalclub_users u ON t.coach_id = u.id
            WHERE mr.match_id = ?
            ORDER BY mr.created_at DESC
        ");
        $stmt->execute([$matchId]);
        $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Vérifier si l'utilisateur a déjà fait une demande pour ce match
        $stmt = $pdo->prepare("
            SELECT mr.*, t.name as team_name
            FROM amicalclub_match_requests mr
            JOIN amicalclub_teams t ON mr.requesting_team_id = t.id
            WHERE mr.match_id = ? AND t.coach_id = ?
        ");
        $stmt->execute([$matchId, $userId]);
        $userRequest = $stmt->fetch(PDO::FETCH_ASSOC);

        // Ajouter des données calculées
        $match['distance'] = _calculateFakeDistance($match['coach_location']);
        $match['status_display'] = _getStatusDisplay($match['status']);
        $match['status_color'] = _getStatusColor($match['status']);
        $match['date_formatted'] = date('d/m/Y', strtotime($match['date']));
        $match['time_formatted'] = date('H:i', strtotime($match['time']));
        // Déterminer si l'utilisateur est propriétaire du match
        $stmt = $pdo->prepare("SELECT coach_id FROM amicalclub_teams WHERE id = ?");
        $stmt->execute([$match['team_id']]);
        $team = $stmt->fetch(PDO::FETCH_ASSOC);
        $match['is_owner'] = ($team && $team['coach_id'] == $userId);
        $match['user_has_requested'] = !empty($userRequest);
        $match['user_request'] = $userRequest;

        // Nettoyer les données sensibles
        unset($match['coach_location']);

        echo json_encode([
            'success' => true,
            'message' => 'Détails du match récupérés avec succès.',
            'data' => [
                'match' => $match,
                'requests' => $requests
            ]
        ]);

    } catch (\PDOException $e) {
        error_log("get_match.php: Erreur PDO: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la récupération du match: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
}

// Fonction utilitaire pour calculer une distance fictive
function _calculateFakeDistance($location) {
    $distances = ['0.5 km', '1.2 km', '2.5 km', '3.8 km', '5.1 km', '7.3 km', '9.6 km', '12.4 km', '15.7 km'];
    return $distances[array_rand($distances)];
}

// Fonction utilitaire pour obtenir l'affichage du statut
function _getStatusDisplay($status) {
    switch ($status) {
        case 'available':
            return 'Disponible';
        case 'pending':
            return 'En attente';
        case 'confirmed':
            return 'Confirmé';
        case 'finished':
            return 'Terminé';
        default:
            return 'Disponible';
    }
}

// Fonction utilitaire pour obtenir la couleur du statut
function _getStatusColor($status) {
    switch ($status) {
        case 'available':
            return '#2E7D32';
        case 'pending':
            return '#FFA726';
        case 'confirmed':
            return '#003366';
        case 'finished':
            return '#999999';
        default:
            return '#2E7D32';
    }
}
?>
