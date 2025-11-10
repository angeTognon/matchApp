<?php
require_once 'db.php';
require_once 'jwt_utils.php';

header('Content-Type: application/json');

// Créer le dossier uploads s'il n'existe pas
$uploadDir = __DIR__ . '/uploads/team_logos/';
if (!file_exists($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $token = get_bearer_token();
    if (!$token || !($payload = verify_jwt($token))) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Non autorisé: Token invalide ou manquant.']);
        exit;
    }

    $userId = $payload['user_id'];

    // Vérifier si un fichier a été uploadé
    if (!isset($_FILES['logo']) || $_FILES['logo']['error'] !== UPLOAD_ERR_OK) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Aucun fichier uploadé ou erreur lors de l\'upload.']);
        exit;
    }

    $file = $_FILES['logo'];
    $teamId = $_POST['team_id'] ?? 'new';

    error_log("upload_team_logo.php: Fichier reçu - Nom: " . $file['name'] . ", Type: " . $file['type'] . ", Taille: " . $file['size'] . ", Team ID: " . $teamId);

    // Vérifier le type de fichier
    $allowedTypes = ['image/jpeg', 'image/jpg', 'image/png'];
    $allowedExtensions = ['jpg', 'jpeg', 'png'];

    // Vérifier l'extension du fichier
    $extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    error_log("upload_team_logo.php: Extension détectée: " . $extension);

    if (!in_array($extension, $allowedExtensions)) {
        error_log("upload_team_logo.php: Extension non autorisée: " . $extension);
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Extension de fichier non autorisée. Utilisez JPG ou PNG.']);
        exit;
    }

    // Vérifier le type MIME si disponible
    if (!empty($file['type']) && !in_array($file['type'], $allowedTypes)) {
        error_log("upload_team_logo.php: Type MIME inattendu: " . $file['type'] . " pour extension: " . $extension);
    }

    // Vérifier la taille du fichier (max 5MB)
    if ($file['size'] > 5 * 1024 * 1024) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Fichier trop volumineux. Taille maximale: 5MB.']);
        exit;
    }

    // Générer un nom de fichier unique
    $filename = 'team_logo_' . $teamId . '_' . time() . '.' . $extension;
    $filepath = $uploadDir . $filename;

    // Déplacer le fichier uploadé
    if (move_uploaded_file($file['tmp_name'], $filepath)) {
        // Construire l'URL relative pour la base de données
        $logoUrl = 'uploads/team_logos/' . $filename;

        // Si c'est une équipe existante, mettre à jour la base de données
        if ($teamId !== 'new') {
            try {
                // Vérifier que l'équipe appartient à l'utilisateur
                $stmt = $pdo->prepare("SELECT id FROM amicalclub_teams WHERE id = ? AND coach_id = ?");
                $stmt->execute([$teamId, $userId]);
                $team = $stmt->fetch(PDO::FETCH_ASSOC);

                if (!$team) {
                    // Supprimer le fichier si l'équipe n'existe pas ou n'appartient pas à l'utilisateur
                    unlink($filepath);
                    http_response_code(403);
                    echo json_encode(['success' => false, 'message' => 'Équipe non trouvée ou non autorisée.']);
                    exit;
                }

                // Mettre à jour le logo dans la base de données
                $stmt = $pdo->prepare("UPDATE amicalclub_teams SET logo = ? WHERE id = ?");
                $stmt->execute([$logoUrl, $teamId]);

                echo json_encode([
                    'success' => true,
                    'message' => 'Logo uploadé et mis à jour avec succès.',
                    'data' => [
                        'logo_url' => $logoUrl
                    ]
                ]);
            } catch (\PDOException $e) {
                // Supprimer le fichier en cas d'erreur BD
                unlink($filepath);
                http_response_code(500);
                echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour du logo: ' . $e->getMessage()]);
            }
        } else {
            // Pour une nouvelle équipe, retourner juste l'URL
            echo json_encode([
                'success' => true,
                'message' => 'Logo uploadé avec succès.',
                'data' => [
                    'logo_url' => $logoUrl
                ]
            ]);
        }
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors du déplacement du fichier.']);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
}
?>

