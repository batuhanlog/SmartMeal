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
  // --- RENK PALETİ ---
  final Color primaryColor = Colors.green.shade700;
  final Color backgroundColor = Colors.grey.shade100;

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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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

  Future<void> _loadUserProfile() async {
    // ... Bu fonksiyonun içeriği aynı kalıyor ...
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

  Future<void> _pickAndUploadBloodTest() async {
    // ... Bu fonksiyonun içeriği aynı kalıyor ...
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
    // ... Bu fonksiyonun içeriği aynı kalıyor ...
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

  double _calculateBMI() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    if (height == 0) return 0;
    return weight / ((height / 100) * (height / 100));
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Zayıf';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Fazla Kilolu';
    return 'Obez';
  }
  
  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue.shade400;
    if (bmi < 25) return primaryColor;
    if (bmi < 30) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final bmi = _calculateBMI();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Profil Düzenle'),
        backgroundColor: primaryColor,
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Kaydet',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (bmi > 0) ...[
              Card(
                // --- DEĞİŞTİRİLEN KISIM ---
                color: const Color.fromARGB(211, 250, 255, 247),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                // --- DEĞİŞİKLİK SONU ---
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('📊 BMI Durumunuz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getBMIColor(bmi))),
                      const SizedBox(height: 8),
                      Text(bmi.toStringAsFixed(1), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _getBMIColor(bmi))),
                      Text(_getBMICategory(bmi), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _getBMIColor(bmi))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            _buildSectionCard(
              title: '👤 Kişisel Bilgiler',
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Ad Soyad', prefixIcon: Icon(Icons.person)),
                  validator: (value) => (value?.isEmpty ?? true) ? 'Ad soyad giriniz' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Yaş', prefixIcon: Icon(Icons.cake)),
                  validator: (value) {
                    final age = int.tryParse(value ?? '');
                    return (age == null || age <= 0) ? 'Geçerli bir yaş giriniz' : null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: 'Cinsiyet', prefixIcon: Icon(Icons.wc)),
                  items: _genderOptions.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
                  onChanged: (value) => setState(() => _gender = value!),
                ),
              ],
            ),

            const SizedBox(height: 16),
            
            _buildSectionCard(
              title: '📏 Fiziksel Özellikler',
              children: [
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Kilo (kg)', prefixIcon: Icon(Icons.monitor_weight)),
                  onChanged: (value) => setState(() {}), // Kilo değiştikçe BMI'yi anında güncellemek için
                  validator: (value) {
                    final weight = double.tryParse(value ?? '');
                    return (weight == null || weight <= 0) ? 'Geçerli bir kilo giriniz' : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Boy (cm)', prefixIcon: Icon(Icons.height)),
                  onChanged: (value) => setState(() {}), // Boy değiştikçe BMI'yi anında güncellemek için
                  validator: (value) {
                    final height = double.tryParse(value ?? '');
                    return (height == null || height <= 0) ? 'Geçerli bir boy giriniz' : null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _activityLevel,
                  decoration: const InputDecoration(labelText: 'Aktivite Seviyesi', prefixIcon: Icon(Icons.fitness_center)),
                  items: _activityLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
                  onChanged: (value) => setState(() => _activityLevel = value!),
                ),
              ],
            ),

            const SizedBox(height: 16),
            
            _buildSectionCard(
              title: '🥗 Beslenme Tercihleri',
              children: [
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.restaurant_menu, color: primaryColor),
                        title: const Text('🍽️ Beslenme Tercihleri'),
                        subtitle: secilenDiyetTurleri.isEmpty 
                          ? const Text('Tercihlerinizi seçin')
                          : Text('${secilenDiyetTurleri.length} seçenek seçildi'),
                        trailing: Icon(isDietSectionExpanded ? Icons.expand_less : Icons.expand_more),
                        onTap: () => setState(() => isDietSectionExpanded = !isDietSectionExpanded),
                      ),
                      if (isDietSectionExpanded)
                        // ... (İçerik aynı, renkler temaya uygun)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...dietTypesWithEmojis.entries.map((entry) {
                                final type = entry.key;
                                final emoji = entry.value;
                                return _buildCheckboxRow(
                                  title: type,
                                  emoji: emoji,
                                  isSelected: secilenDiyetTurleri.contains(type),
                                  onChanged: (isChecked) {
                                    setState(() {
                                      if (isChecked == true) secilenDiyetTurleri.add(type);
                                      else secilenDiyetTurleri.remove(type);
                                    });
                                  },
                                  color: primaryColor,
                                );
                              }),
                              _buildCheckboxRow(
                                title: 'Diğer',
                                emoji: '✏️',
                                isSelected: digerDiyetTuruSecili,
                                onChanged: (isChecked) => setState(() => digerDiyetTuruSecili = isChecked ?? false),
                                color: primaryColor,
                              ),
                              if (digerDiyetTuruSecili)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TextFormField(
                                    controller: _digerDiyetTuruController,
                                    decoration: const InputDecoration(labelText: 'Lütfen belirtin', border: OutlineInputBorder(), isDense: true),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            
            _buildSectionCard(
              title: '⚠️ Alerjiler',
              children: [
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.warning, color: Colors.orange.shade700),
                        title: const Text('⚠️ Alerjileriniz'),
                        subtitle: secilenAlerjiler.isEmpty 
                          ? const Text('Varsa seçin (isteğe bağlı)')
                          : Text('${secilenAlerjiler.length} alerji seçildi'),
                        trailing: Icon(isAllergySectionExpanded ? Icons.expand_less : Icons.expand_more),
                        onTap: () => setState(() => isAllergySectionExpanded = !isAllergySectionExpanded),
                      ),
                      if (isAllergySectionExpanded)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...allergiesWithEmojis.entries.map((entry) {
                                final allergen = entry.key;
                                final emoji = entry.value;
                                return _buildCheckboxRow(
                                  title: allergen,
                                  emoji: emoji,
                                  isSelected: secilenAlerjiler.contains(allergen),
                                  onChanged: (isChecked) {
                                    setState(() {
                                      if (isChecked == true) secilenAlerjiler.add(allergen);
                                      else secilenAlerjiler.remove(allergen);
                                    });
                                  },
                                  color: Colors.orange.shade700,
                                );
                              }),
                              _buildCheckboxRow(
                                title: 'Diğer',
                                emoji: '✏️',
                                isSelected: digerAlerjiSecili,
                                onChanged: (isChecked) => setState(() => digerAlerjiSecili = isChecked ?? false),
                                color: Colors.orange.shade700,
                              ),
                              if (digerAlerjiSecili)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TextFormField(
                                    controller: _digerAlerjiController,
                                    decoration: const InputDecoration(labelText: 'Lütfen belirtin', border: OutlineInputBorder(), isDense: true),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            
            _buildSectionCard(
              title: '🩸 Kan Tahlili Sonuçları',
              children: [
                if (_isUploading)
                  Center(child: CircularProgressIndicator(color: primaryColor))
                else if (_bloodTestImageUrl != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_bloodTestImageUrl!)),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Değiştir'),
                          onPressed: _pickAndUploadBloodTest,
                        ),
                      )
                    ],
                  )
                else
                  ListTile(
                    leading: Icon(Icons.upload_file_rounded, color: primaryColor),
                    title: const Text('Kan Tahlili Sonuçlarını Yükle'),
                    subtitle: const Text('PDF veya resim formatında yükleyin'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _pickAndUploadBloodTest,
                  ),
              ],
            ),
            
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                      SizedBox(width: 12),
                      Text('Kaydediliyor...'),
                    ],
                  )
                : const Text('💾 Profili Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  // --- YENİ EKLENDİ: TEKRAR KULLANILABİLİR CHECKBOX SATIRI ---
  Widget _buildCheckboxRow({
    required String title,
    required String emoji,
    required bool isSelected,
    required ValueChanged<bool?> onChanged,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CheckboxListTile(
        activeColor: color,
        title: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        value: isSelected,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        onChanged: onChanged,
      ),
    );
  }
}