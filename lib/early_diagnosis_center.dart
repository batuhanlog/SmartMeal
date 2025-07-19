import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
// YUKARIDAKİ 'flutter pub add confetti' KOMUTUNU ÇALIŞTIRDIKTAN SONRA
// BU SATIRDAKİ HATA GİDECEKTİR.
import 'package:confetti/confetti.dart';
import 'dart:math';


String _getWeekString(DateTime date) {
  final year = date.year;
  final firstDayOfYear = DateTime(year, 1, 1);
  final dayInYear = date.difference(firstDayOfYear).inDays;
  final weekOfYear = (dayInYear / 7).ceil();
  return '$year-W$weekOfYear';
}
// Ana Sayfa
class EarlyDiagnosisCenterPage extends StatefulWidget {
  const EarlyDiagnosisCenterPage({super.key});

  @override
  State<EarlyDiagnosisCenterPage> createState() => _EarlyDiagnosisCenterPageState();
}

class _EarlyDiagnosisCenterPageState extends State<EarlyDiagnosisCenterPage> {
  // --- TEMA RENKLERİ ---
  final Color primaryColor = const Color(0xFF8A0707); // Ana Bordo
  final Color accentColor = const Color(0xFFA82E2E); // Vurgu için açık bordo
  final Color backgroundColor = const Color(0xFFF8F9FA); // Ferah ve açık arkaplan
  final Color cardColor = Colors.white; // Kartlar için temiz beyaz
  final Color primaryTextColor = const Color(0xFF212529);
  final Color secondaryTextColor = const Color(0xFF6C757D);

  List<Map<String, dynamic>> surveyHistory = [];
  Map<String, dynamic>? currentWeekSurvey;
  bool isLoading = true;
  int streakCount = 0;
  int totalHealthScore = 0;
  List<String> achievements = [];

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    setState(() => isLoading = true); 
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final surveySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('health_surveys')
            .orderBy('date', descending: true)
            .limit(12)
            .get();

