import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'meal_suggestion_page.dart';
import 'food_photo_page.dart';
import 'ingredients_recipe_page.dart';
import 'services/error_handler.dart';
import 'auth_page.dart';
import 'profile_page.dart';
import 'meal_history_page.dart';
import 'settings_page.dart';
import 'water_tracking_page.dart';
import 'step_counter_page.dart';
import 'early_diagnosis_center.dart';
import 'calorie_tracker_page.dart';
import 'fitness_tracker_page.dart';
import 'motivation_tracker_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkWeeklySurveyReminder();
  }

  Future<void> _checkWeeklySurveyReminder() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final now = DateTime.now();
        final weekString = '${now.year}-W${_getWeekOfYear(now)}';
        
        // Bu haftanın anketini kontrol et
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('health_surveys')
            .doc(weekString)
            .get();
        
        if (mounted && !doc.exists) {
          // 3 saniye sonra pop-up göster
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _showWeeklySurveyReminder();
            }
          });
        }
      }
    } catch (e) {
      print('Haftalık anket kontrolü hatası: $e');
    }
  }

  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }

  void _showWeeklySurveyReminder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.medical_services, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '🏥 Haftalık Sağlık Kontrolü',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu haftanın erken tanı taramasını henüz yapmadınız!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              '✓ Sadece 10 kısa soru\n✓ 2 dakika sürer\n✓ Sağlığınız için önemli',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ Erken tanı hayat kurtarır!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Daha Sonra'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EarlyDiagnosisCenterPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Şimdi Yap'),
          ),
        ],
      ),
    );
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
          setState(() {
            userProfile = doc.data();
            isLoading = false;
          });
        } else if (mounted) {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Başarıyla çıkış yapıldı');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Çıkış yapılırken hata oluştu');
      }
    }
  }

  double _calculateBMI() {
    if (userProfile == null) return 0;
    final weight = userProfile!['weight']?.toDouble() ?? 0;
    final height = userProfile!['height']?.toDouble() ?? 0;
    if (height == 0) return 0;
    return weight / ((height / 100) * (height / 100));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: CircularProgressIndicator(color: Colors.green.shade700),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Modern Header
              _buildModernHeader(),
              
              // Sağlıklı Beslenme Asistanı + Profil Bilgileri
              _buildNutritionAssistantCard(),
              
              // Hızlı Eylemler
              _buildQuickActions(),
              
              // Özellikler Grid
              _buildFeaturesGrid(),
              
              // Alt Boşluk
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Merhaba!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    userProfile?['name'] ?? 'Kullanıcı',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                    icon: const Icon(Icons.settings, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bugünün Tarihi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  _getFormattedDate(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionAssistantCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Profil Fotoğrafı
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green.shade100,
              backgroundImage: _getProfileImage(),
              child: _getProfileImage() == null
                  ? Text(
                      _getAvatarEmoji(),
                      style: const TextStyle(fontSize: 32),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Profil Bilgileri ve Beslenme Asistanı
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🤖 Sağlıklı Beslenme Asistanı',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildProfileSummary(),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MealSuggestionPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Öneriler Al'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary() {
    if (userProfile == null) {
      return const Text(
        'Profil bilgilerinizi tamamlayın',
        style: TextStyle(color: Colors.grey),
      );
    }

    final bmi = _calculateBMI();
    final age = userProfile!['age'] ?? 0;
    final weight = userProfile!['weight']?.toDouble() ?? 0;
    final height = userProfile!['height']?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '👤 $age yaş',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Text(
              '⚖️ ${weight.toStringAsFixed(0)} kg',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '📏 ${height.toStringAsFixed(0)} cm',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            if (bmi > 0)
              Text(
                '📊 BMI: ${bmi.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.camera_alt,
              title: 'Fotoğraf Çek',
              subtitle: 'Yemeğini analiz et',
              color: Colors.blue.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FoodPhotoPage()),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.history,
              title: 'Geçmiş',
              subtitle: 'Öğün kayıtların',
              color: Colors.orange.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MealHistoryPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rocket_launch, color: Colors.green.shade700, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Özellikler',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildModernFeatureCard(
                gradient: [Colors.green.shade600, Colors.green.shade400],
                icon: Icons.restaurant_menu,
                title: 'Tarif Önerileri',
                description: 'Malzemelerden\ntarif',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const IngredientsRecipePage()),
                  );
                },
              ),
              _buildModernFeatureCard(
                gradient: [Colors.red.shade600, Colors.red.shade400],
                icon: Icons.medical_services,
                title: 'Erken Tanı',
                description: 'Sağlık\ntaraması',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EarlyDiagnosisCenterPage()),
                  );
                },
              ),
              _buildModernFeatureCard(
                gradient: [Colors.blue.shade600, Colors.blue.shade400],
                icon: Icons.water_drop,
                title: 'Su Takibi',
                description: 'Günlük su\ntüketimi',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WaterTrackingPage()),
                  );
                },
              ),
              _buildModernFeatureCard(
                gradient: [Colors.purple.shade600, Colors.purple.shade400],
                icon: Icons.directions_walk,
                title: 'Adım Sayar',
                description: 'Günlük\naktivite',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StepCounterPage()),
                  );
                },
              ),
              _buildModernFeatureCard(
                gradient: [Colors.orange.shade600, Colors.orange.shade400],
                icon: Icons.person,
                title: 'Profilim',
                description: 'Kişisel\nbilgiler',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  ).then((_) => _loadUserProfile());
                },
              ),
              _buildModernFeatureCard(
                gradient: [Colors.deepOrange.shade600, Colors.deepOrange.shade400],
                icon: Icons.local_fire_department,
                title: 'Kalori Takibi',
                description: 'Besin\ndeğerleri',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CalorieTrackerPage()),
                  );
                },
              ),
              _buildModernFeatureCard(
                gradient: [Colors.teal.shade600, Colors.teal.shade400],
                icon: Icons.fitness_center,
                title: 'Fitness Takibi',
                description: 'Antrenman\nkaydı',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FitnessTrackerPage()),
                  );
                },
              ),
              _buildModernFeatureCard(
                gradient: [Colors.indigo.shade600, Colors.pink.shade400],
                icon: Icons.emoji_events,
                title: 'Motivasyon',
                description: 'Günlük hedefler\nve başarımlar',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MotivationTrackerPage()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernFeatureCard({
    required List<Color> gradient,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (userProfile?['profileImageUrl'] != null) {
      return NetworkImage(userProfile!['profileImageUrl']);
    }
    return null;
  }

  String _getAvatarEmoji() {
    final selectedIndex = userProfile?['selectedAvatarIndex'];
    if (selectedIndex != null) {
      final avatars = ['👨', '👩', '🧑', '👴', '👵', '🧔'];
      return avatars[selectedIndex % avatars.length];
    }
    return '👤';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}