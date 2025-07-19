import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart'; // Shimmer paketini import edin
import 'services/gemini_service.dart';
import 'services/error_handler.dart';

class MealSuggestionPage extends StatefulWidget {
  const MealSuggestionPage({super.key});

  @override
  State<MealSuggestionPage> createState() => _MealSuggestionPageState();
}

class _MealSuggestionPageState extends State<MealSuggestionPage> {
  // --- Tutarlı Renk Paleti ve Stil Sabitleri ---
  static const Color _primaryColor = Color(0xFF1B5E20);
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF343A40);
  static const Color _subtleTextColor = Color(0xFF6C757D);

  final GeminiService _geminiService = GeminiService();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        if (doc.exists) {
          setState(() => _userProfile = doc.data());
          _getSuggestions();
        } else {
          ErrorHandler.showError(context, 'Kullanıcı profili bulunamadı.');
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _getSuggestions() async {
    if (_userProfile == null) {
      ErrorHandler.showError(context, 'Önce profil bilgilerinizi tamamlamalısınız.');
      return;
    }
    setState(() {
      _isLoading = true;
      _suggestions = []; // Yenileme sırasında listeyi temizle
    });

    try {
      final dietTypes = _userProfile!['dietTypes'] as List? ?? ['Dengeli'];
      final allergies = _userProfile!['allergies'] as List? ?? [];
      final bmi = _calculateBMI();

      final suggestions = await _geminiService.getMealSuggestions(
        dietType: dietTypes.join(', '),
        allergies: allergies.join(', '),
        bmi: bmi,
        activityLevel: _userProfile!['activityLevel'] ?? 'Orta',
        age: _userProfile!['age'] ?? 25,
      );
      if (mounted) setState(() => _suggestions = suggestions);
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, 'Yemek önerileri alınırken hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateBMI() {
    if (_userProfile == null) return 0;
    final weight = _userProfile!['weight']?.toDouble() ?? 70;
    final height = _userProfile!['height']?.toDouble() ?? 170;
    if (height == 0) return 0.0;
    return weight / ((height / 100) * (height / 100));
  }
  
  // --- UI WIDGET'LARI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildShimmerEffect()
                  : _suggestions.isEmpty
                      ? _buildEmptyState()
                      : _buildSuggestionsList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Modern, özel başlık widget'ı
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: _textColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text(
            'Kişiye Özel Öneriler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: _textColor),
            tooltip: 'Yenile',
            onPressed: _isLoading ? null : _getSuggestions,
          ),
        ],
      ),
    );
  }
  
  /// Yükleme sırasında gösterilecek Shimmer efekti
  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Öneri bulunamadığında gösterilecek ekran
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🤔', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Size Özel Öneri Bulunamadı', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textColor)),
            const SizedBox(height: 8),
            const Text('Profil bilgilerinize göre kişiselleştirilmiş yemek önerileri almak için yenileme butonuna basın.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: _subtleTextColor)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _getSuggestions,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Öneri listesini gösteren widget
  Widget _buildSuggestionsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) => _buildSuggestionCard(_suggestions[index]),
    );
  }

  /// Modernize edilmiş öneri kartı
  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRecipeDetail(suggestion),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: Center(child: Text(suggestion['emoji'] ?? '🍽️', style: const TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(suggestion['name'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textColor)),
                          const SizedBox(height: 4),
                          Text(
                            '${suggestion['prep_time']} dk • ${suggestion['difficulty']}',
                            style: const TextStyle(fontSize: 14, color: _subtleTextColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text('${suggestion['calories']} kcal', style: TextStyle(color: Colors.purple.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildNutrientChip('P: ${suggestion['protein']}g', Colors.blue.shade700),
                        const SizedBox(width: 8),
                        _buildNutrientChip('K: ${suggestion['carbs']}g', Colors.brown.shade700),
                        const SizedBox(width: 8),
                        _buildNutrientChip('Y: ${suggestion['fat']}g', Colors.amber.shade800),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: _subtleTextColor)
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  // _showRecipeDetail ve yardımcıları (stil güncellemeleriyle)
  // Bu fonksiyonların iç stillerini de uygulamanın geneliyle uyumlu hale getirdim.
  void _showRecipeDetail(Map<String, dynamic> recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8, minChildSize: 0.5, maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    children: [
                       Row(
                        children: [
                           Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryColor, Colors.green.shade600]), shape: BoxShape.circle),
                            child: Center(child: Text(recipe['emoji'] ?? '🍽️', style: const TextStyle(fontSize: 32))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(recipe['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textColor)),
                                const SizedBox(height: 6),
                                Text(
                                  '${recipe['prep_time']} dk • ${recipe['difficulty']}',
                                  style: const TextStyle(fontSize: 15, color: _subtleTextColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildNutritionSection(recipe),
                      const SizedBox(height: 24),
                      _buildSection('🛒 Malzemeler', recipe['ingredients'] ?? [], (item) => _buildIngredientItem(item)),
                      const SizedBox(height: 24),
                      _buildSection('👨‍🍳 Hazırlık Adımları', recipe['instructions'] ?? [], (item) => _buildInstructionItem(item, (recipe['instructions'] ?? []).indexOf(item) + 1)),
                      const SizedBox(height: 24),
                      if (recipe['health_benefits'] != null && recipe['health_benefits'].isNotEmpty)
                        _buildSection('💚 Sağlık Faydaları', recipe['health_benefits'], (item) => _buildBenefitItem(item)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

   Widget _buildNutritionSection(Map<String, dynamic> recipe) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Besin Değerleri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textColor)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutritionItem('Kalori', '${recipe['calories']}', 'kcal', Colors.purple.shade600),
              _buildNutritionItem('Protein', '${recipe['protein']}', 'g', Colors.blue.shade600),
              _buildNutritionItem('Karbonhidrat', '${recipe['carbs']}', 'g', Colors.brown.shade500),
              _buildNutritionItem('Yağ', '${recipe['fat']}', 'g', Colors.amber.shade600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(unit, style: TextStyle(fontSize: 12, color: _subtleTextColor)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textColor)),
      ],
    );
  }

  Widget _buildSection(String title, List<dynamic> items, Widget Function(dynamic) itemBuilder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textColor)),
        const Divider(height: 20, thickness: 0.5),
        ...items.map(itemBuilder),
      ],
    );
  }

  Widget _buildIngredientItem(String ingredient) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: _primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(ingredient, style: const TextStyle(fontSize: 16, color: _textColor))),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String instruction, int step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: _primaryColor,
            child: Text('$step', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(instruction, style: const TextStyle(fontSize: 16, height: 1.4, color: _textColor))),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_border, size: 20, color: Colors.pink.shade400),
          const SizedBox(width: 12),
          Expanded(child: Text(benefit, style: const TextStyle(fontSize: 16, color: _textColor))),
        ],
      ),
    );
  }
}