        if (mounted) {
          setState(() {
            surveyHistory = surveySnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
            final thisWeek = _getWeekString(DateTime.now());
            currentWeekSurvey = surveyHistory.firstWhere(
              (survey) => survey['week'] == thisWeek,
              orElse: () => {},
            );
            _calculateStreakAndAchievements();
            _calculateHealthScore();
            isLoading = false;
          });
        }
      } else {
         if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Sağlık verileri yükleme hatası: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- Yardımcı Fonksiyonlar ---
  String _getWeekString(DateTime date) {
    final year = date.year;
    final firstDayOfYear = DateTime(year, 1, 1);
    final dayInYear = date.difference(firstDayOfYear).inDays;
    final weekOfYear = (dayInYear / 7).ceil();
    return '$year-W$weekOfYear';
  }
  
  void _calculateStreakAndAchievements() {
    streakCount = 0;
    if (surveyHistory.isEmpty) return;
    
    final uniqueWeeks = surveyHistory.map((s) => s['week']).toSet();
    DateTime checkDate = DateTime.now();
    
    for (int i = 0; i < 12; i++) {
        final weekString = _getWeekString(checkDate.subtract(Duration(days: i * 7)));
        if(uniqueWeeks.contains(weekString)) {
            streakCount++;
        } else {
            break;
        }
    }
    
    achievements.clear();
    if (streakCount >= 4) achievements.add('🏆 Sağlık Şampiyonu');
    if (streakCount >= 12) achievements.add('💪 Sağlık Takipçisi');
    final lowRiskCount = surveyHistory.where((s) => (s['risk_score'] ?? 100) <= 20).length;
    if (lowRiskCount >= 4) achievements.add('🎯 Risk Fark Edici');
  }

  void _calculateHealthScore() {
    if (surveyHistory.isEmpty) {
        totalHealthScore = 0;
        return;
    }
    final recentScores = surveyHistory.take(4).map((s) => s['risk_score'] ?? 0).toList();
    final averageRisk = recentScores.reduce((a, b) => a + b) / recentScores.length;
    totalHealthScore = (100 - averageRisk).round().clamp(0, 100);
  }

  Color _getRiskColor(int riskScore) {
    if (riskScore <= 20) return Colors.green.shade600;
    if (riskScore <= 40) return Colors.lime.shade600;
    if (riskScore <= 60) return Colors.amber.shade600;
    if (riskScore <= 80) return Colors.orange.shade700;
    return Colors.red.shade600;
  }

  String _getRiskText(int riskScore) {
    if (riskScore <= 20) return 'Çok Düşük Risk';
    if (riskScore <= 40) return 'Düşük Risk';
    if (riskScore <= 60) return 'Orta Risk';
    if (riskScore <= 80) return 'Yüksek Risk';
    return 'Çok Yüksek Risk';
  }

  IconData _getRiskIcon(int riskScore) {
    if (riskScore <= 20) return Icons.sentiment_very_satisfied;
    if (riskScore <= 40) return Icons.sentiment_satisfied;
    if (riskScore <= 60) return Icons.sentiment_neutral;
    if (riskScore <= 80) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_very_dissatisfied;
  }
  // --- ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Erken Tanı Merkezi'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _loadHealthData,
              color: primaryColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(icon: Icons.dashboard_customize, title: "Sağlık Paneli"),
                    _buildDashboardMetrics(),
                    const SizedBox(height: 24),

                    _buildSectionHeader(icon: Icons.calendar_today, title: "Haftalık Tarama"),
                    _buildWeeklySurveyCard(),
                    const SizedBox(height: 24),

                     if (achievements.isNotEmpty) ...[
                      _buildSectionHeader(icon: Icons.emoji_events, title: "Başarı Rozetleri"),
                      _buildAchievementsCard(),
                      const SizedBox(height: 24),
                    ],

                    if (surveyHistory.length >= 2) ...[
                      _buildSectionHeader(icon: Icons.trending_up, title: "Risk Trendi"),
                      _buildTrendChart(),
                      const SizedBox(height: 24),
                    ],

                    _buildSectionHeader(icon: Icons.history, title: "Anket Geçmişi"),
                    _buildSurveyHistory(),
                    const SizedBox(height: 24),

                    _buildSectionHeader(icon: Icons.info, title: "Bilgilendirme"),
                    _buildEarlyDiagnosisStats(),
                    const SizedBox(height: 16),
                    _buildLegalWarning(),
                  ],
                ),
              ),
            ),
    );
  }

  // --- Widget'lar ---

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor)),
        ],
      ),
    );
  }

  Widget _buildDashboardMetrics() {
    return Row(
      children: [
        Expanded(child: _buildMetricCard(icon: Icons.favorite, title: 'Sağlık Skoru', value: '$totalHealthScore', color: Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard(icon: Icons.local_fire_department, title: 'Takip Serisi', value: '$streakCount Hafta', color: Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard(icon: Icons.shield, title: 'Bu Hafta', value: currentWeekSurvey?.isNotEmpty ?? false ? _getRiskText(currentWeekSurvey!['risk_score']) : 'Bekliyor', color: Colors.blue)),
      ],
    );
  }
  
  Widget _buildMetricCard({required IconData icon, required String title, required String value, required Color color}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 13, color: secondaryTextColor)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryTextColor), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySurveyCard() {
    final hasCurrentWeek = currentWeekSurvey?.isNotEmpty ?? false;

    return Card(
      elevation: 4,
      shadowColor: primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [primaryColor, accentColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasCurrentWeek ? 'Bu Haftanın Taraması Tamamlandı!' : 'Haftalık Sağlık Taraması Hazır',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                hasCurrentWeek ? 'Sonuçlarınızı aşağıda görebilirsiniz. Haftaya görüşmek üzere!' : '10 kısa soru ile genel sağlık durumunuzu ve kanser riskinizi değerlendirin.',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: hasCurrentWeek ? null : _startWeeklySurvey,
                  icon: Icon(hasCurrentWeek ? Icons.check_circle_outline : Icons.arrow_forward_ios_rounded),
                  label: Text(hasCurrentWeek ? 'Tamamlandı' : 'Anketi Başlat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                    disabledBackgroundColor: Colors.white.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsCard() {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: achievements.map((achievement) => Card(
          elevation: 1,
          color: Colors.green.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: Colors.green.shade100)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(child: Text(achievement, style: TextStyle(color: Colors.green.shade800, fontSize: 13, fontWeight: FontWeight.bold))),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSurveyHistory() {
    if (surveyHistory.isEmpty) {
      return Card(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history_toggle_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('Henüz anket geçmişi yok', style: TextStyle(fontSize: 16, color: secondaryTextColor)),
              ],
            ),
          ),
        ),
      );
    }
    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: surveyHistory.length,
          separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200),
          itemBuilder: (context, index) {
            final survey = surveyHistory[index];
            final riskScore = survey['risk_score'] ?? 0;
            final date = (survey['date'] as Timestamp).toDate();
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _getRiskColor(riskScore).withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(_getRiskIcon(riskScore), color: _getRiskColor(riskScore), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getRiskText(riskScore), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryTextColor)),
                        Text('${date.day}/${date.month}/${date.year}', style: TextStyle(color: secondaryTextColor, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _getRiskColor(riskScore), borderRadius: BorderRadius.circular(20)),
                    child: Text('$riskScore%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: surveyHistory.take(8).toList().reversed.toList().asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), (entry.value['risk_score'] ?? 0).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: primaryColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: true, color: primaryColor.withOpacity(0.1)),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Son 8 haftalık risk skoru değişimi', style: TextStyle(fontSize: 12, color: secondaryTextColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildEarlyDiagnosisStats() {
    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatItem(icon: Icons.female, title: 'Meme Kanseri', percentage: '%95', description: 'erken teşhis ile iyileşme'),
            const Divider(height: 24),
            _buildStatItem(icon: Icons.monitor_heart, title: 'Kolorektal Kanser', percentage: '%90', description: 'erken evrede yaşam oranı'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String title, required String percentage, required String description}) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor, fontSize: 15)),
              Text(description, style: TextStyle(color: secondaryTextColor, fontSize: 13)),
            ],
          ),
        ),
        Text(percentage, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 22)),
      ],
    );
  }

  Widget _buildLegalWarning() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Önemli Uyarı', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                  const SizedBox(height: 4),
                  Text(
                    'Bu değerlendirme yalnızca bilgilendirme amaçlıdır ve tıbbi tanı yerine geçmez. Lütfen şüphe durumunda bir sağlık uzmanına danışın.',
                    style: TextStyle(fontSize: 13, color: Colors.amber.shade800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🏥 Erken Tanı Merkezi'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nasıl Çalışır?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('• Haftalık 10 soruluk sağlık taraması'),
              Text('• Akıllı risk hesaplaması (0-100 puan)'),
              Text('• Renk kodlu risk seviyesi'),
              Text('• Kişiselleştirilmiş öneriler'),
              SizedBox(height: 16),
              Text('Risk Seviyeleri:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('🟢 0-20: Çok Düşük Risk'),
              Text('🟡 21-40: Düşük Risk'),
              Text('🟠 41-60: Orta Risk'),
              Text('🔴 61-80: Yüksek Risk'),
              Text('🔴 81-100: Çok Yüksek Risk'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  void _startWeeklySurvey() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WeeklySurveyPage(primaryColor: primaryColor)),
    ).then((_) => _loadHealthData());
  }
}

