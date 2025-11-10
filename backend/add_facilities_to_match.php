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
        echo "Colonne facilities ajoutée.\n";
    }
    
    // Récupérer le premier match
    $stmt = $pdo->query("SELECT id FROM amicalclub_matches LIMIT 1");
    $match = $stmt->fetch();
    
    if ($match) {
        // Ajouter des équipements de test
        $facilities = ['Vestiaires', 'Douches', 'Parking', 'Éclairage', 'Tribunes', 'Buvette'];
        $facilitiesJson = json_encode($facilities);
        
        $stmt = $pdo->prepare("UPDATE amicalclub_matches SET facilities = ? WHERE id = ?");
        $stmt->execute([$facilitiesJson, $match['id']]);
        
        echo json_encode([
            'success' => true, 
            'message' => 'Équipements ajoutés au match ID: ' . $match['id'],
            'facilities' => $facilities
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Aucun match trouvé.']);
    }
    
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Erreur: ' . $e->getMessage()]);
}
?>
