import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class DailyGoal {
  final String title;
  final String description;
  final String category;
  final bool isCompleted;
  final DateTime createdAt;
  final int points;

  DailyGoal({
    required this.title,
    required this.description,
    required this.category,
    required this.isCompleted,
    required this.createdAt,
    required this.points,
  });

  String toJson() => json.encode({
    'title': title,
    'description': description,
    'category': category,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'points': points,
  });

  static DailyGoal fromJson(String jsonString) {
    final map = json.decode(jsonString);
    return DailyGoal(
      title: map['title'],
      description: map['description'],
      category: map['category'],
      isCompleted: map['isCompleted'],
      createdAt: DateTime.parse(map['createdAt']),
      points: map['points'],
    );
  }

  DailyGoal copyWith({bool? isCompleted}) {
    return DailyGoal(
      title: title,
      description: description,
      category: category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      points: points,
    );
  }
}

class MotivationTrackerPage extends StatefulWidget {
  const MotivationTrackerPage({super.key});

  @override
  State<MotivationTrackerPage> createState() => _MotivationTrackerPageState();
}

class _MotivationTrackerPageState extends State<MotivationTrackerPage> {
  final Color primaryColor = const Color(0xFF6A4C93);
  final Color secondaryColor = const Color(0xFF9B59B6);
  final Color backgroundColor = Colors.grey.shade50;

  List<DailyGoal> todayGoals = [];
  List<String> motivationalQuotes = [];
  int totalPoints = 0;
  int weeklyPoints = 0;
  int streak = 0;
  String currentQuote = "";

  @override
  void initState() {
    super.initState();
    _initializeMotivationalQuotes();
    _loadGoalsData();
    _generateDailyGoals();
  }

  void _initializeMotivationalQuotes() {
    motivationalQuotes = [
      "🌟 Büyük değişiklikler küçük adımlarla başlar!",
      "💪 Her sağlıklı seçim, daha güçlü bir sen demek!",
      "🎯 Hedeflerine odaklan, sonuçlar gelecek!",
      "🌱 Bugün attığın her adım yarının temelini atar!",
      "⭐ Sen kendi hikayenin kahramanısın!",
      "🚀 Sınırların sadece zihninde var!",
      "🌸 Kendine iyi davranmak bir lüks değil, gereklilik!",
      "🔥 Motivasyonun bittiği yerde disiplin başlar!",
      "🌈 Her gün yeni bir fırsat, yeni bir başlangıç!",
      "💎 Değerini bil, potansiyelini keşfet!",
    ];
    
    final random = Random();
    currentQuote = motivationalQuotes[random.nextInt(motivationalQuotes.length)];
  }

  Future<void> _loadGoalsData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    // Bugünün hedeflerini yükle
    final goalsJson = prefs.getStringList('daily_goals_$todayString') ?? [];
    todayGoals = goalsJson.map((e) => DailyGoal.fromJson(e)).toList();
    
    // Toplam puanları hesapla
    totalPoints = prefs.getInt('total_points') ?? 0;
    weeklyPoints = prefs.getInt('weekly_points') ?? 0;
    streak = prefs.getInt('streak') ?? 0;
    
