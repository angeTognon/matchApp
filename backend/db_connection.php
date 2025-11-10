<?php
// Configuration de la base de données (SANS headers)
// Ce fichier est destiné à être inclus dans d'autres scripts

$host = 'localhost';
$db   = 'u145148450_guya';
$user = 'u145148450_guya';
$pass = 'Guyaapp02@';
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
    error_log("Erreur de connexion DB: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Erreur de connexion à la base de données.',
        'error' => $e->getMessage()
    ]);
    exit;
}

// Fonction utilitaire pour générer un token de session
function generateToken($length = 64) {
    return bin2hex(random_bytes($length / 2));
}

// Fonction pour vérifier un token de session
function verifyToken($pdo, $token) {
    $stmt = $pdo->prepare("
        SELECT u.*, s.token 
        FROM amicalclub_sessions s
        JOIN amicalclub_users u ON s.user_id = u.id
        WHERE s.token = ? AND s.expires_at > NOW()
    ");
    $stmt->execute([$token]);
    return $stmt->fetch();
}

// Fonction pour hasher les mots de passe
function hashPassword($password) {
    return password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
}

// Fonction pour vérifier les mots de passe
function verifyPassword($password, $hash) {
    return password_verify($password, $hash);
}
?>

