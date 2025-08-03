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

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  // Modern Renkli Tema
  static const Color _primaryColor = Color(0xFF667EEA);
  static const Color _secondaryColor = Color(0xFF764BA2);
  static const Color _accentColor = Color(0xFF4CAF50);
  static const Color _errorColor = Color(0xFFE74C3C);
  static const Color _successColor = Color(0xFF27AE60);
  static const Color _backgroundColor = Color(0xFFF5F7FA);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF2C3E50);
  static const Color _subtleTextColor = Color(0xFF7F8C8D);

  bool isLogin = true;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Form kontrolcüleri - Giriş
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _emailController = TextEditingController(); // Eksik olan controller
  final _passwordController = TextEditingController(); // Eksik olan controller
  
  // Form kontrolcüleri - Kayıt
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _digerDiyetTuruController = TextEditingController(); // Eksik olan controller
  final _digerAlerjiController = TextEditingController(); // Eksik olan controller

  String gender = 'Erkek';
  List<String> secilenDiyetTurleri = [];
  List<String> secilenAlerjiler = [];
  bool isDietSectionExpanded = false;
  bool isAllergySectionExpanded = false;
  bool digerDiyetTuruSecili = false; // Eksik olan değişken
  bool digerAlerjiSecili = false; // Eksik olan değişken

  final Map<String, String> dietTypesWithEmojis = {
    'Dengeli': '⚖️', 'Vegan': '🌱', 'Vejetaryen': '🥗', 'Ketojenik': '🥑', 'Akdeniz Diyeti': '🫒',
    'Yüksek Protein': '🥩', 'Düşük Karbonhidrat': '🥬', 'Şekersiz': '🚫', 'Karnivor': '🥩',
  };

  final Map<String, String> allergiesWithEmojis = {
    'Gluten': '🌾', 'Laktoz': '🥛', 'Yumurta': '🥚', 'Soya': '🫘', 'Fıstık': '🥜',
    'Ceviz, Badem vb.': '🌰', 'Deniz Ürünleri': '🐟', 'Hardal': '🟡', 'Susam': '🌻',
  };
  
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
    setState(() {
      isLoading = true;
    });
    
    try {
      final userCredential = await GoogleSignInService.signInWithGoogle();
      
      if (userCredential != null && mounted) {
        ErrorHandler.showSuccess(context, 'Başarıyla giriş yapıldı!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(
          context, 
          ErrorHandler.getFriendlyErrorMessage(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        isLoading = true;
      });
      
      try {
        if (isLogin) {
          // 🔑 E-posta/Şifre ile giriş işlemi
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

          if (mounted) {
            ErrorHandler.showSuccess(context, 'Başarıyla giriş yapıldı!');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }

        } else {
          // 👤 Kayıt işlemi (isteğe bağlı)
        }

      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(
            context,
            ErrorHandler.getFriendlyErrorMessage(e.toString()),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(isLogin ? '🔐 Giriş Yap' : '🌟 Hesap Oluştur'),
        backgroundColor: _primaryColor,
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
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.restaurant_menu, size: 80, color: _primaryColor),
                const SizedBox(height: 16),
                const Text('Smeal\'e Hoş Geldiniz', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryColor)),
                const SizedBox(height: 8),
                const Text('Sağlıklı beslenme yolculuğunuz başlasın!', style: TextStyle(fontSize: 16, color: _subtleTextColor), textAlign: TextAlign.center),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          _buildModernTextField(
            controller: _emailController, icon: Icons.email, label: 'E-posta', keyboardType: TextInputType.emailAddress,
            validator: (val) => val!.isEmpty ? 'E-posta girin' : null,
          ),
          
          const SizedBox(height: 16),
          
          _buildModernTextField(
            controller: _passwordController, icon: Icons.lock, label: 'Şifre', obscureText: true,
            validator: (val) => val!.length < 6 ? 'En az 6 karakter' : null,
          ),
          
          const SizedBox(height: 32),
          
          ElevatedButton(
            // *** DÜZELTME: Fonksiyon çağrısı eski haline getirildi ***
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: const Text('Giriş Yap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('veya', style: TextStyle(color: _subtleTextColor)),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          OutlinedButton.icon(
            onPressed: _signInWithGoogle,
            icon: Image.asset('assets/images/google_logo.png', height: 22, width: 22),
            label: const Text('Google ile Devam Et', style: TextStyle(color: _textColor, fontSize: 16, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade300),
              backgroundColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          TextButton(
            onPressed: () => setState(() => isLogin = false),
            child: RichText(
              text: TextSpan( // *** DÜZELTME: const kaldırıldı ***
                text: 'Hesabın yok mu? ',
                style: const TextStyle(color: _subtleTextColor, fontSize: 16, fontFamily: 'System'),
                children: const [
                  TextSpan(
                    text: 'Kayıt Ol',
                    style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
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
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.person_add, size: 80, color: _primaryColor),
                const SizedBox(height: 16),
                const Text('Hesap Oluştur', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryColor)),
                const SizedBox(height: 8),
                const Text('Kişiselleştirilmiş beslenme deneyimi için bilgilerinizi girin', style: TextStyle(fontSize: 16, color: _subtleTextColor), textAlign: TextAlign.center),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildSectionCard(
            title: '👤 Kişisel Bilgiler',
            children: [
              _buildModernTextField(controller: _nameController, icon: Icons.person, label: 'Ad Soyad', validator: (val) => val!.isEmpty ? 'Ad soyad girin' : null),
              const SizedBox(height: 16),
              _buildModernTextField(controller: _emailController, icon: Icons.email, label: 'E-posta', keyboardType: TextInputType.emailAddress, validator: (val) => val!.isEmpty ? 'E-posta girin' : null),
              const SizedBox(height: 16),
              _buildModernTextField(controller: _passwordController, icon: Icons.lock, label: 'Şifre', obscureText: true, validator: (val) => val!.length < 6 ? 'En az 6 karakter' : null),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSectionCard(
            title: '📊 Fiziksel Bilgiler',
            children: [
              Row(children: [
                Expanded(child: _buildModernTextField(controller: _ageController, icon: Icons.cake, label: 'Yaş', keyboardType: TextInputType.number, validator: (val) => val!.isEmpty ? 'Yaş girin' : null)),
                const SizedBox(width: 16),
                Expanded(child: DropdownButtonFormField<String>(
                  value: gender,
                  decoration: InputDecoration(labelText: 'Cinsiyet', prefixIcon: const Icon(Icons.people, color: _primaryColor), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300))),
                  items: ['Erkek', 'Kadın'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setState(() => gender = val ?? 'Erkek'),
                )),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _buildModernTextField(controller: _weightController, icon: Icons.fitness_center, label: 'Kilo (kg)', keyboardType: TextInputType.number, validator: (val) => val!.isEmpty ? 'Kilo girin' : null)),
                const SizedBox(width: 16),
                Expanded(child: _buildModernTextField(controller: _heightController, icon: Icons.height, label: 'Boy (cm)', keyboardType: TextInputType.number, validator: (val) => val!.isEmpty ? 'Boy girin' : null)),
              ]),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSectionCard(
            title: '🥗 Beslenme Tercihleri',
            children: [
              Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.restaurant_menu, color: _primaryColor),
                    title: const Text('Beslenme Tercihleri'),
                    subtitle: secilenDiyetTurleri.isEmpty ? const Text('Tercihlerinizi seçin') : Text('${secilenDiyetTurleri.length} seçenek seçildi'),
                    trailing: const Icon(Icons.expand_more, color: _primaryColor),
                    onTap: () => setState(() => isDietSectionExpanded = !isDietSectionExpanded),
                  ),
                  if (isDietSectionExpanded)
                    Container(padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        ...dietTypesWithEmojis.entries.map((entry) => _buildModernCheckboxRow(
                          title: entry.key, emoji: entry.value, isSelected: secilenDiyetTurleri.contains(entry.key),
                          onChanged: (isChecked) { setState(() { if (isChecked == true) secilenDiyetTurleri.add(entry.key); else secilenDiyetTurleri.remove(entry.key); }); },
                          color: _primaryColor,
                        )),
                        _buildModernCheckboxRow(
                          title: 'Diğer', emoji: '✏️', isSelected: digerDiyetTuruSecili,
                          onChanged: (isChecked) => setState(() => digerDiyetTuruSecili = isChecked ?? false),
                          color: _primaryColor,
                        ),
                        if (digerDiyetTuruSecili)
                          _buildModernTextField(controller: _digerDiyetTuruController, icon: Icons.edit, label: 'Lütfen belirtin', validator: (val) => digerDiyetTuruSecili && (val == null || val.isEmpty) ? 'Lütfen beslenme türünü belirtin' : null),
                      ]),
                    ),
                ]),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSectionCard(
            title: '⚠️ Alerjiler',
            children: [
              Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: _primaryColor),
                    title: const Text('Alerjileriniz'),
                    subtitle: secilenAlerjiler.isEmpty ? const Text('Varsa seçin (isteğe bağlı)') : Text('${secilenAlerjiler.length} alerji seçildi'),
                    trailing: const Icon(Icons.expand_more, color: _primaryColor),
                    onTap: () => setState(() => isAllergySectionExpanded = !isAllergySectionExpanded),
                  ),
                  if (isAllergySectionExpanded)
                    Container(padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        ...allergiesWithEmojis.entries.map((entry) => _buildModernCheckboxRow(
                          title: entry.key, emoji: entry.value, isSelected: secilenAlerjiler.contains(entry.key),
                          onChanged: (isChecked) { setState(() { if (isChecked == true) secilenAlerjiler.add(entry.key); else secilenAlerjiler.remove(entry.key); }); },
                          color: _primaryColor,
                        )),
                        _buildModernCheckboxRow(
                          title: 'Diğer', emoji: '✏️', isSelected: digerAlerjiSecili,
                          onChanged: (isChecked) => setState(() => digerAlerjiSecili = isChecked ?? false),
                          color: _primaryColor,
                        ),
                        if (digerAlerjiSecili)
                          _buildModernTextField(controller: _digerAlerjiController, icon: Icons.edit, label: 'Lütfen belirtin'),
                      ]),
                    ),
                ]),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          ElevatedButton(
            // *** DÜZELTME: Fonksiyon çağrısı eski haline getirildi ***
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: const Text('Hesap Oluştur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('veya', style: TextStyle(color: _subtleTextColor))),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ]),
          const SizedBox(height: 24),
          
          OutlinedButton.icon(
            onPressed: _signInWithGoogle,
            icon: Image.asset('assets/images/google_logo.png', height: 22, width: 22),
            label: const Text('Google ile Devam Et', style: TextStyle(color: _textColor, fontSize: 16, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade300),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => setState(() => isLogin = true),
            child: RichText(
              text: TextSpan( // *** DÜZELTME: const kaldırıldı ***
                text: 'Zaten hesabın var mı? ',
                style: const TextStyle(color: _subtleTextColor, fontSize: 16, fontFamily: 'System'),
                children: const [TextSpan(text: 'Giriş Yap', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold))],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)),
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
        prefixIcon: Icon(icon, color: _primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryColor, width: 2)),
        filled: true,
        fillColor: Colors.white,
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
            border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(fontSize: 16, color: isSelected ? color : _textColor, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
              Checkbox(value: isSelected, onChanged: onChanged, activeColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
            ],
          ),
        ),
      ),
    );
  }
}