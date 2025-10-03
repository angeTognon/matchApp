import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ContactScreen extends StatefulWidget {
  final String teamId;

  const ContactScreen({super.key, required this.teamId});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _messageController = TextEditingController();
  String _selectedTemplate = '';

  final List<Map<String, String>> _messageTemplates = [
    {
      'id': 'match_request',
      'title': 'Demande de match',
      'content': 'Bonjour,\n\nNous sommes intéressés par votre proposition de match amical. Notre équipe serait disponible pour jouer.\n\nPouvez-vous nous confirmer les détails ?\n\nCordialement,',
    },
    {
      'id': 'availability',
      'title': 'Vérifier disponibilité',
      'content': 'Bonjour,\n\nNous recherchons un adversaire pour un match amical. Seriez-vous disponible prochainement ?\n\nMerci de nous faire savoir vos créneaux libres.\n\nCordialement,',
    },
    {
      'id': 'custom',
      'title': 'Message personnalisé',
      'content': '',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _selectTemplate(Map<String, String> template) {
    setState(() {
      _selectedTemplate = template['id']!;
      _messageController.text = template['content']!;
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un message')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message envoyé !'),
        content: const Text('Votre message a été envoyé à l\'équipe.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Ferme le dialog
              context.push('/chat/${widget.teamId}'); // Navigue vers le chat
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _proposeDate() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((selectedDate) {
      if (selectedDate != null) {
        showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 15, minute: 0),
        ).then((selectedTime) {
          if (selectedTime != null) {
            
            final dateStr = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
            final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
            
            setState(() {
              _messageController.text = 'Bonjour,\n\nNous proposons un match amical le $dateStr à $timeStr.\n\nSeriez-vous disponible à cette date ?\n\nCordialement,';
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Date proposée : $dateStr à $timeStr')),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contacter'),
            Text(
              'FC Marseille Amateur',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.phone, color: Colors.green),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Carte équipe
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'FC Marseille Amateur',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Entraîneur: Pierre Martin',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Séniors • Départemental',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Modèles de message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modèles de message',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _messageTemplates.map((template) {
                      final isSelected = _selectedTemplate == template['id'];
                      return OutlinedButton(
                        onPressed: () => _selectTemplate(template),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected ? Theme.of(context).cardColor : null,
                          side: BorderSide(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                          ),
                          foregroundColor: isSelected ? Theme.of(context).textTheme.titleMedium?.color : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        child: Text(template['title']!),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Zone de message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Votre message',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    decoration: InputDecoration(
                      hintText: 'Tapez votre message ici...',
                      hintStyle: TextStyle(color: Theme.of(context).hintColor),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 8,
                    maxLength: 500,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions rapides
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actions rapides',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _proposeDate,
                          icon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                          label: const Text('Proposer une date'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).dividerColor),
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                          label: const Text('Ma localisation'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).dividerColor),
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _messageController.text.trim().isNotEmpty ? _sendMessage : null,
            icon: const Icon(Icons.send),
            label: const Text('Envoyer le message'),
          ),
        ),
      ),
    );
  }
}