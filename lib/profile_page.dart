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

  // Beslenme ve alerji seçimleri
  List<String> secilenDiyetTurleri = [];
  List<String> secilenAlerjiler = [];
  
  // Açılır/kapanır bölümler için kontroller
  bool isDietSectionExpanded = false;
  bool isAllergySectionExpanded = false;
  
  // Emoji'li beslenme türü listesi
  final Map<String, String> dietTypesWithEmojis = {
    'Dengeli': '⚖️',
    'Vegan': '🌱',
    'Vejetaryen': '🥗',
    'Ketojenik': '🥑',
    'Akdeniz Diyeti': '🫒',
    'Yüksek Protein': '🥩',
    'Düşük Karbonhidrat': '🥬',
    'Şekersiz': '🚫',
    'Karnivor': '🥩',
  };
  
  // Emoji'li alerji listesi
  final Map<String, String> allergiesWithEmojis = {
    'Gluten': '🌾',
    'Laktoz': '🥛',
    'Yumurta': '🥚',
    'Soya': '🫘',
    'Fıstık': '🥜',
    'Ceviz, Badem vb. (Ağaç Kuruyemişleri)': '🌰',
    'Deniz Ürünleri (Balık, Kabuklular)': '🐟',
    'Hardal': '🟡',
    'Susam': '🌻',
  };
  
  // "Diğer" seçenekleri için kontroller
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
            _gender = data['gender'] ?? 'Erkek';
            _activityLevel = data['activityLevel'] ?? 'Orta';
            
            // Beslenme türlerini yükle
            if (data['dietTypes'] != null) {
              secilenDiyetTurleri = List<String>.from(data['dietTypes']);
            } else if (data['dietType'] != null) {
              // Eski tek seçim formatından yeni çoklu seçim formatına geçiş
              secilenDiyetTurleri = [data['dietType']];
            }
            
            // Alerjileri yükle
            if (data['allergies'] != null) {
              if (data['allergies'] is List) {
                secilenAlerjiler = List<String>.from(data['allergies']);
              } else {
                // Eski string formatından yeni liste formatına geçiş
                _allergiesController.text = data['allergies'];
              }
            }
            
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
        // "Diğer" seçenekleri için kontroller
        if (digerDiyetTuruSecili && _digerDiyetTuruController.text.isNotEmpty) {
          secilenDiyetTurleri.add(_digerDiyetTuruController.text);
        }
        if (digerAlerjiSecili && _digerAlerjiController.text.isNotEmpty) {
          secilenAlerjiler.add(_digerAlerjiController.text);
        }
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
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
                        bmi.toStringAsFixed(1),
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

            // Modern Beslenme Tercihleri
            _buildSectionCard(
              title: '🥗 Beslenme Tercihleri',
              children: [
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.restaurant_menu, color: Colors.green),
                        title: const Text('🍽️ Beslenme Tercihleri'),
                        subtitle: secilenDiyetTurleri.isEmpty 
                            ? const Text('Tercihlerinizi seçin')
                            : Text('${secilenDiyetTurleri.length} seçenek seçildi'),
                        trailing: Icon(isDietSectionExpanded ? Icons.expand_less : Icons.expand_more),
                        onTap: () {
                          setState(() {
                            isDietSectionExpanded = !isDietSectionExpanded;
                          });
                        },
                      ),
                      if (isDietSectionExpanded)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Beslenme türlerinizi seçin:', 
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              ...dietTypesWithEmojis.entries.map((entry) {
                                final type = entry.key;
                                final emoji = entry.value;
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  decoration: BoxDecoration(
                                    color: secilenDiyetTurleri.contains(type) 
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: CheckboxListTile(
                                    title: Row(
                                      children: [
                                        Text(emoji, style: const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 8),
                                        Text(type),
                                      ],
                                    ),
                                    value: secilenDiyetTurleri.contains(type),
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    onChanged: (bool? isChecked) {
                                      setState(() {
                                        if (isChecked == true) {
                                          secilenDiyetTurleri.add(type);
                                        } else {
                                          secilenDiyetTurleri.remove(type);
                                        }
                                      });
                                    },
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: digerDiyetTuruSecili 
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CheckboxListTile(
                                  title: const Row(
                                    children: [
                                      Text('✏️', style: TextStyle(fontSize: 18)),
                                      SizedBox(width: 8),
                                      Text('Diğer'),
                                    ],
                                  ),
                                  value: digerDiyetTuruSecili,
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  onChanged: (bool? isChecked) {
                                    setState(() {
                                      digerDiyetTuruSecili = isChecked ?? false;
                                    });
                                  },
                                ),
                              ),
                              if (digerDiyetTuruSecili)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TextFormField(
                                    controller: _digerDiyetTuruController,
                                    decoration: const InputDecoration(
                                      labelText: 'Lütfen belirtin',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
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

            // Modern Alerjiler
            _buildSectionCard(
              title: '⚠️ Alerjiler',
              children: [
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.warning, color: Colors.orange),
                        title: const Text('⚠️ Alerjileriniz'),
                        subtitle: secilenAlerjiler.isEmpty 
                            ? const Text('Varsa seçin (isteğe bağlı)')
                            : Text('${secilenAlerjiler.length} alerji seçildi'),
                        trailing: Icon(isAllergySectionExpanded ? Icons.expand_less : Icons.expand_more),
                        onTap: () {
                          setState(() {
                            isAllergySectionExpanded = !isAllergySectionExpanded;
                          });
                        },
                      ),
                      if (isAllergySectionExpanded)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Alerjilerinizi seçin:', 
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              ...allergiesWithEmojis.entries.map((entry) {
                                final allergen = entry.key;
                                final emoji = entry.value;
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  decoration: BoxDecoration(
                                    color: secilenAlerjiler.contains(allergen) 
                                        ? Colors.orange.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: CheckboxListTile(
                                    title: Row(
                                      children: [
                                        Text(emoji, style: const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(allergen)),
                                      ],
                                    ),
                                    value: secilenAlerjiler.contains(allergen),
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    onChanged: (bool? isChecked) {
                                      setState(() {
                                        if (isChecked == true) {
                                          secilenAlerjiler.add(allergen);
                                        } else {
                                          secilenAlerjiler.remove(allergen);
                                        }
                                      });
                                    },
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: digerAlerjiSecili 
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CheckboxListTile(
                                  title: const Row(
                                    children: [
                                      Text('✏️', style: TextStyle(fontSize: 18)),
                                      SizedBox(width: 8),
                                      Text('Diğer'),
                                    ],
                                  ),
                                  value: digerAlerjiSecili,
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  onChanged: (bool? isChecked) {
                                    setState(() {
                                      digerAlerjiSecili = isChecked ?? false;
                                    });
                                  },
                                ),
                              ),
                              if (digerAlerjiSecili)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TextFormField(
                                    controller: _digerAlerjiController,
                                    decoration: const InputDecoration(
                                      labelText: 'Lütfen belirtin',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
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
