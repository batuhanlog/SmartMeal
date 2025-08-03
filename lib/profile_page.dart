import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/error_handler.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  List<String> secilenDiyetTurleri = [];
  List<String> secilenAlerjiler = [];

  final Map<String, String> dietTypesWithEmojis = {
    'Dengeli': '⚖️', 'Vegan': '🌱', 'Vejetaryen': '🥗', 'Ketojenik': '🥑',
    'Akdeniz Diyeti': '🫒', 'Yüksek Protein': '🥩', 'Düşük Karbonhidrat': '🥬',
    'Şekersiz': '🚫', 'Karnivor': '🥩',
  };

  final Map<String, String> allergiesWithEmojis = {
    'Gluten': '🌾', 'Laktoz': '🥛', 'Yumurta': '🥚', 'Soya': '🫘', 'Fıstık': '🥜',
    'Ceviz, Badem vb.': '🌰', 'Deniz Ürünleri': '🐟', 'Hardal': '🟡', 'Susam': '🌻',
  };

  String _gender = 'Erkek';
  String _activityLevel = 'Orta';
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _genderOptions = ['Erkek', 'Kadın', 'Belirtmek istemiyorum'];
  final List<String> _activityLevels = ['Düşük', 'Orta', 'Yüksek', 'Çok Yüksek'];

  // Sağlık verileri
  int _totalHealthScore = 75;
  int _streakCount = 5;
  String _currentRiskLevel = 'Düşük Risk';
  double _bmi = 0.0;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Modern color palette
  final Color primaryColor = const Color(0xFF667EEA);
  final Color secondaryColor = const Color(0xFF764BA2);
  final Color accentColor = const Color(0xFF4CAF50);
  final Color warningColor = const Color(0xFFFF9800);
  final Color errorColor = const Color(0xFFE74C3C);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserProfile();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
            _calculateBMI();
            _isLoading = false;
          });
          _fadeController.forward();
          _slideController.forward();
        } else if (mounted) {
          setState(() => _isLoading = false);
          _fadeController.forward();
          _slideController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showError(context, 'Profil bilgileri yüklenemedi: ${e.toString()}');
      }
    }
  }

  void _calculateBMI() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    if (weight > 0 && height > 0) {
      _bmi = weight / ((height / 100) * (height / 100));
    }
  }

  String _getBMICategory() {
    if (_bmi < 18.5) return 'Zayıf';
    if (_bmi < 25) return 'Normal';
    if (_bmi < 30) return 'Fazla Kilolu';
    return 'Obez';
  }

  Color _getBMIColor() {
    if (_bmi < 18.5) return Colors.blue;
    if (_bmi < 25) return accentColor;
    if (_bmi < 30) return warningColor;
    return errorColor;
  }

  Widget _buildInitialsAvatar() {
    final name = _nameController.text.trim();
    String initials = 'U';
    
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = parts[0][0].toUpperCase();
      }
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHealthHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildInitialsAvatar(),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.isEmpty ? 'Kullanıcı' : _nameController.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sağlık Skoru: $_totalHealthScore/100',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_streakCount hafta aktif',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildHealthCard(
                  'BMI',
                  _bmi > 0 ? _bmi.toStringAsFixed(1) : '-',
                  _bmi > 0 ? _getBMICategory() : 'Hesaplanıyor',
                  Icons.monitor_weight,
                  _getBMIColor(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHealthCard(
                  'Risk Seviyesi',
                  _currentRiskLevel,
                  'Güncel durum',
                  Icons.health_and_safety,
                  accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _calculateBMI();
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'age': int.tryParse(_ageController.text) ?? 0,
          'weight': double.tryParse(_weightController.text) ?? 0,
          'height': double.tryParse(_heightController.text) ?? 0,
          'gender': _gender,
          'activityLevel': _activityLevel,
          'dietTypes': secilenDiyetTurleri,
          'allergies': secilenAlerjiler,
          'bmi': _bmi,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Profil başarıyla güncellendi!'),
                ],
              ),
              backgroundColor: accentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Profil kaydedilemedi: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Profil Düzenle',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildHealthHeader(),
                _buildPersonalInfoSection(),
                const SizedBox(height: 16),
                _buildPhysicalInfoSection(),
                const SizedBox(height: 16),
                _buildDietSection(),
                const SizedBox(height: 16),
                _buildAllergySection(),
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (color ?? primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color ?? primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color ?? primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: 'Kişisel Bilgiler',
      icon: Icons.person_rounded,
      children: [
        _buildModernTextField(
          controller: _nameController,
          label: 'Ad Soyad',
          icon: Icons.account_circle,
          validator: (val) => val!.isEmpty ? 'Ad soyad gerekli' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _ageController,
                label: 'Yaş',
                icon: Icons.cake,
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Yaş gerekli' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernDropdown(
                value: _gender,
                items: _genderOptions,
                label: 'Cinsiyet',
                icon: Icons.people,
                onChanged: (val) => setState(() => _gender = val!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhysicalInfoSection() {
    return _buildSection(
      title: 'Fiziksel Bilgiler',
      icon: Icons.fitness_center,
      color: accentColor,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _weightController,
                label: 'Kilo (kg)',
                icon: Icons.monitor_weight,
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Kilo gerekli' : null,
                onChanged: (val) => _calculateBMI(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernTextField(
                controller: _heightController,
                label: 'Boy (cm)',
                icon: Icons.height,
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Boy gerekli' : null,
                onChanged: (val) => _calculateBMI(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildModernDropdown(
          value: _activityLevel,
          items: _activityLevels,
          label: 'Aktivite Seviyesi',
          icon: Icons.directions_run,
          onChanged: (val) => setState(() => _activityLevel = val!),
        ),
      ],
    );
  }

  Widget _buildDietSection() {
    return _buildSection(
      title: 'Beslenme Tercihleri',
      icon: Icons.restaurant_menu,
      color: warningColor,
      children: [
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? warningColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? warningColor : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.value, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAllergySection() {
    return _buildSection(
      title: 'Alerjiler',
      icon: Icons.warning_amber_rounded,
      color: errorColor,
      children: [
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? errorColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? errorColor : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.value, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: primaryColor.withOpacity(0.3),
        ),
        child: _isSaving
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Kaydediliyor...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Profili Kaydet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
