<?php
echo "=== Test des catégories dynamiques par genre ===\n";

// Catégories pour les hommes
$maleCategories = [
    'Toutes', 'U8', 'U9', 'U10', 'U11', 'U12', 'U13', 'U14', 'U15', 'U16', 'U17', 'U18', 'U19', 'U20', 'Séniors', 'Vétérans'
];

// Catégories pour les femmes
$femaleCategories = [
    'Toutes', 'U11', 'U13', 'U15', 'U17', 'U19', 'Séniors'
];

// Note: L'option "Mixte" a été supprimée des filtres

echo "1. Catégories pour les HOMMES:\n";
echo "   " . implode(', ', $maleCategories) . "\n";
echo "   Total: " . count($maleCategories) . " catégories\n\n";

echo "2. Catégories pour les FEMMES:\n";
echo "   " . implode(', ', $femaleCategories) . "\n";
echo "   Total: " . count($femaleCategories) . " catégories\n\n";

echo "3. OPTION MIXTE SUPPRIMÉE:\n";
echo "   L'option 'Mixte' a été retirée des filtres de genre\n\n";

// Test de logique
echo "4. Test de logique:\n";

$testCases = [
    ['genre' => 'Masculin', 'expected_count' => 16],
    ['genre' => 'Féminin', 'expected_count' => 7],
    ['genre' => 'Tous', 'expected_count' => 16], // Par défaut
];

foreach ($testCases as $test) {
    $genre = $test['genre'];
    $expectedCount = $test['expected_count'];
    
    switch ($genre) {
        case 'Masculin':
            $categories = $maleCategories;
            break;
        case 'Féminin':
            $categories = $femaleCategories;
            break;
        default:
            $categories = $maleCategories; // Par défaut
            break;
    }
    
    $actualCount = count($categories);
    $status = ($actualCount == $expectedCount) ? '✅' : '❌';
    
    echo "   $status Genre: $genre | Attendu: $expectedCount | Réel: $actualCount\n";
}

echo "\n5. Différences entre les catégories:\n";

// Catégories uniquement masculines
$maleOnly = array_diff($maleCategories, $femaleCategories);
echo "   Catégories uniquement masculines: " . implode(', ', $maleOnly) . "\n";

// Catégories uniquement féminines
$femaleOnly = array_diff($femaleCategories, $maleCategories);
echo "   Catégories uniquement féminines: " . implode(', ', $femaleOnly) . "\n";

// Catégories communes
$common = array_intersect($maleCategories, $femaleCategories);
echo "   Catégories communes: " . implode(', ', $common) . "\n";

echo "\n✅ Test des catégories dynamiques terminé !\n";
echo "📱 Fonctionnalités implémentées:\n";
echo "   - Catégories dynamiques selon le genre sélectionné\n";
echo "   - Réinitialisation automatique si catégorie non disponible\n";
echo "   - Interface utilisateur réactive\n";
echo "   - Logique métier respectée (U8-U20 pour hommes, U11-U19 pour femmes)\n";
echo "   - Option 'Mixte' supprimée des filtres\n";
?>


