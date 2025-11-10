<?php
require_once 'db.php';

header('Content-Type: application/json');

try {
    // Vérifier si la colonne facilities existe
    $stmt = $pdo->query("SHOW COLUMNS FROM amicalclub_matches LIKE 'facilities'");
    $columnExists = $stmt->fetch();
    
    if (!$columnExists) {
        // Ajouter la colonne facilities
        $pdo->exec("ALTER TABLE amicalclub_matches ADD COLUMN facilities TEXT NULL");
        echo json_encode(['success' => true, 'message' => 'Colonne facilities ajoutée avec succès.']);
    } else {
        echo json_encode(['success' => true, 'message' => 'Colonne facilities existe déjà.']);
    }
    
    // Ajouter des équipements de test à un match existant
    $testFacilities = json_encode(['Vestiaires', 'Douches', 'Parking', 'Éclairage']);
    $stmt = $pdo->prepare("UPDATE amicalclub_matches SET facilities = ? WHERE id = (SELECT id FROM amicalclub_matches LIMIT 1)");
    $stmt->execute([$testFacilities]);
    
    echo json_encode(['success' => true, 'message' => 'Équipements de test ajoutés.']);
    
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Erreur: ' . $e->getMessage()]);
}
?>
