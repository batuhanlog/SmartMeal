import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'services/google_sign_in_service.dart';
import 'services/error_handler.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  // Minimal Modern Tema
  static const Color _primaryColor = Color(0xFF6366F1);
  static const Color _backgroundColor = Colors.white;
  static const Color _textColor = Color(0xFF1F2937);
  static const Color _subtleTextColor = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);

  late TabController _tabController;
  bool isLoading = false;
  
  // Form Keys
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  
  // Login Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  
  // Register Controllers
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _customDietController = TextEditingController();
  final _customAllergyController = TextEditingController();

  String gender = 'Erkek';
  List<String> selectedDietTypes = [];
  List<String> selectedAllergies = [];
  bool isCustomDietSelected = false;
  bool isCustomAllergySelected = false;

  final Map<String, String> dietTypes = {
    'Dengeli': '⚖️', 'Vegan': '🌱', 'Vejetaryen': '🥗', 'Ketojenik': '🥑', 
    'Akdeniz Diyeti': '🫒', 'Yüksek Protein': '🥩', 'Düşük Karbonhidrat': '🥬', 'Şekersiz': '🚫'
  };

  final Map<String, String> allergies = {
    'Gluten': '🌾', 'Laktoz': '🥛', 'Yumurta': '🥚', 'Soya': '🫘', 
    'Fıstık': '🥜', 'Ceviz, Badem': '🌰', 'Deniz Ürünleri': '🐟', 'Susam': '🌻'
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _customDietController.dispose();
    _customAllergyController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);
    
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    
    setState(() => isLoading = true);
    
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text.trim(),
      );

      if (mounted) {
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;
    
    setState(() => isLoading = true);
    
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text.trim(),
      );

      if (mounted) {
        ErrorHandler.showSuccess(context, 'Hesap başarıyla oluşturuldu!');
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 40,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SmartMeal',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Akıllı beslenme asistanınız',
                    style: TextStyle(
                      fontSize: 16,
                      color: _subtleTextColor,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: _subtleTextColor,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Giriş Yap'),
                  Tab(text: 'Kayıt Ol'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginTab(),
                  _buildRegisterTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            const SizedBox(height: 32),
            
            _buildTextField(
              controller: _loginEmailController,
              label: 'E-posta',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (val) => val?.isEmpty == true ? 'E-posta girin' : null,
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _loginPasswordController,
              label: 'Şifre',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: (val) => val != null && val.length < 6 ? 'En az 6 karakter' : null,
            ),
            
            const SizedBox(height: 32),
            
            _buildPrimaryButton(
              text: 'Giriş Yap',
              onPressed: isLoading ? null : _login,
            ),
            
            const SizedBox(height: 24),
            
            _buildDivider(),
            
            const SizedBox(height: 24),
            
            _buildGoogleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _registerFormKey,
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // Temel Bilgiler
            _buildSectionTitle('Temel Bilgiler'),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _registerNameController,
              label: 'Ad Soyad',
              icon: Icons.person_outline,
              validator: (val) => val?.isEmpty == true ? 'Ad soyad girin' : null,
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _registerEmailController,
              label: 'E-posta',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (val) => val?.isEmpty == true ? 'E-posta girin' : null,
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _registerPasswordController,
              label: 'Şifre',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: (val) => val != null && val.length < 6 ? 'En az 6 karakter' : null,
            ),
            
            const SizedBox(height: 24),
            
            // Fiziksel Bilgiler
            _buildSectionTitle('Fiziksel Bilgiler'),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _ageController,
                    label: 'Yaş',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                    validator: (val) => val?.isEmpty == true ? 'Yaş girin' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(),
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
                    icon: Icons.fitness_center_outlined,
                    keyboardType: TextInputType.number,
                    validator: (val) => val?.isEmpty == true ? 'Kilo girin' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _heightController,
                    label: 'Boy (cm)',
                    icon: Icons.height_outlined,
                    keyboardType: TextInputType.number,
                    validator: (val) => val?.isEmpty == true ? 'Boy girin' : null,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Beslenme Tercihleri
            _buildSectionTitle('Beslenme Tercihleri'),
            const SizedBox(height: 16),
            _buildSelectionGrid(dietTypes, selectedDietTypes, 'diyet'),
            
            const SizedBox(height: 24),
            
            // Alerjiler
            _buildSectionTitle('Alerjiler (İsteğe bağlı)'),
            const SizedBox(height: 16),
            _buildSelectionGrid(allergies, selectedAllergies, 'alerji'),
            
            const SizedBox(height: 32),
            
            _buildPrimaryButton(
              text: 'Hesap Oluştur',
              onPressed: isLoading ? null : _register,
            ),
            
            const SizedBox(height: 24),
            
            _buildDivider(),
            
            const SizedBox(height: 24),
            
            _buildGoogleButton(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _subtleTextColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: gender,
      decoration: InputDecoration(
        labelText: 'Cinsiyet',
        prefixIcon: Icon(Icons.people_outline, color: _subtleTextColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _borderColor),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: ['Erkek', 'Kadın'].map((g) => 
        DropdownMenuItem(value: g, child: Text(g))
      ).toList(),
      onChanged: (val) => setState(() => gender = val ?? 'Erkek'),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      ),
    );
  }

  Widget _buildSelectionGrid(Map<String, String> items, List<String> selected, String type) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.entries.map((entry) {
            final isSelected = selected.contains(entry.key);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selected.remove(entry.key);
                  } else {
                    selected.add(entry.key);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _primaryColor : _borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.value, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: isSelected ? _primaryColor : _textColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Custom option
        Row(
          children: [
            Checkbox(
              value: type == 'diyet' ? isCustomDietSelected : isCustomAllergySelected,
              onChanged: (val) {
                setState(() {
                  if (type == 'diyet') {
                    isCustomDietSelected = val ?? false;
                  } else {
                    isCustomAllergySelected = val ?? false;
                  }
                });
              },
              activeColor: _primaryColor,
            ),
            Expanded(
              child: TextFormField(
                controller: type == 'diyet' ? _customDietController : _customAllergyController,
                enabled: type == 'diyet' ? isCustomDietSelected : isCustomAllergySelected,
                decoration: InputDecoration(
                  hintText: 'Diğer (belirtin)',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({required String text, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : _signInWithGoogle,
        icon: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://developers.google.com/identity/images/g-logo.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        label: const Text(
          'Google ile devam et',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _textColor,
          side: BorderSide(color: _borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: _borderColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'veya',
            style: TextStyle(color: _subtleTextColor, fontSize: 14),
          ),
        ),
        Expanded(child: Divider(color: _borderColor)),
      ],
    );
  }
}
