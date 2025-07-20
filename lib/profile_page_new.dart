import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'services/error_handler.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _allergiesController = TextEditingController();

  List<String> secilenDiyetTurleri = [];
  List<String> secilenAlerjiler = [];

  bool isDietSectionExpanded = false;
  bool isAllergySectionExpanded = false;

  final Map<String, String> dietTypesWithEmojis = {
    'Dengeli': '⚖️', 'Vegan': '🌱', 'Vejetaryen': '🥗', 'Ketojenik': '🥑',
    'Akdeniz Diyeti': '🫒', 'Yüksek Protein': '🥩', 'Düşük Karbonhidrat': '🥬',
    'Şekersiz': '🚫', 'Karnivor': '🥩',
  };

  final Map<String, String> allergiesWithEmojis = {
    'Gluten': '🌾', 'Laktoz': '🥛', 'Yumurta': '🥚', 'Soya': '🫘', 'Fıstık': '🥜',
    'Ceviz, Badem vb. (Ağaç Kuruyemişleri)': '🌰', 'Deniz Ürünleri (Balık, Kabuklular)': '🐟',
    'Hardal': '🟡', 'Susam': '🌻',
  };

  bool digerDiyetTuruSecili = false;
  bool digerAlerjiSecili = false;
  final _digerDiyetTuruController = TextEditingController();
  final _digerAlerjiController = TextEditingController();

  String _gender = 'Erkek';
  String _activityLevel = 'Orta';
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _genderOptions = ['Erkek', 'Kadın', 'Belirtmek istemiyorum'];
  final List<String> _activityLevels = ['Düşük', 'Orta', 'Yüksek', 'Çok Yüksek'];

  String? _bloodTestImageUrl;
  bool _isUploading = false;
  
  // Profil fotoğrafı için yeni değişkenler
  String? _profileImageUrl;
  int? _selectedAvatarIndex;
  
  // Sağlık durumu verileri
  int _totalHealthScore = 0;
  int _streakCount = 0;
  String _currentRiskLevel = 'Bekliyor';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadHealthData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _allergiesController.dispose();
    _digerDiyetTuruController.dispose();
    _digerAlerjiController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Sağlık verilerini yükle
        final surveySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('health_surveys')
            .orderBy('date', descending: true)
            .limit(12)
            .get();

        if (mounted) {
          final surveyHistory = surveySnapshot.docs.map((doc) => doc.data()).toList();
          
          // Sağlık skorunu hesapla
          if (surveyHistory.isNotEmpty) {
            final recentScores = surveyHistory.take(4).map((s) => s['risk_score'] ?? 0).toList();
            if (recentScores.isNotEmpty) {
              final averageRisk = recentScores.reduce((a, b) => a + b) / recentScores.length;
              _totalHealthScore = (100 - averageRisk).round().clamp(0, 100);
            }
          }
          
          // Streak hesapla
          _streakCount = 0;
          final today = DateTime.now();
          for (int i = 0; i < 12; i++) {
            final checkDate = today.subtract(Duration(days: i * 7));
            final weekString = '${checkDate.year}-W${_getWeekOfYear(checkDate)}';
            final hasWeekSurvey = surveyHistory.any((survey) => survey['week'] == weekString);
            
            if (hasWeekSurvey) {
              _streakCount++;
            } else {
              break;
            }
          }
          
          // Bu haftanın risk seviyesini kontrol et
          final thisWeek = '${today.year}-W${_getWeekOfYear(today)}';
          final currentWeekSurvey = surveyHistory.firstWhere(
            (survey) => survey['week'] == thisWeek,
            orElse: () => {},
          );
          
          if (currentWeekSurvey.isNotEmpty) {
            final riskScore = currentWeekSurvey['risk_score'] ?? 0;
            _currentRiskLevel = _getRiskText(riskScore);
          }
          
          setState(() {});
        }
      }
    } catch (e) {
      print('Sağlık verileri yükleme hatası: $e');
    }
  }

  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }

  String _getRiskText(int riskScore) {
    if (riskScore <= 20) return 'Çok Düşük Risk';
    if (riskScore <= 40) return 'Düşük Risk';
    if (riskScore <= 60) return 'Orta Risk';
    if (riskScore <= 80) return 'Yüksek Risk';
    return 'Çok Yüksek Risk';
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && doc.exists) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _ageController.text = (data['age'] ?? '').toString();
            _weightController.text = (data['weight'] ?? '').toString();
            _heightController.text = (data['height'] ?? '').toString();
            _gender = data['gender'] ?? 'Erkek';
            _activityLevel = data['activityLevel'] ?? 'Orta';
            if (data['dietTypes'] != null) secilenDiyetTurleri = List<String>.from(data['dietTypes']);
            if (data['allergies'] is List) secilenAlerjiler = List<String>.from(data['allergies']);
            _bloodTestImageUrl = data['bloodTestImageUrl'];
            _profileImageUrl = data['profileImageUrl'];
            _selectedAvatarIndex = data['selectedAvatarIndex'];
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if(mounted){
        setState(() => _isLoading = false);
        ErrorHandler.showError(context, 'Profil bilgileri yüklenirken hata oluştu');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green.shade700)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('👤 Profilim'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profil Fotoğrafı ve Sağlık Durumu Kartı
            _buildProfileHeader(),
            const SizedBox(height: 20),
            
            // Kişisel Bilgiler
            _buildPersonalInfoCard(),
            const SizedBox(height: 20),
            
            // Sağlık Durumu Detayları
            _buildHealthStatusCard(),
            const SizedBox(height: 20),
            
            // Diyet Tercihleri
            _buildDietPreferencesCard(),
            const SizedBox(height: 20),
            
            // Alerjiler
            _buildAllergiesCard(),
            const SizedBox(height: 20),
            
            // Kan Tahlili
            _buildBloodTestCard(),
            const SizedBox(height: 20),
            
            // Kaydet Butonu
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.green.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profil Fotoğrafı
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _getProfileImage(),
                      child: _getProfileImage() == null
                          ? Icon(Icons.person, size: 60, color: Colors.grey.shade600)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showProfileImagePicker,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // İsim ve Temel Bilgiler
              Text(
                _nameController.text.isNotEmpty ? _nameController.text : 'Hoş geldiniz!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              
              // Sağlık Durumu Özeti
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHealthStat(
                    icon: Icons.favorite,
                    title: 'Sağlık Skoru',
                    value: '$_totalHealthScore',
                    color: Colors.white,
                  ),
                  _buildHealthStat(
                    icon: Icons.local_fire_department,
                    title: 'Streak',
                    value: '$_streakCount hafta',
                    color: Colors.white,
                  ),
                  _buildHealthStat(
                    icon: Icons.trending_up,
                    title: 'Risk Durumu',
                    value: _currentRiskLevel,
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
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  ImageProvider? _getProfileImage() {
    if (_profileImageUrl != null) {
      return NetworkImage(_profileImageUrl!);
    }
    if (_selectedAvatarIndex != null) {
      // Basit emoji avatarlar için
      return null;
    }
    return null;
  }

  String _getAvatarEmoji() {
    if (_selectedAvatarIndex != null) {
      final avatars = ['👨', '👩', '🧑', '👴', '👵', '🧔'];
      return avatars[_selectedAvatarIndex! % avatars.length];
    }
    return '👤';
  }

  void _showProfileImagePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📸 Profil Fotoğrafı Seç',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Hazır Avatarlar
            const Text(
              'Hazır Avatarlar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                itemBuilder: (context, index) {
                  final isSelected = _selectedAvatarIndex == index;
                  final avatars = ['👨', '👩', '🧑', '👴', '👵', '🧔'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatarIndex = index;
                        _profileImageUrl = null;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.grey.shade100,
                        child: Text(
                          avatars[index],
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // Kendi Fotoğrafını Yükle
            ListTile(
              leading: Icon(Icons.photo_camera, color: Colors.green.shade700),
              title: const Text('Kameradan Çek'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.green.shade700),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red.shade700),
              title: const Text('Fotoğrafı Kaldır'),
              onTap: () {
                setState(() {
                  _profileImageUrl = null;
                  _selectedAvatarIndex = null;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance.ref().child('profile_images').child('${user.uid}.jpg');
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      
      setState(() {
        _profileImageUrl = downloadUrl;
        _selectedAvatarIndex = null;
      });
      
      ErrorHandler.showSuccess(context, 'Profil fotoğrafı başarıyla güncellendi!');
    } catch (e) {
      ErrorHandler.showError(context, 'Fotoğraf yüklenirken hata oluştu');
    }
  }

  Widget _buildPersonalInfoCard() {
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
                Icon(Icons.person, color: Colors.green.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Kişisel Bilgiler',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Ad Soyad',
                    icon: Icons.person_outline,
                    validator: (value) => value?.isEmpty ?? true ? 'Ad soyad gerekli' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _ageController,
                          label: 'Yaş',
                          icon: Icons.cake,
                          keyboardType: TextInputType.number,
                          validator: (value) => value?.isEmpty ?? true ? 'Yaş gerekli' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdownField(
                          value: _gender,
                          label: 'Cinsiyet',
                          icon: Icons.wc,
                          items: _genderOptions,
                          onChanged: (value) => setState(() => _gender = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _weightController,
                          label: 'Kilo (kg)',
                          icon: Icons.monitor_weight,
                          keyboardType: TextInputType.number,
                          validator: (value) => value?.isEmpty ?? true ? 'Kilo gerekli' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _heightController,
                          label: 'Boy (cm)',
                          icon: Icons.height,
                          keyboardType: TextInputType.number,
                          validator: (value) => value?.isEmpty ?? true ? 'Boy gerekli' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    value: _activityLevel,
                    label: 'Aktivite Seviyesi',
                    icon: Icons.fitness_center,
                    items: _activityLevels,
                    onChanged: (value) => setState(() => _activityLevel = value!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatusCard() {
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
                Icon(Icons.medical_services, color: Colors.red.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Sağlık Durumu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.favorite, color: Colors.green.shade700, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Sağlık Skoru',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_totalHealthScore/100',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Takip Serisi',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_streakCount hafta',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.trending_up, color: Colors.blue.shade700, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Risk Durumu',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentRiskLevel,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 18,
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

  Widget _buildDietPreferencesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  isDietSectionExpanded = !isDietSectionExpanded;
                });
              },
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu, color: Colors.green.shade700, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Diyet Tercihleri',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(
                    isDietSectionExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.green.shade700,
                  ),
                ],
              ),
            ),
            if (isDietSectionExpanded) ...[
              const SizedBox(height: 16),
              const Text(
                'Hangi diyetleri takip ediyorsunuz? (Çoklu seçim yapabilirsiniz)',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: dietTypesWithEmojis.entries.map((entry) {
                  final isSelected = secilenDiyetTurleri.contains(entry.key);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          secilenDiyetTurleri.remove(entry.key);
                        } else {
                          secilenDiyetTurleri.add(entry.key);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green.shade700.withOpacity(0.2) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '${entry.value} ${entry.key}',
                        style: TextStyle(
                          color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllergiesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  isAllergySectionExpanded = !isAllergySectionExpanded;
                });
              },
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Alerji Durumu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(
                    isAllergySectionExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.orange.shade700,
                  ),
                ],
              ),
            ),
            if (isAllergySectionExpanded) ...[
              const SizedBox(height: 16),
              const Text(
                'Hangi besinlere alerjiniz var? (Çoklu seçim yapabilirsiniz)',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allergiesWithEmojis.entries.map((entry) {
                  final isSelected = secilenAlerjiler.contains(entry.key);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          secilenAlerjiler.remove(entry.key);
                        } else {
                          secilenAlerjiler.add(entry.key);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange.shade100 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.orange.shade700 : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '${entry.value} ${entry.key}',
                        style: TextStyle(
                          color: isSelected ? Colors.orange.shade700 : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBloodTestCard() {
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
                Icon(Icons.bloodtype, color: Colors.red.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Kan Tahlili',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Daha kişiselleştirilmiş beslenme önerileri için kan tahlili sonuçlarınızı paylaşın.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_bloodTestImageUrl != null) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_bloodTestImageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_isUploading)
              Center(child: CircularProgressIndicator(color: Colors.green.shade700))
            else
              ElevatedButton.icon(
                onPressed: _pickAndUploadBloodTest,
                icon: const Icon(Icons.cloud_upload),
                label: Text(_bloodTestImageUrl != null ? 'Güncelle' : 'Yükle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Profili Kaydet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
    );
  }

  Future<void> _pickAndUploadBloodTest() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() => _isUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance.ref().child('blood_tests').child('${user.uid}.jpg');
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'bloodTestImageUrl': downloadUrl});
      if (mounted) {
        setState(() => _bloodTestImageUrl = downloadUrl);
        ErrorHandler.showSuccess(context, 'Kan tahlili başarıyla yüklendi!');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, 'Dosya yüklenirken bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text,
          'age': int.tryParse(_ageController.text) ?? 0,
          'weight': double.tryParse(_weightController.text) ?? 0,
          'height': double.tryParse(_heightController.text) ?? 0,
          'gender': _gender,
          'activityLevel': _activityLevel,
          'dietTypes': secilenDiyetTurleri,
          'allergies': secilenAlerjiler,
          'profileImageUrl': _profileImageUrl,
          'selectedAvatarIndex': _selectedAvatarIndex,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ErrorHandler.showSuccess(context, 'Profil başarıyla güncellendi!');
        }
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, 'Profil güncellenirken hata oluştu');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
