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
  int todaySteps = 0;
  int dailyGoal = 10000;
  double calories = 0;
  double distance = 0;
  String status = 'Durdu';
  
  StreamSubscription<StepCount>? _stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;
  
  List<int> weeklySteps = [0, 0, 0, 0, 0, 0, 0]; // Son 7 gün
  List<StepSession> todaySessions = [];
  
  bool isPermissionGranted = false;
  bool isLoading = true;
  bool isWebPlatform = kIsWeb;

  @override
  void initState() {
    super.initState();
    _initializePedometer();
  }

  Future<void> _initializePedometer() async {
    // Web platformunda adım sayar desteklenmiyor
    if (isWebPlatform) {
      setState(() {
        isLoading = false;
        isPermissionGranted = false;
      });
      return;
    }
    
    await _checkPermissions();
    if (isPermissionGranted) {
      await _loadStepData();
      _startListening();
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _checkPermissions() async {
    try {
      final status = await Permission.activityRecognition.status;
      if (status.isDenied) {
        final result = await Permission.activityRecognition.request();
        isPermissionGranted = result.isGranted;
      } else {
        isPermissionGranted = status.isGranted;
      }
    } catch (e) {
      print('Permission check error: $e');
      isPermissionGranted = false;
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
    
    // Haftalık verileri yükle
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month}-${date.day}';
      weeklySteps[6 - i] = prefs.getInt('steps_$dateString') ?? 0;
    }
    
    _calculateStats();
  }

  void _calculateStats() {
    // Yaklaşık kalori hesaplama (kişi başına değişir)
    calories = todaySteps * 0.04; // Her adım için yaklaşık 0.04 kalori
    
    // Yaklaşık mesafe hesaplama (ortalama adım uzunluğu 0.75m)
    distance = todaySteps * 0.75 / 1000; // km cinsinden
  }

  void _startListening() {
    try {
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
      );

      _pedestrianStatusStream = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: _onPedestrianStatusError,
      );
    } catch (e) {
      print('Error starting pedometer: $e');
    }
  }

  void _onStepCount(StepCount event) {
    setState(() {
      todaySteps = event.steps;
      _calculateStats();
    });
    
    // Adım sayısını kaydet
    _saveStepData();
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    setState(() {
      status = event.status;
    });
  }

  void _onStepCountError(error) {
    print('Step Count Error: $error');
  }

  void _onPedestrianStatusError(error) {
    print('Pedestrian Status Error: $error');
  }

  Future<void> _saveStepData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    await prefs.setInt('steps_$todayString', todaySteps);
    await prefs.setInt('steps_goal', dailyGoal);
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    _pedestrianStatusStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isPermissionGranted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('👟 Adım Sayar'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isWebPlatform ? Icons.web : Icons.warning, 
                size: 64, 
                color: isWebPlatform ? Colors.blue : Colors.orange
              ),
              const SizedBox(height: 16),
              Text(
                isWebPlatform ? 'Web Platformunda Desteklenmiyor' : 'Aktivite İzni Gerekli',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isWebPlatform 
                  ? 'Adım sayar özelliği mobil cihazlarda çalışır. Lütfen Android veya iOS cihazınızdan deneyin.'
                  : 'Adım sayar özelliği için uygulama izinlerini kontrol edin.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              if (isWebPlatform) ...[
                const SizedBox(height: 32),
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Demo Veriler',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildDemoStats(),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final progressPercentage = (todaySteps / dailyGoal).clamp(0.0, 1.0);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('👟 Adım Sayar'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Günlük Progress
            _buildStepProgressCard(progressPercentage),
            const SizedBox(height: 20),
            
            // İstatistikler
            _buildStatsCards(),
            const SizedBox(height: 20),
            
            // Durum ve Motivasyon
            _buildStatusCard(),
            const SizedBox(height: 20),
            
            // Haftalık Grafik
            _buildWeeklyChart(),
            const SizedBox(height: 20),
            
            // Hedef Ayarlama
            _buildGoalSetting(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepProgressCard(double progress) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Bugünün Adımları',
              style: Theme.of(context).textTheme.headlineSmall,
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
                      progress >= 1.0 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$todaySteps',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Hedef: $dailyGoal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '%${(progress * 100).toInt()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: progress >= 1.0 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            if (progress >= 1.0)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Günlük hedef başarıldı! 🎉'),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.local_fire_department, 
                             color: Colors.red, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '${calories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Yakılan Kalori'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.straighten, 
                             color: Colors.blue, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '${distance.toStringAsFixed(2)} km',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Mesafe'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    String statusText = '';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.pause;

    switch (status) {
      case 'walking':
        statusText = 'Yürüyor';
        statusColor = Colors.green;
        statusIcon = Icons.directions_walk;
        break;
      case 'stopped':
        statusText = 'Durdu';
        statusColor = Colors.grey;
        statusIcon = Icons.pause;
        break;
      default:
        statusText = 'Bilinmiyor';
        statusColor = Colors.orange;
        statusIcon = Icons.help;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Motivasyon mesajı
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getMotivationMessage(),
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMotivationMessage() {
    final progress = todaySteps / dailyGoal;
    
    if (progress >= 1.0) {
      return '🎉 Harika! Bugünkü hedefinizi tamamladınız. Sağlıklı yaşam için böyle devam edin!';
    } else if (progress >= 0.8) {
      return '💪 Neredeyse hedefe ulaştınız! Sadece ${dailyGoal - todaySteps} adım kaldı.';
    } else if (progress >= 0.5) {
      return '🚶‍♂️ Güzel gidiyorsunuz! Hedefinizin yarısını geçtiniz.';
    } else if (progress >= 0.2) {
      return '⭐ İyi bir başlangıç! Hareket etmeye devam edin.';
    } else {
      return '🌟 Gün daha yeni başlıyor! Hedefinize ulaşmak için harekete geçin.';
    }
  }

  Widget _buildWeeklyChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Haftalık Adım Sayısı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: dailyGoal.toDouble() * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const days = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];
                          return Text(days[value.toInt() % 7]);
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value >= 1000) {
                            return Text('${(value / 1000).toStringAsFixed(0)}k');
                          }
                          return Text('${value.toInt()}');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: weeklySteps.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: entry.value >= dailyGoal ? Colors.green : Colors.orange,
                          width: 30,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
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
      ),
    );
  }

  Widget _buildGoalSetting() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Günlük Hedef',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: dailyGoal.toDouble(),
                    min: 5000,
                    max: 20000,
                    divisions: 30,
                    label: '$dailyGoal adım',
                    onChanged: (value) {
                      setState(() {
                        dailyGoal = value.toInt();
                      });
                    },
                    onChangeEnd: (value) {
                      _saveStepData();
                    },
                  ),
                ),
                Text(
                  '$dailyGoal',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Sağlık uzmanları günde 10,000 adım atmayı önerir.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoStats() {
    // Demo verileri
    final demoSteps = 7500;
    final demoCalories = 300;
    final demoDistance = 5.6;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDemoStat('👟', '$demoSteps', 'Adım'),
            _buildDemoStat('🔥', '$demoCalories', 'Kalori'),
            _buildDemoStat('📏', '${demoDistance}km', 'Mesafe'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Bu veriler yalnızca demo amaçlıdır. Gerçek adım sayımı için mobil cihaz kullanın.',
            style: TextStyle(fontSize: 12, color: Colors.blue),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildDemoStat(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class StepSession {
  final int steps;
  final DateTime startTime;
  final DateTime endTime;

  StepSession({
    required this.steps,
    required this.startTime,
    required this.endTime,
  });
}
