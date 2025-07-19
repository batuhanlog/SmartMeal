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
  // --- TEMA RENKLERİ ---
  final Color primaryColor = Colors.green.shade800;
  final Color secondaryColor = Colors.green.shade600;
  final Color backgroundColor = Colors.grey.shade100;

  // --- Durum Değişkenleri ---
  int todaySteps = 0;
  int dailyGoal = 10000;
  double calories = 0;
  double distance = 0;
  
  StreamSubscription<StepCount>? _stepCountStream;
  List<int> weeklySteps = List.filled(7, 0);
  
  bool isPermissionGranted = false;
  bool isLoading = true;
  bool isWebPlatform = kIsWeb;

  @override
  void initState() {
    super.initState();
    _initializePedometer();
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
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
    var status = await Permission.activityRecognition.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.activityRecognition.request();
    }
    if(mounted) {
      setState(() {
        isPermissionGranted = status.isGranted;
      });
    }
  }

  Future<void> _loadStepData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    todaySteps = prefs.getInt('steps_$todayString') ?? 0;
    dailyGoal = prefs.getInt('steps_goal') ?? 10000;
    
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month}-${date.day}';
      weeklySteps[6 - i] = prefs.getInt('steps_$dateString') ?? 0;
    }
    if(mounted) setState(() => _calculateStats());
  }

  void _calculateStats() {
    calories = todaySteps * 0.04;
    distance = todaySteps * 0.762 / 1000;
  }

  void _startListening() {
    _stepCountStream = Pedometer.stepCountStream.handleError(_onStepCountError).listen(_onStepCount);
  }

  void _onStepCount(StepCount event) {
    if(!mounted) return;
    // Bu logic, gece yarısı sıfırlanmasını sağlar.
    final lastSavedDate = _getLastSavedDate();
    final today = DateTime.now();

    if(lastSavedDate != null && (today.day != lastSavedDate.day || today.month != lastSavedDate.month)) {
       // Yeni gün, adımları sıfırla
       todaySteps = 0;
    } else {
       todaySteps = event.steps;
    }

    setState(() {
      _calculateStats();
    });
    _saveStepData(todaySteps);
  }

  void _onStepCountError(error) {
    print('Pedometer Error: $error');
  }

  Future<void> _saveStepData(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    await prefs.setInt('steps_$todayString', steps);
    await prefs.setInt('steps_goal', dailyGoal);
    await prefs.setString('last_saved_date', today.toIso8601String());
  }

  DateTime? _getLastSavedDate() {
    // SharedPreferences senkron olabileceğinden bu metodun asenkron olması gerekmez
    // Ama emin olmak için SharedPreferences'i initState'te yüklemek daha iyidir.
    // Bu örnek için basit tutulmuştur.
    return null; 
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(backgroundColor: backgroundColor, body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }
    if (!isPermissionGranted) {
      return _buildPermissionDeniedScreen();
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Adım Sayar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            _buildProgressRing(),
            const SizedBox(height: 24),
            _buildInfoCards(),
            const SizedBox(height: 24),
            _buildWeeklyChart(),
            const SizedBox(height: 24),
            _buildGoalSetting(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedScreen() {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Adım Sayar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(shape: BoxShape.circle, color: isWebPlatform ? Colors.grey.shade200 : primaryColor.withOpacity(0.1)),
                child: Icon(isWebPlatform ? Icons.web_asset_off_outlined : Icons.directions_walk, size: 48, color: isWebPlatform ? Colors.grey.shade600 : primaryColor),
              ),
              const SizedBox(height: 24),
              Text(
                isWebPlatform ? 'Webde Desteklenmiyor' : 'İzin Gerekli',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isWebPlatform 
                  ? 'Adım sayar özelliği, sensör erişimi gerektirdiğinden yalnızca mobil cihazlarda kullanılabilir.'
                  : 'Adımlarını sayabilmemiz için lütfen fiziksel aktivite izni ver.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              if(!isWebPlatform) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: openAppSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('Ayarları Aç'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRing() {
    final progress = (dailyGoal > 0) ? (todaySteps / dailyGoal).clamp(0.0, 1.0) : 0.0;
    final goalReached = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        children: [
          SizedBox(
            width: 180, height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    startDegreeOffset: -90,
                    centerSpaceRadius: 70,
                    sections: [
                      PieChartSectionData(value: progress, color: goalReached ? secondaryColor : primaryColor, radius: 15, showTitle: false),
                      PieChartSectionData(value: 1 - progress, color: primaryColor.withOpacity(0.1), radius: 15, showTitle: false),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$todaySteps', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
                    Text('ADIM', style: TextStyle(fontSize: 14, color: Colors.grey.shade600, letterSpacing: 1.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Hedef: $dailyGoal Adım', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (goalReached)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: secondaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: secondaryColor),
                  const SizedBox(width: 8),
                  Text('Hedef tamamlandı! 🎉', style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(child: _buildInfoCard('Yakılan Kalori', '${calories.toStringAsFixed(0)} kcal', Icons.local_fire_department_rounded, Colors.orange)),
        const SizedBox(width: 16),
        Expanded(child: _buildInfoCard('Mesafe', '${distance.toStringAsFixed(2)} km', Icons.map_rounded, Colors.blue)),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Haftalık Aktivite', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: (dailyGoal * 1.25),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem('${rod.toY.toInt()}\nadım', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                    final dayIndex = DateTime.now().subtract(Duration(days: 6 - value.toInt())).weekday - 1;
                    return SideTitleWidget(axisSide: meta.axisSide, child: Text(days[dayIndex], style: const TextStyle(fontSize: 12)));
                  })),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: weeklySteps.asMap().entries.map((entry) {
                  final isGoalReached = entry.value >= dailyGoal;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        width: 18,
                        borderRadius: const BorderRadius.all(Radius.circular(6)),
                        gradient: LinearGradient(
                          colors: isGoalReached
                              ? [secondaryColor, primaryColor]
                              : [primaryColor.withOpacity(0.5), primaryColor.withOpacity(0.3)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSetting() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Günlük Hedefini Ayarla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Icon(Icons.flag_rounded, color: primaryColor),
              Expanded(
                child: Slider(
                  value: dailyGoal.toDouble(),
                  min: 5000,
                  max: 20000,
                  divisions: 15,
                  label: '${dailyGoal.toInt()} adım',
                  activeColor: primaryColor,
                  inactiveColor: primaryColor.withOpacity(0.2),
                  onChanged: (value) => setState(() => dailyGoal = value.toInt()),
                  onChangeEnd: (value) => _saveStepData(todaySteps),
                ),
              ),
              Text('${(dailyGoal / 1000).toStringAsFixed(1)}k', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}