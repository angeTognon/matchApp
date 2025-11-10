<?php
require_once 'db.php';
require_once 'jwt_utils.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    error_log("update_profile.php: Requête reçue");

    $token = get_bearer_token();
    error_log("update_profile.php: Token reçu: " . $token);

    if (!$token || !($payload = verify_jwt($token))) {
        error_log("update_profile.php: Token invalide");
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Non autorisé: Token invalide ou manquant.']);
        exit;
    }

    $userId = $payload['user_id'];
    error_log("update_profile.php: User ID extrait: " . $userId);

    $data = json_decode(file_get_contents('php://input'), true);
    error_log("update_profile.php: Données reçues: " . json_encode($data));

    $name = $data['name'] ?? '';
    $location = $data['location'] ?? '';
    $licenseNumber = $data['license_number'] ?? '';
    $experience = $data['experience'] ?? '';
    $avatar = $data['avatar'] ?? null;

    error_log("update_profile.php: Champs extraits - name: $name, location: $location, license: $licenseNumber, experience: $experience, avatar: $avatar");

    if (empty($name)) {
        error_log("update_profile.php: Nom vide");
        echo json_encode(['success' => false, 'message' => 'Le nom est obligatoire.']);
        exit;
    }

    try {
        error_log("update_profile.php: Exécution de la requête UPDATE");
        // Construire la requête UPDATE dynamiquement
        $fields = ['name', 'location', 'license_number', 'experience'];
        $values = [$name, $location, $licenseNumber, $experience];

        if ($avatar !== null) {
            $fields[] = 'avatar';
            $values[] = $avatar;
        }

        $setClause = implode(' = ?, ', $fields) . ' = ?';
        $stmt = $pdo->prepare("UPDATE amicalclub_users SET $setClause WHERE id = ?");
        $values[] = $userId;

        $stmt->execute($values);

        error_log("update_profile.php: Lignes affectées: " . $stmt->rowCount());

        // Vérifier si l'utilisateur existe (au lieu de vérifier rowCount qui peut être 0 si rien n'a changé)
        $stmt = $pdo->prepare("SELECT id, name, location, license_number, experience, phone, avatar FROM amicalclub_users WHERE id = ?");
        $stmt->execute([$userId]);
        $updatedUser = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($updatedUser) {
            error_log("update_profile.php: Mise à jour réussie");
            error_log("update_profile.php: Utilisateur mis à jour: " . json_encode($updatedUser));

            // Récupérer les équipes de l'utilisateur
            $stmt = $pdo->prepare("SELECT id, name, club_name, category, level, location, description, logo, founded, home_stadium, achievements FROM amicalclub_teams WHERE coach_id = ?");
            $stmt->execute([$userId]);
            $teams = $stmt->fetchAll(PDO::FETCH_ASSOC);
            error_log("update_profile.php: Équipes récupérées: " . count($teams));

            $response = [
                'success' => true,
                'message' => 'Profil mis à jour avec succès.',
                'data' => [
                    'user' => $updatedUser,
                    'teams' => $teams
                ]
            ];
            error_log("update_profile.php: Réponse finale: " . json_encode($response));
            echo json_encode($response);
        } else {
            http_response_code(404);
            error_log("update_profile.php: Utilisateur non trouvé avec ID: " . $userId);
            echo json_encode(['success' => false, 'message' => 'Utilisateur non trouvé.']);
        }

    } catch (\PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour du profil: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
}
?>
