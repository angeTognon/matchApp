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

    $coachId = $payload['user_id'];
    $data = json_decode(file_get_contents('php://input'), true);

    $teamId = $data['team_id'] ?? '';

    if (empty($teamId)) {
        echo json_encode(['success' => false, 'message' => 'ID de l\'équipe manquant.']);
        exit;
    }

    try {
        // Vérifier que l'équipe appartient au coach
        $stmt = $pdo->prepare("SELECT id FROM amicalclub_teams WHERE id = ? AND coach_id = ?");
        $stmt->execute([$teamId, $coachId]);
        $team = $stmt->fetch();

        if (!$team) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Équipe non trouvée ou non autorisée.']);
            exit;
        }

        // Supprimer l'équipe (les contraintes de clé étrangère supprimeront automatiquement les matchs associés)
        $stmt = $pdo->prepare("DELETE FROM amicalclub_teams WHERE id = ? AND coach_id = ?");
        $stmt->execute([$teamId, $coachId]);

        if ($stmt->rowCount() > 0) {
            echo json_encode([
                'success' => true,
                'message' => 'Équipe supprimée avec succès.'
            ]);
        } else {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Équipe non trouvée ou non autorisée.']);
        }

    } catch (\PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la suppression de l\'équipe: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
}
?>
