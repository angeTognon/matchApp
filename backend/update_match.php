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

// Logs de débogage
error_log("====== UPDATE MATCH START ======");

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
        error_log("Headers via getallheaders: " . print_r($headers, true));
        if (isset($headers['Authorization'])) {
            $authHeader = $headers['Authorization'];
            if (preg_match('/Bearer\s+(\S+)/', $authHeader, $matches)) {
                $token = $matches[1];
            }
        }
    }
    
    if (!$token) {
        error_log("Erreur: Token manquant - Aucune méthode n'a fonctionné");
        error_log("SERVER vars: " . print_r($_SERVER, true));
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
    error_log("Input décodé: " . print_r($input, true));
    
    if (!$input) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Données JSON invalides']);
        exit;
    }
    
    // Validation des champs requis
    $required_fields = ['match_id', 'team_id', 'date', 'time', 'location', 'category'];
    foreach ($required_fields as $field) {
        if (!isset($input[$field]) || empty($input[$field])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => "Le champ $field est requis"]);
            exit;
        }
    }
    
    $match_id = $input['match_id'];
    $team_id = $input['team_id'];
    
    error_log("Match ID: $match_id, Team ID: $team_id");
    
    // Récupérer les données optionnelles
    $category = $input['category'] ?? '';
    $level = $input['level'] ?? '';
    $gender = $input['gender'] ?? '';
    $team_location = $input['team_location'] ?? '';
    $stadium = $input['stadium'] ?? '';
    $description = $input['description'] ?? '';
    
    error_log("===== DONNÉES REÇUES =====");
    error_log("Category: '$category' (isset: " . (isset($input['category']) ? 'oui' : 'non') . ")");
    error_log("Level: '$level' (isset: " . (isset($input['level']) ? 'oui' : 'non') . ")");
    error_log("Gender: '$gender' (isset: " . (isset($input['gender']) ? 'oui' : 'non') . ")");
    error_log("Team Location: '$team_location' (isset: " . (isset($input['team_location']) ? 'oui' : 'non') . ")");
    error_log("Stadium: '$stadium' (isset: " . (isset($input['stadium']) ? 'oui' : 'non') . ")");
    error_log("Description: '$description' (isset: " . (isset($input['description']) ? 'oui' : 'non') . ")");
    error_log("========================");
    
    // La connexion $pdo est déjà fournie par db.php
    error_log("Vérification de la connexion PDO: " . (isset($pdo) ? "OK" : "FAILED"));
    
    // Vérifier que le match appartient au coach
    $stmt = $pdo->prepare("
        SELECT m.id 
        FROM amicalclub_matches m
        JOIN amicalclub_teams t ON m.team_id = t.id
        WHERE m.id = ? AND t.coach_id = ?
    ");
    $stmt->execute([$match_id, $coach_id]);
    
    if ($stmt->rowCount() === 0) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Vous ne pouvez pas modifier ce match']);
        exit;
    }
    
    // Vérifier que l'équipe appartient au coach
    $stmt = $pdo->prepare("SELECT id FROM amicalclub_teams WHERE id = ? AND coach_id = ?");
    $stmt->execute([$team_id, $coach_id]);
    
    if ($stmt->rowCount() === 0) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Équipe non trouvée ou non autorisée']);
        exit;
    }
    
    // Mettre à jour la table amicalclub_teams
    $teamUpdateFields = [];
    $teamUpdateValues = [];
    
    // Toujours mettre à jour ces champs s'ils sont présents (même si vides)
    if (isset($input['category'])) {
        $teamUpdateFields[] = "category = ?";
        $teamUpdateValues[] = htmlspecialchars($category, ENT_QUOTES, 'UTF-8');
    }
    
    if (isset($input['level'])) {
        $teamUpdateFields[] = "level = ?";
        $teamUpdateValues[] = htmlspecialchars($level, ENT_QUOTES, 'UTF-8');
    }
    
    if (isset($input['team_location'])) {
        $teamUpdateFields[] = "location = ?";
        $teamUpdateValues[] = htmlspecialchars($team_location, ENT_QUOTES, 'UTF-8');
    }
    
    if (isset($input['stadium'])) {
        $teamUpdateFields[] = "home_stadium = ?";
        $teamUpdateValues[] = htmlspecialchars($stadium, ENT_QUOTES, 'UTF-8');
        error_log("Stadium sera mis à jour: $stadium");
    }
    
    if (isset($input['description'])) {
        $teamUpdateFields[] = "description = ?";
        $teamUpdateValues[] = htmlspecialchars($description, ENT_QUOTES, 'UTF-8');
        error_log("Description sera mise à jour: $description");
    }
    
    // Exécuter la mise à jour de l'équipe si nécessaire
    error_log("===== MISE À JOUR ÉQUIPE =====");
    error_log("Nombre de champs à mettre à jour: " . count($teamUpdateFields));
    error_log("Champs: " . implode(', ', $teamUpdateFields));
    
    if (!empty($teamUpdateFields)) {
        $teamUpdateValues[] = $team_id;
        $teamSql = "UPDATE amicalclub_teams SET " . implode(', ', $teamUpdateFields) . " WHERE id = ?";
        error_log("SQL Team Update: $teamSql");
        error_log("Team Update Values: " . print_r($teamUpdateValues, true));
        
        $stmt = $pdo->prepare($teamSql);
        $result = $stmt->execute($teamUpdateValues);
        $rowsAffected = $stmt->rowCount();
        
        error_log("Résultat exécution: " . ($result ? 'SUCCESS' : 'FAILED'));
        error_log("Nombre de lignes affectées: $rowsAffected");
        error_log("Team updated successfully");
    } else {
        error_log("No team fields to update");
    }
    error_log("============================");
    
    // Préparer la date et l'heure
    $date = $input['date'];
    $time = $input['time'];
    
    error_log("Date reçue: $date, Time reçu: $time");
    
    // Ajouter les secondes si elles ne sont pas présentes
    if (strlen($time) == 5) { // Format HH:MM
        $time .= ':00'; // Ajouter :00 pour les secondes
        error_log("Secondes ajoutées, nouveau time: $time");
    }
    
    // Valider le format de date - Essayer plusieurs formats
    $dateTime = DateTime::createFromFormat('Y-m-d H:i:s', $date . ' ' . $time);
    
    if (!$dateTime) {
        // Essayer sans les secondes
        $dateTime = DateTime::createFromFormat('Y-m-d H:i', $date . ' ' . $time);
    }
    
    if (!$dateTime) {
        error_log("Erreur: Format de date invalide - Date: $date, Time: $time");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Format de date/heure invalide']);
        exit;
    }
    
    error_log("DateTime créé avec succès: " . $dateTime->format('Y-m-d H:i:s'));
    
    // Préparer les équipements
    $facilities = null;
    if (isset($input['facilities']) && is_array($input['facilities']) && !empty($input['facilities'])) {
        $facilities = json_encode($input['facilities']);
    }
    
    // Construire la requête UPDATE pour amicalclub_matches
    $matchUpdateFields = [];
    $matchUpdateValues = [];
    
    $matchUpdateFields[] = "match_date = ?";
    $matchUpdateValues[] = $dateTime->format('Y-m-d H:i:s');
    
    $matchUpdateFields[] = "location = ?";
    $matchUpdateValues[] = htmlspecialchars($input['location'], ENT_QUOTES, 'UTF-8');
    
    // Notes du match (différent de la description de l'équipe)
    if (isset($input['match_notes'])) {
        $matchUpdateFields[] = "notes = ?";
        $matchUpdateValues[] = htmlspecialchars($input['match_notes'], ENT_QUOTES, 'UTF-8');
        error_log("Notes du match seront mises à jour: " . $input['match_notes']);
    }
    
    if (isset($input['facilities'])) {
        $matchUpdateFields[] = "facilities = ?";
        $matchUpdateValues[] = $facilities;
        error_log("Facilities seront mis à jour: " . json_encode($facilities));
    }
    
    $matchUpdateValues[] = $match_id;
    
    $matchSql = "UPDATE amicalclub_matches SET " . implode(', ', $matchUpdateFields) . " WHERE id = ?";
    
    error_log("SQL Match Update: $matchSql");
    error_log("Match Update Values: " . print_r($matchUpdateValues, true));
    
    $stmt = $pdo->prepare($matchSql);
    $stmt->execute($matchUpdateValues);
    
    error_log("Match updated successfully");
    
    // Récupérer le match mis à jour
    $stmt = $pdo->prepare("
        SELECT 
            m.*,
            t.name as team_name,
            t.club_name,
            t.logo as team_logo,
            t.category,
            t.level,
            u.name as coach_name,
            u.location as coach_location,
            u.avatar as coach_avatar,
            COUNT(mr.id) as requests_count,
            DATE(m.match_date) as date,
            TIME(m.match_date) as time,
            m.result as status
        FROM amicalclub_matches m
        JOIN amicalclub_teams t ON m.team_id = t.id
        JOIN amicalclub_users u ON t.coach_id = u.id
        LEFT JOIN amicalclub_match_requests mr ON m.id = mr.match_id AND mr.status = 'pending'
        WHERE m.id = ?
        GROUP BY m.id
    ");
    
    $stmt->execute([$match_id]);
    $updatedMatch = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($updatedMatch) {
        // Parser les équipements
        if (!empty($updatedMatch['facilities'])) {
            try {
                if (strpos($updatedMatch['facilities'], '[') === 0) {
                    $updatedMatch['facilities'] = json_decode($updatedMatch['facilities'], true);
                } else {
                    $updatedMatch['facilities'] = array_map('trim', explode(',', $updatedMatch['facilities']));
                }
            } catch (Exception $e) {
                $updatedMatch['facilities'] = [];
            }
        } else {
            $updatedMatch['facilities'] = [];
        }
    }
    
    $response = [
        'success' => true,
        'message' => 'Match mis à jour avec succès',
        'data' => $updatedMatch
    ];
    
    error_log("Réponse finale: " . json_encode($response));
    error_log("====== UPDATE MATCH END (SUCCESS) ======");
    
    echo json_encode($response);
    
} catch (Exception $e) {
    error_log("====== ERREUR CRITIQUE ======");
    error_log("Type: " . get_class($e));
    error_log("Message: " . $e->getMessage());
    error_log("File: " . $e->getFile());
    error_log("Line: " . $e->getLine());
    error_log("Stack trace: " . $e->getTraceAsString());
    error_log("====== UPDATE MATCH END (FAILED) ======");
    
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
