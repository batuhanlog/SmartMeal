import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  String _gender = 'Erkek';
  String _dietType = 'Dengeli';
  String _activityLevel = 'Orta';
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _genderOptions = ['Erkek', 'Kadın', 'Belirtmek istemiyorum'];
  final List<String> _dietTypes = ['Dengeli', 'Vegan', 'Vejetaryen', 'Ketojenik', 'Glutensiz', 'Mediteran'];
  final List<String> _activityLevels = ['Düşük', 'Orta', 'Yüksek', 'Çok Yüksek'];

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
        
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _ageController.text = (data['age'] ?? '').toString();
            _weightController.text = (data['weight'] ?? '').toString();
            _heightController.text = (data['height'] ?? '').toString();
            _allergiesController.text = data['allergies'] ?? '';
            _gender = data['gender'] ?? 'Erkek';
            _dietType = data['dietType'] ?? 'Dengeli';
            _activityLevel = data['activityLevel'] ?? 'Orta';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ErrorHandler.showError(context, 'Profil bilgileri yüklenirken hata oluştu');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'name': _nameController.text,
          'age': int.tryParse(_ageController.text) ?? 0,
          'weight': double.tryParse(_weightController.text) ?? 0,
          'height': double.tryParse(_heightController.text) ?? 0,
          'allergies': _allergiesController.text,
          'gender': _gender,
          'dietType': _dietType,
          'activityLevel': _activityLevel,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ErrorHandler.showSuccess(context, 'Profil başarıyla güncellendi!');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Profil güncellenirken hata oluştu');
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
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
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bmi = _calculateBMI();

    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 Profil Düzenle'),
        backgroundColor: Colors.purple.shade300,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
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
            // BMI Card
            if (bmi > 0) ...[
              Card(
                color: _getBMIColor(bmi).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '📊 BMI Durumunuz',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getBMIColor(bmi),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${bmi.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _getBMIColor(bmi),
                        ),
                      ),
                      Text(
                        _getBMICategory(bmi),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _getBMIColor(bmi),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Kişisel Bilgiler
            _buildSectionCard(
              title: '👤 Kişisel Bilgiler',
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Ad soyad giriniz';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Yaş',
                    prefixIcon: Icon(Icons.cake),
                  ),
                  validator: (value) {
                    final age = int.tryParse(value ?? '');
                    if (age == null || age <= 0) return 'Geçerli bir yaş giriniz';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Cinsiyet',
                    prefixIcon: Icon(Icons.wc),
                  ),
                  items: _genderOptions.map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _gender = value!;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Fiziksel Özellikler
            _buildSectionCard(
              title: '📏 Fiziksel Özellikler',
              children: [
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Kilo (kg)',
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                  validator: (value) {
                    final weight = double.tryParse(value ?? '');
                    if (weight == null || weight <= 0) return 'Geçerli bir kilo giriniz';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Boy (cm)',
                    prefixIcon: Icon(Icons.height),
                  ),
                  validator: (value) {
                    final height = double.tryParse(value ?? '');
                    if (height == null || height <= 0) return 'Geçerli bir boy giriniz';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _activityLevel,
                  decoration: const InputDecoration(
                    labelText: 'Aktivite Seviyesi',
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  items: _activityLevels.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _activityLevel = value!;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Beslenme Tercihleri
            _buildSectionCard(
              title: '🥗 Beslenme Tercihleri',
              children: [
                DropdownButtonFormField<String>(
                  value: _dietType,
                  decoration: const InputDecoration(
                    labelText: 'Beslenme Türü',
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                  items: _dietTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _dietType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _allergiesController,
                  decoration: const InputDecoration(
                    labelText: 'Alerjiler (isteğe bağlı)',
                    prefixIcon: Icon(Icons.warning),
                    hintText: 'Örn: Fıstık, süt ürünleri...',
                  ),
                  maxLines: 2,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Kaydet Butonu
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                        SizedBox(width: 8),
                        Text('Kaydediliyor...'),
                      ],
                    )
                  : const Text(
                      '💾 Profili Kaydet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
