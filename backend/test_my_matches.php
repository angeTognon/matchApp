<?php
// Script de test pour get_my_matches.php
header('Content-Type: application/json');

// Simuler une requête GET avec un token
$test_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoyLCJpYXQiOjE3MzY4NDQ5ODN9.test";

// Simuler les headers
$_SERVER['HTTP_AUTHORIZATION'] = "Bearer " . $test_token;
$_SERVER['REQUEST_METHOD'] = 'GET';

echo "Test de get_my_matches.php\n";
echo "Token simulé: " . $test_token . "\n";
echo "Headers simulés: " . json_encode($_SERVER) . "\n";

// Inclure le fichier get_my_matches.php
ob_start();
include 'get_my_matches.php';
$output = ob_get_clean();

echo "\nSortie de get_my_matches.php:\n";
echo $output;
?>
