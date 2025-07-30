import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/calorie_calculator_service.dart';
import '../services/error_handler.dart';

class QuickCalorieWidget extends StatefulWidget {
  const QuickCalorieWidget({super.key});

  @override
  State<QuickCalorieWidget> createState() => _QuickCalorieWidgetState();
}

class _QuickCalorieWidgetState extends State<QuickCalorieWidget> {
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedUnit = 'g';
  bool _isCalculating = false;
  Map<String, dynamic>? _result;
  Map<String, dynamic>? _userProfile;

  final CalorieCalculatorService _calorieService = CalorieCalculatorService();
  final List<String> _units = ['g', 'kg', 'ml', 'L', 'adet', 'porsiyon'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _foodController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && doc.exists) {
          setState(() => _userProfile = doc.data());
        }
      }
    } catch (e) {
      print('Profil yükleme hatası: $e');
    }
  }

  Future<void> _calculateQuickCalories() async {
    final food = _foodController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (food.isEmpty || amount <= 0) {
      ErrorHandler.showError(context, 'Lütfen geçerli bir gıda adı ve miktar girin');
      return;
    }

    setState(() => _isCalculating = true);

    try {
      final result = await _calorieService.calculateCaloriesFromFoodList([
        {
          'name': food,
          'amount': amount,
          'unit': _selectedUnit,
        }
      ]);

      if (mounted) {
        setState(() {
          _result = result;
          _isCalculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCalculating = false);
        ErrorHandler.showError(context, 'Hesaplama hatası: $e');
      }
    }
  }

  void _clearResult() {
    setState(() {
      _result = null;
      _foodController.clear();
      _amountController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_outlined, color: Colors.green.shade800),
              const SizedBox(width: 8),
              const Text('Hızlı Kalori Hesaplama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_result == null) ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _foodController,
                    decoration: const InputDecoration(
                      labelText: 'Gıda Adı',
                      border: OutlineInputBorder(),
                      hintText: 'Örn: Elma',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                onPressed: _isCalculating ? null : _calculateQuickCalories,
                icon: _isCalculating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.calculate),
                label: Text(_isCalculating ? 'Hesaplanıyor...' : 'Hızlı Hesapla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ] else ...[
            _buildResultCard(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _clearResult,
                icon: const Icon(Icons.refresh),
                label: const Text('Yeni Hesaplama'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade800,
                  side: BorderSide(color: Colors.green.shade800),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _result!;
    final totalCalories = result['total_calories'] ?? 0;
    final targetCalories = _userProfile != null ? 
        _calorieService.calculateDailyCalorieNeeds(
          age: _userProfile!['age'] ?? 25,
          gender: _userProfile!['gender'] ?? 'Erkek',
          weight: _userProfile!['weight']?.toDouble() ?? 70.0,
          height: _userProfile!['height']?.toDouble() ?? 170.0,
          activityLevel: _userProfile!['activityLevel'] ?? 'Orta',
          goal: _userProfile!['goal'] ?? 'maintain',
        )['target_calories'] ?? 2000 : 2000;
    
    final percentage = (totalCalories / targetCalories * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${result['foods'][0]['name']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '$totalCalories kcal',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${result['foods'][0]['amount']}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 