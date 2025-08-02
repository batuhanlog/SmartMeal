import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

class FoodEntry {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double portion;
  final DateTime time;

  FoodEntry({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.portion,
    required this.time,
  });

  String toJson() => json.encode({
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'portion': portion,
    'time': time.toIso8601String(),
  });

  static FoodEntry fromJson(String jsonString) {
    final map = json.decode(jsonString);
    return FoodEntry(
      name: map['name'],
      calories: map['calories'],
      protein: map['protein'],
      carbs: map['carbs'],
      fat: map['fat'],
      portion: map['portion'],
      time: DateTime.parse(map['time']),
    );
  }

  double get totalCalories => calories * portion;
  double get totalProtein => protein * portion;
  double get totalCarbs => carbs * portion;
  double get totalFat => fat * portion;
}

class CalorieTrackerPage extends StatefulWidget {
  const CalorieTrackerPage({super.key});

  @override
  State<CalorieTrackerPage> createState() => _CalorieTrackerPageState();
}

class _CalorieTrackerPageState extends State<CalorieTrackerPage> {
  final Color primaryColor = const Color(0xFF1B5E20);
  final Color secondaryColor = const Color(0xFF388E3C);
  final Color calorieColor = const Color(0xFFFF9800);
  final Color proteinColor = const Color(0xFF2196F3);
  final Color carbsColor = const Color(0xFF9C27B0);
  final Color fatColor = const Color(0xFFF44336);

  double dailyCalories = 0;
  double dailyProtein = 0;
  double dailyCarbs = 0;
  double dailyFat = 0;
  
  double calorieGoal = 2000;
  double proteinGoal = 150;
  double carbsGoal = 250;
  double fatGoal = 65;

  List<FoodEntry> todayEntries = [];
  List<double> weeklyCalories = List.filled(7, 0);

  // Önceden tanımlı yiyecekler
  final Map<String, Map<String, double>> predefinedFoods = {
    'Tavuk Göğsü (100g)': {'calories': 165, 'protein': 31, 'carbs': 0, 'fat': 3.6},
    'Pirinç (100g)': {'calories': 130, 'protein': 2.7, 'carbs': 28, 'fat': 0.3},
    'Brokoli (100g)': {'calories': 34, 'protein': 2.8, 'carbs': 7, 'fat': 0.4},
    'Yumurta (1 adet)': {'calories': 70, 'protein': 6, 'carbs': 0.6, 'fat': 5},
    'Ekmek (1 dilim)': {'calories': 80, 'protein': 3, 'carbs': 15, 'fat': 1},
    'Muz (1 adet)': {'calories': 105, 'protein': 1.3, 'carbs': 27, 'fat': 0.4},
    'Elma (1 adet)': {'calories': 95, 'protein': 0.5, 'carbs': 25, 'fat': 0.3},
    'Yoğurt (200g)': {'calories': 120, 'protein': 10, 'carbs': 12, 'fat': 3.5},
    'Balık (100g)': {'calories': 180, 'protein': 25, 'carbs': 0, 'fat': 8},
    'Patates (100g)': {'calories': 77, 'protein': 2, 'carbs': 17, 'fat': 0.1},
  };

  @override
  void initState() {
    super.initState();
    _loadCalorieData();
  }

  Future<void> _loadCalorieData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    setState(() {
      dailyCalories = prefs.getDouble('calories_$todayString') ?? 0;
      dailyProtein = prefs.getDouble('protein_$todayString') ?? 0;
      dailyCarbs = prefs.getDouble('carbs_$todayString') ?? 0;
      dailyFat = prefs.getDouble('fat_$todayString') ?? 0;
      
      calorieGoal = prefs.getDouble('calorie_goal') ?? 2000;
      proteinGoal = prefs.getDouble('protein_goal') ?? 150;
      carbsGoal = prefs.getDouble('carbs_goal') ?? 250;
      fatGoal = prefs.getDouble('fat_goal') ?? 65;
    });
    
