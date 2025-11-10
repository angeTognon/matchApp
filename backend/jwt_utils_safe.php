<?php
// Clé secrète pour signer les JWT (en production, utilisez une clé plus complexe)
define('JWT_SECRET', 'amical_club_secret_key_2024');

// Fonction pour extraire le token Bearer - Compatible tous serveurs
function get_bearer_token() {
    $token = null;
    
    // Méthode 1: $_SERVER['HTTP_AUTHORIZATION']
    if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        if (preg_match('/Bearer\s+(\S+)/', $_SERVER['HTTP_AUTHORIZATION'], $matches)) {
            return $matches[1];
        }
    }
    
    // Méthode 2: $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
    if (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        if (preg_match('/Bearer\s+(\S+)/', $_SERVER['REDIRECT_HTTP_AUTHORIZATION'], $matches)) {
            return $matches[1];
        }
    }
    
    // Méthode 3: getallheaders() si disponible
    if (function_exists('getallheaders')) {
        $headers = getallheaders();
        if (isset($headers['Authorization'])) {
            if (preg_match('/Bearer\s+(\S+)/', $headers['Authorization'], $matches)) {
                return $matches[1];
            }
        }
    }
    
    // Méthode 4: apache_request_headers() si disponible
    if (function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
        if (isset($headers['Authorization'])) {
            if (preg_match('/Bearer\s+(\S+)/', $headers['Authorization'], $matches)) {
                return $matches[1];
            }
        }
    }
    
    return null;
}

// Fonction pour encoder en base64 URL-safe
function base64url_encode($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

// Fonction pour décoder le base64 URL-safe
function base64url_decode($data) {
    return base64_decode(str_pad(strtr($data, '-_', '+/'), strlen($data) % 4, '=', STR_PAD_RIGHT));
}

// Fonction pour générer un JWT
function generate_jwt($headers, $payload) {
    $headers_encoded = base64url_encode(json_encode($headers));
    $payload_encoded = base64url_encode(json_encode($payload));
    
    $signature = hash_hmac('sha256', $headers_encoded . "." . $payload_encoded, JWT_SECRET, true);
    $signature_encoded = base64url_encode($signature);
    
    return $headers_encoded . "." . $payload_encoded . "." . $signature_encoded;
}

// Fonction pour vérifier un JWT
function verify_jwt($token) {
    try {
        error_log("Vérification JWT - Token reçu: " . substr($token, 0, 50) . "...");

        $parts = explode('.', $token);
        error_log("Vérification JWT - Nombre de parties: " . count($parts));

        if (count($parts) !== 3) {
            error_log("Vérification JWT - Nombre de parties incorrect");
            return false;
        }

        $headers = json_decode(base64url_decode($parts[0]), true);
        $payload = json_decode(base64url_decode($parts[1]), true);

        error_log("Vérification JWT - Payload décodé: " . json_encode($payload));

        if (!$headers || !$payload) {
            error_log("Vérification JWT - Headers ou payload invalides");
            return false;
        }

        // Vérifier la signature
        $signature = base64url_decode($parts[2]);
        $expected_signature = hash_hmac('sha256', $parts[0] . "." . $parts[1], JWT_SECRET, true);

        if (!hash_equals($signature, $expected_signature)) {
            error_log("Vérification JWT - Signature invalide");
            return false;
        }

        // Vérifier l'expiration
        if (isset($payload['exp']) && $payload['exp'] < time()) {
            error_log("Vérification JWT - Token expiré");
            return false;
        }

        error_log("Vérification JWT - Token valide");
        return $payload;
    } catch (Exception $e) {
        error_log("Vérification JWT - Exception: " . $e->getMessage());
        return false;
    }
}

// Alias pour compatibilité
function verifyJWT($token) {
    return verify_jwt($token);
}
?>

