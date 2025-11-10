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

    // Récupérer les paramètres de filtrage
    $category = $_GET['category'] ?? '';
    $level = $_GET['level'] ?? '';
    $gender = $_GET['gender'] ?? '';
    $search = $_GET['search'] ?? '';
    $status = $_GET['status'] ?? 'pending';
    $limit = (int)($_GET['limit'] ?? 50);
    $offset = (int)($_GET['offset'] ?? 0);

    try {
        // Construire la requête avec filtres
        $whereConditions = ["m.result = ?"];
        $params = [$status];

        if (!empty($category)) {
            $whereConditions[] = "m.category = ?";
            $params[] = $category;
        }

        if (!empty($level)) {
            $whereConditions[] = "m.level = ?";
            $params[] = $level;
        }

        if (!empty($gender)) {
            $whereConditions[] = "m.gender = ?";
            $params[] = $gender;
        }

        if (!empty($search)) {
            $whereConditions[] = "(t.name LIKE ? OR t.club_name LIKE ? OR m.location LIKE ?)";
            $searchTerm = "%$search%";
            $params[] = $searchTerm;
            $params[] = $searchTerm;
            $params[] = $searchTerm;
        }

        $whereClause = implode(' AND ', $whereConditions);

        // Requête principale
        $sql = "
            SELECT 
                m.*,
                t.id as team_id,
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
                COUNT(DISTINCT CASE WHEN mr.status = 'pending' THEN mr.id END) as requests_count,
                COUNT(DISTINCT CASE WHEN mr.status = 'accepted' THEN mr.id END) as accepted_count,
                DATE(m.match_date) as date,
                TIME(m.match_date) as time,
                m.result as status,
                m.opponent
            FROM amicalclub_matches m
            JOIN amicalclub_teams t ON m.team_id = t.id
            JOIN amicalclub_users u ON t.coach_id = u.id
            LEFT JOIN amicalclub_match_requests mr ON m.id = mr.match_id
            WHERE $whereClause
            GROUP BY m.id
            ORDER BY m.match_date ASC
            LIMIT ? OFFSET ?
        ";

        $params[] = $limit;
        $params[] = $offset;

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $matches = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Ajouter des données calculées et formater
        foreach ($matches as &$match) {
            // Calculer la distance (simulation)
            $match['distance'] = _calculateFakeDistance($match['coach_location']);
            
            // Formater le statut
            $match['status_display'] = _getStatusDisplay($match['status']);
            $match['status_color'] = _getStatusColor($match['status']);
            
            // Formater la date
            $match['date_formatted'] = date('d/m/Y', strtotime($match['date']));
            $match['time_formatted'] = date('H:i', strtotime($match['time']));
            
            // Nettoyer les données
            unset($match['coach_location']);
        }

        // Compter le total pour la pagination
        $countSql = "
            SELECT COUNT(*) as total
            FROM amicalclub_matches m
            JOIN amicalclub_teams t ON m.team_id = t.id
            JOIN amicalclub_users u ON t.coach_id = u.id
            WHERE $whereClause
        ";
        $countParams = array_slice($params, 0, -2); // Enlever limit et offset
        $stmt = $pdo->prepare($countSql);
        $stmt->execute($countParams);
        $total = $stmt->fetch(PDO::FETCH_ASSOC)['total'];

        echo json_encode([
            'success' => true,
            'message' => 'Matchs récupérés avec succès.',
            'data' => [
                'matches' => $matches,
                'total' => $total,
                'limit' => $limit,
                'offset' => $offset
            ]
        ]);

    } catch (\PDOException $e) {
        error_log("get_matches.php: Erreur PDO: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la récupération des matchs: ' . $e->getMessage()]);
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
        case 'pending':
            return 'En attente';
        case 'win':
            return 'Victoire';
        case 'draw':
            return 'Match nul';
        case 'loss':
            return 'Défaite';
        default:
            return 'En attente';
    }
}

// Fonction utilitaire pour obtenir la couleur du statut
function _getStatusColor($status) {
    switch ($status) {
        case 'pending':
            return '#FFA726';
        case 'win':
            return '#2E7D32';
        case 'draw':
            return '#FFA726';
        case 'loss':
            return '#D32F2F';
        default:
            return '#FFA726';
    }
}
?>
