import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

class WorkoutEntry {
  final String name;
  final String type; // cardio, strength, flexibility, sports
  final int duration; // dakika
  final double caloriesBurned;
  final String intensity; // low, medium, high
  final DateTime time;
  final Map<String, dynamic>? details; // set, rep, distance vb.

  WorkoutEntry({
    required this.name,
    required this.type,
    required this.duration,
    required this.caloriesBurned,
    required this.intensity,
    required this.time,
    this.details,
  });

  String toJson() => json.encode({
    'name': name,
    'type': type,
    'duration': duration,
    'caloriesBurned': caloriesBurned,
    'intensity': intensity,
    'time': time.toIso8601String(),
    'details': details,
  });

  static WorkoutEntry fromJson(String jsonString) {
    final map = json.decode(jsonString);
    return WorkoutEntry(
      name: map['name'],
      type: map['type'],
      duration: map['duration'],
      caloriesBurned: map['caloriesBurned'],
      intensity: map['intensity'],
      time: DateTime.parse(map['time']),
      details: map['details'],
    );
  }
}

class FitnessTrackerPage extends StatefulWidget {
  const FitnessTrackerPage({super.key});

  @override
  State<FitnessTrackerPage> createState() => _FitnessTrackerPageState();
}

class _FitnessTrackerPageState extends State<FitnessTrackerPage> {
  final Color primaryColor = const Color(0xFF1B5E20);
  final Color secondaryColor = const Color(0xFF388E3C);
  final Color cardioColor = const Color(0xFFE91E63);
  final Color strengthColor = const Color(0xFF3F51B5);
  final Color flexibilityColor = const Color(0xFF9C27B0);
  final Color sportsColor = const Color(0xFFFF9800);

  // Günlük veriler
  int dailyWorkouts = 0;
  int dailyDuration = 0; // toplam dakika
  double dailyCaloriesBurned = 0;
  int dailySteps = 0;

  // Hedefler
  int weeklyWorkoutGoal = 5;
  int dailyStepGoal = 10000;
  int weeklyDurationGoal = 300; // dakika

  // Listeler
  List<WorkoutEntry> todayWorkouts = [];
  List<int> weeklyWorkouts = List.filled(7, 0);
  List<double> weeklyCalories = List.filled(7, 0);
  List<int> weeklySteps = List.filled(7, 0);

  // Önceden tanımlı egzersizler
  final Map<String, Map<String, dynamic>> predefinedWorkouts = {
    // Cardio
    'Koşu': {'type': 'cardio', 'calories_per_min': 12, 'intensity': 'high'},
    'Yürüyüş': {'type': 'cardio', 'calories_per_min': 5, 'intensity': 'low'},
    'Bisiklet': {'type': 'cardio', 'calories_per_min': 8, 'intensity': 'medium'},
    'Yüzme': {'type': 'cardio', 'calories_per_min': 10, 'intensity': 'high'},
    'Eliptik': {'type': 'cardio', 'calories_per_min': 9, 'intensity': 'medium'},
    
    // Strength
    'Ağırlık Kaldırma': {'type': 'strength', 'calories_per_min': 6, 'intensity': 'medium'},
    'Şınav': {'type': 'strength', 'calories_per_min': 7, 'intensity': 'medium'},
    'Mekik': {'type': 'strength', 'calories_per_min': 5, 'intensity': 'medium'},
    'Squat': {'type': 'strength', 'calories_per_min': 8, 'intensity': 'medium'},
    'Deadlift': {'type': 'strength', 'calories_per_min': 9, 'intensity': 'high'},
    
    // Flexibility
    'Yoga': {'type': 'flexibility', 'calories_per_min': 3, 'intensity': 'low'},
    'Pilates': {'type': 'flexibility', 'calories_per_min': 4, 'intensity': 'low'},
    'Stretching': {'type': 'flexibility', 'calories_per_min': 2, 'intensity': 'low'},
    
    // Sports
    'Futbol': {'type': 'sports', 'calories_per_min': 11, 'intensity': 'high'},
    'Basketbol': {'type': 'sports', 'calories_per_min': 10, 'intensity': 'high'},
    'Tenis': {'type': 'sports', 'calories_per_min': 8, 'intensity': 'medium'},
    'Voleybol': {'type': 'sports', 'calories_per_min': 6, 'intensity': 'medium'},
  };

