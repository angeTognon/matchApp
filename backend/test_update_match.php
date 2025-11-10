<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

try {
    // Test simple - retourner toujours un succès
    $input = json_decode(file_get_contents('php://input'), true);
    
    echo json_encode([
        'success' => true,
        'message' => 'Test update_match - API fonctionne',
        'data' => [
            'match_id' => $input['match_id'] ?? 'test',
            'location' => $input['location'] ?? 'test location',
            'received_data' => $input
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Erreur test_update_match: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur test: ' . $e->getMessage()
    ]);
}
?>
