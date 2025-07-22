import 'package:flutter/material.dart';
// services/gemini_service.dart dosyasının projenizde doğru bir şekilde
// yapılandırıldığından emin olun. Bu kodda o dosya olmadan çalışmaz.
import 'services/gemini_service.dart';

// --- GEÇİCİ GEMINI SERVICE SIMÜLASYONU ---
// Eğer 'gemini_service.dart' dosyanız yoksa veya hata alıyorsanız,
// test etmek için aşağıdaki sahte sınıfı geçici olarak kullanabilirsiniz.
// Kendi servisinizi bağladığınızda bu sınıfı silin.
class GeminiService {
  Future<List<Map<String, dynamic>>> getRecipesByIngredients(List<String> ingredients) async {
    await Future.delayed(const Duration(seconds: 2)); // 2 saniyelik sahte bir bekleme
    if (ingredients.contains('HataTesti')) {
      throw Exception('Yapay zeka servisinde bir sorun oluştu.');
    }
    return [
      {
        'name': 'Menemen',
        'emoji': '🍳',
        'prep_time': '15',
        'difficulty': 'Kolay',
        'calories': '250',
        'missing_ingredients': ['Soğan', 'Sıvı Yağ']
      },
      {
        'name': 'Tavuklu Salata',
        'emoji': '🥗',
        'prep_time': '20',
        'difficulty': 'Kolay',
        'calories': '350',
        'missing_ingredients': []
      },
    ];
  }
}
// --- ------------------------------------ ---


class IngredientsRecipePage extends StatefulWidget {
  const IngredientsRecipePage({super.key});

  @override
  State<IngredientsRecipePage> createState() => _IngredientsRecipePageState();
}

class _IngredientsRecipePageState extends State<IngredientsRecipePage> {
  // --- ÖNEMLİ: BU TEMA, İSTEDİĞİNİZ GİBİ AÇIK RENK BİR ARKA PLANA SAHİPTİR ---
  // --- Arka plan rengi (backgroundColor) açık gri/beyaz olarak ayarlanmıştır. ---
  final Color backgroundColor = const Color(0xFFF8F9FA); // BU SATIR ARKA PLANI AÇIK RENK YAPAR
  final Color surfaceColor = Colors.white; // Kartlar ve alanlar için saf beyaz
  final Color primaryColor = const Color(0xFF2E7D32); // Ana vurgu rengi (koyu ve tok bir yeşil)
  final Color secondaryColor = const Color(0xFF388E3C); // Butonlar için bir ton açık yeşil
  final Color accentColor = const Color(0xFFD9534F);  // Vurgu için canlı bir kırmızı/turuncu (Örn: Eksik Malzemeler)
  final Color primaryTextColor = const Color(0xFF212529); // Okunabilir koyu renk metin
  final Color secondaryTextColor = const Color(0xFF6C757D); // İkincil, daha soluk metin
  // --- -------------------------------------------------------------------------- ---

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
      if (_recipes.isNotEmpty) {
        setState(() {
          _recipes.clear();
        });
      }
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _selectedIngredients.remove(ingredient);
      if (_recipes.isNotEmpty) {
        setState(() {
          _recipes.clear();
        });
      }
    });
  }

  Future<void> _getRecipes() async {
    if (_selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Lütfen en az bir malzeme ekleyin'), backgroundColor: accentColor),
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
          SnackBar(content: Text('Tarif önerisi alınamadı: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildIngredientChip(String ingredient, {bool isSelected = false}) {
    // Seçili Malzemeler Çipi
    if (isSelected) {
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: InputChip(
          label: Text(ingredient, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          backgroundColor: primaryColor,
          onDeleted: () => _removeIngredient(ingredient),
          deleteIcon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.8), size: 18),
        ),
      );
    }
    // Yaygın Malzemeler Çipi
    else {
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: ActionChip(
          label: Text(ingredient, style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w500)),
          backgroundColor: Colors.grey.shade200,
          shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade300)),
          onPressed: () => _addIngredient(ingredient),
        ),
      );
    }
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: surfaceColor,
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(recipe['emoji'] ?? '🍽️', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recipe['name'] ?? 'İsimsiz Tarif',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoIcon(Icons.timer_outlined, '${recipe['prep_time']} dk'),
                _buildInfoIcon(Icons.bar_chart_outlined, recipe['difficulty'] ?? 'Orta'),
                _buildInfoIcon(Icons.local_fire_department_outlined, '${recipe['calories']} kcal', iconColor: accentColor),
              ],
            ),
            if (recipe['missing_ingredients'] != null && (recipe['missing_ingredients'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Eksik Malzemeler:', style: TextStyle(fontWeight: FontWeight.w600, color: accentColor, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (recipe['missing_ingredients'] as List<dynamic>).cast<String>()
                    .map((ing) => Chip(
                  label: Text(ing),
                  backgroundColor: accentColor.withOpacity(0.1),
                  labelStyle: TextStyle(color: accentColor, fontWeight: FontWeight.w500),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, String text, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? secondaryTextColor),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: secondaryTextColor, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // UYGULAMA ARKA PLANI BURADA AYARLANDI
      appBar: AppBar(
        centerTitle: true,
        title: Text('Elimdekilerle Tarifler', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
        children: [
          Text(
            '🥘 Ne Pişirsem?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Malzemelerini seç, yapay zeka senin için harika tarifler önerinsin!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: secondaryTextColor),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ingredientController,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    hintText: 'Malzeme ekle...',
                    hintStyle: TextStyle(color: secondaryTextColor),
                    prefixIcon: Icon(Icons.add_shopping_cart_rounded, color: secondaryTextColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: surfaceColor,
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
                  minimumSize: const Size(60, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),

          if (_selectedIngredients.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Seçili Malzemeler (${_selectedIngredients.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primaryTextColor)),
            const SizedBox(height: 12),
            Wrap(
              children: _selectedIngredients
                  .map((ing) => _buildIngredientChip(ing, isSelected: true))
                  .toList(),
            ),
            Divider(height: 48, color: Colors.grey.shade300),
          ],

          const SizedBox(height: 8),
          Text('Sık Kullanılanlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primaryTextColor)),
          const SizedBox(height: 12),
          Wrap(
            children: _commonIngredients
                .where((ing) => !_selectedIngredients.contains(ing))
                .map((ing) => _buildIngredientChip(ing, isSelected: false))
                .toList(),
          ),

          if (_selectedIngredients.isNotEmpty) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _getRecipes,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  _isLoading ? '🤖 Tarifler Hazırlanıyor...' : 'Tarifleri Getir',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: secondaryColor.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          if (_recipes.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text('Önerilen Tarifler (${_recipes.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor)),
            const SizedBox(height: 8),
            ..._recipes.map((recipe) => _buildRecipeCard(recipe)),
          ],
        ],
      ),
    );
  }
}