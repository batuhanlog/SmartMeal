import 'package:flutter/material.dart';
import 'services/gemini_service.dart';

class IngredientsRecipePage extends StatefulWidget {
  const IngredientsRecipePage({super.key});

  @override
  State<IngredientsRecipePage> createState() => _IngredientsRecipePageState();
}

class _IngredientsRecipePageState extends State<IngredientsRecipePage> {
  final List<String> _selectedIngredients = [];
  final TextEditingController _ingredientController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _recipes = [];
  final GeminiService _geminiService = GeminiService();

  // Common ingredients list
  final List<String> _commonIngredients = [
    'Yumurta', 'Süt', 'Un', 'Tereyağı', 'Zeytinyağı', 'Soğan', 'Sarımsak',
    'Domates', 'Biber', 'Havuç', 'Patates', 'Tavuk', 'Kıyma', 'Balık',
    'Pirinç', 'Makarna', 'Peynir', 'Yoğurt', 'Nohut', 'Mercimek',
    'Ispanak', 'Marul', 'Salatalık', 'Limon', 'Tuz', 'Karabiber', 
    'Kimyon', 'Kırmızıbiber', 'Nane', 'Maydanoz'
  ];

  void _addIngredient(String ingredient) {
    if (ingredient.isNotEmpty && !_selectedIngredients.contains(ingredient)) {
      setState(() {
        _selectedIngredients.add(ingredient);
      });
      _ingredientController.clear();
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _selectedIngredients.remove(ingredient);
      _recipes.clear(); // Clear recipes when ingredients change
    });
  }

  Future<void> _getRecipes() async {
    if (_selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir malzeme ekleyin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final recipes = await _geminiService.getRecipesByIngredients(_selectedIngredients);
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tarif önerisi alınamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildIngredientChip(String ingredient, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: FilterChip(
        label: Text(ingredient),
        selected: isSelected,
        onSelected: isSelected 
          ? null 
          : (selected) {
              if (selected) _addIngredient(ingredient);
            },
        backgroundColor: Colors.grey.shade100,
        selectedColor: Colors.green.shade100,
        checkmarkColor: Colors.green,
        deleteIcon: isSelected ? const Icon(Icons.close, size: 18) : null,
        onDeleted: isSelected ? () => _removeIngredient(ingredient) : null,
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  recipe['emoji'] ?? '🍽️',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recipe['name'] ?? 'İsimsiz Tarif',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${recipe['prep_time']} dk'),
                const SizedBox(width: 16),
                Icon(Icons.restaurant, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(recipe['difficulty'] ?? 'Orta'),
                const SizedBox(width: 16),
                Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text('${recipe['calories']} kcal'),
              ],
            ),
            
            if (recipe['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                recipe['description'],
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],

            // Missing ingredients
            if (recipe['missing_ingredients'] != null && 
                (recipe['missing_ingredients'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Eksik Malzemeler:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                children: (recipe['missing_ingredients'] as List<String>)
                    .map((ingredient) => Chip(
                          label: Text(
                            ingredient,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.orange.shade100,
                          labelStyle: TextStyle(color: Colors.orange.shade700),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 12),
            
            // Instructions preview
            if (recipe['instructions'] != null) ...[
              Text(
                'Yapılış:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ...((recipe['instructions'] as List<String>).take(3).map((step) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(recipe['instructions'] as List<String>).indexOf(step) + 1}. ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
              if ((recipe['instructions'] as List).length > 3)
                Text(
                  '... ve ${(recipe['instructions'] as List).length - 3} adım daha',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Elimdekiler ile Tarifler',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green, Colors.green.shade300],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.kitchen,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '🥘 Elimdekiler ile Neler Yapabilirim?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Malzemelerinizi seçin, size özel tarifler önerelim!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Ingredient input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ingredientController,
                            decoration: InputDecoration(
                              hintText: 'Malzeme ekleyin...',
                              prefixIcon: const Icon(Icons.add),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onSubmitted: _addIngredient,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _addIngredient(_ingredientController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),

                  // Selected ingredients
                  if (_selectedIngredients.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seçili Malzemeler (${_selectedIngredients.length}):',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            children: _selectedIngredients
                                .map((ingredient) => _buildIngredientChip(
                                      ingredient, 
                                      isSelected: true,
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Common ingredients
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yaygın Malzemeler:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          children: _commonIngredients
                              .where((ingredient) => !_selectedIngredients.contains(ingredient))
                              .map((ingredient) => _buildIngredientChip(ingredient))
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  // Get recipes button
                  if (_selectedIngredients.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _getRecipes,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.restaurant_menu),
                          label: Text(
                            _isLoading ? '🤖 AI Tarifler Hazırlıyor...' : '🚀 Tarif Önerilerini Getir',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Recipes list
                  if (_recipes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Önerilen Tarifler (${_recipes.length}):',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_recipes.map((recipe) => _buildRecipeCard(recipe))),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }
}
