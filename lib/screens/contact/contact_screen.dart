import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:amical_club/providers/auth_provider.dart';
import 'package:amical_club/providers/chat_provider.dart';
import 'package:amical_club/services/api_service.dart';

class ContactScreen extends StatefulWidget {
  final String teamId;

  const ContactScreen({super.key, required this.teamId});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _messageController = TextEditingController();
  String _selectedTemplate = '';
  Map<String, dynamic>? _teamData;
  bool _isLoading = true;
  String? _errorMessage;

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
  void initState() {
    super.initState();
    _loadTeamData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.token == null) {
      setState(() {
        _errorMessage = 'Erreur d\'authentification';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiService.getPublicTeam(
        token: authProvider.token!,
        teamId: widget.teamId,
      );

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _teamData = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Erreur lors du chargement de l\'équipe';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion: $e';
        _isLoading = false;
      });
    }
  }

  void _selectTemplate(Map<String, String> template) {
    setState(() {
      _selectedTemplate = template['id']!;
      _messageController.text = template['content']!;
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur d\'authentification'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Utiliser les données de l'équipe déjà chargées
    if (_teamData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données de l\'équipe non disponibles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final coachId = _teamData!['coach_id']?.toString();

      if (coachId != null) {
        // Envoyer le message via le chat
        final success = await chatProvider.sendMessage(
          receiverId: coachId,
          message: _messageController.text.trim(),
          authProvider: authProvider,
        );

        if (success) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Message envoyé !'),
              content: const Text('Votre message a été envoyé à l\'équipe.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Ferme le dialog
                    context.push('/conversations'); // Navigue vers les conversations
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(chatProvider.errorMessage ?? 'Erreur lors de l\'envoi du message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de récupérer les informations du coach'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              _teamData?['name'] ?? 'Chargement...',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTeamData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
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
                    _teamData?['name'] ?? 'Équipe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Entraîneur: ${_teamData?['coach_name'] ?? 'Non disponible'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_teamData?['category'] ?? 'N/A'} • ${_teamData?['level'] ?? 'N/A'}',
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