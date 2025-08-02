import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

class WaterEntry {
  final double amount;
  final String type;
  final DateTime time;
  final IconData icon;

  WaterEntry({required this.amount, required this.type, required this.time, required this.icon});
  
  String toJson() => json.encode({
    'amount': amount, 
    'type': type, 
    'time': time.toIso8601String(),
    'icon': icon.codePoint,
    'fontFamily': icon.fontFamily,
  });

  static WaterEntry fromJson(String jsonString) {
    final map = json.decode(jsonString);
    return WaterEntry(
      amount: map['amount'],
      type: map['type'],
      time: DateTime.parse(map['time']),
      icon: IconData(map['icon'] ?? Icons.water_drop_outlined.codePoint, fontFamily: map['fontFamily'] ?? 'MaterialIcons'),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  final double progress;

  _WaveClipper({required this.progress});

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.addOval(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2));
    
    double waveHeight = size.height * (1 - progress);
    
    Path clipPath = Path();
    clipPath.moveTo(0, waveHeight);
    
    clipPath.quadraticBezierTo(size.width / 4, waveHeight - 20, size.width / 2, waveHeight);
    clipPath.quadraticBezierTo(size.width * 3 / 4, waveHeight + 20, size.width, waveHeight);
    
    clipPath.lineTo(size.width, size.height);
    clipPath.lineTo(0, size.height);
    clipPath.close();

    return Path.combine(PathOperation.intersect, path, clipPath);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

// Ana Widget
class WaterTrackingPage extends StatefulWidget {
  const WaterTrackingPage({super.key});

  @override
  State<WaterTrackingPage> createState() => _WaterTrackingPageState();
}

class _WaterTrackingPageState extends State<WaterTrackingPage> {
  final Color primaryColor = const Color(0xFF005F73); 
  final Color secondaryColor = const Color(0xFF0A9396); 
  final Color successColor = Colors.green.shade600; 
  final Color backgroundColor = Colors.grey.shade100;

  double dailyWaterIntake = 0;
  double dailyGoal = 2500;
  List<WaterEntry> todayEntries = [];
  List<double> weeklyData = List.filled(7, 0);

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
    
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month}-${date.day}';
      weeklyData[6 - i] = prefs.getDouble('water_$dateString') ?? 0;
    }
    
    await _loadTodayEntries();
    setState(() {});
  }

  Future<void> _loadTodayEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    final entriesJson = prefs.getStringList('water_entries_$todayString') ?? [];
    
    todayEntries = entriesJson.map((e) => WaterEntry.fromJson(e)).toList();
  }

  Future<void> _saveWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    await prefs.setDouble('water_$todayString', dailyWaterIntake);
    await prefs.setDouble('water_goal', dailyGoal);
    
    final entriesJson = todayEntries.map((e) => e.toJson()).toList();
    await prefs.setStringList('water_entries_$todayString', entriesJson);
  }

  void _addWater(double amount, String type) {
    setState(() {
      dailyWaterIntake += amount;
      todayEntries.add(WaterEntry(amount: amount, type: type, time: DateTime.now(), icon: Icons.water_drop));
    });
    _saveWaterData();
  }

  void _removeLastEntry() {
    if (todayEntries.isNotEmpty) {
      setState(() {
        final lastEntry = todayEntries.removeLast();
        dailyWaterIntake -= lastEntry.amount;
        if (dailyWaterIntake < 0) dailyWaterIntake = 0;
      });
      _saveWaterData();
    }
  }

  void _deleteEntryAtIndex(int index) {
     if (todayEntries.length > index) {
      setState(() {
        final entry = todayEntries.removeAt(index);
        dailyWaterIntake -= entry.amount;
        if (dailyWaterIntake < 0) dailyWaterIntake = 0;
      });
      _saveWaterData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercentage = (dailyGoal > 0) ? (dailyWaterIntake / dailyGoal).clamp(0.0, 1.0) : 0.0;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Su Takibi'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressCard(progressPercentage),
            const SizedBox(height: 20),
            _buildQuickAddButtons(),
            const SizedBox(height: 20),
            _buildTodayEntries(),
            const SizedBox(height: 20),
            _buildWeeklyChart(),
            const SizedBox(height: 20),
            _buildGoalSetting(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(double progress) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          // --- 1. DÜZELTME: Hizalama "stretch" yapıldı ---
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Günlük Su Tüketimi',
              // --- 2. DÜZELTME: Metin ortalandı ---
              textAlign: TextAlign.center,
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
                    valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? successColor : secondaryColor),
                  ),
                ),
                Column(
                  children: [
                    Text('${(dailyWaterIntake / 1000).toStringAsFixed(1)}L', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    Text(' / ${(dailyGoal / 1000).toStringAsFixed(1)}L Hedef', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text('%${(progress * 100).toInt()}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: progress >= 1.0 ? successColor : secondaryColor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (progress >= 1.0)
              Align( // Bu widget'ı Align ile sarmalayarak ortalıyoruz
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: successColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: successColor),
                      const SizedBox(width: 8),
                      Text('Günlük hedef tamamlandı! 🎉', style: TextStyle(color: successColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddButtons() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hızlı Ekle', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickButton('💧 200ml', 200, 'Bardak'),
                _buildQuickButton('🥤 250ml', 250, 'Kupa'),
                _buildQuickButton('🍶 500ml', 500, 'Şişe'),
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
            backgroundColor: secondaryColor.withOpacity(0.15),
            foregroundColor: primaryColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _buildUndoButton() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          onPressed: todayEntries.isNotEmpty ? _removeLastEntry : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('↶ Geri Al', style: TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ),
      ),
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
            Text('Bugünün Girişleri', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (todayEntries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: Text('Henüz su tüketimi kaydedilmemiş.', style: TextStyle(color: Colors.grey))),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todayEntries.length,
                itemBuilder: (context, index) {
                  final entry = todayEntries.reversed.toList()[index];
                  return ListTile(
                    leading: Icon(Icons.water_drop_outlined, color: secondaryColor),
                    title: Text('${entry.amount.toInt()}ml ${entry.type}'),
                    subtitle: Text('${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                      onPressed: () => _deleteEntryAtIndex(todayEntries.length - 1 - index),
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
            Text('Haftalık Tüketim Grafiği', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: dailyGoal,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                      final today = DateTime.now();
                      final day = today.subtract(Duration(days: 6 - value.toInt()));
                      const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                      return Text(days[day.weekday - 1]);
                    })),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text('${(value / 1000).toStringAsFixed(1)}L'))),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                  borderData: FlBorderData(show: false),
                  barGroups: weeklyData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: entry.value >= dailyGoal ? successColor : secondaryColor,
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Günlük Hedefini Ayarla', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: dailyGoal,
                    min: 1000,
                    max: 5000,
                    divisions: 40,
                    label: '${(dailyGoal / 1000).toStringAsFixed(1)}L',
                    activeColor: primaryColor,
                    onChanged: (value) => setState(() => dailyGoal = value),
                    onChangeEnd: (value) => _saveWaterData(),
                  ),
                ),
                Text('${(dailyGoal / 1000).toStringAsFixed(1)}L', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}