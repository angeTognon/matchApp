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

    error_log("add_match_details.php: Données reçues: " . json_encode($data));

    // Validation
    if (!isset($data['match_id']) || empty($data['match_id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID du match manquant.']);
        exit;
    }

    if (!isset($data['score']) || empty($data['score'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Score manquant.']);
        exit;
    }

    if (!isset($data['result']) || !in_array($data['result'], ['win', 'draw', 'loss'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Résultat invalide.']);
        exit;
    }

    try {
        // Vérifier que le match existe et que les 2 équipes ont confirmé
        $stmt = $pdo->prepare("
            SELECT m.*, t.coach_id
            FROM amicalclub_matches m
            JOIN amicalclub_teams t ON m.team_id = t.id
            WHERE m.id = ?
        ");
        $stmt->execute([$data['match_id']]);
        $match = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$match) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Match non trouvé.']);
            exit;
        }

        // Vérifier que l'utilisateur est le créateur du match
        if ($match['coach_id'] != $userId) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Seul le créateur du match peut ajouter les détails.']);
            exit;
        }

        // Vérifier que les deux équipes ont confirmé
        if (!$match['both_confirmed']) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Les deux équipes doivent d\'abord confirmer que le match est terminé.']);
            exit;
        }

        // Préparer les données
        $homeScorers = isset($data['home_scorers']) && !empty($data['home_scorers']) 
            ? json_encode($data['home_scorers']) 
            : null;
        $awayScorers = isset($data['away_scorers']) && !empty($data['away_scorers']) 
            ? json_encode($data['away_scorers']) 
            : null;
        $yellowCards = isset($data['yellow_cards']) && !empty($data['yellow_cards'])
            ? implode(',', $data['yellow_cards'])
            : null;
        $redCards = isset($data['red_cards']) && !empty($data['red_cards'])
            ? implode(',', $data['red_cards'])
            : null;

        // Mettre à jour le match avec tous les détails
        $stmt = $pdo->prepare("
            UPDATE amicalclub_matches 
            SET 
                score = ?,
                result = ?,
                home_scorers = ?,
                away_scorers = ?,
                man_of_match = ?,
                yellow_cards = ?,
                red_cards = ?,
                match_summary = ?,
                notes = ?,
                updated_at = NOW()
            WHERE id = ?
        ");

        $stmt->execute([
            $data['score'],
            $data['result'],
            $homeScorers,
            $awayScorers,
            $data['man_of_match'] ?? null,
            $yellowCards,
            $redCards,
            $data['match_summary'] ?? null,
            $data['notes'] ?? null,
            $data['match_id']
        ]);

        // Récupérer le match mis à jour
        $stmt = $pdo->prepare("
            SELECT 
                m.*,
                t.name as team_name,
                t.club_name,
                t.logo as team_logo,
                t.category,
                t.level,
                DATE(m.match_date) as date,
                TIME(m.match_date) as time
            FROM amicalclub_matches m
            JOIN amicalclub_teams t ON m.team_id = t.id
            WHERE m.id = ?
        ");
        $stmt->execute([$data['match_id']]);
        $updatedMatch = $stmt->fetch(PDO::FETCH_ASSOC);

        echo json_encode([
            'success' => true,
            'message' => 'Détails du match enregistrés avec succès.',
            'data' => [
                'match' => $updatedMatch
            ]
        ]);

    } catch (\PDOException $e) {
        error_log("add_match_details.php: Erreur PDO: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
}
?>

