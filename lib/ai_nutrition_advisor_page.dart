import 'package:flutter/material.dart';

class AINutritionAdvisorPage extends StatefulWidget {
  const AINutritionAdvisorPage({super.key});

  @override
  State<AINutritionAdvisorPage> createState() => _AINutritionAdvisorPageState();
}

class _AINutritionAdvisorPageState extends State<AINutritionAdvisorPage> {
  // Modern renk paleti
  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _accentColor = Color(0xFF66BB6A);
  static const Color _backgroundColor = Color(0xFFF5F7FA);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF1A1A1A);
  static const Color _subtleTextColor = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('AI Beslenme Danışmanı'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology,
                size: 80,
                color: _primaryColor,
              ),
              SizedBox(height: 24),
              Text(
                '🤖 AI Beslenme Danışmanı',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Yapay zeka destekli beslenme önerileriniz için bu özellik yakında aktif olacak.',
                style: TextStyle(
                  fontSize: 16,
                  color: _subtleTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
