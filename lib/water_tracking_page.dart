import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class WaterTrackingPage extends StatefulWidget {
  const WaterTrackingPage({super.key});

  @override
  State<WaterTrackingPage> createState() => _WaterTrackingPageState();
}

class _WaterTrackingPageState extends State<WaterTrackingPage> {
  double dailyWaterIntake = 0;
  double dailyGoal = 2500; // ml
  List<WaterEntry> todayEntries = [];
  List<double> weeklyData = [0, 0, 0, 0, 0, 0, 0]; // Son 7 gün

  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  Future<void> _loadWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    setState(() {
      dailyWaterIntake = prefs.getDouble('water_$todayString') ?? 0;
      dailyGoal = prefs.getDouble('water_goal') ?? 2500;
    });
    
    // Haftalık verileri yükle
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month}-${date.day}';
      weeklyData[6 - i] = prefs.getDouble('water_$dateString') ?? 0;
    }
    
    _loadTodayEntries();
  }

  Future<void> _loadTodayEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    final entriesJson = prefs.getStringList('water_entries_$todayString') ?? [];
    
    setState(() {
      todayEntries = entriesJson.map((e) => WaterEntry.fromJson(e)).toList();
    });
  }

  Future<void> _saveWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    await prefs.setDouble('water_$todayString', dailyWaterIntake);
    await prefs.setDouble('water_goal', dailyGoal);
    
    // Bugünün girişlerini kaydet
    final entriesJson = todayEntries.map((e) => e.toJson()).toList();
    await prefs.setStringList('water_entries_$todayString', entriesJson);
  }

  void _addWater(double amount, String type) {
    setState(() {
      dailyWaterIntake += amount;
      todayEntries.add(WaterEntry(
        amount: amount,
        type: type,
        time: DateTime.now(),
      ));
    });
    _saveWaterData();
  }

  void _removeLastEntry() {
    if (todayEntries.isNotEmpty) {
      setState(() {
        final lastEntry = todayEntries.removeLast();
        dailyWaterIntake -= lastEntry.amount;
      });
      _saveWaterData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercentage = (dailyWaterIntake / dailyGoal).clamp(0.0, 1.0);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('💧 Su Takibi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Günlük Progress
            _buildProgressCard(progressPercentage),
            const SizedBox(height: 20),
            
            // Hızlı Ekleme Butonları
            _buildQuickAddButtons(),
            const SizedBox(height: 20),
            
            // Bugünün Girişleri
            _buildTodayEntries(),
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

  Widget _buildProgressCard(double progress) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Günlük Su Tüketimi',
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
                      progress >= 1.0 ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${(dailyWaterIntake / 1000).toStringAsFixed(1)}L',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(dailyGoal / 1000).toStringAsFixed(1)}L hedef',
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
                        color: progress >= 1.0 ? Colors.green : Colors.blue,
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
                    Text('Günlük hedef tamamlandı! 🎉'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hızlı Ekleme',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickButton('💧 200ml', 200, '200ml'),
                _buildQuickButton('🥤 250ml', 250, '250ml'),
                _buildQuickButton('🍶 500ml', 500, '500ml'),
                _buildQuickButton('🍶 1L', 1000, '1L'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickButton('☕ Çay', 200, 'Çay'),
                _buildQuickButton('☕ Kahve', 150, 'Kahve'),
                _buildQuickButton('🥤 Meyve Suyu', 250, 'Meyve Suyu'),
                _buildUndoButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton(String label, double amount, String type) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => _addWater(amount, type),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade100,
            foregroundColor: Colors.blue.shade800,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildUndoButton() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: todayEntries.isNotEmpty ? _removeLastEntry : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade100,
            foregroundColor: Colors.red.shade800,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text(
            '↶ Geri Al',
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildTodayEntries() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bugünün Girişleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (todayEntries.isEmpty)
              const Text(
                'Henüz su tüketimi kaydedilmemiş.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todayEntries.length,
                itemBuilder: (context, index) {
                  final entry = todayEntries[index];
                  return ListTile(
                    leading: const Icon(Icons.water_drop, color: Colors.blue),
                    title: Text('${entry.amount.toInt()}ml ${entry.type}'),
                    subtitle: Text(
                      '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          dailyWaterIntake -= entry.amount;
                          todayEntries.removeAt(index);
                        });
                        _saveWaterData();
                      },
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Haftalık Tüketim',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: dailyGoal,
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
                          return Text('${(value / 1000).toStringAsFixed(1)}L');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: weeklyData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: entry.value >= dailyGoal ? Colors.green : Colors.blue,
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
                    value: dailyGoal,
                    min: 1000,
                    max: 5000,
                    divisions: 40,
                    label: '${(dailyGoal / 1000).toStringAsFixed(1)}L',
                    onChanged: (value) {
                      setState(() {
                        dailyGoal = value;
                      });
                    },
                    onChangeEnd: (value) {
                      _saveWaterData();
                    },
                  ),
                ),
                Text(
                  '${(dailyGoal / 1000).toStringAsFixed(1)}L',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Yaş, kilo ve aktivite seviyenize göre günlük 2-3 litre su tüketimi önerilir.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class WaterEntry {
  final double amount;
  final String type;
  final DateTime time;

  WaterEntry({
    required this.amount,
    required this.type,
    required this.time,
  });

  String toJson() {
    return '${amount.toString()},${type},${'${time.year}-${time.month}-${time.day}-${time.hour}-${time.minute}'}';
  }

  static WaterEntry fromJson(String json) {
    final parts = json.split(',');
    final timeParts = parts[2].split('-');
    return WaterEntry(
      amount: double.parse(parts[0]),
      type: parts[1],
      time: DateTime(
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
        int.parse(timeParts[3]),
        int.parse(timeParts[4]),
      ),
    );
  }
}
