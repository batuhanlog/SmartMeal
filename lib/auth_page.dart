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
  
  // --- DEĞİŞİKLİK 1: 'dietType' artık bir liste ---
  // Tek bir String yerine, seçilen birden çok beslenme türünü tutacak bir liste oluşturuyoruz.
  List<String> secilenDiyetTurleri = [];
  
  // Beslenme türü listesi
  final dietTypes = ['Dengeli', 'Vegan', 'Vejetaryen', 'Ketojenik', 'Akdeniz Diyeti', 'Yüksek Protein', 'Düşük Karbonhidrat', 'Şekersiz', 'Karnivor'];
  
  // "Diğer" beslenme türü için değişkenler
  bool digerDiyetTuruSecili = false;
  final _digerDiyetTuruController = TextEditingController();

  // Alerji değişkenleri (Aynen kalıyor)
  final List<String> tumAlerjenler = [
    'Gluten', 'Laktoz', 'Yumurta', 'Soya', 'Fıstık',
    'Ceviz, Badem vb. (Ağaç Kuruyemişleri)', 'Deniz Ürünleri (Balık, Kabuklular)',
    'Hardal', 'Susam'
  ];
  List<String> secilenAlerjiler = [];
  bool digerAlerjiSecili = false;
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
      appBar: AppBar(title: Text(isLogin ? 'Giriş Yap' : 'Kayıt Ol')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ... (Diğer alanlar aynı kalıyor) ...
              if (!isLogin)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Ad Soyad'),
                  onSaved: (val) => name = val ?? '',
                  validator: (val) => val!.isEmpty ? 'Ad Soyad girin' : null,
                ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'E-posta'),
                onSaved: (val) => email = val ?? '',
                validator: (val) => val!.isEmpty ? 'E-posta girin' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Şifre'),
                obscureText: true,
                onSaved: (val) => password = val ?? '',
                validator: (val) => val!.length < 6 ? 'En az 6 karakter' : null,
              ),
              if (!isLogin)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Yaş'),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => age = int.tryParse(val ?? '') ?? 0,
                  validator: (val) => val!.isEmpty ? 'Yaş girin' : null,
                ),
              if (!isLogin)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Kilo (kg)'),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => weight = double.tryParse(val ?? '') ?? 0,
                  validator: (val) => val!.isEmpty ? 'Kilo girin' : null,
                ),
              if (!isLogin)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Boy (cm)'),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => height = double.tryParse(val ?? '') ?? 0,
                  validator: (val) => val!.isEmpty ? 'Boy girin' : null,
                ),
              if (!isLogin)
                DropdownButtonFormField<String>(
                  value: gender,
                  items: ['Erkek', 'Kadın'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setState(() => gender = val ?? 'Erkek'),
                  decoration: const InputDecoration(labelText: 'Cinsiyet'),
                ),

              // --- DEĞİŞİKLİK 3: ARAYÜZÜ GÜNCELLEME ---
              // Radyo butonları, çoklu seçim için onay kutuları ile değiştirildi.
              if (!isLogin)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text('Beslenme Tercihleri:', style: TextStyle(fontSize: 16)),
                    ...dietTypes.map((type) {
                      return CheckboxListTile(
                        title: Text(type),
                        value: secilenDiyetTurleri.contains(type),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (bool? isChecked) {
                          setState(() {
                            if (isChecked == true) {
                              secilenDiyetTurleri.add(type);
                            } else {
                              secilenDiyetTurleri.remove(type);
                            }
                          });
                        },
                      );
                    }),
                    CheckboxListTile(
                      title: const Text('Diğer'),
                      value: digerDiyetTuruSecili,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool? isChecked) {
                        setState(() {
                          digerDiyetTuruSecili = isChecked ?? false;
                        });
                      },
                    ),
                    if (digerDiyetTuruSecili)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                        child: TextFormField(
                          controller: _digerDiyetTuruController,
                          decoration: const InputDecoration(
                            labelText: 'Lütfen belirtin',
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
              
              // Alerji seçimi 
              if (!isLogin)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text('Alerjileriniz (Varsa seçin):', style: TextStyle(fontSize: 16)),
                    ...tumAlerjenler.map((String tekBirAlerjen) {
                      return CheckboxListTile(
                        title: Text(tekBirAlerjen),
                        value: secilenAlerjiler.contains(tekBirAlerjen),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (bool? secildiMi) {
                          setState(() {
                            if (secildiMi == true) {
                              secilenAlerjiler.add(tekBirAlerjen);
                            } else {
                              secilenAlerjiler.remove(tekBirAlerjen);
                            }
                          });
                        },
                      );
                    }).toList(),
                    CheckboxListTile(
                      title: const Text("Diğer"),
                      value: digerAlerjiSecili,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool? isChecked) {
                        setState(() {
                          digerAlerjiSecili = isChecked ?? false;
                        });
                      },
                    ),
                    if (digerAlerjiSecili)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                        child: TextFormField(
                          controller: _digerAlerjiController,
                          decoration: const InputDecoration(labelText: 'Lütfen belirtin', isDense: true),
                        ),
                      ),
                  ],
                ),
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isLogin ? 'Giriş Yap' : 'Kayıt Ol', style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: const Icon(Icons.account_circle, color: Colors.white),
                label: const Text('Google ile Giriş Yap', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? 'Hesabın yok mu? Kayıt Ol' : 'Zaten hesabın var mı? Giriş Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}