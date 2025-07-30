import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/calorie_calculator_service.dart';
import 'services/error_handler.dart';
import 'dart:convert';

class DailyCalorieTracker extends StatefulWidget {
  const DailyCalorieTracker({super.key});

  @override
  State<DailyCalorieTracker> createState() => _DailyCalorieTrackerState();
}

class _DailyCalorieTrackerState extends State<DailyCalorieTracker> {
  // Tema renkleri
  final Color primaryColor = Colors.green.shade800;
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color cardColor = Colors.white;

  // Durum değişkenleri
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _dailyTarget;
  List<Map<String, dynamic>> _todayMeals = [];
  List<double> _weeklyCalories = List.filled(7, 0);
  bool _isLoading = true;
  int _selectedTabIndex = 0;

  final CalorieCalculatorService _calorieService = CalorieCalculatorService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _loadUserProfile(),
        _loadTodayMeals(),
        _loadWeeklyData(),
      ]);
    } catch (e) {
      print('Veri yükleme hatası: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Future<void> _loadTodayMeals() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final today = DateTime.now();
        final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('daily_calories')
            .doc(todayString)
            .get();

        if (mounted && doc.exists) {
          final data = doc.data()!;
          setState(() {
            _todayMeals = List<Map<String, dynamic>>.from(data['meals'] ?? []);
          });
        }
      }
    } catch (e) {
      print('Günlük öğün yükleme hatası: $e');
    }
  }

  Future<void> _loadWeeklyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      
      for (int i = 0; i < 7; i++) {
        final date = today.subtract(Duration(days: i));
        final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        _weeklyCalories[6 - i] = prefs.getDouble('calories_$dateString') ?? 0;
      }
    } catch (e) {
      print('Haftalık veri yükleme hatası: $e');
    }
  }

  Future<void> _addMeal(Map<String, dynamic> meal) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final today = DateTime.now();
        final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        
        setState(() {
          _todayMeals.add({
            ...meal,
            'timestamp': FieldValue.serverTimestamp(),
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
          });
        });

        // Firestore'a kaydet
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('daily_calories')
            .doc(todayString)
            .set({
          'meals': _todayMeals,
          'total_calories': _getTotalCalories(),
          'date': todayString,
        }, SetOptions(merge: true));

        // SharedPreferences'a kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('calories_$todayString', _getTotalCalories().toDouble());

        if (mounted) {
          ErrorHandler.showSuccess(context, 'Öğün eklendi!');
          _loadWeeklyData(); // Haftalık veriyi güncelle
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Öğün eklenirken hata oluştu: $e');
      }
    }
  }

  Future<void> _removeMeal(String mealId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _todayMeals.removeWhere((meal) => meal['id'] == mealId);
        });

        final today = DateTime.now();
        final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        
        // Firestore'u güncelle
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('daily_calories')
            .doc(todayString)
            .set({
          'meals': _todayMeals,
          'total_calories': _getTotalCalories(),
          'date': todayString,
        }, SetOptions(merge: true));

        // SharedPreferences'ı güncelle
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('calories_$todayString', _getTotalCalories().toDouble());

        if (mounted) {
          ErrorHandler.showSuccess(context, 'Öğün kaldırıldı');
          _loadWeeklyData(); // Haftalık veriyi güncelle
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Öğün kaldırılırken hata oluştu: $e');
      }
    }
  }

  int _getTotalCalories() {
    return _todayMeals.fold<int>(0, (int sum, meal) => sum + (meal['calories'] as int? ?? 0));
  }

  double _getCaloriePercentage() {
    if (_dailyTarget == null) return 0;
    final target = _dailyTarget!['target_calories'] ?? 2000;
    final total = _getTotalCalories();
    return (total / target * 100).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Günlük Kalori Takibi'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  TabBar(
                    labelColor: primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: primaryColor,
                    tabs: [
                      const Tab(text: 'Bugün', icon: Icon(Icons.today)),
                      const Tab(text: 'Haftalık', icon: Icon(Icons.calendar_today)),
                      const Tab(text: 'Hedefler', icon: Icon(Icons.track_changes)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTodayTab(),
                        _buildWeeklyTab(),
                        _buildGoalsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMealDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Öğün Ekle'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalCalories = _getTotalCalories();
    final percentage = _getCaloriePercentage();
    final targetCalories = _dailyTarget?['target_calories'] ?? 2000;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bugün',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  Text(
                    '$totalCalories kcal',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Hedef',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  Text(
                    '$targetCalories kcal',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 100 ? Colors.red : Colors.green,
            ),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            'Hedefinizin %${percentage.toStringAsFixed(1)}\'i',
            style: TextStyle(
              color: percentage > 100 ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_todayMeals.isEmpty)
          Container(
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
                Text('Henüz öğün eklenmedi', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text('Sağ alttaki butona tıklayarak öğün ekleyin', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
              ],
            ),
          )
        else
          ..._todayMeals.map((meal) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal['name'] ?? 'Bilinmeyen',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (meal['description'] != null)
                        Text(
                          meal['description'],
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${meal['calories']} kcal',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                    ),
                    Text(
                      meal['time'] ?? '',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _removeMeal(meal['id']),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Sil',
                ),
              ],
            ),
          )).toList(),
      ],
    );
  }

  Widget _buildWeeklyTab() {
    final weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                const Text('Haftalık Kalori Takibi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _weeklyCalories.reduce((a, b) => a > b ? a : b) * 1.2,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(weekDays[value.toInt()], style: const TextStyle(fontSize: 12));
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _weeklyCalories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final calories = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: calories,
                              color: primaryColor,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    if (_dailyTarget == null) {
      return const Center(child: Text('Hedef bilgileri yüklenemedi'));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Günlük Hedefleriniz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildGoalCard('Kalori', '${_dailyTarget!['target_calories']} kcal', Colors.orange),
                _buildGoalCard('Protein', '${_dailyTarget!['protein_grams']}g', Colors.blue),
                _buildGoalCard('Karbonhidrat', '${_dailyTarget!['carbs_grams']}g', Colors.purple),
                _buildGoalCard('Yağ', '${_dailyTarget!['fat_grams']}g', Colors.amber),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hedef Ayarları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('BMR (Bazal Metabolizma Hızı)'),
                  subtitle: Text('${_dailyTarget!['bmr']} kcal'),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('TDEE (Toplam Günlük Enerji Harcaması)'),
                  subtitle: Text('${_dailyTarget!['tdee']} kcal'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.track_changes, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, color: Color.lerp(color, Colors.black, 0.7)!)),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.lerp(color, Colors.black, 0.8)!)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMealDialog() {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğün Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Öğün Adı',
                hintText: 'Örn: Kahvaltı, Öğle Yemeği',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kalori',
                hintText: 'Örn: 350',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama (Opsiyonel)',
                hintText: 'Örn: Yulaf ezmesi, süt, muz',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final calories = int.tryParse(caloriesController.text) ?? 0;
              
              if (name.isEmpty || calories <= 0) {
                ErrorHandler.showError(context, 'Lütfen geçerli bir öğün adı ve kalori girin');
                return;
              }

              _addMeal({
                'name': name,
                'calories': calories,
                'description': descriptionController.text.trim(),
                'time': TimeOfDay.now().format(context),
              });

              Navigator.pop(context);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
} 