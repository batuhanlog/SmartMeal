import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/gemini_service.dart';
import 'services/error_handler.dart';
// import 'services/meal_history_service.dart'; // Bu dosyanın projenizde olduğundan emin olun

class MealSuggestionPage extends StatefulWidget {
  const MealSuggestionPage({super.key});

  @override
  State<MealSuggestionPage> createState() => _MealSuggestionPageState();
}

class _MealSuggestionPageState extends State<MealSuggestionPage> {
  // --- RENK PALETİ ---
  final Color primaryColor = Colors.green.shade800;
  final Color secondaryColor = Colors.green.shade600;
  final Color backgroundColor = Colors.grey.shade100;

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
      if (mounted && doc.exists) {
        setState(() => _userProfile = doc.data());
        _getSuggestions();
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getSuggestions() async {
    if (_userProfile == null) {
      ErrorHandler.showError(context, 'Önce profil bilgilerinizi tamamlamalısınız.');
      return;
    }

    setState(() => _isLoading = true);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Kişiye Özel Öneriler'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _getSuggestions,
              icon: const Icon(Icons.refresh),
              tooltip: 'Yenile',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 20),
                  Text('🤖 AI Sizin İçin Öneriler Hazırlıyor...', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                ],
              ),
            )
          : _suggestions.isEmpty
              ? _buildEmptyState()
              : _buildSuggestionsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🤔', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Size Özel Öneri Bulunamadı', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Profil bilgilerinize göre kişiselleştirilmiş yemek önerileri almak için butona basın.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _getSuggestions,
              icon: const Icon(Icons.refresh),
              label: const Text('Öneri Al'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
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

  Widget _buildSuggestionsList() {
    final dietTypesList = _userProfile?['dietTypes'] as List? ?? [];
    final dietTypesText = dietTypesList.isNotEmpty ? dietTypesList.join(', ') : 'Belirtilmemiş';

    return Column(
      children: [
        if (_userProfile != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.person_pin_circle_outlined, size: 32, color: primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bu Öneriler Size Özel',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        dietTypesText,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: secondaryColor),
              ],
            ),
          ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) => _buildSuggestionCard(_suggestions[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // await MealHistoryService.saveMealToHistory(suggestion);
          _showRecipeDetail(suggestion);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Center(child: Text(suggestion['emoji'] ?? '🍽️', style: const TextStyle(fontSize: 28))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(suggestion['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('${suggestion['prep_time']} dk', style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(width: 16),
                            Icon(Icons.bar_chart, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(suggestion['difficulty'] ?? '', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // --- RENK DEĞİŞİKLİĞİ 1: KALORİ RENGİ ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text('${suggestion['calories']} kcal', style: TextStyle(color: Colors.purple.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildNutrientChip('Protein', '${suggestion['protein']}g', Colors.blue.shade700),
                  const SizedBox(width: 8),
                  _buildNutrientChip('Karb', '${suggestion['carbs']}g', Colors.brown.shade700),
                  const SizedBox(width: 8),
                  _buildNutrientChip('Yağ', '${suggestion['fat']}g', Colors.amber.shade800),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Text('$label: $value', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  void _showRecipeDetail(Map<String, dynamic> recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8, minChildSize: 0.5, maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(color: backgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
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
                            width: 80, height: 80,
                            decoration: BoxDecoration(gradient: LinearGradient(colors: [secondaryColor, primaryColor]), shape: BoxShape.circle),
                            child: Center(child: Text(recipe['emoji'] ?? '🍽️', style: const TextStyle(fontSize: 40))),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(recipe['name'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildInfoChip(Icons.access_time, '${recipe['prep_time']} dk'),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(Icons.bar_chart, recipe['difficulty']),
                                  ],
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
                      if (recipe['health_benefits'] != null)
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(Map<String, dynamic> recipe) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 Besin Değerleri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // --- RENK DEĞİŞİKLİĞİ 2: KALORİ RENGİ ---
              _buildNutritionItem('Kalori', '${recipe['calories']}', 'kcal', Colors.purple.shade600),
              _buildNutritionItem('Protein', '${recipe['protein']}', 'g', Colors.blue.shade600),
              _buildNutritionItem('Karb', '${recipe['carbs']}', 'g', Colors.brown.shade500),
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
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
          child: Center(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color))),
        ),
        const SizedBox(height: 4),
        Text(unit, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSection(String title, List<dynamic> items, Widget Function(dynamic) itemBuilder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Divider(height: 24),
        ...items.map(itemBuilder),
      ],
    );
  }

  Widget _buildIngredientItem(String ingredient) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: secondaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(ingredient, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String instruction, int step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
            child: Center(child: Text('$step', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(instruction, style: const TextStyle(fontSize: 16, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_border, size: 20, color: Colors.pink.shade400),
          const SizedBox(width: 12),
          Expanded(child: Text(benefit, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}