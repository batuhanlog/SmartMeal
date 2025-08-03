import 'package:flutter/material.dart';
import 'services/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AINutritionAdvisorPage extends StatefulWidget {
  const AINutritionAdvisorPage({super.key});

  @override
  State<AINutritionAdvisorPage> createState() => _AINutritionAdvisorPageState();
}

class _AINutritionAdvisorPageState extends State<AINutritionAdvisorPage> with TickerProviderStateMixin {
  // Modern renk paleti
  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _secondaryColor = Color(0xFF4CAF50);
  static const Color _accentColor = Color(0xFF66BB6A);
  static const Color _backgroundColor = Color(0xFFF5F7FA);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF1A1A1A);
  static const Color _subtleTextColor = Color(0xFF757575);

  final GeminiService _geminiService = GeminiService();
  
  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // State variables
  bool _isGeneratingReport = false;
  Map<String, dynamic>? _weeklyReport;
  List<String> _healthTips = [];
  double _currentHealthScore = 0.0;
  String _selectedFocusArea = 'nutrition';
  List<Map<String, dynamic>> _savedReports = [];
  Map<String, dynamic>? _userProfile;
  
  // Focus areas
  final List<Map<String, String>> _focusAreas = [
    {'key': 'nutrition', 'label': 'Beslenme', 'icon': '🥗'},
    {'key': 'fitness', 'label': 'Fitness', 'icon': '💪'},
    {'key': 'sleep', 'label': 'Uyku', 'icon': '😴'},
    {'key': 'mental', 'label': 'Mental Sağlık', 'icon': '🧠'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedReports();
    _loadUserProfile();
    _loadMockUserData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  void _loadMockUserData() {
    // Mock user data for demonstration
    setState(() {
      _currentHealthScore = 7.8;
    });
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() => _userProfile = doc.data());
        }
      } catch (e) {
        print('Error loading user profile: $e');
      }
    }
  }

  Future<void> _loadSavedReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedReportsString = prefs.getString('saved_health_reports') ?? '[]';
      final List<dynamic> savedReportsList = jsonDecode(savedReportsString);
      setState(() {
        _savedReports = savedReportsList.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      print('Error loading saved reports: $e');
    }
  }

  Future<void> _saveReport(Map<String, dynamic> report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedReportsList = List<Map<String, dynamic>>.from(_savedReports);
      savedReportsList.insert(0, report);
      
      // Keep only last 10 reports
      if (savedReportsList.length > 10) {
        savedReportsList.removeRange(10, savedReportsList.length);
      }
      
      await prefs.setString('saved_health_reports', jsonEncode(savedReportsList));
      setState(() {
        _savedReports = savedReportsList;
      });
      
      _showSuccessSnackBar('Rapor başarıyla kaydedildi! 📄');
    } catch (e) {
      print('Error saving report: $e');
      _showErrorSnackBar('Rapor kaydedilemedi: $e');
    }
  }

  Future<void> _generateWeeklyReport() async {
    setState(() {
      _isGeneratingReport = true;
    });

    try {
      // Gerçek kullanıcı profilini kullan, yoksa varsayılan değerler
      final userProfile = _userProfile ?? {
        'age': 25,
        'gender': 'erkek',
        'weight': 70,
        'height': 170,
        'activity_level': 'orta',
        'diet_preference': 'dengeli'
      };

      // Mock haftalık yemek verileri (gerçek uygulamada database'den gelecek)
      final mockWeeklyMeals = [
        {'date': '2025-08-01', 'breakfast': 'Kahvaltı', 'lunch': 'Öğle yemeği', 'dinner': 'Akşam yemeği'},
        {'date': '2025-08-02', 'breakfast': 'Kahvaltı', 'lunch': 'Öğle yemeği', 'dinner': 'Akşam yemeği'},
        // Daha fazla veri eklenebilir...
      ];

      // Mock haftalık aktivite verileri (gerçek uygulamada fitness tracker'dan gelecek)  
      final mockWeeklyActivity = {
        'total_steps': 45000,
        'workout_sessions': 4,
        'average_sleep': 7.5,
        'water_intake': 2.2
      };

      // Gerçek kullanıcı sağlık metrikleri
      final healthMetrics = {
        'weight': userProfile['weight'] ?? 70,
        'bmi': _calculateBMI(userProfile['weight'] ?? 70, userProfile['height'] ?? 170),
        'body_fat': userProfile['body_fat'] ?? 15.0,
        'muscle_mass': userProfile['muscle_mass'] ?? 30.0
      };

      final report = await _geminiService.generateWeeklyHealthReport(
        userProfile: userProfile,
        weeklyMeals: mockWeeklyMeals,
        weeklyActivity: mockWeeklyActivity,
        healthMetrics: healthMetrics,
      );

      if (report.isNotEmpty) {
        setState(() {
          _weeklyReport = report;
          _currentHealthScore = (report['overall_score'] as num?)?.toDouble() ?? 0.0;
        });
        
        _showSuccessSnackBar('🎉 Haftalık rapor oluşturuldu!');
      } else {
        _showErrorSnackBar('Rapor oluşturulamadı. Lütfen tekrar deneyin.');
      }
    } catch (e) {
      _showErrorSnackBar('Rapor oluşturma hatası: $e');
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
    }
  }

  // BMI hesaplama helper metodu
  double _calculateBMI(num weight, num height) {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  Future<void> _getHealthTips() async {
    try {
      // Gerçek kullanıcı profilini kullan
      final userProfile = _userProfile ?? {
        'age': 25,
        'weight': 70,
        'height': 170,
        'activity_level': 'orta'
      };

      final tips = await _geminiService.getPersonalizedHealthTips(
        userProfile: userProfile,
        focusArea: _selectedFocusArea,
      );

      setState(() {
        _healthTips = tips;
      });

      if (tips.isNotEmpty) {
        _showSuccessSnackBar('💡 Kişiselleştirilmiş öneriler alındı!');
      } else {
        _showErrorSnackBar('Öneriler alınamadı. Lütfen tekrar deneyin.');
      }
    } catch (e) {
      _showErrorSnackBar('Öneri alma hatası: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          '🤖 AI Sağlık Danışmanı',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildHealthScoreCard(),
              _buildActionButtons(),
              if (_weeklyReport != null) _buildWeeklyReport(),
              if (_healthTips.isNotEmpty) _buildHealthTips(),
              _buildSavedReports(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_primaryColor, _secondaryColor],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gemini AI Sağlık Asistanı',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Kişiselleştirilmiş sağlık raporları ve öneriler alın\nAI destekli haftalık analiz ve takip',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '📊 Güncel Sağlık Skoru',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: _currentHealthScore / 10,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getScoreColor(_currentHealthScore),
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    _currentHealthScore.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const Text(
                    '/ 10.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: _subtleTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getScoreDescription(_currentHealthScore),
            style: const TextStyle(
              fontSize: 14,
              color: _subtleTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_userProfile != null) _buildUserInfo(),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    if (_userProfile == null) return const SizedBox.shrink();
    
    final age = _userProfile!['age'] ?? 25;
    final weight = _userProfile!['weight'] ?? 70;
    final height = _userProfile!['height'] ?? 170;
    final bmi = _calculateBMI(weight, height);
    final gender = _userProfile!['gender'] ?? 'Belirtilmemiş';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '👤 Kişisel Bilgiler',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('Yaş', '$age'),
              _buildInfoItem('Boy', '${height}cm'),
              _buildInfoItem('Kilo', '${weight}kg'),
              _buildInfoItem('BMI', bmi.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cinsiyet: $gender',
            style: const TextStyle(
              fontSize: 14,
              color: _subtleTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _subtleTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingReport ? null : _generateWeeklyReport,
              icon: _isGeneratingReport
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.assessment_rounded),
              label: Text(
                _isGeneratingReport ? 'Rapor Oluşturuluyor...' : '📊 Haftalık Sağlık Raporu',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildFocusAreaSelector(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _getHealthTips,
              icon: const Icon(Icons.lightbulb_outline_rounded),
              label: const Text(
                '💡 Kişiselleştirilmiş Öneriler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: BorderSide(color: _primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusAreaSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _focusAreas.map((area) {
          final isSelected = area['key'] == _selectedFocusArea;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFocusArea = area['key']!;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      area['icon']!,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      area['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : _textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeeklyReport() {
    final report = _weeklyReport!;
    
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📋 Haftalık Rapor',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.save_rounded),
                  onPressed: () => _saveReport(report),
                  tooltip: 'Raporu Kaydet',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              report['report_date'] ?? 'Tarih belirtilmemiş',
              style: const TextStyle(
                fontSize: 12,
                color: _subtleTextColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildReportSection('📝 Özet', report['summary'] ?? 'Özet bulunamadı'),
            const SizedBox(height: 16),
            _buildReportSection('🏆 Başarılar', (report['achievements'] as List<dynamic>?)?.join('\n• ') ?? 'Başarı bulunamadı'),
            const SizedBox(height: 16),
            _buildReportSection('🎯 Öneriler', (report['recommendations'] as List<dynamic>?)?.join('\n• ') ?? 'Öneri bulunamadı'),
            const SizedBox(height: 16),
            _buildReportSection('🚀 Gelecek Hafta Hedefleri', (report['next_week_goals'] as List<dynamic>?)?.join('\n• ') ?? 'Hedef bulunamadı'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentColor.withOpacity(0.3)),
              ),
              child: Text(
                '💪 ${report['motivation_message'] ?? 'Motivasyon mesajı bulunamadı'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: _subtleTextColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthTips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💡 ${_focusAreas.firstWhere((area) => area['key'] == _selectedFocusArea)['label']} Önerileri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ..._healthTips.asMap().entries.map((entry) {
              final index = entry.key;
              final tip = entry.value;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _textColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedReports() {
    if (_savedReports.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📚 Kaydedilen Raporlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ..._savedReports.take(3).map((report) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          report['report_date'] ?? 'Tarih yok',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getScoreColor((report['overall_score'] as num?)?.toDouble() ?? 0.0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(report['overall_score'] as num?)?.toStringAsFixed(1) ?? '0.0'}/10',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report['summary'] ?? 'Özet bulunamadı',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _subtleTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
            if (_savedReports.length > 3)
              Center(
                child: Text(
                  've ${_savedReports.length - 3} rapor daha...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _subtleTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    if (score >= 4.0) return Colors.deepOrange;
    return Colors.red;
  }

  String _getScoreDescription(double score) {
    if (score >= 8.0) return 'Mükemmel! Sağlık durumunuz çok iyi 🎉';
    if (score >= 6.0) return 'İyi! Bazı alanlarda gelişim gerekli 👍';
    if (score >= 4.0) return 'Orta. Daha fazla özen gösterin ⚠️';
    return 'Dikkat! Sağlık alışkanlıklarınızı gözden geçirin 🚨';
  }
}