class WeeklySurveyPage extends StatefulWidget {
  final Color primaryColor;
  const WeeklySurveyPage({super.key, required this.primaryColor});

  @override
  State<WeeklySurveyPage> createState() => _WeeklySurveyPageState();
}

class _WeeklySurveyPageState extends State<WeeklySurveyPage> {
  int currentQuestion = 0;
  final List<int> answers = List.filled(10, -1);
  bool isSubmitting = false;
  final List<Map<String, dynamic>> questions = const [
    {'question': 'Son 3 ayda vücut ağırlığınızda beklenmedik bir kayıp yaşadınız mı?','options': ['Hayır', 'Evet, 3-5kg', 'Evet, 5-10kg', 'Evet, 10kg+'],'weights': [0, 10, 20, 30],'category': 'Genel Sağlık'},
    {'question': 'Sürekli yorgunluk ve halsizlik probleminiz var mı?','options': ['Hayır', 'Hafif', 'Orta', 'Şiddetli'],'weights': [0, 8, 15, 25],'category': 'Genel Sağlık'},
    {'question': 'Geceleri aşırı terleme yaşıyor musunuz?','options': ['Hayır', 'Bazen', 'Sık sık', 'Her gece'],'weights': [0, 5, 12, 20],'category': 'Genel Sağlık'},
    {'question': 'Vücudunuzda yeni çıkan ben, leke veya değişiklik fark ettiniz mi?','options': ['Hayır', 'Emin değilim', 'Evet, küçük', 'Evet, büyük/çok'],'weights': [0, 8, 15, 25],'category': 'Deri Sağlığı'},
    {'question': 'Öksürük, nefes darlığı veya göğüs ağrısı yaşıyor musunuz?','options': ['Hayır', 'Bazen', 'Sık sık', 'Sürekli'],'weights': [0, 10, 18, 28],'category': 'Solunum'},
    {'question': 'Bağırsak alışkanlıklarınızda değişiklik var mı?','options': ['Hayır', 'Hafif değişiklik', 'Belirgin değişiklik', 'Kan görme'],'weights': [0, 8, 15, 25],'category': 'Sindirim'},
    {'question': 'Alkol tüketim sıklığınız nedir?','options': ['Hiç', 'Haftada 1-2', 'Haftada 3-5', 'Günlük'],'weights': [0, 3, 8, 15],'category': 'Yaşam Tarzı'},
    {'question': 'Sigara kullanım durumunuz nedir?','options': ['Hiç kullanmadım', 'Bıraktım', 'Bazen içiyorum', 'Düzenli içiyorum'],'weights': [0, 5, 12, 20],'category': 'Yaşam Tarzı'},
    {'question': 'Güneşe korunmasız maruz kalma durumunuz?','options': ['Hiç', 'Bazen', 'Sık sık', 'Sürekli'],'weights': [0, 4, 8, 15],'category': 'Yaşam Tarzı'},
    {'question': 'Ailenizde kanser geçmişi var mı?','options': ['Hayır', 'Uzak akrabada', 'Yakın akrabada', 'Çoklu aile üyesi'],'weights': [0, 5, 12, 20],'category': 'Aile Geçmişi'},
  ];