    // Haftalık veri yükle
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month}-${date.day}';
      weeklyCalories[6 - i] = prefs.getDouble('calories_$dateString') ?? 0;
    }
    
    await _loadTodayEntries();
    setState(() {});
  }

  Future<void> _loadTodayEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    final entriesJson = prefs.getStringList('food_entries_$todayString') ?? [];
    
    todayEntries = entriesJson.map((e) => FoodEntry.fromJson(e)).toList();
  }

  Future<void> _saveCalorieData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    await prefs.setDouble('calories_$todayString', dailyCalories);
    await prefs.setDouble('protein_$todayString', dailyProtein);
    await prefs.setDouble('carbs_$todayString', dailyCarbs);
    await prefs.setDouble('fat_$todayString', dailyFat);
    
    await prefs.setDouble('calorie_goal', calorieGoal);
    await prefs.setDouble('protein_goal', proteinGoal);
    await prefs.setDouble('carbs_goal', carbsGoal);
    await prefs.setDouble('fat_goal', fatGoal);
    
    final entriesJson = todayEntries.map((e) => e.toJson()).toList();
    await prefs.setStringList('food_entries_$todayString', entriesJson);
  }

  void _addFood(String name, double calories, double protein, double carbs, double fat, double portion) {
    final entry = FoodEntry(
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      portion: portion,
      time: DateTime.now(),
    );

    setState(() {
      todayEntries.add(entry);
      dailyCalories += entry.totalCalories;
      dailyProtein += entry.totalProtein;
      dailyCarbs += entry.totalCarbs;
      dailyFat += entry.totalFat;
    });
    _saveCalorieData();
  }

  void _showAddFoodDialog() {
    showDialog(
      context: context,
      builder: (context) => AddFoodDialog(
        predefinedFoods: predefinedFoods,
        onAddFood: _addFood,
      ),
    );
  }

  void _deleteEntry(int index) {
    if (todayEntries.length > index) {
      setState(() {
        final entry = todayEntries.removeAt(index);
        dailyCalories -= entry.totalCalories;
        dailyProtein -= entry.totalProtein;
        dailyCarbs -= entry.totalCarbs;
        dailyFat -= entry.totalFat;
        
        // Negatif değerleri önle
        if (dailyCalories < 0) dailyCalories = 0;
        if (dailyProtein < 0) dailyProtein = 0;
        if (dailyCarbs < 0) dailyCarbs = 0;
        if (dailyFat < 0) dailyFat = 0;
      });
      _saveCalorieData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Kalori Takibi'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddFoodDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCalorieOverview(),
            const SizedBox(height: 20),
            _buildMacroBreakdown(),
            const SizedBox(height: 20),
            _buildTodayEntries(),
            const SizedBox(height: 20),
            _buildWeeklyChart(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFoodDialog,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCalorieOverview() {
    final progress = (calorieGoal > 0) ? (dailyCalories / calorieGoal).clamp(0.0, 1.0) : 0.0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Günlük Kalori',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 15,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? Colors.green : calorieColor,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${dailyCalories.toInt()}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '/ ${calorieGoal.toInt()} kcal',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '%${(progress * 100).toInt()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: progress >= 1.0 ? Colors.green : calorieColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (progress >= 1.0)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Günlük hedef tamamlandı! 🎉',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBreakdown() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Besin Değerleri',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMacroBar('Protein', dailyProtein, proteinGoal, proteinColor, 'g'),
            const SizedBox(height: 12),
            _buildMacroBar('Karbonhidrat', dailyCarbs, carbsGoal, carbsColor, 'g'),
            const SizedBox(height: 12),
            _buildMacroBar('Yağ', dailyFat, fatGoal, fatColor, 'g'),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBar(String name, double current, double goal, Color color, String unit) {
    final progress = (goal > 0) ? (current / goal).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${current.toInt()}/${goal.toInt()}$unit'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildTodayEntries() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bugünün Yemekleri',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (todayEntries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'Henüz yemek eklenmemiş.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todayEntries.length,
                itemBuilder: (context, index) {
                  final entry = todayEntries.reversed.toList()[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: calorieColor.withOpacity(0.2),
                      child: Text(
                        '${entry.totalCalories.toInt()}',
                        style: TextStyle(
                          color: calorieColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(entry.name),
                    subtitle: Text(
                      '${entry.portion}x porsiyon • '
                      'P:${entry.totalProtein.toInt()}g C:${entry.totalCarbs.toInt()}g Y:${entry.totalFat.toInt()}g',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                      onPressed: () => _deleteEntry(todayEntries.length - 1 - index),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Haftalık Kalori Grafiği',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: calorieGoal * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final today = DateTime.now();
                          final day = today.subtract(Duration(days: 6 - value.toInt()));
                          const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                          return Text(days[day.weekday - 1]);
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: weeklyCalories.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: entry.value >= calorieGoal ? Colors.green : calorieColor,
                          width: 22,
                          borderRadius: const BorderRadius.all(Radius.circular(6)),
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
    );
  }
}

class AddFoodDialog extends StatefulWidget {
  final Map<String, Map<String, double>> predefinedFoods;
  final Function(String, double, double, double, double, double) onAddFood;

  const AddFoodDialog({
    super.key,
    required this.predefinedFoods,
    required this.onAddFood,
  });

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  String? selectedFood;
  double portion = 1.0;
  bool useCustomFood = false;
  
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yemek Ekle'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Listeden Seç'),
                    value: false,
                    groupValue: useCustomFood,
                    onChanged: (value) => setState(() => useCustomFood = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Manuel Gir'),
                    value: true,
                    groupValue: useCustomFood,
                    onChanged: (value) => setState(() => useCustomFood = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (!useCustomFood) ...[
              DropdownButtonFormField<String>(
                value: selectedFood,
                decoration: const InputDecoration(labelText: 'Yemek Seçin'),
                items: widget.predefinedFoods.keys
                    .map((food) => DropdownMenuItem(value: food, child: Text(food)))
                    .toList(),
                onChanged: (value) => setState(() => selectedFood = value),
              ),
            ] else ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Yemek Adı'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(labelText: 'Kalori'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _proteinController,
                      decoration: const InputDecoration(labelText: 'Protein (g)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _carbsController,
                      decoration: const InputDecoration(labelText: 'Karbonhidrat (g)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _fatController,
                      decoration: const InputDecoration(labelText: 'Yağ (g)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Porsiyon: '),
                Expanded(
                  child: Slider(
                    value: portion,
                    min: 0.5,
                    max: 5.0,
                    divisions: 9,
                    label: '${portion}x',
                    onChanged: (value) => setState(() => portion = value),
                  ),
                ),
                Text('${portion}x'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _addFood,
          child: const Text('Ekle'),
        ),
      ],
    );
  }

  void _addFood() {
    if (!useCustomFood && selectedFood != null) {
      final food = widget.predefinedFoods[selectedFood]!;
      widget.onAddFood(
        selectedFood!,
        food['calories']!,
        food['protein']!,
        food['carbs']!,
        food['fat']!,
        portion,
      );
    } else if (useCustomFood && _nameController.text.isNotEmpty) {
      widget.onAddFood(
        _nameController.text,
        double.tryParse(_caloriesController.text) ?? 0,
        double.tryParse(_proteinController.text) ?? 0,
        double.tryParse(_carbsController.text) ?? 0,
        double.tryParse(_fatController.text) ?? 0,
        portion,
      );
    } else {
      return;
    }
    
    Navigator.pop(context);
  }
}
