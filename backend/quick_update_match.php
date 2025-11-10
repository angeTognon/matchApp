<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Test simple
$input = json_decode(file_get_contents('php://input'), true);

if ($input) {
    echo json_encode([
        'success' => true,
        'message' => 'Test API fonctionne - Match ID: ' . ($input['match_id'] ?? 'N/A'),
        'data' => $input
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Pas de données reçues'
    ]);
}
?>
