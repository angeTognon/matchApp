<?php
require_once 'db.php';
require_once 'jwt_utils.php';

// Récupérer les données JSON de la requête
$data = json_decode(file_get_contents('php://input'), true);

// Validation des données
if (empty($data['email']) || empty($data['password']) || empty($data['name'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Veuillez fournir tous les champs obligatoires (email, password, name)'
    ]);
    exit;
}

$email = filter_var($data['email'], FILTER_SANITIZE_EMAIL);
$password = $data['password'];
$name = htmlspecialchars($data['name'], ENT_QUOTES, 'UTF-8');
$location = isset($data['location']) ? htmlspecialchars($data['location'], ENT_QUOTES, 'UTF-8') : null;
$license_number = isset($data['license_number']) ? htmlspecialchars($data['license_number'], ENT_QUOTES, 'UTF-8') : null;
$experience = isset($data['experience']) ? htmlspecialchars($data['experience'], ENT_QUOTES, 'UTF-8') : null;
$phone = isset($data['phone']) ? htmlspecialchars($data['phone'], ENT_QUOTES, 'UTF-8') : null;

// Validation email
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Adresse email invalide'
    ]);
    exit;
}

// Validation mot de passe
if (strlen($password) < 6) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Le mot de passe doit contenir au moins 6 caractères'
    ]);
    exit;
}

try {
    // Vérifier si l'email existe déjà
    $stmt = $pdo->prepare("SELECT id FROM amicalclub_users WHERE email = ?");
    $stmt->execute([$email]);
    
    if ($stmt->fetch()) {
        http_response_code(409);
        echo json_encode([
            'success' => false,
            'message' => 'Cette adresse email est déjà utilisée'
        ]);
        exit;
    }

    // Hasher le mot de passe
    $hashedPassword = hashPassword($password);

    // Insérer l'utilisateur
    $stmt = $pdo->prepare("
        INSERT INTO amicalclub_users (email, password, name, location, license_number, experience, phone) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ");
    
    $stmt->execute([
        $email, 
        $hashedPassword, 
        $name, 
        $location, 
        $license_number, 
        $experience, 
        $phone
    ]);

    $userId = $pdo->lastInsertId();

    // Créer une équipe si les informations sont fournies
    if (isset($data['team_name']) && !empty($data['team_name'])) {
        $teamName = htmlspecialchars($data['team_name'], ENT_QUOTES, 'UTF-8');
        $clubName = isset($data['club_name']) ? htmlspecialchars($data['club_name'], ENT_QUOTES, 'UTF-8') : null;
        $category = isset($data['category']) ? htmlspecialchars($data['category'], ENT_QUOTES, 'UTF-8') : null;
        $level = isset($data['level']) ? htmlspecialchars($data['level'], ENT_QUOTES, 'UTF-8') : null;

        $stmt = $pdo->prepare("
            INSERT INTO amicalclub_teams (coach_id, name, club_name, category, level, location) 
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $userId,
            $teamName,
            $clubName,
            $category,
            $level,
            $location
        ]);
    }

    // Générer un token JWT
    $headers = ['alg' => 'HS256', 'typ' => 'JWT'];
    $payload = [
        'user_id' => $userId, 
        'email' => $data['email'], 
        'exp' => time() + (3600 * 24 * 7) // Expire dans 7 jours
    ];
    $token = generate_jwt($headers, $payload);

    // Récupérer les informations de l'utilisateur créé
    $stmt = $pdo->prepare("SELECT id, email, name, location, license_number, experience, phone FROM amicalclub_users WHERE id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Inscription réussie',
        'data' => [
            'user' => $user,
            'token' => $token
        ]
    ]);

} catch (\PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de l\'inscription',
        'error' => $e->getMessage()
    ]);
}
?>