  @override
  void initState() {
    super.initState();
    _loadFitnessData();
  }

  Future<void> _loadFitnessData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    setState(() {
      dailyWorkouts = prefs.getInt('workouts_$todayString') ?? 0;
      dailyDuration = prefs.getInt('duration_$todayString') ?? 0;
      dailyCaloriesBurned = prefs.getDouble('calories_burned_$todayString') ?? 0;
      dailySteps = prefs.getInt('steps_$todayString') ?? 0;
      
      weeklyWorkoutGoal = prefs.getInt('weekly_workout_goal') ?? 5;
      dailyStepGoal = prefs.getInt('daily_step_goal') ?? 10000;
      weeklyDurationGoal = prefs.getInt('weekly_duration_goal') ?? 300;
    });
    
    // Haftalık veriler
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month}-${date.day}';
      weeklyWorkouts[6 - i] = prefs.getInt('workouts_$dateString') ?? 0;
      weeklyCalories[6 - i] = prefs.getDouble('calories_burned_$dateString') ?? 0;
      weeklySteps[6 - i] = prefs.getInt('steps_$dateString') ?? 0;
    }
    
    await _loadTodayWorkouts();
    setState(() {});
  }

  Future<void> _loadTodayWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    final workoutsJson = prefs.getStringList('workout_entries_$todayString') ?? [];
    
    todayWorkouts = workoutsJson.map((e) => WorkoutEntry.fromJson(e)).toList();
  }

  Future<void> _saveFitnessData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    await prefs.setInt('workouts_$todayString', dailyWorkouts);
    await prefs.setInt('duration_$todayString', dailyDuration);
    await prefs.setDouble('calories_burned_$todayString', dailyCaloriesBurned);
    await prefs.setInt('steps_$todayString', dailySteps);
    
    await prefs.setInt('weekly_workout_goal', weeklyWorkoutGoal);
    await prefs.setInt('daily_step_goal', dailyStepGoal);
    await prefs.setInt('weekly_duration_goal', weeklyDurationGoal);
    
    final workoutsJson = todayWorkouts.map((e) => e.toJson()).toList();
    await prefs.setStringList('workout_entries_$todayString', workoutsJson);
  }

  void _addWorkout(String name, String type, int duration, String intensity, {Map<String, dynamic>? details}) {
    final workoutData = predefinedWorkouts[name];
    final caloriesPerMin = workoutData?['calories_per_min'] ?? 5.0;
    final calculatedCalories = (duration * caloriesPerMin).toDouble();

    final workout = WorkoutEntry(
      name: name,
      type: type,
      duration: duration,
      caloriesBurned: calculatedCalories,
      intensity: intensity,
      time: DateTime.now(),
      details: details,
    );

    setState(() {
      todayWorkouts.add(workout);
      dailyWorkouts++;
      dailyDuration += duration;
      dailyCaloriesBurned += calculatedCalories;
    });
    _saveFitnessData();
  }

  void _showAddWorkoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AddWorkoutDialog(
        predefinedWorkouts: predefinedWorkouts,
        onAddWorkout: _addWorkout,
      ),
    );
  }

  void _deleteWorkout(int index) {
    if (todayWorkouts.length > index) {
      setState(() {
        final workout = todayWorkouts.removeAt(index);
        dailyWorkouts--;
        dailyDuration -= workout.duration;
        dailyCaloriesBurned -= workout.caloriesBurned;
        
        // Negatif değerleri önle
        if (dailyWorkouts < 0) dailyWorkouts = 0;
        if (dailyDuration < 0) dailyDuration = 0;
        if (dailyCaloriesBurned < 0) dailyCaloriesBurned = 0;
      });
      _saveFitnessData();
    }
  }

  Color _getWorkoutTypeColor(String type) {
    switch (type) {
      case 'cardio': return cardioColor;
      case 'strength': return strengthColor;
      case 'flexibility': return flexibilityColor;
      case 'sports': return sportsColor;
      default: return Colors.grey;
    }
  }

  IconData _getWorkoutTypeIcon(String type) {
    switch (type) {
      case 'cardio': return Icons.directions_run;
      case 'strength': return Icons.fitness_center;
      case 'flexibility': return Icons.self_improvement;
      case 'sports': return Icons.sports_soccer;
      default: return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeklyWorkoutTotal = weeklyWorkouts.reduce((a, b) => a + b);
    final weeklyWorkoutProgress = weeklyWorkoutGoal > 0 ? (weeklyWorkoutTotal / weeklyWorkoutGoal).clamp(0.0, 1.0) : 0.0;
    final stepProgress = dailyStepGoal > 0 ? (dailySteps / dailyStepGoal).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Fitness Takibi'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddWorkoutDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFitnessOverview(weeklyWorkoutProgress, stepProgress),
            const SizedBox(height: 20),
            _buildTodayStats(),
            const SizedBox(height: 20),
            _buildTodayWorkouts(),
            const SizedBox(height: 20),
            _buildWeeklyCharts(),
            const SizedBox(height: 20),
            _buildGoalSettings(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWorkoutDialog,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFitnessOverview(double weeklyProgress, double stepProgress) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Haftalık Antrenman',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 80,
                        width: 80,
                        child: CircularProgressIndicator(
                          value: weeklyProgress,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            weeklyProgress >= 1.0 ? Colors.green : secondaryColor,
                          ),
                        ),
                      ),
                      Text(
                        '${weeklyWorkouts.reduce((a, b) => a + b)}/${weeklyWorkoutGoal}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Günlük Adım',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 80,
                        width: 80,
                        child: CircularProgressIndicator(
                          value: stepProgress,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            stepProgress >= 1.0 ? Colors.green : cardioColor,
                          ),
                        ),
                      ),
                      Text(
                        '${(dailySteps / 1000).toStringAsFixed(1)}k',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bugünün Özeti',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Antrenman', '$dailyWorkouts', Icons.fitness_center, strengthColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Süre', '${dailyDuration}dk', Icons.timer, secondaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Kalori', '${dailyCaloriesBurned.toInt()}', Icons.local_fire_department, cardioColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayWorkouts() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bugünün Antrenmanları',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (todayWorkouts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'Henüz antrenman eklenmemiş.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todayWorkouts.length,
                itemBuilder: (context, index) {
                  final workout = todayWorkouts.reversed.toList()[index];
                  final typeColor = _getWorkoutTypeColor(workout.type);
                  final typeIcon = _getWorkoutTypeIcon(workout.type);
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: typeColor.withOpacity(0.2),
                      child: Icon(typeIcon, color: typeColor),
                    ),
                    title: Text(workout.name),
                    subtitle: Text(
                      '${workout.duration} dakika • ${workout.caloriesBurned.toInt()} kalori • ${workout.intensity.toUpperCase()}',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                      onPressed: () => _deleteWorkout(todayWorkouts.length - 1 - index),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyCharts() {
    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Haftalık Antrenman Sayısı',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: weeklyWorkoutGoal.toDouble() * 1.5,
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
                            reservedSize: 30,
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
                      barGroups: weeklyWorkouts.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              color: secondaryColor,
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
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Haftalık Yakılan Kalori',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final today = DateTime.now();
                              final day = today.subtract(Duration(days: 6 - value.toInt()));
                              const days = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];
                              return Text(days[day.weekday - 1]);
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: weeklyCalories.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value);
                          }).toList(),
                          isCurved: true,
                          color: cardioColor,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: cardioColor.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hedeflerini Ayarla',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildGoalSlider(
              'Haftalık Antrenman',
              weeklyWorkoutGoal.toDouble(),
              3,
              10,
              '${weeklyWorkoutGoal} antrenman',
              (value) => setState(() => weeklyWorkoutGoal = value.toInt()),
            ),
            const SizedBox(height: 16),
            _buildGoalSlider(
              'Günlük Adım',
              dailyStepGoal.toDouble(),
              5000,
              20000,
              '${dailyStepGoal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} adım',
              (value) => setState(() => dailyStepGoal = value.toInt()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSlider(String title, double value, double min, double max, String label, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / (max > 1000 ? 1000 : 1)).toInt(),
          activeColor: primaryColor,
          onChanged: onChanged,
          onChangeEnd: (value) => _saveFitnessData(),
        ),
      ],
    );
  }
}

