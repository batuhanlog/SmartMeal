import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_page.dart';
import 'main_navigation_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading durumu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'SmartMeal Yükleniyor...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sağlıklı beslenme yolculuğunuz başlıyor',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Kullanıcı giriş yapmış mı kontrol et
        if (snapshot.hasData && snapshot.data != null) {
          // Kullanıcı giriş yapmış, ana navigasyona git
          return const MainNavigationPage();
        } else {
          // Kullanıcı giriş yapmamış, giriş sayfasına git
          return const AuthPage();
        }
      },
    );
  }
}
