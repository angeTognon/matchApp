<?php
require_once 'db.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        // Récupérer toutes les équipes avec les informations du coach
        $stmt = $pdo->prepare("
            SELECT t.id, t.name, t.club_name, t.category, t.level, t.location,
                   t.description, t.logo, t.founded, t.home_stadium, t.achievements,
                   u.name as coach_name, u.location as coach_location
            FROM amicalclub_teams t
            JOIN amicalclub_users u ON t.coach_id = u.id
            ORDER BY t.created_at DESC
        ");

        $stmt->execute();
        $teams = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Ajouter des informations de statut fictives pour la recherche
        foreach ($teams as &$team) {
            // Ajouter une distance fictive basée sur la localisation
            $team['distance'] = _calculateFakeDistance($team['location']);

            // Ajouter une dernière activité fictive
            $team['lastActive'] = _getFakeLastActive();

            // Nettoyer les données
            unset($team['coach_location']);
        }

        echo json_encode([
            'success' => true,
            'message' => 'Équipes récupérées avec succès.',
            'data' => $teams
        ]);

    } catch (\PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Erreur lors de la récupération des équipes: ' . $e->getMessage()
        ]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
}

// Fonction utilitaire pour calculer une distance fictive
function _calculateFakeDistance($location) {
    $distances = ['1.2 km', '2.5 km', '3.8 km', '5.1 km', '7.3 km', '9.6 km', '12.4 km', '15.7 km'];
    return $distances[array_rand($distances)];
}

// Fonction utilitaire pour générer une dernière activité fictive
function _getFakeLastActive() {
    $activities = ['2 minutes', '15 minutes', '1 heure', '3 heures', '12 heures', '1 jour', '2 jours'];
    return $activities[array_rand($activities)];
}
?>