class AddWorkoutDialog extends StatefulWidget {
  final Map<String, Map<String, dynamic>> predefinedWorkouts;
  final Function(String, String, int, String, {Map<String, dynamic>? details}) onAddWorkout;

  const AddWorkoutDialog({
    super.key,
    required this.predefinedWorkouts,
    required this.onAddWorkout,
  });

  @override
  State<AddWorkoutDialog> createState() => _AddWorkoutDialogState();
}

class _AddWorkoutDialogState extends State<AddWorkoutDialog> {
  String? selectedWorkout;
  int duration = 30;
  String selectedType = 'cardio';
  String selectedIntensity = 'medium';
  bool useCustomWorkout = false;
  
  final _nameController = TextEditingController();

  final List<String> types = ['cardio', 'strength', 'flexibility', 'sports'];
  final List<String> intensities = ['low', 'medium', 'high'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Antrenman Ekle'),
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
                    groupValue: useCustomWorkout,
                    onChanged: (value) => setState(() => useCustomWorkout = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Manuel Gir'),
                    value: true,
                    groupValue: useCustomWorkout,
                    onChanged: (value) => setState(() => useCustomWorkout = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (!useCustomWorkout) ...[
              DropdownButtonFormField<String>(
                value: selectedWorkout,
                decoration: const InputDecoration(labelText: 'Egzersiz Seçin'),
                items: widget.predefinedWorkouts.keys
                    .map((workout) => DropdownMenuItem(value: workout, child: Text(workout)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedWorkout = value;
                    if (value != null) {
                      final workoutData = widget.predefinedWorkouts[value]!;
                      selectedType = workoutData['type'];
                      selectedIntensity = workoutData['intensity'];
                    }
                  });
                },
              ),
            ] else ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Egzersiz Adı'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Tür'),
                items: types.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                )).toList(),
                onChanged: (value) => setState(() => selectedType = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedIntensity,
                decoration: const InputDecoration(labelText: 'Yoğunluk'),
                items: intensities.map((intensity) => DropdownMenuItem(
                  value: intensity,
                  child: Text(intensity.toUpperCase()),
                )).toList(),
                onChanged: (value) => setState(() => selectedIntensity = value!),
              ),
            ],
            
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Süre: '),
                Expanded(
                  child: Slider(
                    value: duration.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '${duration} dk',
                    onChanged: (value) => setState(() => duration = value.toInt()),
                  ),
                ),
                Text('${duration} dk'),
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
          onPressed: _addWorkout,
          child: const Text('Ekle'),
        ),
      ],
    );
  }

  void _addWorkout() {
    String workoutName;
    
    if (!useCustomWorkout && selectedWorkout != null) {
      workoutName = selectedWorkout!;
    } else if (useCustomWorkout && _nameController.text.isNotEmpty) {
      workoutName = _nameController.text;
    } else {
      return;
    }
    
    widget.onAddWorkout(
      workoutName,
      selectedType,
      duration,
      selectedIntensity,
    );
    
    Navigator.pop(context);
  }
}
