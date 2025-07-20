import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class EarlyDiagnosisCenterPage extends StatefulWidget {
  const EarlyDiagnosisCenterPage({super.key});

  @override
  State<EarlyDiagnosisCenterPage> createState() => _EarlyDiagnosisCenterPageState();
}

class _EarlyDiagnosisCenterPageState extends State<EarlyDiagnosisCenterPage> {
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
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Anket geçmişini yükle
        final surveySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('health_surveys')
            .orderBy('date', descending: true)
            .limit(12) // Son 12 hafta
            .get();

        // Kullanıcı istatistiklerini yükle

        setState(() {
          surveyHistory = surveySnapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList();
          
          // Bu haftanın anketini kontrol et
          final thisWeek = _getWeekString(DateTime.now());
          currentWeekSurvey = surveyHistory.firstWhere(
            (survey) => survey['week'] == thisWeek,
            orElse: () => {},
          );
          
          // Streak ve başarıları hesapla
          _calculateStreakAndAchievements();
          
          // Sağlık skorunu hesapla
          _calculateHealthScore();
          
          isLoading = false;
        });
      }
    } catch (e) {
      print('Sağlık verileri yükleme hatası: $e');
      setState(() => isLoading = false);
    }
  }

  String _getWeekString(DateTime date) {
    final year = date.year;
    final weekOfYear = _getWeekOfYear(date);
    return '$year-W$weekOfYear';
  }

  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }

  void _calculateStreakAndAchievements() {
    // Streak hesapla
    streakCount = 0;
    final today = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final checkDate = today.subtract(Duration(days: i * 7));
      final weekString = _getWeekString(checkDate);
      final hasWeekSurvey = surveyHistory.any((survey) => survey['week'] == weekString);
      
      if (hasWeekSurvey) {
        streakCount++;
      } else {
        break;
      }
    }

    // Başarıları hesapla
    achievements.clear();
    if (streakCount >= 4) {
      achievements.add('🏆 Sağlık Şampiyonu');
    }
    if (streakCount >= 12) {
      achievements.add('💪 Sağlık Takipçisi');
    }
    
    // Düşük risk skoru başarısı
    final lowRiskCount = surveyHistory.where((s) => (s['risk_score'] ?? 100) <= 20).length;
    if (lowRiskCount >= 4) {
      achievements.add('🎯 Risk Fark Edici');
    }
  }

  void _calculateHealthScore() {
    if (surveyHistory.isEmpty) {
      totalHealthScore = 0;
      return;
    }

    final recentScores = surveyHistory.take(4).map((s) => s['risk_score'] ?? 0).toList();
    final averageRisk = recentScores.reduce((a, b) => a + b) / recentScores.length;
    
    // Risk skoru ne kadar düşükse sağlık skoru o kadar yüksek
    totalHealthScore = (100 - averageRisk).round().clamp(0, 100);
  }

  Color _getRiskColor(int riskScore) {
    if (riskScore <= 20) return Colors.green;
    if (riskScore <= 40) return Colors.lightGreen;
    if (riskScore <= 60) return Colors.orange;
    if (riskScore <= 80) return Colors.deepOrange;
    return Colors.red;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏥 Erken Tanı Merkezi'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Erken Teşhis İstatistikleri
                  _buildEarlyDiagnosisStats(),
                  const SizedBox(height: 20),
                  
                  // Sağlık Durumu Özeti
                  _buildHealthOverview(),
                  const SizedBox(height: 20),
                  
                  // Haftalık Anket Kartı
                  _buildWeeklySurveyCard(),
                  const SizedBox(height: 20),
                  
                  // Başarılar ve Streak
                  _buildAchievementsCard(),
                  const SizedBox(height: 20),
                  
                  // Trend Grafiği
                  if (surveyHistory.length >= 2) _buildTrendChart(),
                  if (surveyHistory.length >= 2) const SizedBox(height: 20),
                  
                  // Anket Geçmişi
                  _buildSurveyHistory(),
                  const SizedBox(height: 20),
                  
                  // Yasal Uyarı
                  _buildLegalWarning(),
                ],
              ),
            ),
    );
  }

  Widget _buildEarlyDiagnosisStats() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 Erken Teşhis Hayat Kurtarır',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatItem(
                icon: Icons.favorite,
                title: 'Meme Kanseri',
                percentage: '%95',
                description: 'erken teşhis ile iyileşme oranı',
              ),
              const SizedBox(height: 12),
              _buildStatItem(
                icon: Icons.colorize,
                title: 'Kolorektal Kanser',
                percentage: '%90',
                description: 'erken evrede yaşam oranı',
              ),
              const SizedBox(height: 12),
              _buildStatItem(
                icon: Icons.wb_sunny,
                title: 'Deri Kanseri',
                percentage: '%99',
                description: 'erken müdahale ile başarı oranı',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.source, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Kaynak: Türk Onkoloji Derneği, Dünya Sağlık Örgütü (WHO), American Cancer Society',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String percentage,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              Text(
                '$percentage $description',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            percentage,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySurveyCard() {
    final hasCurrentWeek = currentWeekSurvey?.isNotEmpty ?? false;
    final currentRisk = hasCurrentWeek ? currentWeekSurvey!['risk_score'] ?? 0 : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasCurrentWeek ? Colors.green.shade100 : Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasCurrentWeek ? Icons.check_circle : Icons.assignment,
                    color: hasCurrentWeek ? Colors.green : Colors.red.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasCurrentWeek ? 'Bu Hafta Tamamlandı' : 'Haftalık Sağlık Taraması',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasCurrentWeek
                            ? 'Risk Skoru: ${_getRiskText(currentRisk)} ($currentRisk%)'
                            : 'Bu haftanın sağlık taraması hazır!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              hasCurrentWeek
                  ? 'Harika! Bu haftanın taramasını tamamladınız. Sonuçlarınızı geçmişte görüntüleyebilirsiniz.'
                  : 'Haftalık sağlık taramanız hazır. 10 kısa soru ile kanser riskini değerlendirin.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasCurrentWeek ? null : _startWeeklySurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasCurrentWeek ? Colors.grey : Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  hasCurrentWeek ? 'Tamamlandı ✓' : 'Anketi Başlat',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyHistory() {
    if (surveyHistory.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'Henüz anket geçmişi yok',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'İlk anketi başlatarak geçmişinizi oluşturmaya başlayın!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Anket Geçmişi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: surveyHistory.length,
              itemBuilder: (context, index) {
                final survey = surveyHistory[index];
                final riskScore = survey['risk_score'] ?? 0;
                final date = survey['date'] is Timestamp 
                    ? (survey['date'] as Timestamp).toDate()
                    : DateTime.now();
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getRiskColor(riskScore).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getRiskColor(riskScore).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getRiskColor(riskScore),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getRiskIcon(riskScore),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getRiskText(riskScore),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getRiskColor(riskScore),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$riskScore%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthOverview() {
    final hasCurrentWeek = currentWeekSurvey?.isNotEmpty ?? false;
    final currentRisk = hasCurrentWeek ? currentWeekSurvey!['risk_score'] ?? 0 : 0;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.red.shade700, Colors.red.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                '🏥 Sağlık Durumu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHealthStat(
                    icon: Icons.favorite,
                    title: 'Sağlık Skoru',
                    value: '$totalHealthScore',
                    color: Colors.white,
                  ),
                  _buildHealthStat(
                    icon: Icons.local_fire_department,
                    title: 'Streak',
                    value: '$streakCount hafta',
                    color: Colors.white,
                  ),
                  _buildHealthStat(
                    icon: Icons.trending_up,
                    title: 'Bu Hafta',
                    value: hasCurrentWeek ? _getRiskText(currentRisk) : 'Bekliyor',
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthStat({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAchievementsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Başarılar & İstatistikler',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Streak Counter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Takip Serisi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$streakCount hafta üst üste tamamlandı',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$streakCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Başarı Rozetleri
            if (achievements.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: achievements.map((achievement) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    achievement,
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )).toList(),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Henüz başarı rozeti yok. Düzenli takip yaparak rozetler kazanabilirsiniz!',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Risk Trendi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: surveyHistory.take(8).toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final survey = entry.value;
                        return FlSpot(index.toDouble(), (survey['risk_score'] ?? 0).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.red.shade700,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.shade700.withOpacity(0.2),
                      ),
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Son 8 haftalık risk skoru değişimi',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalWarning() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.amber.shade100, Colors.orange.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Önemli Uyarı',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ Bu değerlendirme yalnızca bilgilendirme amaçlıdır ve kesinlikle doktor muayenesi, tanı veya tedavi yerine geçmez.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                '🏥 Herhangi bir sağlık sorunu şüphesi durumunda mutlaka bir sağlık uzmanına başvurun.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                '🔒 Sağlık verileriniz KVKK uyumu ile güvenli şekilde saklanmaktadır.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
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
              Text(
                'Nasıl Çalışır?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Haftalık 10 soruluk sağlık taraması'),
              Text('• Akıllı risk hesaplaması (0-100 puan)'),
              Text('• Renk kodlu risk seviyesi'),
              Text('• Kişiselleştirilmiş öneriler'),
              SizedBox(height: 16),
              Text(
                'Risk Seviyeleri:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
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
      MaterialPageRoute(
        builder: (context) => const WeeklySurveyPage(),
      ),
    ).then((_) => _loadHealthData());
  }
}

// Haftalık Anket Sayfası
class WeeklySurveyPage extends StatefulWidget {
  const WeeklySurveyPage({super.key});

  @override
  State<WeeklySurveyPage> createState() => _WeeklySurveyPageState();
}

class _WeeklySurveyPageState extends State<WeeklySurveyPage> {
  int currentQuestion = 0;
  List<int> answers = [];
  bool isSubmitting = false;

  final List<Map<String, dynamic>> questions = [
    {
      'question': 'Son 3 ayda vücut ağırlığınızda beklenmedik bir kayıp yaşadınız mı?',
      'options': ['Hayır', 'Evet, 3-5kg', 'Evet, 5-10kg', 'Evet, 10kg+'],
      'weights': [0, 10, 20, 30],
      'category': 'Genel Sağlık'
    },
    {
      'question': 'Sürekli yorgunluk ve halsizlik probleminiz var mı?',
      'options': ['Hayır', 'Hafif', 'Orta', 'Şiddetli'],
      'weights': [0, 8, 15, 25],
      'category': 'Genel Sağlık'
    },
    {
      'question': 'Geceleri aşırı terleme yaşıyor musunuz?',
      'options': ['Hayır', 'Bazen', 'Sık sık', 'Her gece'],
      'weights': [0, 5, 12, 20],
      'category': 'Genel Sağlık'
    },
    {
      'question': 'Vücudunuzda yeni çıkan ben, leke veya değişiklik fark ettiniz mi?',
      'options': ['Hayır', 'Emin değilim', 'Evet, küçük', 'Evet, büyük/çok'],
      'weights': [0, 8, 15, 25],
      'category': 'Deri Sağlığı'
    },
    {
      'question': 'Öksürük, nefes darlığı veya göğüs ağrısı yaşıyor musunuz?',
      'options': ['Hayır', 'Bazen', 'Sık sık', 'Sürekli'],
      'weights': [0, 10, 18, 28],
      'category': 'Solunum'
    },
    {
      'question': 'Bağırsak alışkanlıklarınızda değişiklik var mı?',
      'options': ['Hayır', 'Hafif değişiklik', 'Belirgin değişiklik', 'Kan görme'],
      'weights': [0, 8, 15, 25],
      'category': 'Sindirim'
    },
    {
      'question': 'Alkol tüketim sıklığınız nedir?',
      'options': ['Hiç', 'Haftada 1-2', 'Haftada 3-5', 'Günlük'],
      'weights': [0, 3, 8, 15],
      'category': 'Yaşam Tarzı'
    },
    {
      'question': 'Sigara kullanım durumunuz nedir?',
      'options': ['Hiç kullanmadım', 'Bıraktım', 'Bazen içiyorum', 'Düzenli içiyorum'],
      'weights': [0, 5, 12, 20],
      'category': 'Yaşam Tarzı'
    },
    {
      'question': 'Güneşe korunmasız maruz kalma durumunuz?',
      'options': ['Hiç', 'Bazen', 'Sık sık', 'Sürekli'],
      'weights': [0, 4, 8, 15],
      'category': 'Yaşam Tarzı'
    },
    {
      'question': 'Ailenizde kanser geçmişi var mı?',
      'options': ['Hayır', 'Uzak akrabada', 'Yakın akrabada', 'Çoklu aile üyesi'],
      'weights': [0, 5, 12, 20],
      'category': 'Aile Geçmişi'
    },
  ];

  @override
  void initState() {
    super.initState();
    answers = List.filled(questions.length, -1);
  }

  void _nextQuestion() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
    } else {
      _submitSurvey();
    }
  }

  void _previousQuestion() {
    if (currentQuestion > 0) {
      setState(() {
        currentQuestion--;
      });
    }
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      answers[currentQuestion] = answerIndex;
    });
  }

  Future<void> _submitSurvey() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Risk skorunu hesapla
        int totalScore = 0;
        for (int i = 0; i < answers.length; i++) {
          if (answers[i] != -1) {
            totalScore += questions[i]['weights'][answers[i]] as int;
          }
        }

        // Sonucu Firebase'e kaydet
        final now = DateTime.now();
        final weekString = '${now.year}-W${_getWeekOfYear(now)}';
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('health_surveys')
            .doc(weekString)
            .set({
          'week': weekString,
          'questions': questions.map((q) => q['question']).toList(),
          'answers': answers,
          'risk_score': totalScore,
          'date': Timestamp.now(),
          'categories': questions.map((q) => q['category']).toList(),
        });

        // Sonuç sayfasına git
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SurveyResultPage(riskScore: totalScore),
          ),
        );
      }
    } catch (e) {
      print('Anket kaydetme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anket kaydedilirken hata oluştu')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestion];
    final progress = (currentQuestion + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Soru ${currentQuestion + 1}/${questions.length}'),
        backgroundColor: Colors.red.shade700,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Bar
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade700),
                  ),
                  const SizedBox(height: 24),
                  
                  // Soru
                  Text(
                    question['question'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  // Cevap Seçenekleri
                  Expanded(
                    child: ListView.builder(
                      itemCount: question['options'].length,
                      itemBuilder: (context, index) {
                        final isSelected = answers[currentQuestion] == index;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: RadioListTile<int>(
                            title: Text(question['options'][index]),
                            value: index,
                            groupValue: answers[currentQuestion],
                            onChanged: (value) => _selectAnswer(value!),
                            activeColor: Colors.red.shade700,
                            selected: isSelected,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Navigation Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentQuestion > 0)
                        ElevatedButton(
                          onPressed: _previousQuestion,
                          child: const Text('Önceki'),
                        )
                      else
                        const SizedBox(),
                      
                      ElevatedButton(
                        onPressed: answers[currentQuestion] != -1 ? _nextQuestion : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          currentQuestion == questions.length - 1 ? 'Tamamla' : 'Sonraki',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

// Sonuç Sayfası
class SurveyResultPage extends StatelessWidget {
  final int riskScore;

  const SurveyResultPage({super.key, required this.riskScore});

  Color _getRiskColor() {
    if (riskScore <= 30) return Colors.green;
    if (riskScore <= 60) return Colors.orange;
    return Colors.red;
  }

  String _getRiskText() {
    if (riskScore <= 30) return 'Düşük Risk';
    if (riskScore <= 60) return 'Orta Risk';
    return 'Yüksek Risk';
  }

  String _getRecommendation() {
    if (riskScore <= 30) {
      return 'Harika! Mevcut sağlıklı yaşam tarzınızı sürdürün. Düzenli kontrolleri ihmal etmeyin.';
    } else if (riskScore <= 60) {
      return 'Dikkatli olun. Yaşam tarzınızda bazı değişiklikler yapmanız ve doktor kontrolünden geçmeniz önerilir.';
    } else {
      return 'Yüksek risk grubundasınız. Mutlaka bir doktora başvurun ve detaylı inceleme yaptırın.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anket Sonucu'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Risk Skoru
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: _getRiskColor(),
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$riskScore%',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _getRiskText(),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Öneri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      '📋 Öneriler',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getRecommendation(),
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Ana Sayfaya Dön
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Ana Sayfaya Dön',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
