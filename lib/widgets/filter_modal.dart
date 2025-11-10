import 'package:flutter/material.dart';

class FilterModal extends StatefulWidget {
  final Map<String, String> filters;
  final Function(Map<String, String>) onApplyFilters;
  final VoidCallback? onClose;

  const FilterModal({
    super.key,
    required this.filters,
    required this.onApplyFilters,
    this.onClose,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late Map<String, String> _tempFilters;

  // Catégories pour les hommes
  final List<String> _maleCategories = [
    'Toutes', 'U8', 'U9', 'U10', 'U11', 'U12', 'U13', 'U14', 'U15', 'U16', 'U17', 'U18', 'U19', 'U20', 'Séniors', 'Vétérans'
  ];
  
  // Catégories pour les femmes
  final List<String> _femaleCategories = [
    'Toutes', 'U11', 'U13', 'U15', 'U17', 'U19', 'Séniors'
  ];
  
  final List<String> _levels = ['Tous', 'Loisir', 'Départemental', 'Régional', 'National'];
  final List<String> _distances = ['Toutes', '5 km', '10 km', '25 km', '50 km'];
  final List<String> _genders = ['Tous', 'Masculin', 'Féminin'];

  @override
  void initState() {
    super.initState();
    _tempFilters = Map.from(widget.filters);
    
    // S'assurer que les filtres ont des valeurs par défaut
    _tempFilters.putIfAbsent('category', () => '');
    _tempFilters.putIfAbsent('level', () => '');
    _tempFilters.putIfAbsent('gender', () => '');
    _tempFilters.putIfAbsent('distance', () => '');
  }
  
  // Convertir la valeur d'affichage en valeur API
  String _getApiValue(String displayValue, String filterType) {
    // Les valeurs "Toutes" ou "Tous" deviennent des chaînes vides
    if (displayValue == 'Toutes' || displayValue == 'Tous') {
      return '';
    }
    return displayValue;
  }
  
  // Convertir la valeur API en valeur d'affichage
  String _getDisplayValue(String apiValue, String filterType) {
    if (apiValue.isEmpty) {
      return filterType == 'category' ? 'Toutes' : 'Tous';
    }
    return apiValue;
  }

  // Obtenir les catégories en fonction du genre sélectionné
  List<String> _getCategoriesForGender(String gender) {
    switch (gender) {
      case 'Masculin':
        return _maleCategories;
      case 'Féminin':
        return _femaleCategories;
      default:
        return _maleCategories; // Par défaut, afficher les catégories masculines
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header avec titre centré et bouton X à droite
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40), // Espace pour centrer le titre
                Text(
                  'Filtres',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                IconButton(
                  onPressed: () => widget.onClose?.call(),
                  icon: Icon(Icons.close, color: Theme.of(context).textTheme.titleLarge?.color, size: 24),
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
                  _buildFilterSection('Catégorie', _getCategoriesForGender(_getDisplayValue(_tempFilters['gender'] ?? '', 'gender')), 'category'),
                  const SizedBox(height: 25),
                  _buildFilterSection('Niveau', _levels, 'level'),
                  const SizedBox(height: 25),
                  _buildFilterSection('Genre', _genders, 'gender'),
                  const SizedBox(height: 25),
                  _buildFilterSection('Distance', _distances, 'distance'),
                ],
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _tempFilters = {'category': '', 'level': '', 'distance': '', 'gender': ''};
                      });
                      widget.onApplyFilters(_tempFilters);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      foregroundColor: Theme.of(context).textTheme.titleMedium?.color,
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Réinitialiser'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApplyFilters(_tempFilters);
                      widget.onClose?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options, String filterKey) {
    // Obtenir la valeur d'affichage actuelle
    final currentApiValue = _tempFilters[filterKey] ?? '';
    final currentDisplayValue = _getDisplayValue(currentApiValue, filterKey);
    
    // Si c'est la section catégorie et que la catégorie actuelle n'est pas dans les options disponibles,
    // réinitialiser à "Toutes"
    if (filterKey == 'category' && currentDisplayValue != 'Toutes' && !options.contains(currentDisplayValue)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _tempFilters[filterKey] = '';
        });
      });
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
          children: options.map((option) {
            final isSelected = currentDisplayValue == option;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _tempFilters[filterKey] = _getApiValue(option, filterKey);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.titleMedium?.color,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}