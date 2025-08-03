import 'package:flutter/material.dart';

class SmartFoodAnalysisPage extends StatelessWidget {
  const SmartFoodAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akıllı Besin Analizi'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: Colors.green,
            ),
            SizedBox(height: 20),
            Text(
              'Akıllı Besin Analizi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Bu özellik yakında aktif olacak',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}