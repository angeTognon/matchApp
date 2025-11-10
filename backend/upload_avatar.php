<?php
require_once 'db.php';
require_once 'jwt_utils.php';

header('Content-Type: application/json');

// Créer le dossier uploads s'il n'existe pas
$uploadDir = __DIR__ . '/uploads/avatars/';
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
    if (!isset($_FILES['avatar']) || $_FILES['avatar']['error'] !== UPLOAD_ERR_OK) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Aucun fichier uploadé ou erreur lors de l\'upload.']);
        exit;
    }

    $file = $_FILES['avatar'];

    error_log("upload_avatar.php: Fichier reçu - Nom: " . $file['name'] . ", Type: " . $file['type'] . ", Taille: " . $file['size']);

    // Vérifier le type de fichier
    $allowedTypes = ['image/jpeg', 'image/jpg', 'image/png'];
    $allowedExtensions = ['jpg', 'jpeg', 'png'];

    // Vérifier l'extension du fichier
    $extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    error_log("upload_avatar.php: Extension détectée: " . $extension);

    if (!in_array($extension, $allowedExtensions)) {
        error_log("upload_avatar.php: Extension non autorisée: " . $extension);
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Extension de fichier non autorisée. Utilisez JPG ou PNG.']);
        exit;
    }

    // Vérifier le type MIME si disponible
    if (!empty($file['type']) && !in_array($file['type'], $allowedTypes)) {
        error_log("upload_avatar.php: Type MIME inattendu: " . $file['type'] . " pour extension: " . $extension);
    }

    // Vérifier la taille du fichier (max 5MB)
    if ($file['size'] > 5 * 1024 * 1024) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Fichier trop volumineux. Taille maximale: 5MB.']);
        exit;
    }

    // Générer un nom de fichier unique
    $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $filename = 'avatar_' . $userId . '_' . time() . '.' . $extension;
    $filepath = $uploadDir . $filename;

    // Déplacer le fichier uploadé
    if (move_uploaded_file($file['tmp_name'], $filepath)) {
        // Construire l'URL relative pour la base de données
        $avatarUrl = 'uploads/avatars/' . $filename;

        try {
            // Mettre à jour l'avatar dans la base de données
            $stmt = $pdo->prepare("UPDATE amicalclub_users SET avatar = ? WHERE id = ?");
            $stmt->execute([$avatarUrl, $userId]);

            if ($stmt->rowCount() > 0) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Avatar uploadé et mis à jour avec succès.',
                    'data' => [
                        'avatar_url' => $avatarUrl
                    ]
                ]);
            } else {
                // Supprimer le fichier si la mise à jour BD a échoué
                unlink($filepath);
                http_response_code(500);
                echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour de la base de données.']);
            }

        } catch (\PDOException $e) {
            // Supprimer le fichier en cas d'erreur BD
            unlink($filepath);
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour de l\'avatar: ' . $e->getMessage()]);
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