  void _nextQuestion() {
    if (currentQuestion < questions.length - 1) {
      setState(() => currentQuestion++);
    } else {
      _submitSurvey();
    }
  }

  void _previousQuestion() {
    if (currentQuestion > 0) {
      setState(() => currentQuestion--);
    }
  }

  void _selectAnswer(int answerIndex) {
    setState(() => answers[currentQuestion] = answerIndex);
  }

  Future<void> _submitSurvey() async {
    setState(() => isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        int totalScore = 0;
        for (int i = 0; i < answers.length; i++) {
          if (answers[i] != -1) {
            totalScore += questions[i]['weights'][answers[i]] as int;
          }
        }
        final weekString = _getWeekString(DateTime.now());
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid)
            .collection('health_surveys').doc(weekString).set({
              'week': weekString,
              'risk_score': totalScore,
              'date': Timestamp.now(),
            });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SurveyResultPage(riskScore: totalScore, primaryColor: widget.primaryColor),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Anket kaydetme hatası: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anket kaydedilirken hata oluştu')));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestion];
    final progress = (currentQuestion + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Soru ${currentQuestion + 1}/${questions.length}'),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Anket sonuçlarınız kaydediliyor...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(question['question'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: question['options'].length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: RadioListTile<int>(
                            title: Text(question['options'][index], style: const TextStyle(fontSize: 16)),
                            value: index,
                            groupValue: answers[currentQuestion],
                            onChanged: (value) => _selectAnswer(value!),
                            activeColor: widget.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: answers[currentQuestion] == index ? widget.primaryColor : Colors.grey.shade300)),
                            tileColor: answers[currentQuestion] == index ? widget.primaryColor.withOpacity(0.05) : Colors.transparent,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentQuestion > 0)
                        TextButton.icon(onPressed: _previousQuestion, icon: const Icon(Icons.arrow_back), label: const Text('Önceki'))
                      else
                        const SizedBox(),

                      ElevatedButton.icon(
                        icon: Icon(currentQuestion == questions.length - 1 ? Icons.check : Icons.arrow_forward),
                        onPressed: answers[currentQuestion] != -1 ? _nextQuestion : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        label: Text(currentQuestion == questions.length - 1 ? 'Tamamla' : 'Sonraki'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class SurveyResultPage extends StatefulWidget {
  final int riskScore;
  final Color primaryColor;

  const SurveyResultPage({super.key, required this.riskScore, required this.primaryColor});

  @override
  State<SurveyResultPage> createState() => _SurveyResultPageState();
}

class _SurveyResultPageState extends State<SurveyResultPage> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    if (widget.riskScore <= 20) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Color _getRiskColor() {
    if (widget.riskScore <= 20) return Colors.green.shade600;
    if (widget.riskScore <= 40) return Colors.lime.shade600;
    if (widget.riskScore <= 60) return Colors.amber.shade600;
    if (widget.riskScore <= 80) return Colors.orange.shade700;
    return Colors.red.shade600;
  }

  String _getRiskText() {
    if (widget.riskScore <= 20) return 'Çok Düşük Risk';
    if (widget.riskScore <= 40) return 'Düşük Risk';
    if (widget.riskScore <= 60) return 'Orta Risk';
    if (widget.riskScore <= 80) return 'Yüksek Risk';
    return 'Çok Yüksek Risk';
  }

  String _getRecommendation() {
    if (widget.riskScore <= 20) return 'Harika! Mevcut sağlıklı yaşam tarzınızı sürdürün. Düzenli kontrolleri ihmal etmeyin.';
    if (widget.riskScore <= 40) return 'Risk seviyeniz düşük. Sağlıklı alışkanlıklarınızı devam ettirmeniz önemlidir.';
    if (widget.riskScore <= 60) return 'Dikkatli olun. Yaşam tarzınızda bazı değişiklikler yapmanız ve doktor kontrolünden geçmeniz önerilir.';
    return 'Risk seviyeniz yüksek. Lütfen en kısa zamanda bir doktora başvurun ve detaylı inceleme yaptırın.';
  }

  IconData _getRiskIcon() {
    if (widget.riskScore <= 20) return Icons.verified_user;
    if (widget.riskScore <= 40) return Icons.health_and_safety;
    if (widget.riskScore <= 60) return Icons.info;
    return Icons.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Anket Sonucunuz'),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    elevation: 8,
                    shadowColor: _getRiskColor().withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        children: [
                          Icon(_getRiskIcon(), color: _getRiskColor(), size: 64),
                          const SizedBox(height: 16),
                          Text('Risk Skorunuz', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                          Text('${widget.riskScore}%', style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: _getRiskColor())),
                          Text(_getRiskText(), style: TextStyle(fontSize: 22, color: _getRiskColor(), fontWeight: FontWeight.w500)),
                          const Divider(height: 40),
                          const Text('Öneri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_getRecommendation(), style: const TextStyle(fontSize: 16, height: 1.5), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Ana Sayfaya Dön'),
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
        ],
      ),
    );
  }
}