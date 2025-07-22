import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

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
  // --- TEMA RENKLERİ ---
  final Color primaryColor = const Color(0xFF005F73); 
  final Color secondaryColor = const Color(0xFF0A9396); 
  final Color successColor = const Color(0xFF2D9A6C);
  final Color backgroundColor = const Color(0xFFF0FAFA);

  // --- Durum Değişkenleri ---
  double dailyWaterIntake = 0;
  double dailyGoal = 2500;
  List<WaterEntry> todayEntries = [];
  List<double> weeklyData = List.filled(7, 0);
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  Future<void> _loadWaterData() async {
    // Web platformu SharedPreferences'i desteklemediği için
    // ve sensör gerektirmediği için bu kontrol kalabilir.
    if (kIsWeb) {
      setState(() => isLoading = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    final lastDateString = prefs.getString('water_last_date');
    if (lastDateString != todayString) {
      dailyWaterIntake = 0;
      todayEntries.clear();
      await prefs.setDouble('water_$todayString', 0);
      await prefs.setStringList('water_entries_$todayString', []);
    } else {
      dailyWaterIntake = prefs.getDouble('water_$todayString') ?? 0;
      final entriesJson = prefs.getStringList('water_entries_$todayString') ?? [];
      todayEntries = entriesJson.map((e) => WaterEntry.fromJson(e)).toList();
    }
    
    dailyGoal = prefs.getDouble('water_goal') ?? 2500;
    
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month}-${date.day}';
      weeklyData[6 - i] = prefs.getDouble('water_$dateString') ?? 0;
    }
    
    if(mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveWaterData() async {
    if (kIsWeb) return; 
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    await prefs.setDouble('water_$todayString', dailyWaterIntake);
    await prefs.setDouble('water_goal', dailyGoal);
    await prefs.setString('water_last_date', todayString);
    
    final entriesJson = todayEntries.map((e) => e.toJson()).toList();
    await prefs.setStringList('water_entries_$todayString', entriesJson);
    
    final dayIndex = today.weekday - 1;
    setState(() {
      weeklyData[dayIndex] = dailyWaterIntake;
    });
  }

  void _addWater(double amount, String type, IconData icon) {
    setState(() {
      dailyWaterIntake += amount;
      todayEntries.add(WaterEntry(amount: amount, type: type, time: DateTime.now(), icon: icon));
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(backgroundColor: backgroundColor, body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }
    
    // Su takibi için fiziksel aktivite izni GEREKMEZ. Sadece web kontrolü yeterli.
    if (kIsWeb) {
      return _buildWebNotSupportedScreen();
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Su Takibi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            _buildWaterProgress(),
            const SizedBox(height: 24),
            _buildQuickAddButtons(),
            const SizedBox(height: 24),
            _buildTodayEntries(),
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
  
  Widget _buildWebNotSupportedScreen() {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Su Takibi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        foregroundColor: primaryColor,
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
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200),
                child: Icon(Icons.web_asset_off_outlined, size: 48, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              const Text('Webde Desteklenmiyor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Bu özellik, verileri cihaza kaydettiği için yalnızca mobil platformlarda kullanılabilir.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterProgress() {
    final progress = (dailyGoal > 0) ? (dailyWaterIntake / dailyGoal).clamp(0.0, 1.0) : 0.0;
    final goalReached = progress >= 1.0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor.withOpacity(0.05))),
                ClipPath(
                  clipper: _WaveClipper(progress: progress),
                  child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: goalReached ? successColor : secondaryColor)),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${dailyWaterIntake.toInt()}', style: TextStyle(color: primaryColor, fontSize: 42, fontWeight: FontWeight.bold)),
                    Text('ml', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Hedef: ${dailyGoal.toInt()} ml', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 12),
          if (goalReached)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: successColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: successColor),
                  const SizedBox(width: 8),
                  Text('Hedef tamamlandı! 💧', style: TextStyle(color: successColor, fontWeight: FontWeight.bold)),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildQuickAddButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(left: 4.0, bottom: 12.0), child: Text('Hızlı Ekle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickButton('Bardak', 200, Icons.local_drink_rounded),
            _buildQuickButton('Kupa', 350, Icons.coffee_rounded),
            _buildQuickButton('Şişe', 500, Icons.wine_bar_rounded),
            IconButton(
              onPressed: todayEntries.isNotEmpty ? _removeLastEntry : null,
              icon: Icon(Icons.undo_rounded, color: Colors.grey.shade500),
              tooltip: 'Son Girişi Geri Al',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickButton(String type, double amount, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _addWater(amount, type, icon),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Icon(icon, color: primaryColor, size: 28),
              const SizedBox(height: 8),
              Text('${amount.toInt()}ml', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayEntries() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bugünün Tüketimi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (todayEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: Text('Bugün henüz su içmedin.', style: TextStyle(color: Colors.grey.shade500))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayEntries.length,
              itemBuilder: (context, index) {
                final entry = todayEntries.reversed.toList()[index];
                return ListTile(
                  leading: Icon(entry.icon, color: secondaryColor),
                  title: Text('${entry.amount.toInt()} ml ${entry.type}'),
                  subtitle: Text('${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}'),
                  contentPadding: EdgeInsets.zero,
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Haftalık Özet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: (dailyGoal * 1.25),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem('${rod.toY.toInt()} ml', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                  }),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                    const days = ['PZT', 'SAL', 'ÇAR', 'PER', 'CUM', 'CMT', 'PAZ'];
                    // DÜZELTME: Haftanın günlerini doğru göstermek için
                    final today = DateTime.now();
                    final dayOfWeek = today.subtract(Duration(days: 6 - value.toInt())).weekday;
                    return SideTitleWidget(axisSide: meta.axisSide, child: Text(days[dayOfWeek - 1], style: const TextStyle(fontSize: 10)));
                  })),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: weeklyData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        width: 18,
                        borderRadius: const BorderRadius.all(Radius.circular(6)),
                        gradient: LinearGradient(
                          colors: entry.value >= dailyGoal
                            ? [successColor.withOpacity(0.8), successColor]
                            : [secondaryColor.withOpacity(0.8), primaryColor],
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
                  value: dailyGoal,
                  min: 1000,
                  max: 5000,
                  divisions: 40,
                  label: '${dailyGoal.toInt()} ml',
                  activeColor: primaryColor,
                  inactiveColor: primaryColor.withOpacity(0.2),
                  onChanged: (value) => setState(() => dailyGoal = value.roundToDouble()),
                  onChangeEnd: (value) => _saveWaterData(),
                ),
              ),
              Text('${(dailyGoal / 1000).toStringAsFixed(1)}L', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}