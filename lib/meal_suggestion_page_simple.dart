import 'package:flutter/material.dart';

class MealSuggestionPage extends StatefulWidget {
  const MealSuggestionPage({super.key});

  @override
  State<MealSuggestionPage> createState() => _MealSuggestionPageState();
}

class _MealSuggestionPageState extends State<MealSuggestionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Öğün Önerisi'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 64,
              color: Color(0xFF2E7D32),
            ),
            SizedBox(height: 16),
            Text(
              'AI Öğün Önerisi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kişiselleştirilmiş tarifler yakında...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
