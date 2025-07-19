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
  // --- Tutarlı Tema ve Stil Sabitleri ---
  static const Color _primaryColor = Color(0xFF1B5E20); // Koyu Yeşil Tema
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF343A40);
  static const Color _subtleTextColor = Color(0xFF6C757D);

  // Form ve Controller'lar
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _digerDiyetTuruController = TextEditingController();
  final _digerAlerjiController = TextEditingController();

  // Durum Değişkenleri
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  // Profil Verileri
  List<String> secilenDiyetTurleri = [];
  List<String> secilenAlerjiler = [];
  bool digerDiyetTuruSecili = false;
  bool digerAlerjiSecili = false;
  String _gender = 'Erkek';
  String _activityLevel = 'Orta';
  String? _profileImageUrl;
  int? _selectedAvatarIndex;
  String? _bloodTestImageUrl;

  // Sağlık Verileri
  int _totalHealthScore = 0;
  int _streakCount = 0;
  String _currentRiskLevel = 'Bekliyor';
  
  // Sabit Listeler
  final List<String> _genderOptions = ['Erkek', 'Kadın', 'Belirtmek istemiyorum'];
  final List<String> _activityLevels = ['Düşük', 'Orta', 'Yüksek', 'Çok Yüksek'];
  final Map<String, String> dietTypesWithEmojis = {
    'Dengeli': '⚖️', 'Vegan': '🌱', 'Vejetaryen': '🥗', 'Ketojenik': '🥑',
    'Akdeniz Diyeti': '🫒', 'Yüksek Protein': '🥩', 'Düşük Karbonhidrat': '🥬',
    'Şekersiz': '🚫', 'Karnivor': '🥩',
  };
  final Map<String, String> allergiesWithEmojis = {
    'Gluten': '🌾', 'Laktoz': '🥛', 'Yumurta': '🥚', 'Soya': '🫘', 'Fıstık': '🥜',
    'Ceviz, Badem vb.': '🌰', 'Deniz Ürünleri': '🐟',
  };
  final List<String> _avatarEmojis = ['👨‍💼', '👩‍💼', '🧑‍🎓', '👨‍⚕️', '👩‍⚕️', '🧑‍🍳', '👨‍🏫', '👩‍🏫'];
  
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _digerDiyetTuruController.dispose();
    _digerAlerjiController.dispose();
    super.dispose();
  }

  // --- Mantıksal Fonksiyonlar ---
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await _loadUserProfile();
    await _loadHealthData();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && doc.exists) {
          final data = doc.data()!;
          _nameController.text = data['name'] ?? '';
          _ageController.text = (data['age'] ?? '').toString();
          _weightController.text = (data['weight'] ?? '').toString();
          _heightController.text = (data['height'] ?? '').toString();
          _gender = data['gender'] ?? 'Erkek';
          _activityLevel = data['activityLevel'] ?? 'Orta';
          secilenDiyetTurleri = List<String>.from(data['dietTypes'] ?? []);
          secilenAlerjiler = List<String>.from(data['allergies'] ?? []);
          _profileImageUrl = data['profileImageUrl'];
          _selectedAvatarIndex = data['selectedAvatarIndex'];
          _bloodTestImageUrl = data['bloodTestImageUrl'];
        }
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, 'Profil bilgileri yüklenirken hata oluştu');
    }
  }

  Future<void> _loadHealthData() async {
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
          final surveyHistory = surveySnapshot.docs.map((doc) => doc.data()).toList();
          
          if (surveyHistory.isNotEmpty) {
            final recentScores = surveyHistory.take(4).map((s) => (s['risk_score'] as num?)?.toInt() ?? 0).toList();
            if (recentScores.isNotEmpty) {
              final averageRisk = recentScores.reduce((a, b) => a + b) / recentScores.length;
              _totalHealthScore = (100 - averageRisk).round().clamp(0, 100);
            }
          }
          
          _streakCount = 0;
          final today = DateTime.now();
          final uniqueWeeks = surveyHistory.map((s) => s['week']).toSet();
          for (int i = 0; i < 12; i++) {
            final checkDate = today.subtract(Duration(days: i * 7));
            final weekString = '${checkDate.year}-W${_getWeekOfYear(checkDate)}';
            if (uniqueWeeks.contains(weekString)) {
              _streakCount++;
            } else {
              break;
            }
          }
          
          final thisWeek = '${today.year}-W${_getWeekOfYear(today)}';
          final currentWeekSurvey = surveyHistory.firstWhere(
            (survey) => survey['week'] == thisWeek,
            orElse: () => {},
          );
          
          if (currentWeekSurvey.isNotEmpty) {
            final riskScore = (currentWeekSurvey['risk_score'] as num?)?.toInt() ?? 0;
            _currentRiskLevel = _getRiskText(riskScore);
          }
        }
      }
    } catch (e) {
      print('Sağlık verileri yükleme hatası: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (digerDiyetTuruSecili && _digerDiyetTuruController.text.isNotEmpty) secilenDiyetTurleri.add(_digerDiyetTuruController.text);
        if (digerAlerjiSecili && _digerAlerjiController.text.isNotEmpty) secilenAlerjiler.add(_digerAlerjiController.text);
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text,
          'age': int.tryParse(_ageController.text) ?? 0,
          'weight': double.tryParse(_weightController.text) ?? 0,
          'height': double.tryParse(_heightController.text) ?? 0,
          'gender': _gender,
          'dietTypes': secilenDiyetTurleri,
          'allergies': secilenAlerjiler,
          'activityLevel': _activityLevel,
          'profileImageUrl': _profileImageUrl,
          'selectedAvatarIndex': _selectedAvatarIndex,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ErrorHandler.showSuccess(context, 'Profil başarıyla güncellendi!');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, 'Profil güncellenirken hata oluştu');
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }
  
  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      
      if (pickedFile != null) {
        setState(() => _isUploading = true);
        final user = FirebaseAuth.instance.currentUser!;
        final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('${user.uid}.jpg');
        await storageRef.putFile(File(pickedFile.path));
        final downloadUrl = await storageRef.getDownloadURL();
        
        if (mounted) {
          setState(() {
            _profileImageUrl = downloadUrl;
            _selectedAvatarIndex = null;
          });
        }
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, 'Fotoğraf yüklenirken hata oluştu');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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
  // --- UI Widget'ları ---
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    const SizedBox(height: 16),
                    _buildHealthStatsCard(),
                    const SizedBox(height: 16),
                    _buildBmiCard(),
                    const SizedBox(height: 16),
                    _buildAvatarSection(),
                    const SizedBox(height: 16),
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 16),
                    _buildPhysicalInfoSection(),
                    const SizedBox(height: 16),
                    _buildExpansionSection(
                      title: 'Beslenme Tercihleri',
                      icon: Icons.restaurant_menu_outlined,
                      items: dietTypesWithEmojis,
                      selectedItems: secilenDiyetTurleri,
                      isOtherSelected: digerDiyetTuruSecili,
                      otherController: _digerDiyetTuruController,
                      onChanged: (item, isSelected) => setState(() => isSelected ? secilenDiyetTurleri.add(item) : secilenDiyetTurleri.remove(item)),
                      onOtherChanged: (isSelected) => setState(() => digerDiyetTuruSecili = isSelected),
                    ),
                    const SizedBox(height: 16),
                    _buildExpansionSection(
                      title: 'Alerjiler',
                      icon: Icons.warning_amber_rounded,
                      // *** DEĞİŞİKLİK: Alerjiler bölümü için uyarı rengi tanımlandı ***
                      accentColor: Colors.orange.shade700,
                      items: allergiesWithEmojis,
                      selectedItems: secilenAlerjiler,
                      isOtherSelected: digerAlerjiSecili,
                      otherController: _digerAlerjiController,
                      onChanged: (item, isSelected) => setState(() => isSelected ? secilenAlerjiler.add(item) : secilenAlerjiler.remove(item)),
                      onOtherChanged: (isSelected) => setState(() => digerAlerjiSecili = isSelected),
                    ),
                    const SizedBox(height: 100), // Alttaki buton için boşluk
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildStickySaveButton(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: _textColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text(
            'Profil',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textColor),
          ),
          const SizedBox(width: 48), // Simetri için boş widget
        ],
      ),
    );
  }

  Widget _buildHealthStatsCard() {
    return _buildSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // *** DEĞİŞİKLİK: İstatistik renkleri daha modern tonlarla güncellendi ***
            _buildStatItem('Sağlık Skoru', '$_totalHealthScore', Icons.favorite_rounded, Colors.pink.shade400),
            _buildStatItem('Seri', '$_streakCount', Icons.local_fire_department_rounded, Colors.orange.shade600),
            _buildStatItem('Risk', _currentRiskLevel, Icons.shield_rounded, Colors.blue.shade600),
          ],
        )
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: _subtleTextColor)),
      ],
    );
  }

  Widget _buildBmiCard() {
    final bmi = _calculateBMI();
    final bmiCategory = _getBMICategory(bmi);
    final bmiColor = _getBMIColor(bmi);
    double bmiPercent = (bmi.clamp(10, 35) - 10) / (35 - 10);

    return _buildSectionCard(
      children: [
        Row(
          children: [
            SizedBox(
              width: 80, height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: bmiPercent,
                    strokeWidth: 8,
                    backgroundColor: bmiColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(bmiColor),
                  ),
                  Center(
                    child: Text(
                      bmi.toStringAsFixed(1),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: bmiColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Vücut Kitle İndeksi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
                  const SizedBox(height: 4),
                  Text(bmiCategory, style: TextStyle(fontSize: 16, color: bmiColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  const Text("Bu değer genel bir göstergedir.", style: TextStyle(fontSize: 12, color: _subtleTextColor)),
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildAvatarSection() {
    return _buildSectionCard(
      title: "Profil Görünümü",
      children: [
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundColor: _primaryColor.withOpacity(0.1),
            backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
            child: _isUploading 
              ? const CircularProgressIndicator(color: _primaryColor)
              : (_profileImageUrl == null)
                  ? Text(_selectedAvatarIndex != null ? _avatarEmojis[_selectedAvatarIndex!] : '👤', style: const TextStyle(fontSize: 48))
                  : null,
          ),
        ),
        const SizedBox(height: 16),
        const Text("Avatar Seç", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textColor)),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _avatarEmojis.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedAvatarIndex == index;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedAvatarIndex = index;
                  _profileImageUrl = null;
                }),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? _primaryColor.withOpacity(0.15) : _cardColor,
                    border: Border.all(
                      color: isSelected ? _primaryColor : Colors.grey.shade300,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                  ),
                  child: Center(child: Text(_avatarEmojis[index], style: const TextStyle(fontSize: 28))),
                ),
              );
            },
          ),
        ),
        const Divider(height: 32),
        Center(
          child: TextButton.icon(
            onPressed: _pickProfileImage,
            icon: const Icon(Icons.camera_alt_outlined, color: _primaryColor),
            label: const Text('Özel Fotoğraf Yükle', style: TextStyle(color: _primaryColor)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: _primaryColor.withOpacity(0.08),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSectionCard(
      title: 'Kişisel Bilgiler',
      children: [
        _buildTextFormField(controller: _nameController, label: 'Ad Soyad', icon: Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextFormField(controller: _ageController, label: 'Yaş', icon: Icons.cake_outlined, keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildDropdownField(_gender, _genderOptions, 'Cinsiyet', (val) => setState(() => _gender = val!), Icons.wc_outlined),
      ],
    );
  }

  Widget _buildPhysicalInfoSection() {
    return _buildSectionCard(
      title: 'Fiziksel Özellikler',
      children: [
        _buildTextFormField(controller: _weightController, label: 'Kilo (kg)', icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildTextFormField(controller: _heightController, label: 'Boy (cm)', icon: Icons.height_outlined, keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildDropdownField(_activityLevel, _activityLevels, 'Aktivite Seviyesi', (val) => setState(() => _activityLevel = val!), Icons.fitness_center_outlined),
      ],
    );
  }

  Widget _buildExpansionSection({
    required String title,
    required IconData icon,
    required Map<String, String> items,
    required List<String> selectedItems,
    required bool isOtherSelected,
    required TextEditingController otherController,
    required Function(String, bool) onChanged,
    required Function(bool) onOtherChanged,
    Color? accentColor, // *** DEĞİŞİKLİK: Opsiyonel renk parametresi eklendi ***
  }) {
    final color = accentColor ?? _primaryColor;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textColor)),
        subtitle: Text('${selectedItems.length} seçenek seçili', style: const TextStyle(color: _subtleTextColor)),
        iconColor: color,
        collapsedIconColor: color,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          ...items.entries.map((entry) => _buildCheckboxRow(
            title: entry.key,
            emoji: entry.value,
            isSelected: selectedItems.contains(entry.key),
            onChanged: (val) => onChanged(entry.key, val ?? false),
            color: color,
          )),
          _buildCheckboxRow(
            title: 'Diğer', emoji: '✏️', isSelected: isOtherSelected,
            onChanged: (val) => onOtherChanged(val ?? false),
            color: color,
          ),
          if (isOtherSelected)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 0, right: 0, bottom: 8),
              child: _buildTextFormField(
                controller: otherController,
                label: 'Lütfen belirtin',
                icon: Icons.notes_outlined,
                isDense: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStickySaveButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _cardColor.withOpacity(0.95),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
            : const Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
  
  // --- Yardımcı Widget'lar ---
  Widget _buildSectionCard({String? title, required List<Widget> children, EdgeInsets? padding}) {
    return Card(
      elevation: 0,
      color: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
              const Divider(height: 24),
            ],
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isDense = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _subtleTextColor),
        filled: true,
        fillColor: _backgroundColor,
        isDense: isDense,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (value) => (value?.isEmpty ?? true) ? 'Bu alan boş bırakılamaz' : null,
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildDropdownField(String value, List<String> items, String label, ValueChanged<String?> onChanged, IconData icon) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _subtleTextColor),
        filled: true,
        fillColor: _backgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildCheckboxRow({
    required String title,
    required String emoji,
    required bool isSelected,
    required ValueChanged<bool?> onChanged,
    required Color color, // *** DEĞİŞİKLİK: Renk parametresi eklendi ***
  }) {
    return CheckboxListTile(
      value: isSelected,
      onChanged: onChanged,
      activeColor: color, // *** DEĞİŞİKLİK: Gelen renk parametresi kullanıldı ***
      title: Text('$emoji $title', style: const TextStyle(color: _textColor)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  // --- Yardımcı Hesaplama Fonksiyonları ---
  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }

  String _getRiskText(int riskScore) {
    if (riskScore <= 20) return 'Çok Düşük';
    if (riskScore <= 40) return 'Düşük';
    if (riskScore <= 60) return 'Orta';
    if (riskScore <= 80) return 'Yüksek';
    return 'Çok Yüksek';
  }

  double _calculateBMI() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    if (height <= 0) return 0;
    return weight / ((height / 100) * (height / 100));
  }

  String _getBMICategory(double bmi) {
    if (bmi <= 0) return 'Değer bekleniyor';
    if (bmi < 18.5) return 'Zayıf';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Fazla Kilolu';
    return 'Obez';
  }

  Color _getBMIColor(double bmi) {
    if (bmi <= 0) return _subtleTextColor;
    if (bmi < 18.5) return Colors.blue.shade400;
    if (bmi < 25) return _primaryColor;
    if (bmi < 30) return Colors.orange.shade600;
    return Colors.red.shade600;
  }
}