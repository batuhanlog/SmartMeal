import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'auth_page.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // --- Tutarlı Tema ve Stil Sabitleri ---
  static const Color _primaryColor = Color(0xFF1B5E20);
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _textColor = Color(0xFF343A40);
  static const Color _subtleTextColor = Color(0xFF6C757D);
  static const Color _cardColor = Colors.white; // *** EKSİK OLAN VE EKLENEN SATIR ***

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToMainPage();
  }
  
  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  Future<void> _navigateToMainPage() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        
        final pageRoute = MaterialPageRoute(
          builder: (context) => user != null ? const HomePage() : const AuthPage(),
        );

        Navigator.pushReplacement(context, pageRoute);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: _cardColor, // Artık bu değişken tanımlı
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/icon.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: _primaryColor,
                          child: const Icon(Icons.restaurant_menu, size: 50, color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Smeal',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'AI destekli beslenme asistanınız',
                  style: TextStyle(
                    fontSize: 16,
                    color: _subtleTextColor,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}