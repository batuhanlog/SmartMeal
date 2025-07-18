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
  
  // Form kontrolcüleri
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _digerDiyetTuruController = TextEditingController();
  final _digerAlerjiController = TextEditingController();

  String gender = 'Erkek';
  List<String> secilenDiyetTurleri = [];
  List<String> secilenAlerjiler = [];
  bool digerDiyetTuruSecili = false;
  bool digerAlerjiSecili = false;
  bool isDietSectionExpanded = false;
  bool isAllergySectionExpanded = false;

  // Emojili beslenme türleri
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

  // Emojili alerjiler
  final Map<String, String> allergiesWithEmojis = {
    'Gluten': '🌾',
    'Laktoz': '🥛',
    'Yumurta': '🥚',
    'Soya': '🫘',
    'Fıstık': '🥜',
    'Ceviz, Badem vb.': '🌰',
    'Deniz Ürünleri': '🐟',
    'Hardal': '🟡',
    'Susam': '🌻',
  };

  // Renk teması
  Color get primaryColor => Colors.red.shade700;
  Color get backgroundColor => Colors.grey.shade50;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _digerDiyetTuruController.dispose();
    _digerAlerjiController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
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
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          if (mounted) {
            LoadingDialog.hide(context);
            ErrorHandler.showSuccess(context, 'Başarıyla giriş yapıldı!');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else {
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          
          if (digerAlerjiSecili && _digerAlerjiController.text.isNotEmpty) {
            secilenAlerjiler.add(_digerAlerjiController.text);
          }
          
          if (digerDiyetTuruSecili && _digerDiyetTuruController.text.isNotEmpty) {
            secilenDiyetTurleri.add(_digerDiyetTuruController.text);
          }

          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'email': _emailController.text.trim(),
            'name': _nameController.text,
            'age': int.tryParse(_ageController.text) ?? 0,
            'weight': double.tryParse(_weightController.text) ?? 0,
            'height': double.tryParse(_heightController.text) ?? 0,
            'gender': gender,
            'dietTypes': secilenDiyetTurleri,
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(isLogin ? '🔐 Giriş Yap' : '🌟 Hesap Oluştur'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLogin ? _buildLoginForm() : _buildSignupForm(),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Logo/Başlık
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'SmartMeal\'e Hoş Geldiniz',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sağlıklı beslenme yolculuğunuz başlasın!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // E-posta alanı
          _buildModernTextField(
            controller: _emailController,
            icon: Icons.email,
            label: 'E-posta',
            keyboardType: TextInputType.emailAddress,
            validator: (val) => val!.isEmpty ? 'E-posta girin' : null,
          ),
          
          const SizedBox(height: 16),
          
          // Şifre alanı
          _buildModernTextField(
            controller: _passwordController,
            icon: Icons.lock,
            label: 'Şifre',
            obscureText: true,
            validator: (val) => val!.length < 6 ? 'En az 6 karakter' : null,
          ),
          
          const SizedBox(height: 32),
          
          // Giriş butonu
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Giriş Yap',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade400)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'veya',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade400)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Google ile giriş
          ElevatedButton.icon(
            onPressed: _signInWithGoogle,
            icon: const Icon(Icons.account_circle, color: Colors.white),
            label: const Text(
              'Google ile Giriş Yap',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Kayıt ol linki
          TextButton(
            onPressed: () => setState(() => isLogin = false),
            child: RichText(
              text: TextSpan(
                text: 'Hesabın yok mu? ',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                children: [
                  TextSpan(
                    text: 'Kayıt Ol',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.person_add,
                  size: 80,
                  color: primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Hesap Oluştur',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kişiselleştirilmiş beslenme deneyimi için bilgilerinizi girin',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Kişisel bilgiler bölümü
          _buildSectionCard(
            title: '👤 Kişisel Bilgiler',
            children: [
              _buildModernTextField(
                controller: _nameController,
                icon: Icons.person,
                label: 'Ad Soyad',
                validator: (val) => val!.isEmpty ? 'Ad soyad girin' : null,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _emailController,
                icon: Icons.email,
                label: 'E-posta',
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val!.isEmpty ? 'E-posta girin' : null,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _passwordController,
                icon: Icons.lock,
                label: 'Şifre',
                obscureText: true,
                validator: (val) => val!.length < 6 ? 'En az 6 karakter' : null,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Fiziksel bilgiler bölümü
          _buildSectionCard(
            title: '📊 Fiziksel Bilgiler',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _ageController,
                      icon: Icons.cake,
                      label: 'Yaş',
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Yaş girin' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: gender,
                      decoration: InputDecoration(
                        labelText: 'Cinsiyet',
                        prefixIcon: Icon(Icons.people, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: ['Erkek', 'Kadın']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) => setState(() => gender = val ?? 'Erkek'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _weightController,
                      icon: Icons.fitness_center,
                      label: 'Kilo (kg)',
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Kilo girin' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _heightController,
                      icon: Icons.height,
                      label: 'Boy (cm)',
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Boy girin' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Beslenme tercihleri bölümü
          _buildSectionCard(
            title: '🥗 Beslenme Tercihleri',
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.restaurant_menu, color: primaryColor),
                      title: const Text('Beslenme Tercihleri'),
                      subtitle: secilenDiyetTurleri.isEmpty
                          ? const Text('Tercihlerinizi seçin')
                          : Text('${secilenDiyetTurleri.length} seçenek seçildi'),
                      trailing: Icon(
                        isDietSectionExpanded ? Icons.expand_less : Icons.expand_more,
                        color: primaryColor,
                      ),
                      onTap: () => setState(() => isDietSectionExpanded = !isDietSectionExpanded),
                    ),
                    if (isDietSectionExpanded) ...[
                      const Divider(height: 1),
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ...dietTypesWithEmojis.entries.map((entry) {
                              final type = entry.key;
                              final emoji = entry.value;
                              return _buildModernCheckboxRow(
                                title: type,
                                emoji: emoji,
                                isSelected: secilenDiyetTurleri.contains(type),
                                onChanged: (isChecked) {
                                  setState(() {
                                    if (isChecked == true) {
                                      secilenDiyetTurleri.add(type);
                                    } else {
                                      secilenDiyetTurleri.remove(type);
                                    }
                                  });
                                },
                                color: primaryColor,
                              );
                            }),
                            _buildModernCheckboxRow(
                              title: 'Diğer',
                              emoji: '✏️',
                              isSelected: digerDiyetTuruSecili,
                              onChanged: (isChecked) => setState(() => digerDiyetTuruSecili = isChecked ?? false),
                              color: primaryColor,
                            ),
                            if (digerDiyetTuruSecili) ...[
                              const SizedBox(height: 8),
                              _buildModernTextField(
                                controller: _digerDiyetTuruController,
                                icon: Icons.edit,
                                label: 'Lütfen belirtin',
                                validator: (val) {
                                  if (digerDiyetTuruSecili && (val == null || val.isEmpty)) {
                                    return 'Lütfen beslenme türünü belirtin';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Alerjiler bölümü
          _buildSectionCard(
            title: '⚠️ Alerjiler',
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.warning, color: Colors.orange.shade700),
                      title: const Text('Alerjileriniz'),
                      subtitle: secilenAlerjiler.isEmpty
                          ? const Text('Varsa seçin (isteğe bağlı)')
                          : Text('${secilenAlerjiler.length} alerji seçildi'),
                      trailing: Icon(
                        isAllergySectionExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.orange.shade700,
                      ),
                      onTap: () => setState(() => isAllergySectionExpanded = !isAllergySectionExpanded),
                    ),
                    if (isAllergySectionExpanded) ...[
                      const Divider(height: 1),
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ...allergiesWithEmojis.entries.map((entry) {
                              final allergen = entry.key;
                              final emoji = entry.value;
                              return _buildModernCheckboxRow(
                                title: allergen,
                                emoji: emoji,
                                isSelected: secilenAlerjiler.contains(allergen),
                                onChanged: (isChecked) {
                                  setState(() {
                                    if (isChecked == true) {
                                      secilenAlerjiler.add(allergen);
                                    } else {
                                      secilenAlerjiler.remove(allergen);
                                    }
                                  });
                                },
                                color: Colors.orange.shade700,
                              );
                            }),
                            _buildModernCheckboxRow(
                              title: 'Diğer',
                              emoji: '✏️',
                              isSelected: digerAlerjiSecili,
                              onChanged: (isChecked) => setState(() => digerAlerjiSecili = isChecked ?? false),
                              color: Colors.orange.shade700,
                            ),
                            if (digerAlerjiSecili) ...[
                              const SizedBox(height: 8),
                              _buildModernTextField(
                                controller: _digerAlerjiController,
                                icon: Icons.edit,
                                label: 'Lütfen belirtin',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Kayıt ol butonu
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Hesap Oluştur',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade400)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'veya',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade400)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Google ile kayıt ol
          ElevatedButton.icon(
            onPressed: _signInWithGoogle,
            icon: const Icon(Icons.account_circle, color: Colors.white),
            label: const Text(
              'Google ile Kayıt Ol',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Giriş yap linki
          TextButton(
            onPressed: () => setState(() => isLogin = true),
            child: RichText(
              text: TextSpan(
                text: 'Zaten hesabın var mı? ',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                children: [
                  TextSpan(
                    text: 'Giriş Yap',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildModernCheckboxRow({
    required String title,
    required String emoji,
    required bool isSelected,
    required ValueChanged<bool?> onChanged,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onChanged(!isSelected),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? color : Colors.grey.shade800,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: onChanged,
                activeColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}