import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'meal_suggestion_page.dart';
import 'food_photo_page.dart';
import 'ingredients_recipe_page.dart';
import 'services/google_sign_in_service.dart';
import 'services/error_handler.dart';
import 'auth_page.dart';
import 'profile_page.dart';
import 'meal_history_page.dart';
import 'settings_page.dart';
import 'water_tracking_page.dart';
import 'step_counter_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;

  // --- RENK PALETİ TANIMLAMALARI ---
  final Color primaryColor = Colors.green.shade800;
  final Color secondaryColor = Colors.green.shade600;
  final Color backgroundColor = Colors.grey.shade100;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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
      await GoogleSignInService.signOut();
      
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

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Zayıf';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Fazla Kilolu';
    return 'Obez';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final bmi = _calculateBMI();
    final dietTypes = userProfile?['dietTypes'] as List? ?? [];
    final dietTypesText = dietTypes.isNotEmpty ? dietTypes.join(', ') : '-';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Hoşgeldin, ${userProfile?['name'] ?? 'Kullanıcı'} 👋',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor, // Değiştirildi
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              ).then((_) => _loadUserProfile());
            },
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Ayarlar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Çıkış Yap'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primaryColor, secondaryColor], // Değiştirildi
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Image.asset('assets/smeal_icon.png', height: 48, errorBuilder: (context, error, stackTrace) => Icon(Icons.restaurant, size: 48, color: Colors.white)),
                    const SizedBox(height: 12),
                    const Text(
                      '🍽️ Sağlıklı Beslenme Asistanın',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI destekli beslenme önerileri ve kişisel analizler',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, color: primaryColor, size: 24), // Değiştirildi
                              const SizedBox(width: 8),
                              Text(
                                'Profil Bilgilerin',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: primaryColor, // Değiştirildi
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50, // Değiştirildi
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildProfileItem(Icons.cake, 'Yaş', '${userProfile?['age'] ?? '-'}'),
                                      const SizedBox(height: 8),
                                      _buildProfileItem(Icons.monitor_weight, 'Kilo', '${userProfile?['weight'] ?? '-'} kg'),
                                      const SizedBox(height: 8),
                                      _buildProfileItem(Icons.height, 'Boy', '${userProfile?['height'] ?? '-'} cm'),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildProfileItem(Icons.person_outline, 'Cinsiyet', '${userProfile?['gender'] ?? '-'}'),
                                      const SizedBox(height: 8),
                                      _buildProfileItem(Icons.restaurant, 'Beslenme', dietTypesText),
                                      const SizedBox(height: 8),
                                      if (bmi > 0)
                                        _buildProfileItem(Icons.analytics, 'BMI', '${bmi.toStringAsFixed(1)} (${_getBMICategory(bmi)})'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    '🚀 Ana Menü',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildMenuButton(
                    icon: Icons.restaurant_menu,
                    title: 'Kişisel Yemek Önerisi',
                    subtitle: 'AI ile size özel sağlıklı tarifler',
                    color: Colors.green.shade700, // Değiştirildi
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const MealSuggestionPage()));
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildMenuButton(
                    icon: Icons.camera_alt,
                    title: 'Yemeği Analiz Et',
                    subtitle: 'Fotoğrafla besin değeri ve sağlık analizi',
                    color: Colors.teal.shade700, // Değiştirildi
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FoodPhotoPage()));
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildMenuButton(
                    icon: Icons.kitchen,
                    title: 'Elimdekiler ile Tarifler',
                    subtitle: 'Malzemelerinizle yapabileceğiniz yemekler',
                    color: Colors.orange.shade700, // Değiştirildi
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const IngredientsRecipePage()));
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    '💪 Sağlık Takibi',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildHealthButton(
                          icon: Icons.water_drop,
                          title: 'Su Takibi',
                          subtitle: 'Günlük su tüketimi',
                          color: Colors.blue.shade600, // Değiştirildi
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const WaterTrackingPage()));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHealthButton(
                          icon: Icons.directions_walk,
                          title: 'Adım Sayar',
                          subtitle: 'Günlük aktivite',
                          color: Colors.green.shade700, // Değiştirildi
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const StepCounterPage()));
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildMenuButton(
                    icon: Icons.history,
                    title: 'Yemek Geçmişim',
                    subtitle: 'Geçmiş önerileriniz ve favori yemekleriniz',
                    color: Colors.blueGrey.shade700, // Değiştirildi
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const MealHistoryPage()));
                    },
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryColor), // Değiştirildi
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}