import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'services/google_sign_in_service.dart';
import 'services/error_handler.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String name = '';
  int age = 0;
  double weight = 0;
  double height = 0;
  String gender = 'Erkek';
  
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

  @override
  void dispose() {
    _digerAlerjiController.dispose();
    _digerDiyetTuruController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    // ... (Bu fonksiyon değişmedi) ...
    try {
      LoadingDialog.show(context, message: 'Google ile giriş yapılıyor...');
      final userCredential = await GoogleSignInService.signInWithGoogle();
      if (mounted) LoadingDialog.hide(context);
      
      if (userCredential != null && mounted) {
        ErrorHandler.showSuccess(context, 'Başarıyla giriş yapıldı!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        ErrorHandler.showError(
          context, 
          ErrorHandler.getFriendlyErrorMessage(e.toString()),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        LoadingDialog.show(context, message: isLogin ? 'Giriş yapılıyor...' : 'Hesap oluşturuluyor...');
        
        if (isLogin) {
          // ... (Giriş yapma bloğu değişmedi) ...
           await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          if (mounted) {
            LoadingDialog.hide(context);
            ErrorHandler.showSuccess(context, 'Başarıyla giriş yapıldı!');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else { // Kayıt olma bloğu
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          if (digerAlerjiSecili && _digerAlerjiController.text.isNotEmpty) {
            secilenAlerjiler.add(_digerAlerjiController.text);
          }
          
          // --- DEĞİŞİKLİK 2: Beslenme Türü Kaydetme Mantığı ---
          // "Diğer" seçiliyse ve metin alanı boş değilse, özel diyet türünü listeye ekle.
          if (digerDiyetTuruSecili && _digerDiyetTuruController.text.isNotEmpty) {
            secilenDiyetTurleri.add(_digerDiyetTuruController.text);
          }

          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'email': email,
            'name': name,
            'age': age,
            'weight': weight,
            'height': height,
            'gender': gender,
            'dietTypes': secilenDiyetTurleri, // <<< DEĞİŞİKLİK! Alan adı çoğul yapıldı ve liste gönderiliyor.
            'activityLevel': 'Orta',
            'allergies': secilenAlerjiler,
            'createdAt': FieldValue.serverTimestamp(),
            'loginMethod': 'email',
          });

          if (mounted) {
            LoadingDialog.hide(context);
            ErrorHandler.showSuccess(context, 'Hesap başarıyla oluşturuldu!');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          LoadingDialog.hide(context);
          ErrorHandler.showError(
            context, 
            ErrorHandler.getFriendlyErrorMessage(e.toString()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isLogin ? '🔐 Giriş Yap' : '📝 Kayıt Ol',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık ve açıklama
              if (!isLogin)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '🍽️ SmartMeal\'e Hoş Geldiniz!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Kişiselleştirilmiş beslenme deneyimi için bilgilerinizi paylaşın',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              
              // Kişisel Bilgiler Kartı
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('👤 Kişisel Bilgiler', 
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!isLogin)
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Ad Soyad',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (val) => name = val ?? '',
                          validator: (val) => val!.isEmpty ? 'Ad Soyad girin' : null,
                        ),
                      if (!isLogin) const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (val) => email = val ?? '',
                        validator: (val) => val!.isEmpty ? 'E-posta girin' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        onSaved: (val) => password = val ?? '',
                        validator: (val) => val!.length < 6 ? 'En az 6 karakter' : null,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Fiziksel Bilgiler Kartı
              if (!isLogin)
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.fitness_center, color: Colors.green),
                            SizedBox(width: 8),
                            Text('📊 Fiziksel Bilgiler', 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Yaş',
                                  prefixIcon: Icon(Icons.cake_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (val) => age = int.tryParse(val ?? '') ?? 0,
                                validator: (val) => val!.isEmpty ? 'Yaş girin' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: gender,
                                decoration: const InputDecoration(
                                  labelText: 'Cinsiyet',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                                items: ['Erkek', 'Kadın'].map((g) => 
                                  DropdownMenuItem(value: g, child: Text(g))).toList(),
                                onChanged: (val) => setState(() => gender = val ?? 'Erkek'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Kilo (kg)',
                                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (val) => weight = double.tryParse(val ?? '') ?? 0,
                                validator: (val) => val!.isEmpty ? 'Kilo girin' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Boy (cm)',
                                  prefixIcon: Icon(Icons.height_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (val) => height = double.tryParse(val ?? '') ?? 0,
                                validator: (val) => val!.isEmpty ? 'Boy girin' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Modern Beslenme Tercihleri Bölümü
              if (!isLogin)
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
                                    validator: (val) {
                                      if (digerDiyetTuruSecili && (val == null || val.isEmpty)) {
                                        return 'Lütfen beslenme türünü belirtin';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              
              // Modern Alerjiler Bölümü
              if (!isLogin)
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
              
              const SizedBox(height: 24),
              
              // Ana Giriş/Kayıt Butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    isLogin ? '🔐 Giriş Yap' : '📝 Kayıt Ol', 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Ayırıcı
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('veya', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Google Giriş Butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: const Text('🔍', style: TextStyle(fontSize: 20)),
                  label: const Text(
                    'Google ile Giriş Yap', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Alt Metin Butonu
              Center(
                child: TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    isLogin ? 'Hesabın yok mu? 📝 Kayıt Ol' : 'Zaten hesabın var mı? 🔐 Giriş Yap',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}