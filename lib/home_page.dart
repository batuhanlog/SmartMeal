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
import 'early_diagnosis_center.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- Renk ve Stil Sabitleri ---
  static const Color _primaryColor = Color(0xFF1B5E20); // Koyu Yeşil
  static const Color _backgroundColor = Color(0xFFF8F9FA); // Açık Arka Plan
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF343A40);
  static const Color _subtleTextColor = Color(0xFF6C757D);

  Map<String, dynamic>? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkWeeklySurveyReminder();
  }

  // --- Veri Yükleme ve Kontrol Fonksiyonları ---

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && doc.exists) {
          setState(() => userProfile = doc.data());
        }
      }
    } catch (e) {
      // Hata yönetimi
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _checkWeeklySurveyReminder() async {
    // Bu fonksiyonun içeriği aynı kalabilir, arayüzü etkilemiyor.
    // ... (Mevcut kodunuzdaki _checkWeeklySurveyReminder fonksiyonunu buraya kopyalayabilirsiniz)
  }

  // ... (Mevcut kodunuzdaki diğer yardımcı fonksiyonlar: _getWeekOfYear, _showWeeklySurveyReminder, _logout)
  // Bu fonksiyonlar UI ile doğrudan ilişkili olmadığından değiştirilmesine gerek yoktur.
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
  
  // --- UI Widget'ları ---

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Yeni Header: Profil Bilgisi ve İkonlar
              _buildHeaderProfile(),
              const SizedBox(height: 24),

              // 2. Ana Eylem Kartı: Yemek Önerisi
              _buildMainActionCard(),
              const SizedBox(height: 24),

              // 3. Özellikler Başlığı
              const Text(
                'Tüm Özellikler',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 16),

              // 4. Özellikler Izgarası
              _buildFeaturesGrid(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Ekranın en üstünde yer alan, profil fotoğrafı, isim ve ikonları içeren bölüm.
  Widget _buildHeaderProfile() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()))
                    .then((_) => _loadUserProfile());
              },
              child: CircleAvatar(
                radius: 28,
                backgroundColor: _primaryColor.withOpacity(0.1),
                backgroundImage: _getProfileImage(),
                child: _getProfileImage() == null
                    ? Text(_getAvatarEmoji(), style: const TextStyle(fontSize: 24))
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Merhaba,',
                  style: TextStyle(color: _subtleTextColor, fontSize: 16),
                ),
                Text(
                  userProfile?['name'] ?? 'Kullanıcı',
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _buildIconButton(Icons.settings_outlined, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            }),
            _buildIconButton(Icons.logout, _logout),
          ],
        ),
      ],
    );
  }

  /// Sağ üst köşedeki ikon butonlar için yardımcı widget.
  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: _subtleTextColor, size: 24),
      splashRadius: 24,
    );
  }
  
  /// Kullanıcıyı yemek önerisi almaya teşvik eden ana kart.
  Widget _buildMainActionCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MealSuggestionPage()));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [_primaryColor, Colors.green.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bugün Ne Yesem?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Yapay zeka destekli öğün önerileri alın.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
  
  /// Tüm özellikleri içeren 2 sütunlu ızgara yapısı.
  Widget _buildFeaturesGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildFeatureCard(
          icon: Icons.restaurant_menu_outlined,
          title: 'Tarif Bul',
          color: Colors.orange.shade700,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const IngredientsRecipePage())),
        ),
        _buildFeatureCard(
          icon: Icons.camera_alt_outlined,
          title: 'Yemek Analizi',
          color: Colors.blue.shade700,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FoodPhotoPage())),
        ),
         _buildFeatureCard(
          icon: Icons.history,
          title: 'Öğün Geçmişi',
          color: Colors.teal.shade600,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MealHistoryPage())),
        ),
        _buildFeatureCard(
          icon: Icons.medical_services_outlined,
          title: 'Erken Tanı',
          color: Colors.red.shade700,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EarlyDiagnosisCenterPage())),
        ),
        _buildFeatureCard(
          icon: Icons.water_drop_outlined,
          title: 'Su Takibi',
          color: Colors.lightBlue.shade600,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WaterTrackingPage())),
        ),
        _buildFeatureCard(
          icon: Icons.directions_walk,
          title: 'Adım Sayar',
          color: Colors.purple.shade700,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StepCounterPage())),
        ),
      ],
    );
  }

  /// Izgara içindeki her bir özellik kartını oluşturan yardımcı widget.
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Profil Fotoğrafı ve Emoji Yardımcı Fonksiyonları ---
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
}