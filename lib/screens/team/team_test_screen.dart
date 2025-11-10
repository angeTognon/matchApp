import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeamTestScreen extends StatelessWidget {
  const TeamTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Navigation Équipes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test de navigation pour les équipes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Test création d'équipe
            ElevatedButton(
              onPressed: () {
                print('Navigation vers /team/edit (création)');
                context.push('/team/edit');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
              child: const Text('Test: Créer une nouvelle équipe'),
            ),
            const SizedBox(height: 10),
            
            // Test édition d'équipe
            ElevatedButton(
              onPressed: () {
                print('Navigation vers /team/edit/123 (édition)');
                context.push('/team/edit/123');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
              child: const Text('Test: Éditer une équipe (ID: 123)'),
            ),
            const SizedBox(height: 10),
            
            // Test profil d'équipe
            ElevatedButton(
              onPressed: () {
                print('Navigation vers /team/123 (profil)');
                context.push('/team/123');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
              child: const Text('Test: Voir profil équipe (ID: 123)'),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Instructions:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text('1. Testez la création d\'équipe (bouton vert)'),
            const Text('2. Testez l\'édition d\'équipe (bouton orange)'),
            const Text('3. Vérifiez les logs dans la console'),
            const Text('4. Vérifiez que les écrans s\'affichent correctement'),
          ],
        ),
      ),
    );
  }
}
