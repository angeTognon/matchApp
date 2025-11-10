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

    error_log("confirm_match_completion.php: Données reçues: " . json_encode($data));

    // Validation
    if (!isset($data['match_id']) || empty($data['match_id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID du match manquant.']);
        exit;
    }

    try {
        // Récupérer le match et déterminer le rôle de l'utilisateur
        $stmt = $pdo->prepare("
            SELECT 
                m.*,
                host_team.coach_id as host_coach_id,
                mr.requesting_team_id,
                away_team.coach_id as away_coach_id
            FROM amicalclub_matches m
            JOIN amicalclub_teams host_team ON m.team_id = host_team.id
            LEFT JOIN amicalclub_match_requests mr ON m.id = mr.match_id AND mr.status = 'accepted'
            LEFT JOIN amicalclub_teams away_team ON mr.requesting_team_id = away_team.id
            WHERE m.id = ? AND m.result = 'confirmed'
        ");
        $stmt->execute([$data['match_id']]);
        $match = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$match) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Match non trouvé ou non confirmé.']);
            exit;
        }

        // Déterminer si l'utilisateur est l'équipe hôte ou l'équipe adverse
        $isHomeTeam = $match['host_coach_id'] == $userId;
        $isAwayTeam = $match['away_coach_id'] == $userId;

        if (!$isHomeTeam && !$isAwayTeam) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Vous n\'êtes pas impliqué dans ce match.']);
            exit;
        }

        // Mettre à jour la confirmation
        if ($isHomeTeam) {
            $stmt = $pdo->prepare("UPDATE amicalclub_matches SET home_confirmed = TRUE WHERE id = ?");
            $stmt->execute([$data['match_id']]);
            $confirmationType = 'home';
        } else {
            $stmt = $pdo->prepare("UPDATE amicalclub_matches SET away_confirmed = TRUE WHERE id = ?");
            $stmt->execute([$data['match_id']]);
            $confirmationType = 'away';
        }

        // Vérifier si les deux équipes ont confirmé
        $stmt = $pdo->prepare("SELECT home_confirmed, away_confirmed FROM amicalclub_matches WHERE id = ?");
        $stmt->execute([$data['match_id']]);
        $confirmations = $stmt->fetch(PDO::FETCH_ASSOC);

        $bothConfirmed = $confirmations['home_confirmed'] && $confirmations['away_confirmed'];

        // Si les deux ont confirmé, mettre à jour
        if ($bothConfirmed) {
            $stmt = $pdo->prepare("UPDATE amicalclub_matches SET both_confirmed = TRUE WHERE id = ?");
            $stmt->execute([$data['match_id']]);
        }

        echo json_encode([
            'success' => true,
            'message' => $bothConfirmed 
                ? 'Les deux équipes ont confirmé. Le créateur du match peut maintenant ajouter les détails.'
                : 'Confirmation enregistrée. En attente de la confirmation de l\'autre équipe.',
            'data' => [
                'confirmation_type' => $confirmationType,
                'home_confirmed' => $confirmations['home_confirmed'] == 1,
                'away_confirmed' => $confirmations['away_confirmed'] == 1,
                'both_confirmed' => $bothConfirmed
            ]
        ]);

    } catch (\PDOException $e) {
        error_log("confirm_match_completion.php: Erreur PDO: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
}
?>

