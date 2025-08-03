import 'package:flutter/material.dart';
import 'auth_wrapper.dart';

// EKLENDİ: Firebase'i başlatmak için gerekli kütüphaneler
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// DEĞİŞTİ: Firebase.initializeApp'ı beklemek için main fonksiyonu "async" yapıldı
void main() async {
  // EKLENDİ: Flutter'ın başlatıldığından emin olmak için
  WidgetsFlutterBinding.ensureInitialized();
  
  // EKLENDİ: Firebase servislerini başlatmak için en önemli satır
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smeal',
      debugShowCheckedModeBanner: false, // Geliştirme aşamasındaki "debug" bandını kaldırır
      // DEĞİŞTİ: Tema, uygulama genelindeki modern temamızla uyumlu hale getirildi
      theme: ThemeData(
        useMaterial3: true, // Modern Material 3 tasarımını etkinleştirir
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20), // Ana tema rengimiz (Koyu Yeşil)
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Standart arka plan rengimiz
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B5E20),
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
