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

    error_log("update_match_score.php: Données reçues: " . json_encode($data));

    // Validation des champs obligatoires
    $requiredFields = ['match_id', 'home_score', 'away_score'];
    foreach ($requiredFields as $field) {
        if (!isset($data[$field]) || $data[$field] === '') {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => "Le champ '$field' est obligatoire."]);
            exit;
        }
    }

    try {
        // Vérifier que le match existe et appartient à l'utilisateur
        $stmt = $pdo->prepare("
            SELECT m.*, t.name as team_name, u.name as coach_name
            FROM amicalclub_matches m
            JOIN amicalclub_teams t ON m.team_id = t.id
            JOIN amicalclub_users u ON m.coach_id = u.id
            WHERE m.id = ? AND m.coach_id = ?
        ");
        $stmt->execute([$data['match_id'], $userId]);
        $match = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$match) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Match non trouvé ou non autorisé.']);
            exit;
        }

        // Vérifier que le match est confirmé
        if ($match['status'] !== 'confirmed') {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Le match doit être confirmé pour saisir le score.']);
            exit;
        }

        // Valider les scores (doivent être des nombres)
        if (!is_numeric($data['home_score']) || !is_numeric($data['away_score'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Les scores doivent être des nombres valides.']);
            exit;
        }

        // Préparer les données pour la mise à jour
        $homeScorers = isset($data['home_scorers']) && is_array($data['home_scorers']) 
            ? implode(',', array_map('htmlspecialchars', $data['home_scorers'])) 
            : null;
        $awayScorers = isset($data['away_scorers']) && is_array($data['away_scorers']) 
            ? implode(',', array_map('htmlspecialchars', $data['away_scorers'])) 
            : null;
        $notes = isset($data['notes']) ? htmlspecialchars($data['notes'], ENT_QUOTES, 'UTF-8') : null;

        // Mettre à jour le match
        $stmt = $pdo->prepare("
            UPDATE amicalclub_matches 
            SET 
                home_score = ?,
                away_score = ?,
                home_scorers = ?,
                away_scorers = ?,
                notes = ?,
                status = 'finished',
                updated_at = NOW()
            WHERE id = ?
        ");

        $stmt->execute([
            $data['home_score'],
            $data['away_score'],
            $homeScorers,
            $awayScorers,
            $notes,
            $data['match_id']
        ]);

        if ($stmt->rowCount() > 0) {
            // Récupérer le match mis à jour
            $stmt = $pdo->prepare("
                SELECT 
                    m.*,
                    t.name as team_name,
                    t.club_name,
                    t.logo as team_logo,
                    u.name as coach_name,
                    u.avatar as coach_avatar
                FROM amicalclub_matches m
                JOIN amicalclub_teams t ON m.team_id = t.id
                JOIN amicalclub_users u ON m.coach_id = u.id
                WHERE m.id = ?
            ");
            $stmt->execute([$data['match_id']]);
            $updatedMatch = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($updatedMatch) {
                // Ajouter des données calculées
                $updatedMatch['distance'] = '0 km'; // À calculer côté client
                $updatedMatch['status_display'] = 'Terminé';
                $updatedMatch['status_color'] = '#999999';
                $updatedMatch['date_formatted'] = date('d/m/Y', strtotime($updatedMatch['date']));
                $updatedMatch['time_formatted'] = date('H:i', strtotime($updatedMatch['time']));
            }

            echo json_encode([
                'success' => true,
                'message' => 'Score mis à jour avec succès.',
                'data' => $updatedMatch
            ]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour du score.']);
        }

    } catch (\PDOException $e) {
        error_log("update_match_score.php: Erreur PDO: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour du score: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
}
?>
