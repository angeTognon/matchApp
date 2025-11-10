import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SimpleEditTeamScreen extends StatelessWidget {
  final String? teamId;

  const SimpleEditTeamScreen({super.key, this.teamId});

  @override
  Widget build(BuildContext context) {
    final isEditing = teamId != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'équipe' : 'Nouvelle équipe'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debug info
            Container(
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✅ Écran Simple - Pas d\'erreur !',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text('teamId: ${teamId ?? "null"}'),
                  Text('Mode: ${isEditing ? "Édition" : "Création"}'),
                  Text('Timestamp: ${DateTime.now().toString()}'),
                ],
              ),
            ),
            
            const Text(
              'Test de l\'écran d\'édition d\'équipe',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nom de l\'équipe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Club',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Équipe mise à jour !' : 'Équipe créée !'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: Text(isEditing ? 'Mettre à jour' : 'Créer'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Annuler'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
