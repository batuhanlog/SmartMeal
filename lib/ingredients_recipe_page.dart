import 'package:flutter/material.dart';
import 'services/gemini_service.dart';

class IngredientsRecipePage extends StatefulWidget {
  const IngredientsRecipePage({super.key});

  @override
  State<IngredientsRecipePage> createState() => _IngredientsRecipePageState();
}

class _IngredientsRecipePageState extends State<IngredientsRecipePage> {
  // --- RENK PALETİ ---
  final Color primaryColor = Colors.green.shade800;
  final Color secondaryColor = Colors.green.shade600;
  final Color backgroundColor = Colors.grey.shade100;

  final List<String> _selectedIngredients = [];
  final TextEditingController _ingredientController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _recipes = [];
  final GeminiService _geminiService = GeminiService();

  final List<String> _commonIngredients = [
    'Yumurta', 'Süt', 'Un', 'Tereyağı', 'Zeytinyağı', 'Soğan', 'Sarımsak', 'Domates', 'Biber',
    'Havuç', 'Patates', 'Tavuk', 'Kıyma', 'Balık', 'Pirinç', 'Makarna', 'Peynir', 'Yoğurt',
    'Nohut', 'Mercimek', 'Ispanak', 'Marul', 'Salatalık', 'Limon', 'Tuz', 'Karabiber'
  ];

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  void _addIngredient(String ingredient) {
    if (ingredient.trim().isNotEmpty && !_selectedIngredients.contains(ingredient.trim())) {
      setState(() {
        _selectedIngredients.add(ingredient.trim());
      });
      _ingredientController.clear();
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _selectedIngredients.remove(ingredient);
      _recipes.clear();
    });
  }

  Future<void> _getRecipes() async {
    if (_selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir malzeme ekleyin'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final recipes = await _geminiService.getRecipesByIngredients(_selectedIngredients);
      if(mounted) setState(() => _recipes = recipes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tarif önerisi alınamadı: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // --- DÜZELTME: Bu fonksiyon tamamen yenilendi ---
  Widget _buildIngredientChip(String ingredient, {bool isSelected = false}) {
    if (isSelected) {
      // Bu, üstteki "Seçili Malzemeler" listesi için olan tasarım
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: InputChip(
          label: Text(ingredient, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          backgroundColor: primaryColor,
          onDeleted: () => _removeIngredient(ingredient),
          deleteIconColor: Colors.white70,
        ),
      );
    } else {
      // Bu, alttaki "Yaygın Malzemeler" listesi için olan tasarım
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: FilterChip(
          label: Text(ingredient, style: TextStyle(color: Colors.grey.shade800)),
          selected: false, // Tik işaretini göstermemek için her zaman false
          backgroundColor: Colors.grey.shade200, // Grimsi arka plan
          shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade300)),
          onSelected: (bool selected) {
            // Tıklandığında seçili listesine ekle
             _addIngredient(ingredient);
          },
        ),
      );
    }
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    // ... (Bu fonksiyon aynı kalıyor) ...
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(recipe['emoji'] ?? '🍽️', style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recipe['name'] ?? 'İsimsiz Tarif',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${recipe['prep_time']} dk'),
                const SizedBox(width: 16),
                Icon(Icons.bar_chart_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(recipe['difficulty'] ?? 'Orta'),
                const SizedBox(width: 16),
                Icon(Icons.local_fire_department_outlined, size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Text('${recipe['calories']} kcal'),
              ],
            ),
            if (recipe['missing_ingredients'] != null && (recipe['missing_ingredients'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Eksik Malzemeler:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (recipe['missing_ingredients'] as List<dynamic>).cast<String>()
                    .map((ing) => Chip(
                          label: Text(ing, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          labelStyle: TextStyle(color: Colors.orange.shade800),
                          side: BorderSide.none,
                        )).toList(),
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Elimdekilerle Tarifler'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryColor, secondaryColor],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.kitchen_outlined, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    '🥘 Elimdekiler ile Neler Yapabilirim?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Malzemelerinizi seçin, size özel tarifler önerelim!',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ingredientController,
                        decoration: InputDecoration(
                          hintText: 'Malzeme ekleyin...',
                          prefixIcon: const Icon(Icons.add),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (_selectedIngredients.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Seçili Malzemeler (${_selectedIngredients.length}):', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    children: _selectedIngredients
                        .map((ing) => _buildIngredientChip(ing, isSelected: true))
                        .toList(),
                  ),
                  const Divider(height: 32),
                ],
                const SizedBox(height: 8),
                const Text('Yaygın Malzemeler:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  children: _commonIngredients
                      .where((ing) => !_selectedIngredients.contains(ing))
                      .map((ing) => _buildIngredientChip(ing, isSelected: false))
                      .toList(),
                ),
                if (_selectedIngredients.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _getRecipes,
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        _isLoading ? '🤖 AI Tarifler Hazırlıyor...' : 'Tarif Önerilerini Getir',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
                if (_recipes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Önerilen Tarifler (${_recipes.length}):', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._recipes.map((recipe) => _buildRecipeCard(recipe)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}