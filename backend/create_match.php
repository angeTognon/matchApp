<?php
require_once 'db.php';
require_once 'jwt_utils.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $token = get_bearer_token();
    if (!$token || !($payload = verify_jwt($token))) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Non autorisé: Token invalide ou manquant.']);
        exit;
    }

    $userId = $payload['user_id'];
    $data = json_decode(file_get_contents('php://input'), true);

    error_log("create_match.php: Données reçues: " . json_encode($data));

    // Validation des champs obligatoires
    $requiredFields = ['team_id', 'date', 'time', 'location', 'category'];
    foreach ($requiredFields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => "Le champ '$field' est obligatoire."]);
            exit;
        }
    }

    try {
        // Vérifier que l'équipe appartient à l'utilisateur
        $stmt = $pdo->prepare("SELECT id, name, club_name FROM amicalclub_teams WHERE id = ? AND coach_id = ?");
        $stmt->execute([$data['team_id'], $userId]);
        $team = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$team) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Équipe non trouvée ou non autorisée.']);
            exit;
        }

        // Validation de la date (format seulement)
        error_log("create_match.php: Date reçue: " . $data['date']);
        $matchDate = DateTime::createFromFormat('Y-m-d', $data['date']);
        
        if (!$matchDate) {
            error_log("create_match.php: Erreur de parsing de la date");
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Format de date invalide.']);
            exit;
        }
        
        error_log("create_match.php: Date validée avec succès");

        // Combiner date et heure pour créer un datetime
        $dateTime = $data['date'] . ' ' . $data['time'] . ':00';
        $matchDateTime = DateTime::createFromFormat('Y-m-d H:i:s', $dateTime);
        
        if (!$matchDateTime) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Format de date/heure invalide.']);
            exit;
        }

        // Préparer les équipements
        $facilities = null;
        if (isset($data['facilities']) && is_array($data['facilities']) && !empty($data['facilities'])) {
            $facilities = json_encode($data['facilities']);
        }

        // Insérer le match avec la structure de votre table
        $stmt = $pdo->prepare("
            INSERT INTO amicalclub_matches (
                team_id, opponent, match_date, location, notes, facilities, result
            ) VALUES (?, ?, ?, ?, ?, ?, 'pending')
        ");

        $stmt->execute([
            $data['team_id'],
            'Équipe à déterminer', // opponent - sera mis à jour quand une équipe accepte
            $matchDateTime->format('Y-m-d H:i:s'),
            htmlspecialchars($data['location'], ENT_QUOTES, 'UTF-8'),
            isset($data['description']) ? htmlspecialchars($data['description'], ENT_QUOTES, 'UTF-8') : null,
            $facilities,
        ]);

        $matchId = $pdo->lastInsertId();

        // Récupérer le match créé avec les informations de l'équipe
        $stmt = $pdo->prepare("
            SELECT 
                m.*,
                t.name as team_name,
                t.club_name,
                t.logo as team_logo,
                u.name as coach_name,
                u.location as coach_location,
                DATE(m.match_date) as date,
                TIME(m.match_date) as time,
                m.result as status
            FROM amicalclub_matches m
            JOIN amicalclub_teams t ON m.team_id = t.id
            JOIN amicalclub_users u ON t.coach_id = u.id
            WHERE m.id = ?
        ");
        $stmt->execute([$matchId]);
        $match = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($match) {
            // Ajouter des données calculées
            $match['distance'] = '0 km'; // À calculer côté client
            $match['requests_count'] = 0;
            $match['status_display'] = 'En attente';
            $match['status_color'] = '#FFA726';
        }

        http_response_code(201);
        echo json_encode([
            'success' => true,
            'message' => 'Match publié avec succès.',
            'data' => $match
        ]);

    } catch (\PDOException $e) {
        error_log("create_match.php: Erreur PDO: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la création du match: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
}
?>
