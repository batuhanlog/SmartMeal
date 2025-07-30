import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/calorie_calculator_service.dart';
import 'services/error_handler.dart';

class ManualCaloriePage extends StatefulWidget {
  const ManualCaloriePage({super.key});

  @override
  State<ManualCaloriePage> createState() => _ManualCaloriePageState();
}

class _ManualCaloriePageState extends State<ManualCaloriePage> {
  // Tema renkleri
  final Color primaryColor = Colors.green.shade800;
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color cardColor = Colors.white;

  // Durum değişkenleri
  final List<Map<String, dynamic>> _foods = [];
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedUnit = 'g';
  bool _isCalculating = false;
  Map<String, dynamic>? _calculationResult;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _dailyTarget;

  final CalorieCalculatorService _calorieService = CalorieCalculatorService();

  // Birim seçenekleri
  final List<String> _units = ['g', 'kg', 'ml', 'L', 'adet', 'porsiyon', 'kaşık', 'bardak'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && doc.exists) {
          final profile = doc.data()!;
          setState(() {
            _userProfile = profile;
            _dailyTarget = _calorieService.calculateDailyCalorieNeeds(
              age: profile['age'] ?? 25,
              gender: profile['gender'] ?? 'Erkek',
              weight: profile['weight']?.toDouble() ?? 70.0,
              height: profile['height']?.toDouble() ?? 170.0,
              activityLevel: profile['activityLevel'] ?? 'Orta',
              goal: profile['goal'] ?? 'maintain',
            );
          });
        }
      }
    } catch (e) {
      print('Profil yükleme hatası: $e');
    }
  }

  void _addFood() {
    final name = _foodNameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (name.isEmpty || amount <= 0) {
      ErrorHandler.showError(context, 'Lütfen geçerli bir gıda adı ve miktar girin');
      return;
    }

    setState(() {
      _foods.add({
        'name': name,
        'amount': amount,
        'unit': _selectedUnit,
        'calories': 100, // Varsayılan değer
        'protein': 5,
        'carbs': 15,
        'fat': 2,
      });
    });

    _foodNameController.clear();
    _amountController.clear();
    _calculationResult = null; // Sonucu temizle
  }

  void _removeFood(int index) {
    setState(() {
      _foods.removeAt(index);
      _calculationResult = null; // Sonucu temizle
    });
  }

  Future<void> _calculateCalories() async {
    if (_foods.isEmpty) {
      ErrorHandler.showError(context, 'Lütfen en az bir gıda ekleyin');
      return;
    }

    setState(() => _isCalculating = true);

    try {
      final result = await _calorieService.calculateCaloriesFromFoodList(_foods);
      if (mounted) {
        setState(() {
          _calculationResult = result;
          _isCalculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCalculating = false);
        ErrorHandler.showError(context, 'Kalori hesaplama hatası: $e');
      }
    }
  }

  void _clearAll() {
    setState(() {
      _foods.clear();
      _calculationResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Manuel Kalori Hesaplama'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDailyTargetCard(),
            const SizedBox(height: 20),
            _buildFoodInputSection(),
            const SizedBox(height: 20),
            _buildFoodList(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            if (_calculationResult != null) ...[
              const SizedBox(height: 20),
              _buildCalculationResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTargetCard() {
    if (_dailyTarget == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes, color: primaryColor),
              const SizedBox(width: 8),
              const Text('Günlük Kalori Hedefiniz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTargetInfo('Hedef Kalori', '${_dailyTarget!['target_calories']} kcal', Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTargetInfo('Protein', '${_dailyTarget!['protein_grams']}g', Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTargetInfo('Karbonhidrat', '${_dailyTarget!['carbs_grams']}g', Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTargetInfo('Yağ', '${_dailyTarget!['fat_grams']}g', Colors.amber),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetInfo(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Color.lerp(color, Colors.black, 0.7)!)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.lerp(color, Colors.black, 0.8)!)),
        ],
      ),
    );
  }

  Widget _buildFoodInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: primaryColor),
              const SizedBox(width: 8),
              const Text('Gıda Ekle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _foodNameController,
                  decoration: const InputDecoration(
                    labelText: 'Gıda Adı',
                    border: OutlineInputBorder(),
                    hintText: 'Örn: Tavuk Göğsü',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Miktar',
                    border: OutlineInputBorder(),
                    hintText: '100',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _units.map((unit) => DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => _selectedUnit = value!);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addFood,
              icon: const Icon(Icons.add),
              label: const Text('Gıda Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList() {
    if (_foods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Henüz gıda eklenmedi', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Yukarıdan gıda ekleyerek başlayın', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list, color: primaryColor),
              const SizedBox(width: 8),
              Text('Gıda Listesi (${_foods.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ..._foods.asMap().entries.map((entry) {
            final index = entry.key;
            final food = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${food['amount']} ${food['unit']}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeFood(index),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Sil',
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _foods.isEmpty ? null : _clearAll,
            icon: const Icon(Icons.clear_all),
            label: const Text('Temizle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _foods.isEmpty || _isCalculating ? null : _calculateCalories,
            icon: _isCalculating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.calculate),
            label: Text(_isCalculating ? 'Hesaplanıyor...' : 'Hesapla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationResult() {
    final result = _calculationResult!;
    final totalCalories = result['total_calories'] ?? 0;
    final targetCalories = _dailyTarget?['target_calories'] ?? 2000;
    final percentage = (totalCalories / targetCalories * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: primaryColor),
              const SizedBox(width: 8),
              const Text('Hesaplama Sonucu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          // Günlük hedef karşılaştırması
          if (_dailyTarget != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Günlük Hedef: ${targetCalories} kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Bu Öğün: $totalCalories kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage > 100 ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Günlük hedefinizin %${percentage.toStringAsFixed(1)}\'i',
                    style: TextStyle(
                      color: percentage > 100 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Toplam besin değerleri
          const Text('Toplam Besin Değerleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            children: [
              _buildNutritionCard('Toplam Kalori', '${result['total_calories']}', Colors.orange),
              _buildNutritionCard('Toplam Protein', '${result['total_protein']}g', Colors.blue),
              _buildNutritionCard('Toplam Karbonhidrat', '${result['total_carbs']}g', Colors.purple),
              _buildNutritionCard('Toplam Yağ', '${result['total_fat']}g', Colors.amber),
            ],
          ),
          const SizedBox(height: 16),

          // Yemek detayları
          const Text('Gıda Detayları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...(result['foods'] as List<dynamic>).map((food) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food['name'] ?? 'Bilinmeyen',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        food['amount'] ?? '',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${food['calories']} kcal',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          )).toList(),

          // Öneriler
          if (result['recommendations'] != null) ...[
            const SizedBox(height: 16),
            const Text('Öneriler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: (result['recommendations'] as List<dynamic>).map((rec) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(children: [
                    Icon(Icons.check, size: 20, color: primaryColor),
                    const SizedBox(width: 12),
                    Expanded(child: Text(rec.toString(), style: const TextStyle(fontSize: 15, color: Colors.black54))),
                  ]),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Color.lerp(color, Colors.black, 0.7)!)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.lerp(color, Colors.black, 0.8)!)),
        ],
      ),
    );
  }
} 