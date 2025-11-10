<?php
require_once 'db.php';

// Récupérer le token depuis les headers
$headers = getallheaders();
$token = isset($headers['Authorization']) ? str_replace('Bearer ', '', $headers['Authorization']) : null;

if (!$token) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Token manquant'
    ]);
    exit;
}

try {
    // Supprimer le token de session
    $stmt = $pdo->prepare("DELETE FROM amicalclub_sessions WHERE token = ?");
    $stmt->execute([$token]);

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Déconnexion réussie'
    ]);

} catch (\PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la déconnexion',
        'error' => $e->getMessage()
    ]);
}
?>

