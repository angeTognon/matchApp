import 'package:amical_club/constant.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:amical_club/providers/auth_provider.dart';
import 'package:amical_club/models/team.dart';
import 'package:amical_club/services/api_service.dart';
import 'dart:convert';

class EditMatchScreen extends StatefulWidget {
  final String matchId;
  
  const EditMatchScreen({
    super.key,
    required this.matchId,
  });

  @override
  State<EditMatchScreen> createState() => _EditMatchScreenState();
}

class _EditMatchScreenState extends State<EditMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _stadiumController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  
  String _displayDate = '';
  String _selectedTeam = '';
  String _selectedCategory = '';
  String _selectedLevel = '';
  String _selectedGender = '';
  List<String> _selectedFacilities = [];
  bool _autoValidation = false;
  bool _isLoading = false;
  bool _isInitializing = true;
  
  List<Team> _coachTeams = [];
  
  final List<String> _categories = ['U6', 'U8', 'U10', 'U12', 'U14', 'U16', 'U17', 'U19', 'Séniors', 'Vétérans', 'Féminines'];
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
    
    // Charger les détails du match avec un timeout
    _loadMatchDetails().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('🔍 DEBUG: Timeout lors du chargement, utilisation des valeurs par défaut');
        _initializeWithDefaults();
      },
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    _stadiumController.dispose();
    _dateController.dispose();
    _timeController.dispose();
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

  Future<void> _loadMatchDetails() async {
    print('🔍 DEBUG: Début de _loadMatchDetails pour match ID: ${widget.matchId}');
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.token == null) {
        print('🔍 DEBUG: Token null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Non authentifié'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      print('🔍 DEBUG: Token trouvé, tentative API getMatch');

      // Utiliser directement la méthode de fallback car getMatch n'est pas encore déployé
      Map<String, dynamic>? response;
      print('🔍 DEBUG: Utilisation de la méthode de fallback');
      response = await _getMatchFromMatchesList(authProvider.token!);

      if (response != null && response['success'] == true) {
        final matchData = response['data'];
        print('🔍 DEBUG: Données du match reçues: $matchData');
        
        // Les données peuvent être dans matchData['match'] ou directement dans matchData
        final actualMatchData = matchData['match'] ?? matchData;
        print('🔍 DEBUG: Données réelles du match: $actualMatchData');
        
        setState(() {
          try {
            _selectedTeam = actualMatchData['team_id'].toString();
            print('🔍 DEBUG: Team ID sélectionné: $_selectedTeam');
            final category = actualMatchData['category']?.toString() ?? '';
            _selectedCategory = _categories.contains(category) ? category : '';
            
            final level = actualMatchData['level']?.toString() ?? '';
            _selectedLevel = _levels.contains(level) ? level : '';
            
            final gender = actualMatchData['gender']?.toString() ?? '';
            _selectedGender = _genders.contains(gender) ? gender : '';
            _locationController.text = actualMatchData['location']?.toString() ?? '';
            _notesController.text = actualMatchData['notes']?.toString() ?? '';
            _stadiumController.text = actualMatchData['home_stadium']?.toString() ?? '';
            _dateController.text = actualMatchData['date']?.toString() ?? '';
            _timeController.text = actualMatchData['time']?.toString() ?? '';
            _displayDate = _formatDateForDisplay(actualMatchData['date']?.toString() ?? '');
          } catch (e) {
            print('🔍 DEBUG: Erreur parsing données de base: $e');
            _selectedTeam = '';
            _selectedCategory = '';
            _selectedLevel = '';
            _selectedGender = '';
            _locationController.text = '';
            _notesController.text = '';
            _stadiumController.text = '';
            _dateController.text = '';
            _timeController.text = '';
            _displayDate = '';
          }
          
          // Parser les équipements
          if (actualMatchData['facilities'] != null) {
            try {
              if (actualMatchData['facilities'] is List) {
                _selectedFacilities = List<String>.from(actualMatchData['facilities']);
              } else if (actualMatchData['facilities'] is String) {
                String facilitiesStr = actualMatchData['facilities'] as String;
                
                // Décoder les caractères Unicode échappés
                facilitiesStr = facilitiesStr.replaceAll('\\u00e9', 'é');
                facilitiesStr = facilitiesStr.replaceAll('\\u00e8', 'è');
                facilitiesStr = facilitiesStr.replaceAll('\\u00e0', 'à');
                facilitiesStr = facilitiesStr.replaceAll('\\u00e7', 'ç');
                
                // Parser comme JSON ou comme liste séparée par virgules
                if (facilitiesStr.startsWith('[') && facilitiesStr.endsWith(']')) {
                  // C'est un JSON array
                  final decoded = json.decode(facilitiesStr);
                  if (decoded is List) {
                    _selectedFacilities = List<String>.from(decoded);
                  } else {
                    _selectedFacilities = [];
                  }
                } else {
                  // C'est une liste séparée par virgules
                  _selectedFacilities = facilitiesStr.split(',').map((s) => s.trim()).toList();
                }
              } else {
                _selectedFacilities = [];
              }
              print('🔍 DEBUG: Équipements chargés: $_selectedFacilities');
            } catch (e) {
              print('🔍 DEBUG: Erreur parsing facilities: $e');
              _selectedFacilities = [];
            }
          } else {
            _selectedFacilities = [];
            print('🔍 DEBUG: Aucun équipement trouvé');
          }
          
          _autoValidation = (actualMatchData['auto_validation'] == 1 || actualMatchData['auto_validation'] == true);
          _isInitializing = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?['message'] ?? 'Erreur lors du chargement du match'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('🔍 DEBUG: Erreur dans _loadMatchDetails: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isInitializing = false;
      });
    }
  }

  // Méthode pour initialiser avec des valeurs par défaut
  void _initializeWithDefaults() {
    setState(() {
      _selectedTeam = '';
      _selectedCategory = '';
      _selectedLevel = '';
      _selectedGender = '';
      _locationController.text = '';
      _notesController.text = '';
      _stadiumController.text = '';
      _dateController.text = '';
      _timeController.text = '';
      _displayDate = '';
      _selectedFacilities = [];
      _autoValidation = false;
      _isInitializing = false;
    });
  }

  String _formatDateForDisplay(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateController.text.isNotEmpty 
          ? DateTime.parse(_dateController.text) 
          : DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _dateController.text = picked.toIso8601String().split('T')[0]; // Format YYYY-MM-DD
        _displayDate = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _timeController.text.isNotEmpty
          ? TimeOfDay(
              hour: int.parse(_timeController.text.split(':')[0]),
              minute: int.parse(_timeController.text.split(':')[1]),
            )
          : TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedTeam.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une équipe'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 DEBUG: Tentative de mise à jour du match ${widget.matchId}');
      print('🔍 DEBUG: Données envoyées - Team: $_selectedTeam, Date: ${_dateController.text}, Location: ${_locationController.text}');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      Map<String, dynamic> response;
      
      // Utiliser update_match.php pour mettre à jour le match et l'équipe
      print('🔍 DEBUG: Mise à jour du match avec update_match.php');
      
      try {
        response = await ApiService.updateMatch(
          token: authProvider.token!,
          matchId: widget.matchId,
          teamId: _selectedTeam,
          date: _dateController.text,
          time: _timeController.text,
          location: _locationController.text,
          category: _selectedCategory,
          level: _selectedLevel.isNotEmpty ? _selectedLevel : null,
          gender: _selectedGender.isNotEmpty ? _selectedGender : null,
          stadium: _stadiumController.text.isNotEmpty ? _stadiumController.text : null,
          description: _notesController.text.isNotEmpty ? _notesController.text : null, // Pour teams.description
          notes: _notesController.text.isNotEmpty ? _notesController.text : null, // Pour matches.notes
          facilities: _selectedFacilities.isNotEmpty ? _selectedFacilities : null,
          autoValidation: _autoValidation,
        );
        
        print('🔍 DEBUG: Réponse update_match: $response');
        
      } catch (e) {
        print('🔍 DEBUG: Erreur update_match: $e');
        response = {
          'success': false,
          'message': 'Erreur lors de la mise à jour: $e'
        };
      }

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Match modifié avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/my-matches');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']?.toString() ?? 'Erreur lors de la modification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } 
    catch (e) {
      print('🔍 DEBUG: Erreur dans _handleSubmit: $e');
      String errorMessage = 'Erreur lors de la modification';
      
      if (e.toString().contains('FormatException')) {
        errorMessage = 'Erreur de format de réponse du serveur. Veuillez réessayer.';
      } else if (e.toString().contains('HandshakeException')) {
        errorMessage = 'Erreur de connexion SSL. Vérifiez votre connexion internet.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Erreur de connexion. Vérifiez votre connexion internet.';
      } else {
        errorMessage = 'Erreur: ${e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return WillPopScope(
        onWillPop: () async {
          try {
            context.pop();
            return false;
          } catch (e) {
            print('🔍 DEBUG: Erreur WillPopScope: $e');
            context.go('/main');
            return false;
          }
        },
        child: _buildContent(context),
      );
    } catch (e) {
      print('🔍 DEBUG: Erreur dans build: $e');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/main'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Une erreur est survenue'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/main'),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Modifier le match'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              try {
                context.pop();
              } catch (e) {
                print('🔍 DEBUG: Erreur lors du retour: $e');
                context.go('/main');
              }
            },
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des données du match...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le match'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              context.pop();
            } catch (e) {
              print('🔍 DEBUG: Erreur lors du retour: $e');
              // Fallback: naviguer vers l'écran principal
              context.go('/main');
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélection de l'équipe
              Text(
                'Équipe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _showTeamPicker,
                icon: const Icon(Icons.sports_soccer),
                label: Text(
                  _selectedTeam.isNotEmpty 
                      ? _coachTeams.firstWhere((team) => team.id == _selectedTeam).name
                      : 'Sélectionner une équipe',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 25),

              // Catégorie
              Text(
                'Catégorie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Sélectionner une catégorie',
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner une catégorie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),

              // Niveau
              Text(
                'Niveau',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedLevel.isNotEmpty ? _selectedLevel : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Sélectionner un niveau (optionnel)',
                ),
                items: _levels.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLevel = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 25),

              // Genre
              Text(
                'Genre',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedGender.isNotEmpty ? _selectedGender : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Sélectionner un genre (optionnel)',
                ),
                items: _genders.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value ?? '';
                  });
                },
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
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_displayDate.isEmpty ? 'Choisir une date' : _displayDate),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(_timeController.text.isEmpty ? 'Heure' : _timeController.text),
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
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Lieu du match',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir le lieu du match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),

              // Stade
              Text(
                'Stade (optionnel)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stadiumController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Nom du stade',
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
                          Stack(
                            children: [
                              Icon(
                                facility['icon'],
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).textTheme.bodyMedium?.color,
                                size: 20,
                              ),
                              if (isSelected)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 8,
                                    ),
                                  ),
                                ),
                            ],
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

              // Description
              Text(
                'Description (optionnel)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Description du match, règles spéciales, etc.',
                ),
              ),
              const SizedBox(height: 25),

              // Validation automatique
              CheckboxListTile(
                title: const Text('Validation automatique'),
                subtitle: const Text('Accepter automatiquement les demandes'),
                value: _autoValidation,
                onChanged: (value) {
                  setState(() {
                    _autoValidation = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 30),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Modifier le match',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showTeamPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sélectionner une équipe'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _coachTeams.length,
              itemBuilder: (context, index) {
                final team = _coachTeams[index];
                return ListTile(
                  leading: team.logo != null && team.logo!.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage('$baseUrl}/${team.logo}'),
                        )
                      : CircleAvatar(
                          child: Icon(
                            Icons.sports_soccer,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                  title: Text(team.name),
                  subtitle: Text(team.clubName),
                  onTap: () {
                    setState(() {
                      _selectedTeam = team.id;
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Méthode de fallback pour récupérer un match spécifique
  Future<Map<String, dynamic>?> _getMatchFromMatchesList(String token) async {
    try {
      // Récupérer tous les matchs avec différents statuts
      List<dynamic> allMatches = [];
      
      for (String status in ['pending', 'available', 'confirmed', 'finished']) {
        try {
          final response = await ApiService.getMatches(
            token: token,
            status: status,
            limit: 100,
          );
          
          if (response['success'] == true) {
            final List<dynamic> matches = response['data']['matches'];
            allMatches.addAll(matches);
          }
        } catch (e) {
          print('Erreur pour statut $status: $e');
        }
      }
      
      // Trouver le match avec l'ID spécifique
      print('🔍 DEBUG: Recherche du match ID: ${widget.matchId}');
      print('🔍 DEBUG: Nombre total de matchs: ${allMatches.length}');
      
      for (var match in allMatches) {
        print('🔍 DEBUG: Match trouvé - ID: ${match['id']}, team_id: ${match['team_id']}');
      }
      
      final match = allMatches.where(
        (m) => m['id'].toString() == widget.matchId,
      ).toList();
      
      if (match.isNotEmpty) {
        return {
          'success': true,
          'data': match.first,
        };
      } else {
        return {
          'success': false,
          'message': 'Match non trouvé',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      };
    }
  }
}
