import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:amical_club/models/team.dart';
import 'package:amical_club/models/coach.dart';
import 'package:amical_club/providers/auth_provider.dart';
import 'package:amical_club/services/api_service.dart';
import 'package:amical_club/config/app_theme.dart';
import 'package:amical_club/constants/team_constants.dart';
import 'package:amical_club/constant.dart';

class EditTeamScreen extends StatefulWidget {
  final String? teamId; // null pour création, non-null pour édition

  const EditTeamScreen({super.key, this.teamId});

  @override
  State<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends State<EditTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _clubNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _levelController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _foundedController = TextEditingController();
  final _homeStadiumController = TextEditingController();
  final _achievementsController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  Team? _currentTeam;
  String? _selectedCategory;
  String? _selectedLevel;
  File? _selectedLogo;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.teamId != null && widget.teamId!.isNotEmpty;
    
    if (_isEditing) {
      _loadTeamData();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clubNameController.dispose();
    _categoryController.dispose();
    _levelController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _foundedController.dispose();
    _homeStadiumController.dispose();
    _achievementsController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamData() async {
    if (widget.teamId == null || widget.teamId!.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.getTeam(authProvider.token!, widget.teamId!);

      if (response['success'] == true) {
        _currentTeam = Team.fromJson(response['data']);
        _populateFields();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Erreur lors du chargement'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _populateFields() {
    if (_currentTeam == null) return;

    _nameController.text = _currentTeam!.name;
    _clubNameController.text = _currentTeam!.clubName;
    _categoryController.text = _currentTeam!.category;
    _levelController.text = _currentTeam!.level;
    _locationController.text = _currentTeam!.location;
    _descriptionController.text = _currentTeam!.description ?? '';
    _foundedController.text = _currentTeam!.founded ?? '';
    _homeStadiumController.text = _currentTeam!.homeStadium ?? '';
    _achievementsController.text = _currentTeam!.achievements?.join('\n') ?? '';
    
    // Mettre à jour les valeurs des dropdowns
    // Normaliser et vérifier que la valeur existe dans la liste des options
    final normalizedCategory = TeamConstants.normalizeCategory(_currentTeam!.category);
    final normalizedLevel = TeamConstants.normalizeLevel(_currentTeam!.level);
    
    _selectedCategory = normalizedCategory;
    _selectedLevel = normalizedLevel;
    
    // Mettre à jour les controllers avec les valeurs normalisées
    if (normalizedCategory != null) _categoryController.text = normalizedCategory;
    if (normalizedLevel != null) _levelController.text = normalizedLevel;
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Vérifier l'extension du fichier
        final extension = pickedFile.path.toLowerCase().split('.').last;
        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Format d\'image non supporté. Utilisez JPG ou PNG.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedLogo = File(pickedFile.path);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logo sélectionné avec succès'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection du logo: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveTeam() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation supplémentaire pour la création
    if (!_isEditing) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le nom de l\'équipe est obligatoire'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Upload du logo si sélectionné
      String? logoUrl;
      if (_selectedLogo != null) {
        final uploadResponse = await ApiService.uploadTeamLogo(
          token: authProvider.token!,
          imageFile: _selectedLogo!,
          teamId: widget.teamId ?? 'new',
        );
        if (uploadResponse['success'] == true) {
          logoUrl = uploadResponse['data']['logo_url'];
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(uploadResponse['message'] ?? 'Erreur lors de l\'upload du logo'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      Map<String, dynamic> response;

      if (_isEditing && widget.teamId != null && widget.teamId!.isNotEmpty) {
        // Mode édition - mettre à jour une équipe existante
        response = await ApiService.updateTeam(
          token: authProvider.token!,
          teamId: widget.teamId!,
          name: _nameController.text,
          clubName: _clubNameController.text,
          category: _categoryController.text,
          level: _levelController.text,
          location: _locationController.text,
          description: _descriptionController.text,
          founded: _foundedController.text,
          homeStadium: _homeStadiumController.text,
          achievements: _achievementsController.text,
          logo: logoUrl,
        );
      } else {
        // Mode création - créer une nouvelle équipe
        response = await ApiService.createTeam(
          token: authProvider.token!,
          name: _nameController.text,
          clubName: _clubNameController.text,
          category: _categoryController.text,
          level: _levelController.text,
          location: _locationController.text,
          description: _descriptionController.text,
          founded: _foundedController.text,
          homeStadium: _homeStadiumController.text,
          achievements: _achievementsController.text,
          logo: logoUrl,
        );
      }

      if (response['success'] == true) {
        if (mounted) {
          // Pour la création, mettre à jour directement avec les nouvelles données
          if (!_isEditing && response['data'] != null) {
            final responseData = response['data'];
            if (responseData['user'] != null && responseData['teams'] != null) {
              // Mettre à jour l'AuthProvider avec les nouvelles données
              await _updateAuthProviderWithNewData(authProvider, responseData);
            } else {
              // Fallback: recharger les données
              await authProvider.checkAuthentication();
            }
          } else {
            // Pour l'édition, recharger les données utilisateur
            await authProvider.checkAuthentication();
          }
          
          if (_isEditing) {
            // Message simple pour l'édition
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Équipe mise à jour avec succès !'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            context.pop();
          } else {
            // Dialog de confirmation pour la création
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                    SizedBox(width: 10),
                    Text('Équipe créée !'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Votre équipe "${_nameController.text}" a été créée avec succès !'),
                    const SizedBox(height: 10),
                    const Text(
                      'Vous pouvez maintenant :',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    const Text('• Modifier ses informations'),
                    const Text('• Créer des matchs amicaux'),
                    const Text('• Inviter d\'autres équipes'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Ferme le dialog
                      context.pop(); // Retourne au profil
                    },
                    child: const Text('Continuer'),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Erreur lors de la sauvegarde'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateAuthProviderWithNewData(AuthProvider authProvider, Map<String, dynamic> responseData) async {
    try {
      // Convertir les équipes
      List<Team> teams = [];
      if (responseData['teams'] != null && responseData['teams'] is List) {
        teams = (responseData['teams'] as List)
            .where((t) => t is Map<String, dynamic>)
            .map((t) => Team.fromJson(t as Map<String, dynamic>))
            .toList();
      }

      // Mettre à jour l'AuthProvider avec les nouvelles données
      final userData = responseData['user'];
      if (userData != null) {
        final coach = Coach.fromJson(userData, teams);
        authProvider.updateCoachData(coach);
      }
    } catch (e) {
      debugPrint('Erreur mise à jour AuthProvider: $e');
      // Fallback: recharger les données
      await authProvider.checkAuthentication();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier l\'équipe' : 'Nouvelle équipe'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
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
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo de l'équipe
                    _buildSectionTitle('Logo de l\'équipe'),
                    const SizedBox(height: 15),
                    Center(
                      child: GestureDetector(
                        onTap: _pickLogo,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: _selectedLogo != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    _selectedLogo!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _currentTeam?.logo != null && _currentTeam!.logo!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        '$baseUrl/${_currentTeam!.logo}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate,
                                                size: 40,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Ajouter un logo',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 40,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Ajouter un logo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Informations de base
                    _buildSectionTitle('Informations de base'),
                    const SizedBox(height: 15),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'équipe *',
                        prefixIcon: Icon(Icons.groups),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom de l\'équipe est obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    
                    TextFormField(
                      controller: _clubNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du club',
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Catégorie',
                              prefixIcon: Icon(Icons.category),
                              hintText: 'Sélectionner une catégorie',
                            ),
                            items: TeamConstants.categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(
                                  category,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                                if (value != null) {
                                  _categoryController.text = value;
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner une catégorie';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedLevel,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Niveau',
                              prefixIcon: Icon(Icons.emoji_events),
                              hintText: 'Sélectionner un niveau',
                            ),
                            items: TeamConstants.levels.map((String level) {
                              return DropdownMenuItem<String>(
                                value: level,
                                child: Text(
                                  level,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLevel = value;
                                if (value != null) {
                                  _levelController.text = value;
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner un niveau';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Localisation',
                        prefixIcon: Icon(Icons.location_on),
                        hintText: 'Ville, département',
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Informations détaillées
                    _buildSectionTitle('Informations détaillées'),
                    const SizedBox(height: 15),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                        hintText: 'Présentez votre équipe...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 15),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _foundedController,
                            decoration: const InputDecoration(
                              labelText: 'Année de création',
                              prefixIcon: Icon(Icons.calendar_today),
                              hintText: 'Ex: 1983',
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (value.length != 4) {
                                  return 'L\'année doit contenir 4 chiffres';
                                }
                                final year = int.tryParse(value);
                                if (year == null || year < 1800 || year > 2100) {
                                  return 'Année invalide (1800-2100)';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextFormField(
                            controller: _homeStadiumController,
                            decoration: const InputDecoration(
                              labelText: 'Stade domicile',
                              prefixIcon: Icon(Icons.stadium),
                              hintText: 'Nom du stade',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    TextFormField(
                      controller: _achievementsController,
                      decoration: const InputDecoration(
                        labelText: 'Palmarès',
                        prefixIcon: Icon(Icons.emoji_events),
                        hintText: 'Un titre par ligne...',
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 30),
                    
                    // Bouton de sauvegarde
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTeam,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          _isLoading 
                              ? 'Sauvegarde...' 
                              : (_isEditing ? 'Mettre à jour' : 'Créer l\'équipe'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
