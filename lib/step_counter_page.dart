import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class StepCounterPage extends StatefulWidget {
  const StepCounterPage({super.key});

  @override
  State<StepCounterPage> createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> {
  // --- YENİ RENK PALETİ ---
  final Color primaryColor = Colors.green.shade800;
  final Color secondaryColor = Colors.green.shade600;
  final Color backgroundColor = Colors.grey.shade100;

  int todaySteps = 0;
  int dailyGoal = 10000;
  double calories = 0;
  double distance = 0;
  String status = 'Durdu';
  
  StreamSubscription<StepCount>? _stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;
  
  List<int> weeklySteps = List.filled(7, 0);
  
  bool isPermissionGranted = false;
  bool isLoading = true;
  bool isWebPlatform = kIsWeb;

  @override
  void initState() {
    super.initState();
    _initializePedometer();
  }
  
  // Fonksiyonların geri kalanı aynı, sadece build metodları ve içindeki renkler güncellendi.

  @override
  void dispose() {
    _stepCountStream?.cancel();
    _pedestrianStatusStream?.cancel();
    super.dispose();
  }

  Future<void> _initializePedometer() async {
    if (isWebPlatform) {
      setState(() { isLoading = false; isPermissionGranted = false; });
      return;
    }
    await _checkPermissions();
    if (isPermissionGranted) {
      await _loadStepData();
      _startListening();
    }
    setState(() => isLoading = false);
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.activityRecognition.status;
    if (status.isDenied) {
      final result = await Permission.activityRecognition.request();
      isPermissionGranted = result.isGranted;
    } else {
      isPermissionGranted = status.isGranted;
    }
  }

  Future<void> _loadStepData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    setState(() {
      todaySteps = prefs.getInt('steps_$todayString') ?? 0;
      dailyGoal = prefs.getInt('steps_goal') ?? 10000;
    });
    
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month}-${date.day}';
      weeklySteps[6 - i] = prefs.getInt('steps_$dateString') ?? 0;
    }
    _calculateStats();
  }

  void _calculateStats() {
    calories = todaySteps * 0.04;
    distance = todaySteps * 0.75 / 1000;
  }

  void _startListening() {
    _stepCountStream = Pedometer.stepCountStream.listen(_onStepCount, onError: _onStepCountError);
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream.listen(_onPedestrianStatusChanged, onError: _onPedestrianStatusError);
  }

  void _onStepCount(StepCount event) {
    setState(() {
      todaySteps = event.steps;
      _calculateStats();
    });
    _saveStepData();
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) => setState(() => status = event.status);
  void _onStepCountError(error) => print('Step Count Error: $error');
  void _onPedestrianStatusError(error) => print('Pedestrian Status Error: $error');

  Future<void> _saveStepData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    await prefs.setInt('steps_$todayString', todaySteps);
    await prefs.setInt('steps_goal', dailyGoal);
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (!isPermissionGranted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Adım Sayar'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isWebPlatform ? Icons.web_asset_off_outlined : Icons.directions_walk, 
                  size: 64, 
                  color: isWebPlatform ? Colors.grey.shade500 : Colors.orange.shade700,
                ),
                const SizedBox(height: 16),
                Text(
                  isWebPlatform ? 'Web Platformunda Desteklenmiyor' : 'Aktivite İzni Gerekli',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isWebPlatform 
                    ? 'Adım sayar özelliği yalnızca mobil cihazlarda kullanılabilir.'
                    : 'Adım sayar özelliğini kullanmak için lütfen telefonunuzun ayarlarından fiziksel aktivite iznini verin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final progressPercentage = (dailyGoal > 0) ? (todaySteps / dailyGoal).clamp(0.0, 1.0) : 0.0;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Adım Sayar'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepProgressCard(progressPercentage),
            const SizedBox(height: 20),
            _buildStatsCards(),
            const SizedBox(height: 20),
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildWeeklyChart(),
            const SizedBox(height: 20),
            _buildGoalSetting(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepProgressCard(double progress) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Bugünün Adımları', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
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
                    valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? secondaryColor : primaryColor),
                  ),
                ),
                Column(
                  children: [
                    Text('$todaySteps', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    Text('Hedef: $dailyGoal', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text('%${(progress * 100).toInt()}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: progress >= 1.0 ? secondaryColor : primaryColor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (progress >= 1.0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: secondaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: secondaryColor),
                    const SizedBox(width: 8),
                    Text('Günlük hedef başarıldı! 🎉', style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 32),
                  const SizedBox(height: 8),
                  Text('${calories.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Yakılan Kalori', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.straighten, color: Colors.teal.shade600, size: 32),
                  const SizedBox(height: 8),
                  Text('${distance.toStringAsFixed(2)} km', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Mesafe', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'walking':
        statusText = 'Yürüyor';
        statusColor = secondaryColor;
        statusIcon = Icons.directions_walk;
        break;
      case 'stopped':
        statusText = 'Duruyor';
        statusColor = Colors.grey.shade600;
        statusIcon = Icons.accessibility_new;
        break;
      default:
        statusText = 'Bilinmiyor';
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.help_outline;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Text(statusText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor)),
              ],
            ),
            const Divider(height: 24),
            Text(_getMotivationMessage(), style: TextStyle(fontSize: 14, color: Colors.grey.shade700), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _getMotivationMessage() {
    if (isPermissionGranted == false) return "Adım sayar için lütfen aktivite izni verin.";
    final progress = todaySteps / dailyGoal;
    if (progress >= 1.0) return '🎉 Harika! Bugünkü hedefinizi tamamladınız. Sağlıklı yaşam için böyle devam edin!';
    if (progress >= 0.8) return '💪 Neredeyse hedefe ulaştınız! Sadece ${dailyGoal - todaySteps} adım kaldı.';
    if (progress >= 0.5) return '🚶‍♂️ Güzel gidiyorsunuz! Hedefinizin yarısını geçtiniz.';
    if (progress >= 0.2) return '⭐ İyi bir başlangıç! Hareket etmeye devam edin.';
    return '🌟 Gün daha yeni başlıyor! Hedefinize ulaşmak için harekete geçin.';
  }

  Widget _buildWeeklyChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Haftalık Adım Grafiği', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: dailyGoal * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                       final today = DateTime.now();
                      final day = today.subtract(Duration(days: 6 - value.toInt()));
                      const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                      return Text(days[day.weekday - 1]);
                    })),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (value, meta) {
                      if (value >= 1000) return Text('${(value / 1000).toStringAsFixed(0)}k');
                      return Text('${value.toInt()}');
                    })),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                  borderData: FlBorderData(show: false),
                  barGroups: weeklySteps.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: entry.value >= dailyGoal ? secondaryColor : primaryColor.withOpacity(0.5),
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

  Widget _buildGoalSetting() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Günlük Adım Hedefi', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: dailyGoal.toDouble(),
                    min: 5000,
                    max: 20000,
                    divisions: 30,
                    label: '$dailyGoal adım',
                    activeColor: primaryColor,
                    onChanged: (value) => setState(() => dailyGoal = value.toInt()),
                    onChangeEnd: (value) => _saveStepData(),
                  ),
                ),
                Text('$dailyGoal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}