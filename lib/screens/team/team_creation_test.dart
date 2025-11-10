import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Écran de test pour vérifier la création et édition d'équipes
class TeamCreationTestScreen extends StatelessWidget {
  const TeamCreationTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Création Équipes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test des fonctionnalités d\'équipe',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Test création d'équipe
            ElevatedButton.icon(
              onPressed: () => context.push('/team/edit'),
              icon: const Icon(Icons.add),
              label: const Text('Test: Créer une nouvelle équipe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
            ),
            const SizedBox(height: 10),
            
            // Test édition d'équipe (avec ID fictif)
            ElevatedButton.icon(
              onPressed: () => context.push('/team/edit/123'),
              icon: const Icon(Icons.edit),
              label: const Text('Test: Éditer une équipe (ID: 123)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
            ),
            const SizedBox(height: 10),
            
            // Test profil d'équipe
            ElevatedButton.icon(
              onPressed: () => context.push('/team/123'),
              icon: const Icon(Icons.info),
              label: const Text('Test: Voir profil équipe (ID: 123)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Instructions:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text('1. Testez la création d\'équipe (bouton vert)'),
            const Text('2. Testez l\'édition d\'équipe (bouton orange)'),
            const Text('3. Vérifiez que les dropdowns fonctionnent'),
            const Text('4. Vérifiez la validation des champs'),
            const Text('5. Testez la sauvegarde'),
          ],
        ),
      ),
    );
  }
}
