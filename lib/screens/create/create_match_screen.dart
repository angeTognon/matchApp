import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:amical_club/providers/auth_provider.dart';
import 'package:amical_club/services/api_service.dart';
import 'package:amical_club/models/team.dart';

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
  String _displayDate = ''; // Pour l'affichage en français
  List<String> _selectedFacilities = []; // Équipements sélectionnés

  List<Team> _coachTeams = [];

  final List<String> _categories = ['U6', 'U8', 'U10', 'U12', 'U14', 'U16', 'U17', 'U19', 'Séniors', 'Vétérans'];
  final List<String> _levels = ['Loisir', 'Départemental', 'Régional', 'National'];
  final List<String> _genders = ['Masculin', 'Féminin', 'Mixte'];
  
  // Équipements disponibles avec icônes
  final List<Map<String, dynamic>> _facilities = [
    {'name': 'Vestiaires', 'icon': Icons.dry_cleaning, 'description': 'Vestiaires disponibles'},
    {'name': 'Douches', 'icon': Icons.shower, 'description': 'Douches après le match'},
    {'name': 'Parking', 'icon': Icons.local_parking, 'description': 'Parking gratuit'},
    {'name': 'Éclairage', 'icon': Icons.lightbulb, 'description': 'Éclairage du terrain'},
    {'name': 'Tribunes', 'icon': Icons.chair, 'description': 'Tribunes pour spectateurs'},
    {'name': 'Buvette', 'icon': Icons.local_drink, 'description': 'Buvette sur place'},
    {'name': 'Médecin', 'icon': Icons.medical_services, 'description': 'Médecin présent'},
    {'name': 'Arbitre', 'icon': Icons.sports, 'description': 'Arbitre fourni'},
    {'name': 'Ballons', 'icon': Icons.sports_soccer, 'description': 'Ballons fournis'},
    {'name': 'Chasubles', 'icon': Icons.checkroom, 'description': 'Chasubles disponibles'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCoachTeams();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _stadiumController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCoachTeams() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentCoach != null) {
      setState(() {
        _coachTeams = authProvider.currentCoach!.teams;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        // Stocker la date au format ISO pour l'envoi
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        // Stocker l'affichage en français
        _displayDate = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 15, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _timeController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedTeam.isEmpty || 
        _displayDate.isEmpty || 
        _timeController.text.isEmpty || 
        _locationController.text.isEmpty || 
        _selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    // La date est déjà au format ISO (AAAA-MM-JJ)
    final isoDate = _dateController.text;
    print('Date à envoyer: $isoDate');

    setState(() => _loading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final response = await ApiService.createMatch(
        token: authProvider.token!,
        teamId: _selectedTeam,
        date: isoDate,
        time: _timeController.text,
        location: _locationController.text,
        category: _selectedCategory,
        level: _selectedLevel.isNotEmpty ? _selectedLevel : null,
        gender: _selectedGender.isNotEmpty ? _selectedGender : null,
        stadium: _stadiumController.text.isNotEmpty ? _stadiumController.text : null,
        description: _notesController.text.isNotEmpty ? _notesController.text : null,
        facilities: _selectedFacilities.isNotEmpty ? _selectedFacilities : null,
        autoValidation: _autoValidation,
      );

      setState(() => _loading = false);

      if (mounted) {
        if (response['success'] == true) {
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
                      _selectedFacilities = [];
                      _autoValidation = false;
                    });
                    _dateController.clear();
                    _timeController.clear();
                    _locationController.clear();
                    _stadiumController.clear();
                    _notesController.clear();
                    // Retourner à l'accueil
                    context.go('/main');
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Erreur lors de la publication'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                        _selectedTeam.isEmpty 
                            ? 'Sélectionner une équipe' 
                            : _coachTeams.firstWhere((team) => team.id == _selectedTeam, orElse: () => _coachTeams.first).name,
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
                          child: OutlinedButton.icon(
                            onPressed: () => _selectDate(),
                            icon: Icon(Icons.calendar_today, color: Theme.of(context).textTheme.bodyMedium?.color),
                            label: Text(
                              _displayDate.isEmpty ? 'Sélectionner une date' : _displayDate,
                              style: TextStyle(
                                color: _displayDate.isEmpty 
                                    ? Theme.of(context).textTheme.bodyMedium?.color 
                                    : Theme.of(context).textTheme.titleMedium?.color,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Theme.of(context).dividerColor),
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectTime(),
                            icon: Icon(Icons.access_time, color: Theme.of(context).textTheme.bodyMedium?.color),
                            label: Text(
                              _timeController.text.isEmpty ? 'Sélectionner l\'heure' : _timeController.text,
                              style: TextStyle(
                                color: _timeController.text.isEmpty 
                                    ? Theme.of(context).textTheme.bodyMedium?.color 
                                    : Theme.of(context).textTheme.titleMedium?.color,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Theme.of(context).dividerColor),
                              alignment: Alignment.centerLeft,
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

                    // Équipements disponibles
                    Text(
                      'Équipements disponibles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sélectionnez les équipements disponibles pour ce match',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Grille des équipements
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _facilities.length,
                      itemBuilder: (context, index) {
                        final facility = _facilities[index];
                        final isSelected = _selectedFacilities.contains(facility['name']);
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedFacilities.remove(facility['name']);
                              } else {
                                _selectedFacilities.add(facility['name']);
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                Icon(
                                  facility['icon'],
                                  color: isSelected 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).textTheme.bodyMedium?.color,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        facility['name'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected 
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).textTheme.titleMedium?.color,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        facility['description'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
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
                    team.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  subtitle: Text(
                    '${team.category} • ${team.level}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedTeam = team.id);
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