import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/gemini_service.dart';
import 'services/error_handler.dart';

class EarlyDiagnosisPage extends StatefulWidget {
  const EarlyDiagnosisPage({super.key});

  @override
  State<EarlyDiagnosisPage> createState() => _EarlyDiagnosisPageState();
}

class _EarlyDiagnosisPageState extends State<EarlyDiagnosisPage> 
    with TickerProviderStateMixin {
  
  // Modern renk paleti
  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _accentColor = Color(0xFF66BB6A);
  static const Color _backgroundColor = Color(0xFFF5F7FA);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF1A1A1A);
  static const Color _subtleTextColor = Color(0xFF757575);
  static const Color _warningColor = Color(0xFFFF6B35);
  static const Color _successColor = Color(0xFF4CAF50);

  final GeminiService _geminiService = GeminiService();
  final PageController _pageController = PageController();
  
  // Animasyon kontrolcüleri
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Form durumu
  int _currentQuestionIndex = 0;
  Map<String, dynamic> _responses = {};
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _healthAnalysis;
  bool _isAnalyzing = false;
  bool _showResults = false;

  // Sağlık soruları
  final List<Map<String, dynamic>> _healthQuestions = [
    {
      'id': 'family_history',
      'question': 'Ailenizde kanser öyküsü var mı?',
      'icon': '👨‍👩‍👧‍👦',
      'type': 'multiple',
      'options': ['Yok', 'Anne/Baba', 'Kardeş', 'Büyükanne/Büyükbaba', 'Diğer akrabalar']
    },
    {
      'id': 'smoking_status',
      'question': 'Sigara kullanım durumunuz nedir?',
      'icon': '🚭',
      'type': 'single',
      'options': ['Hiç içmedim', 'Bıraktım (1-5 yıl önce)', 'Bıraktım (5+ yıl önce)', 'Halen içiyorum (az)', 'Halen içiyorum (çok)']
    },
    {
      'id': 'alcohol_consumption',
      'question': 'Alkol tüketiminiz nasıl?',
      'icon': '🍷',
      'type': 'single',
      'options': ['Hiç içmem', 'Nadiren (ayda 1-2)', 'Haftada 1-2 gün', 'Günlük az miktarda', 'Günlük çok miktarda']
    },
    {
      'id': 'exercise_frequency',
      'question': 'Ne sıklıkla egzersiz yapıyorsunuz?',
      'icon': '🏃‍♂️',
      'type': 'single',
      'options': ['Hiç', 'Ayda birkaç kez', 'Haftada 1-2 gün', 'Haftada 3-4 gün', 'Günlük']
    },
    {
      'id': 'sleep_quality',
      'question': 'Uyku kalitenizi nasıl değerlendiriyorsunuz?',
      'icon': '😴',
      'type': 'single',
      'options': ['Çok kötü', 'Kötü', 'Orta', 'İyi', 'Mükemmel']
    },
    {
      'id': 'stress_level',
      'question': 'Günlük stres seviyeniz nedir?',
      'icon': '😰',
      'type': 'single',
      'options': ['Çok düşük', 'Düşük', 'Orta', 'Yüksek', 'Çok yüksek']
    },
    {
      'id': 'diet_quality',
      'question': 'Beslenme alışkanlıklarınızı nasıl tanımlarsınız?',
      'icon': '🥗',
      'type': 'single',
      'options': ['Çok sağlıksız', 'Sağlıksız', 'Orta', 'Sağlıklı', 'Çok sağlıklı']
    },
    {
      'id': 'health_checkups',
      'question': 'Ne sıklıkla sağlık kontrolü yaptırıyorsunuz?',
      'icon': '🩺',
      'type': 'single',
      'options': ['Hiç', 'Sadece hasta olduğumda', 'Yılda bir', 'Yılda iki kez', '6 ayda bir']
    },
    {
      'id': 'symptoms',
      'question': 'Son 6 ayda aşağıdakilerden herhangi birini yaşadınız mı?',
      'icon': '⚠️',
      'type': 'multiple',
      'options': ['Hiçbiri', 'Açıklanamayan kilo kaybı', 'Sürekli yorgunluk', 'Gece terlemesi', 'Nefes darlığı', 'Sürekli öksürük']
    },
    {
      'id': 'skin_changes',
      'question': 'Cildinizde son zamanlarda değişiklik fark ettiniz mi?',
      'icon': '🔍',
      'type': 'multiple',
      'options': ['Hayır', 'Yeni ben/leke', 'Değişen ben', 'İyileşmeyen yara', 'Renk değişimi']
    }
  ];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _loadUserProfile();
    _fadeController.forward();
    _checkWeeklyReminder();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (mounted && doc.exists) {
          setState(() => _userProfile = doc.data());
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Profil bilgileri yüklenemedi');
      }
    }
  }

  Future<void> _checkWeeklyReminder() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('health_checkups')
          .doc(user.uid)
          .get();

      final now = DateTime.now();
      DateTime? lastCheckup;

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['last_checkup'] as Timestamp?;
        if (timestamp != null) {
          lastCheckup = timestamp.toDate();
        }
      }

      // Eğer 7 gün geçmişse hatırlatma göster
      if (lastCheckup == null || now.difference(lastCheckup).inDays >= 7) {
        _showWeeklyReminder();
      }
    } catch (e) {
      print('Haftalık hatırlatma kontrolü hatası: $e');
    }
  }

  void _showWeeklyReminder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.health_and_safety, color: _warningColor),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Sağlık Kontrolü Zamanı',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Haftalık sağlık kontrol anketinizi tamamlamanızın zamanı geldi. Sağlığınızı takip etmek için birkaç dakikanızı ayırın.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Sonra', style: TextStyle(color: _subtleTextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startSurvey();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Başlat'),
          ),
        ],
      ),
    );
  }

  void _startSurvey() {
    setState(() {
      _currentQuestionIndex = 0;
      _responses.clear();
      _showResults = false;
      _healthAnalysis = null;
    });
    
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _healthQuestions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      _analyzeHealth();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    }
  }

  Future<void> _analyzeHealth() async {
    if (_userProfile == null) {
      ErrorHandler.showError(context, 'Profil bilgileri bulunamadı');
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final analysis = await _geminiService.analyzeHealthCondition(
        responses: _responses,
        userProfile: _userProfile!,
      );

      // Sonuçları kaydet
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('health_checkups')
            .doc(user.uid)
            .set({
          'last_checkup': FieldValue.serverTimestamp(),
          'responses': _responses,
          'analysis': analysis,
        });
      }

      if (mounted) {
        setState(() {
          _healthAnalysis = analysis;
          _isAnalyzing = false;
          _showResults = true;
        });

        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ErrorHandler.showError(context, 'Analiz sırasında hata oluştu: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildWelcomePage(),
            _buildSurveyPage(),
            _buildResultsPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 40),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, _accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.health_and_safety_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'AI Sağlık Kontrolü',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Yapay zeka destekli erken tanı sistemi',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildFeatureCard(
                    '🔍 Kapsamlı Analiz',
                    '10 kritik sağlık sorusu ile detaylı değerlendirme',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    '🤖 AI Destekli',
                    'Gelişmiş yapay zeka ile kişiselleştirilmiş öneriler',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    '⏰ Haftalık Takip',
                    'Düzenli kontroller ile sağlığınızı izleyin',
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, _accentColor],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _startSurvey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Sağlık Kontrolünü Başlat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildFeatureCard(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: _subtleTextColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: _accentColor,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyPage() {
    if (_currentQuestionIndex >= _healthQuestions.length) {
      return _buildLoadingPage();
    }

    final question = _healthQuestions[_currentQuestionIndex];
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildSurveyHeader(),
            const SizedBox(height: 40),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestionCard(question),
                    const SizedBox(height: 30),
                    _buildNavigationButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  question['icon'],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  question['question'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...question['options'].map<Widget>((option) {
            final isSelected = question['type'] == 'single' 
                ? _responses[question['id']] == option
                : (_responses[question['id']] as List<String>?)?.contains(option) == true;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _selectOption(question, option),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? _accentColor.withOpacity(0.1) : _backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _accentColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: question['type'] == 'single' ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: question['type'] == 'single' ? null : BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected ? _accentColor : _subtleTextColor,
                            width: 2,
                          ),
                          color: isSelected ? _accentColor : Colors.transparent,
                        ),
                        child: isSelected
                            ? Icon(
                                question['type'] == 'single' ? Icons.circle : Icons.check,
                                size: 12,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? _accentColor : _textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _selectOption(Map<String, dynamic> question, String option) {
    setState(() {
      if (question['type'] == 'single') {
        _responses[question['id']] = option;
      } else {
        _responses[question['id']] ??= <String>[];
        final selected = _responses[question['id']] as List<String>;
        
        if (option == 'Yok' || option == 'Hiç' || option == 'Hiçbiri' || option == 'Hayır') {
          _responses[question['id']] = [option];
        } else {
          selected.remove('Yok');
          selected.remove('Hiç');
          selected.remove('Hiçbiri');
          selected.remove('Hayır');
          
          if (selected.contains(option)) {
            selected.remove(option);
          } else {
            selected.add(option);
          }
          
          if (selected.isEmpty) {
            _responses[question['id']] = ['Yok'];
          }
        }
      }
    });
  }

  Widget _buildNavigationButtons() {
    final hasAnswer = _responses.containsKey(_healthQuestions[_currentQuestionIndex]['id']);
    
    return Row(
      children: [
        if (_currentQuestionIndex > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousQuestion,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _subtleTextColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Önceki',
                style: TextStyle(color: _subtleTextColor, fontSize: 16),
              ),
            ),
          ),
        if (_currentQuestionIndex > 0) const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: hasAnswer ? _nextQuestion : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasAnswer ? _primaryColor : _subtleTextColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _currentQuestionIndex == _healthQuestions.length - 1 ? 'Analiz Et' : 'Sonraki',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingPage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'AI Analiz Yapıyor',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cevaplarınız yapay zeka tarafından değerlendiriliyor...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: _subtleTextColor,
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

  Widget _buildResultsPage() {
    if (_healthAnalysis == null) return _buildLoadingPage();

    final riskLevel = _healthAnalysis!['overall_risk_level'] ?? 'Orta';
    final riskPercentage = _healthAnalysis!['risk_percentage'] ?? 30;
    
    Color riskColor;
    IconData riskIcon;
    
    switch (riskLevel.toLowerCase()) {
      case 'düşük':
        riskColor = _successColor;
        riskIcon = Icons.check_circle;
        break;
      case 'yüksek':
        riskColor = _warningColor;
        riskIcon = Icons.warning;
        break;
      default:
        riskColor = Colors.orange;
        riskIcon = Icons.info;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildResultsHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildRiskCard(riskLevel, riskPercentage, riskColor, riskIcon),
                    const SizedBox(height: 20),
                    _buildAnalysisCard(),
                    const SizedBox(height: 20),
                    _buildRecommendationsCard(),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCard(String riskLevel, int riskPercentage, Color riskColor, IconData riskIcon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: riskColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(riskIcon, size: 40, color: riskColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Genel Risk Seviyesi',
            style: TextStyle(
              fontSize: 16,
              color: _subtleTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            riskLevel,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: riskColor,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.7 * (riskPercentage / 100),
                height: 12,
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '%$riskPercentage risk faktörü',
            style: TextStyle(
              fontSize: 14,
              color: _subtleTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: _accentColor),
              const SizedBox(width: 12),
              const Text(
                'Detaylı Analiz',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _healthAnalysis!['detailed_analysis'] ?? 'Analiz bulunamadı',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recommendations = _healthAnalysis!['recommendations'] as List<dynamic>? ?? [];
    final lifestyleSuggestions = _healthAnalysis!['lifestyle_suggestions'] as List<dynamic>? ?? [];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: _accentColor),
              const SizedBox(width: 12),
              const Text(
                'Öneriler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rec.toString(),
                    style: TextStyle(fontSize: 14, color: _textColor),
                  ),
                ),
              ],
            ),
          )).toList(),
          if (lifestyleSuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Yaşam Tarzı Önerileri:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            ...lifestyleSuggestions.map((sug) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sug.toString(),
                      style: TextStyle(fontSize: 14, color: _textColor),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _warningColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.medical_services, color: _warningColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _healthAnalysis!['when_to_see_doctor'] ?? 'Herhangi bir endişeniz varsa doktora başvurun',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _warningColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 50,
          margin: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentQuestionIndex = 0;
                _responses.clear();
                _showResults = false;
                _healthAnalysis = null;
              });
              _pageController.animateToPage(0, 
                duration: const Duration(milliseconds: 300), 
                curve: Curves.easeInOut);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Yeni Kontrol Yap',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _subtleTextColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Ana Sayfaya Dön',
              style: TextStyle(fontSize: 16, color: _subtleTextColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: _textColor),
        ),
        const Expanded(
          child: Text(
            'Erken Tanı Merkezi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildSurveyHeader() {
    final progress = (_currentQuestionIndex + 1) / _healthQuestions.length;
    
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => _pageController.animateToPage(0, 
                duration: const Duration(milliseconds: 300), 
                curve: Curves.easeInOut),
              icon: Icon(Icons.arrow_back_ios, color: _textColor),
            ),
            Expanded(
              child: Text(
                'Soru ${_currentQuestionIndex + 1}/${_healthQuestions.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => _pageController.animateToPage(0, 
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeInOut),
          icon: Icon(Icons.arrow_back_ios, color: _textColor),
        ),
        const Expanded(
          child: Text(
            'Sağlık Analizi Sonucu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}
