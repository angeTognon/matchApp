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

    $coach_id = $payload['user_id'];
    
    try {
        $pdo = get_db_connection();
    
    // Récupérer les matchs du coach avec les détails de l'équipe
    $stmt = $pdo->prepare("
        SELECT 
            m.*,
            t.name as team_name,
            t.club_name,
            t.logo as team_logo,
            t.category,
            t.level,
            u.name as coach_name,
            u.location as coach_location,
            u.avatar as coach_avatar,
            COUNT(mr.id) as requests_count,
            DATE(m.match_date) as date,
            TIME(m.match_date) as time,
            m.result as status
        FROM amicalclub_matches m
        JOIN amicalclub_teams t ON m.team_id = t.id
        JOIN amicalclub_users u ON t.coach_id = u.id
        LEFT JOIN amicalclub_match_requests mr ON m.id = mr.match_id AND mr.status = 'pending'
        WHERE t.coach_id = ?
        GROUP BY m.id
        ORDER BY m.match_date DESC
    ");
    
        $stmt->execute([$coach_id]);
        $matches = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Traiter les matchs pour ajouter des informations supplémentaires
    foreach ($matches as &$match) {
        // Calculer la distance (simulée)
        $match['distance'] = _calculateFakeDistance();
        
        // Dernière activité (simulée)
        $match['last_active'] = _getFakeLastActive();
        
        // Statut d'affichage
        $match['status_display'] = _getStatusDisplay($match['status']);
        $match['status_color'] = _getStatusColor($match['status']);
        
        // Parser les équipements
        if (!empty($match['facilities'])) {
            try {
                if (strpos($match['facilities'], '[') === 0) {
                    $match['facilities'] = json_decode($match['facilities'], true);
                } else {
                    $match['facilities'] = array_map('trim', explode(',', $match['facilities']));
                }
            } catch (Exception $e) {
                $match['facilities'] = [];
            }
        } else {
            $match['facilities'] = [];
        }
    }
    
        echo json_encode([
            'success' => true,
            'data' => [
                'matches' => $matches,
                'total' => count($matches)
            ]
        ]);
        
    } catch (Exception $e) {
        error_log("Erreur get_my_matches: " . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Erreur serveur: ' . $e->getMessage()
        ]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée']);
}

// Fonction pour calculer une distance simulée
function _calculateFakeDistance() {
    return rand(1, 50) . ' km';
}

// Fonction pour obtenir une dernière activité simulée
function _getFakeLastActive() {
    $activities = ['Il y a 2h', 'Il y a 1j', 'Il y a 3j', 'Il y a 1 semaine'];
    return $activities[array_rand($activities)];
}

// Fonction pour obtenir l'affichage du statut
function _getStatusDisplay($status) {
    switch ($status) {
        case 'pending':
            return 'En attente';
        case 'win':
            return 'Gagné';
        case 'draw':
            return 'Nul';
        case 'loss':
            return 'Perdu';
        default:
            return 'Inconnu';
    }
}

// Fonction pour obtenir la couleur du statut
function _getStatusColor($status) {
    switch ($status) {
        case 'pending':
            return '#FFA500'; // Orange
        case 'win':
            return '#4CAF50'; // Vert
        case 'draw':
            return '#2196F3'; // Bleu
        case 'loss':
            return '#F44336'; // Rouge
        default:
            return '#9E9E9E'; // Gris
    }
}
?>
