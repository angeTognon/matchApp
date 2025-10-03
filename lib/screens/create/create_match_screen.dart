import 'package:flutter/material.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();
  final _stadiumController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedTeam = '';
  String _selectedCategory = '';
  String _selectedLevel = '';
  String _selectedGender = '';
  bool _autoValidation = false;
  bool _loading = false;

  final List<Map<String, String>> _coachTeams = [
    {'id': '1', 'name': 'FC Marseille Jeunes', 'category': 'U17', 'level': 'Départemental'},
    {'id': '2', 'name': 'Olympic Provence Séniors', 'category': 'Séniors', 'level': 'Régional'},
    {'id': '3', 'name': 'AS Aubagne Féminines', 'category': 'Séniors F', 'level': 'Départemental'}
  ];

  final List<String> _categories = ['U6', 'U8', 'U10', 'U12', 'U14', 'U16', 'U17', 'U19', 'Séniors', 'Vétérans'];
  final List<String> _levels = ['Loisir', 'Départemental', 'Régional', 'National'];
  final List<String> _genders = ['Masculin', 'Féminin', 'Mixte'];

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _stadiumController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedTeam.isEmpty || 
        _dateController.text.isEmpty || 
        _timeController.text.isEmpty || 
        _locationController.text.isEmpty || 
        _selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    setState(() => _loading = true);
    
    // Simulate match creation
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _loading = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Match Proposé !'),
          content: const Text('Votre demande de match a été publiée avec succès.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset form
                setState(() {
                  _selectedTeam = '';
                  _selectedCategory = '';
                  _selectedLevel = '';
                  _selectedGender = '';
                  _autoValidation = false;
                });
                _dateController.clear();
                _timeController.clear();
                _locationController.clear();
                _stadiumController.clear();
                _notesController.clear();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proposer un Match',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Organisez un match amical avec une autre équipe',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sélection équipe
                    Text(
                      'Quelle équipe ?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showTeamPicker(),
                      icon: Icon(Icons.groups, color: Theme.of(context).textTheme.bodyMedium?.color),
                      label: Text(
                        _selectedTeam.isEmpty ? 'Sélectionner une équipe' : _selectedTeam,
                        style: TextStyle(
                          color: _selectedTeam.isEmpty ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Date et heure
                    Text(
                      'Quand ?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dateController,
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                            decoration: InputDecoration(
                              labelText: 'Date (JJ/MM/AAAA)',
                              prefixIcon: Icon(Icons.calendar_today, color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _timeController,
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                            decoration: InputDecoration(
                              labelText: 'Heure (HH:MM)',
                              prefixIcon: Icon(Icons.access_time, color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Lieu
                    Text(
                      'Où ?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _locationController,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      decoration: InputDecoration(
                        labelText: 'Ville, nom du stade',
                        prefixIcon: Icon(Icons.location_on, color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _stadiumController,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      decoration: const InputDecoration(
                        labelText: 'Disponibilité du stade (optionnel)',
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Catégorie, Niveau & Genre
                    Text(
                      'Catégorie, Niveau & Genre',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    OutlinedButton.icon(
                      onPressed: () => _showPicker('Catégorie', _categories, _selectedCategory, (value) {
                        setState(() => _selectedCategory = value);
                      }),
                      icon: Icon(Icons.groups, color: Theme.of(context).textTheme.bodyMedium?.color),
                      label: Text(
                        _selectedCategory.isEmpty ? 'Sélectionner une catégorie' : _selectedCategory,
                        style: TextStyle(
                          color: _selectedCategory.isEmpty ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    OutlinedButton.icon(
                      onPressed: () => _showPicker('Niveau', _levels, _selectedLevel, (value) {
                        setState(() => _selectedLevel = value);
                      }),
                      icon: Icon(Icons.emoji_events, color: Theme.of(context).textTheme.bodyMedium?.color),
                      label: Text(
                        _selectedLevel.isEmpty ? 'Sélectionner un niveau' : _selectedLevel,
                        style: TextStyle(
                          color: _selectedLevel.isEmpty ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    OutlinedButton.icon(
                      onPressed: () => _showPicker('Genre', _genders, _selectedGender, (value) {
                        setState(() => _selectedGender = value);
                      }),
                      icon: Icon(Icons.groups, color: Theme.of(context).textTheme.bodyMedium?.color),
                      label: Text(
                        _selectedGender.isEmpty ? 'Sélectionner le genre' : _selectedGender,
                        style: TextStyle(
                          color: _selectedGender.isEmpty ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Notes
                    Text(
                      'Notes complémentaires',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      decoration: InputDecoration(
                        hintText: 'Informations supplémentaires, conditions particulières...',
                        hintStyle: TextStyle(color: Theme.of(context).hintColor),
                        prefixIcon: Icon(Icons.note, color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 25),

                    // Auto-validation
                    CheckboxListTile(
                      title: Text(
                        'Validation automatique des demandes',
                        style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color),
                      ),
                      value: _autoValidation,
                      onChanged: (value) => setState(() => _autoValidation = value ?? false),
                      activeColor: Theme.of(context).colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),

            // Footer avec bouton
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _handleSubmit,
                  icon: const Icon(Icons.send),
                  label: Text(
                    _loading ? 'Publication...' : 'Publier le Match',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTeamPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sélectionner une équipe',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 20),
            ..._coachTeams.map((team) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    team['name']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  subtitle: Text(
                    '${team['category']} • ${team['level']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedTeam = team['name']!);
                    Navigator.of(context).pop();
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showPicker(String title, List<String> options, String selectedValue, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sélectionner $title',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 20),
            ...options.map((option) {
              return Container(
                margin: const EdgeInsets.only(bottom: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  trailing: selectedValue == option 
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    onSelect(option);
                    Navigator.of(context).pop();
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}