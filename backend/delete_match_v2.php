<?php
// Version simplifiée et robuste de delete_match.php
error_reporting(E_ALL);
ini_set('display_errors', 0); // Pas d'affichage direct, tout dans les logs
ini_set('log_errors', 1);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

error_log("====== DELETE MATCH V2 START ======");

try {
    // Connexion à la base de données
    $host = 'localhost';
    $dbname = 'u145148450_guya';
    $username = 'u145148450_guya';
    $password = 'Guyaapp02@'; // Mot de passe correct
    
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
    
    error_log("Connexion DB OK");
    
    // Récupérer le token - Compatible tous serveurs
    $token = null;
    
    if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $token = str_replace('Bearer ', '', $_SERVER['HTTP_AUTHORIZATION']);
    } elseif (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $token = str_replace('Bearer ', '', $_SERVER['REDIRECT_HTTP_AUTHORIZATION']);
    } elseif (function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
        if (isset($headers['Authorization'])) {
            $token = str_replace('Bearer ', '', $headers['Authorization']);
        }
    }
    
    if (!$token) {
        error_log("Erreur: Token manquant");
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Token manquant']);
        exit;
    }
    
    error_log("Token trouvé: " . substr($token, 0, 20) . "...");
    
    // Décoder le token JWT (version simple)
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        error_log("Erreur: Token JWT invalide");
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Token invalide']);
        exit;
    }
    
    $payload = json_decode(base64_decode(str_replace(['-', '_'], ['+', '/'], $parts[1])), true);
    
    if (!$payload || !isset($payload['user_id'])) {
        error_log("Erreur: Payload JWT invalide");
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Token invalide']);
        exit;
    }
    
    $coach_id = $payload['user_id'];
    error_log("Coach ID: " . $coach_id);
    
    // Récupérer les données POST
    $rawInput = file_get_contents('php://input');
    error_log("Raw input: " . $rawInput);
    
    $input = json_decode($rawInput, true);
    
    if (!$input || !isset($input['match_id'])) {
        error_log("Erreur: ID du match manquant");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID du match requis']);
        exit;
    }
    
    $match_id = $input['match_id'];
    error_log("Match ID à supprimer: " . $match_id);
    
    // Vérifier que le match appartient au coach
    $stmt = $pdo->prepare("
        SELECT m.id 
        FROM amicalclub_matches m
        JOIN amicalclub_teams t ON m.team_id = t.id
        WHERE m.id = ? AND t.coach_id = ?
    ");
    $stmt->execute([$match_id, $coach_id]);
    
    if ($stmt->rowCount() === 0) {
        error_log("Erreur: Le match n'appartient pas au coach");
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Vous ne pouvez pas supprimer ce match']);
        exit;
    }
    
    error_log("Vérification OK - Le match appartient au coach");
    
    // Commencer une transaction
    $pdo->beginTransaction();
    error_log("Transaction démarrée");
    
    // Supprimer les demandes de match associées
    $stmt = $pdo->prepare("DELETE FROM amicalclub_match_requests WHERE match_id = ?");
    $stmt->execute([$match_id]);
    $deletedRequests = $stmt->rowCount();
    error_log("Demandes supprimées: " . $deletedRequests);
    
    // Supprimer le match
    $stmt = $pdo->prepare("DELETE FROM amicalclub_matches WHERE id = ?");
    $stmt->execute([$match_id]);
    error_log("Match supprimé");
    
    // Valider la transaction
    $pdo->commit();
    error_log("Transaction validée");
    error_log("====== DELETE MATCH V2 END (SUCCESS) ======");
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Match supprimé avec succès'
    ]);
    
} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
        error_log("Transaction annulée");
    }
    
    error_log("====== ERREUR CRITIQUE ======");
    error_log("Type: " . get_class($e));
    error_log("Message: " . $e->getMessage());
    error_log("File: " . $e->getFile());
    error_log("Line: " . $e->getLine());
    error_log("====== DELETE MATCH V2 END (FAILED) ======");
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur serveur: ' . $e->getMessage()
    ]);
}
?>

