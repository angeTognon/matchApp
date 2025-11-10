<?php
// Headers d'abord
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once 'db_connection.php';
require_once 'jwt_utils_safe.php';

error_log("====== DELETE MATCH START ======");

try {
    // Récupérer le token - Compatible tous serveurs
    $token = null;
    
    // Méthode 1: $_SERVER['HTTP_AUTHORIZATION']
    if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
        error_log("Token trouvé via HTTP_AUTHORIZATION");
        if (preg_match('/Bearer\s+(\S+)/', $authHeader, $matches)) {
            $token = $matches[1];
        }
    }
    
    // Méthode 2: $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
    if (!$token && isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $authHeader = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        error_log("Token trouvé via REDIRECT_HTTP_AUTHORIZATION");
        if (preg_match('/Bearer\s+(\S+)/', $authHeader, $matches)) {
            $token = $matches[1];
        }
    }
    
    // Méthode 3: getallheaders() si disponible
    if (!$token && function_exists('getallheaders')) {
        $headers = getallheaders();
        if (isset($headers['Authorization'])) {
            $authHeader = $headers['Authorization'];
            if (preg_match('/Bearer\s+(\S+)/', $authHeader, $matches)) {
                $token = $matches[1];
            }
        }
    }
    
    if (!$token) {
        error_log("Erreur: Token manquant");
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Token manquant']);
        exit;
    }
    
    error_log("Token trouvé: " . substr($token, 0, 20) . "...");
    
    // Vérifier le token
    $decoded = verifyJWT($token);
    if (!$decoded) {
        error_log("Erreur: Token invalide");
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Token invalide']);
        exit;
    }
    
    $coach_id = $decoded['user_id'];
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
    
    // La connexion $pdo est déjà fournie par db.php
    
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
    
    try {
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
        error_log("====== DELETE MATCH END (SUCCESS) ======");
        
        echo json_encode([
            'success' => true,
            'message' => 'Match supprimé avec succès'
        ]);
        
    } catch (Exception $e) {
        // Annuler la transaction en cas d'erreur
        $pdo->rollBack();
        error_log("Transaction annulée");
        throw $e;
    }
    
} catch (Exception $e) {
    error_log("====== ERREUR CRITIQUE ======");
    error_log("Type: " . get_class($e));
    error_log("Message: " . $e->getMessage());
    error_log("File: " . $e->getFile());
    error_log("Line: " . $e->getLine());
    error_log("Stack trace: " . $e->getTraceAsString());
    error_log("====== DELETE MATCH END (FAILED) ======");
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur serveur: ' . $e->getMessage(),
        'debug' => [
            'type' => get_class($e),
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ]
    ]);
}
?>