    setState(() {});
  }

  Future<void> _saveGoalsData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    final goalsJson = todayGoals.map((e) => e.toJson()).toList();
    await prefs.setStringList('daily_goals_$todayString', goalsJson);
    
    await prefs.setInt('total_points', totalPoints);
    await prefs.setInt('weekly_points', weeklyPoints);
    await prefs.setInt('streak', streak);
  }

  void _generateDailyGoals() {
    if (todayGoals.isNotEmpty) return; // Zaten bugün için hedefler var
    
    final goalTemplates = [
      DailyGoal(
        title: "8 Bardak Su İç",
        description: "Günde en az 2 litre su tüket",
        category: "Sağlık",
        isCompleted: false,
        createdAt: DateTime.now(),
        points: 10,
      ),
      DailyGoal(
        title: "30 Dakika Yürüyüş",
        description: "Aktif kalabilmek için günlük yürüyüş yap",
        category: "Spor",
        isCompleted: false,
        createdAt: DateTime.now(),
        points: 15,
      ),
      DailyGoal(
        title: "Sebze Ağırlıklı Öğün",
        description: "En az bir öğünde sebze ağırlıklı beslen",
        category: "Beslenme",
        isCompleted: false,
        createdAt: DateTime.now(),
        points: 12,
      ),
      DailyGoal(
        title: "Meditasyon/Nefes Egzersizi",
        description: "5 dakika kendine zaman ayır",
        category: "Mental",
        isCompleted: false,
        createdAt: DateTime.now(),
        points: 8,
      ),
      DailyGoal(
        title: "Erken Yatış",
        description: "Saat 23:00'dan önce yatağa git",
        category: "Uyku",
        isCompleted: false,
        createdAt: DateTime.now(),
        points: 10,
      ),
    ];
    
    // Rastgele 3-4 hedef seç
    final random = Random();
    final selectedGoals = <DailyGoal>[];
    final goalCount = 3 + random.nextInt(2); // 3 veya 4 hedef
    
    while (selectedGoals.length < goalCount && goalTemplates.isNotEmpty) {
      final randomIndex = random.nextInt(goalTemplates.length);
      selectedGoals.add(goalTemplates.removeAt(randomIndex));
    }
    
    setState(() {
      todayGoals = selectedGoals;
    });
    
    _saveGoalsData();
  }

  void _toggleGoalCompletion(int index) {
    final goal = todayGoals[index];
    final newGoal = goal.copyWith(isCompleted: !goal.isCompleted);
    
    setState(() {
      todayGoals[index] = newGoal;
      
      if (newGoal.isCompleted && !goal.isCompleted) {
        // Hedef tamamlandı, puan ekle
        totalPoints += newGoal.points;
        weeklyPoints += newGoal.points;
        
        // Streak kontrolü
        _checkStreak();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Harika! +${newGoal.points} puan kazandın!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (!newGoal.isCompleted && goal.isCompleted) {
        // Hedef iptal edildi, puan çıkar
        totalPoints -= newGoal.points;
        weeklyPoints -= newGoal.points;
        if (totalPoints < 0) totalPoints = 0;
        if (weeklyPoints < 0) weeklyPoints = 0;
      }
    });
    
    _saveGoalsData();
  }

  void _checkStreak() {
    // Basit streak kontrolü - gerçek uygulamada daha karmaşık olabilir
    final completedToday = todayGoals.where((goal) => goal.isCompleted).length;
    if (completedToday >= todayGoals.length * 0.7) { // %70 tamamlama
      streak++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedGoals = todayGoals.where((goal) => goal.isCompleted).length;
    final progressPercentage = todayGoals.isEmpty ? 0.0 : completedGoals / todayGoals.length;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Günlük Motivasyon'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMotivationalCard(),
            const SizedBox(height: 20),
            _buildProgressCard(progressPercentage),
            const SizedBox(height: 20),
            _buildPointsCard(),
            const SizedBox(height: 20),
            _buildDailyGoals(),
            const SizedBox(height: 20),
            _buildAchievements(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomGoalDialog(),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMotivationalCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.wb_sunny, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(
              'Bugünün Motivasyonu',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentQuote,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(double progress) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '📊 Günlük İlerleme',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? Colors.green : primaryColor,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${todayGoals.where((g) => g.isCompleted).length}/${todayGoals.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (progress >= 1.0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Tebrikler! Bugünü tamamladın! 🎉',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏆 Puanların',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '💎',
                    '$totalPoints',
                    'Toplam Puan',
                    primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '📅',
                    '$weeklyPoints',
                    'Bu Hafta',
                    secondaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '🔥',
                    '$streak',
                    'Seri',
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoals() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 Bugünün Hedefleri',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (todayGoals.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Bugün için hedef oluşturuluyor...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...todayGoals.asMap().entries.map((entry) {
                final index = entry.key;
                final goal = entry.value;
                return _buildGoalTile(goal, index);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTile(DailyGoal goal, int index) {
    final categoryColor = _getCategoryColor(goal.category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: goal.isCompleted ? Colors.green.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: goal.isCompleted ? Colors.green : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _toggleGoalCompletion(index),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: goal.isCompleted ? Colors.green : Colors.transparent,
              border: Border.all(
                color: goal.isCompleted ? Colors.green : Colors.grey,
                width: 2,
              ),
            ),
            child: goal.isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
        title: Text(
          goal.title,
          style: TextStyle(
            decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: categoryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '+${goal.points} puan',
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _toggleGoalCompletion(index),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Sağlık':
        return Colors.blue;
      case 'Spor':
        return Colors.orange;
      case 'Beslenme':
        return Colors.green;
      case 'Mental':
        return Colors.purple;
      case 'Uyku':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAchievements() {
    final achievements = [
      if (streak >= 3) '🔥 3 Günlük Seri!',
      if (totalPoints >= 100) '🏆 100 Puan Kulübü!',
      if (weeklyPoints >= 50) '⭐ Haftanın Yıldızı!',
      if (todayGoals.where((g) => g.isCompleted).length >= 3) '🎯 Hedef Avcısı!',
    ];
    
    if (achievements.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏅 Başarıların',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: achievements.map((achievement) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    achievement,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomGoalDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Sağlık';
    int selectedPoints = 10;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Özel Hedef Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Hedef Başlığı'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: ['Sağlık', 'Spor', 'Beslenme', 'Mental', 'Uyku', 'Özel']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => selectedCategory = value!),
                  decoration: const InputDecoration(labelText: 'Kategori'),
                ),
                const SizedBox(height: 8),
                Text('Puan: $selectedPoints'),
                Slider(
                  value: selectedPoints.toDouble(),
                  min: 5,
                  max: 25,
                  divisions: 4,
                  onChanged: (value) => setDialogState(() => selectedPoints = value.toInt()),
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
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final newGoal = DailyGoal(
                    title: titleController.text,
                    description: descriptionController.text,
                    category: selectedCategory,
                    isCompleted: false,
                    createdAt: DateTime.now(),
                    points: selectedPoints,
                  );
                  
                  setState(() {
                    todayGoals.add(newGoal);
                  });
                  
                  _saveGoalsData();
                  Navigator.pop(context);
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
