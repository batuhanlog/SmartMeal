import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
import 'dart:convert';

class CalorieCalculatorService {
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
  
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;

  CalorieCalculatorService() {
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      print('⚠️ Gemini API anahtarı ayarlanmamış, mock data kullanılıyor');
    } else {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );
      _visionModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );
    }
  }

  // Fotoğraftan kalori hesaplama
  Future<Map<String, dynamic>> calculateCaloriesFromPhoto(Uint8List imageBytes) async {
    try {
      if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        return _getMockCalorieAnalysis();
      }

      final prompt = '''
Bu fotoğraftaki yemekleri detaylı analiz et ve kalori hesaplaması yap:

1. Fotoğraftaki tüm yemekleri tespit et
2. Her yemek için porsiyon miktarını tahmin et
3. Detaylı kalori hesaplaması yap
4. Makro besin değerlerini hesapla (protein, karbonhidrat, yağ)
5. Toplam kalori ve besin değerlerini ver

JSON formatında döndür:
{
  "total_calories": 450,
  "total_protein": 25,
  "total_carbs": 60,
  "total_fat": 15,
  "foods": [
    {
      "name": "Yemek adı",
      "portion": "1 porsiyon",
      "calories": 200,
      "protein": 10,
      "carbs": 25,
      "fat": 8
    }
  ],
  "analysis": "Detaylı kalori analizi",
  "recommendations": ["öneri1", "öneri2"]
}
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _visionModel.generateContent(content);
      
      if (response.text != null) {
        try {
          String cleanedResponse = response.text!
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          
          final Map<String, dynamic> jsonResponse = jsonDecode(cleanedResponse);
          return jsonResponse;
        } catch (parseError) {
          print('JSON Parse Error: $parseError');
          return _getMockCalorieAnalysis();
        }
      }
      
      return _getMockCalorieAnalysis();
    } catch (e) {
      print('Calorie Calculation Error: $e');
      return _getMockCalorieAnalysis();
    }
  }

  // Manuel gıda girişi ile kalori hesaplama
  Future<Map<String, dynamic>> calculateCaloriesFromFoodList(List<Map<String, dynamic>> foods) async {
    try {
      if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        return _getMockManualCalorieCalculation(foods);
      }

      final foodList = foods.map((food) => 
        '${food['name']} - ${food['amount']} ${food['unit']}'
      ).join(', ');

      final prompt = '''
Bu gıdaların kalori ve besin değerlerini hesapla:

$foodList

Her gıda için detaylı besin değerlerini hesapla ve toplam değerleri ver.

JSON formatında döndür:
{
  "total_calories": 450,
  "total_protein": 25,
  "total_carbs": 60,
  "total_fat": 15,
  "foods": [
    {
      "name": "Gıda adı",
      "amount": "100g",
      "calories": 200,
      "protein": 10,
      "carbs": 25,
      "fat": 8
    }
  ],
  "analysis": "Detaylı analiz",
  "recommendations": ["öneri1", "öneri2"]
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text != null) {
        try {
          String cleanedResponse = response.text!
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          
          final Map<String, dynamic> jsonResponse = jsonDecode(cleanedResponse);
          return jsonResponse;
        } catch (parseError) {
          print('JSON Parse Error: $parseError');
          return _getMockManualCalorieCalculation(foods);
        }
      }
      
      return _getMockManualCalorieCalculation(foods);
    } catch (e) {
      print('Manual Calorie Calculation Error: $e');
      return _getMockManualCalorieCalculation(foods);
    }
  }

  // Günlük kalori ihtiyacı hesaplama
  Map<String, dynamic> calculateDailyCalorieNeeds({
    required int age,
    required String gender,
    required double weight,
    required double height,
    required String activityLevel,
    String? goal, // 'lose', 'maintain', 'gain'
  }) {
    // Harris-Benedict formülü
    double bmr;
    if (gender.toLowerCase() == 'erkek') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }

    // Aktivite seviyesi çarpanları
    double activityMultiplier;
    switch (activityLevel.toLowerCase()) {
      case 'düşük':
        activityMultiplier = 1.2;
        break;
      case 'orta':
        activityMultiplier = 1.375;
        break;
      case 'yüksek':
        activityMultiplier = 1.55;
        break;
      case 'çok yüksek':
        activityMultiplier = 1.725;
        break;
      default:
        activityMultiplier = 1.375;
    }

    double tdee = bmr * activityMultiplier;

    // Hedef bazlı kalori ayarlaması
    double targetCalories = tdee;
    if (goal != null) {
      switch (goal.toLowerCase()) {
        case 'lose':
          targetCalories = tdee - 500; // Günlük 500 kalori açık
          break;
        case 'gain':
          targetCalories = tdee + 300; // Günlük 300 kalori fazla
          break;
        default:
          targetCalories = tdee;
      }
    }

    return {
      'bmr': bmr.round(),
      'tdee': tdee.round(),
      'target_calories': targetCalories.round(),
      'protein_grams': (targetCalories * 0.25 / 4).round(), // %25 protein
      'carbs_grams': (targetCalories * 0.45 / 4).round(), // %45 karbonhidrat
      'fat_grams': (targetCalories * 0.30 / 9).round(), // %30 yağ
    };
  }

  // Mock data fonksiyonları
  Map<String, dynamic> _getMockCalorieAnalysis() {
    return {
      'total_calories': 450,
      'total_protein': 25,
      'total_carbs': 60,
      'total_fat': 15,
      'foods': [
        {
          'name': 'Tavuk Göğsü',
          'portion': '150g',
          'calories': 250,
          'protein': 45,
          'carbs': 0,
          'fat': 5
        },
        {
          'name': 'Pirinç',
          'portion': '100g',
          'calories': 130,
          'protein': 3,
          'carbs': 28,
          'fat': 0.3
        },
        {
          'name': 'Sebze Salatası',
          'portion': '1 porsiyon',
          'calories': 70,
          'protein': 2,
          'carbs': 12,
          'fat': 0.5
        }
      ],
      'analysis': 'Bu öğün dengeli bir protein, karbonhidrat ve vitamin kaynağı sağlıyor.',
      'recommendations': [
        'Protein miktarı yeterli',
        'Sebze çeşitliliği artırılabilir',
        'Su tüketimi unutulmamalı'
      ]
    };
  }

  Map<String, dynamic> _getMockManualCalorieCalculation(List<Map<String, dynamic>> foods) {
    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    List<Map<String, dynamic>> calculatedFoods = [];

    for (var food in foods) {
      // Basit mock hesaplama
      int calories = (food['calories'] ?? 100) * (food['amount'] ?? 1);
      double protein = (food['protein'] ?? 5) * (food['amount'] ?? 1);
      double carbs = (food['carbs'] ?? 15) * (food['amount'] ?? 1);
      double fat = (food['fat'] ?? 2) * (food['amount'] ?? 1);

      totalCalories += calories;
      totalProtein += protein;
      totalCarbs += carbs;
      totalFat += fat;

      calculatedFoods.add({
        'name': food['name'],
        'amount': '${food['amount']} ${food['unit']}',
        'calories': calories,
        'protein': protein.round(),
        'carbs': carbs.round(),
        'fat': fat.round(),
      });
    }

    return {
      'total_calories': totalCalories,
      'total_protein': totalProtein.round(),
      'total_carbs': totalCarbs.round(),
      'total_fat': totalFat.round(),
      'foods': calculatedFoods,
      'analysis': 'Manuel giriş ile hesaplanan besin değerleri',
      'recommendations': [
        'Günlük hedefinize göre değerlendirin',
        'Çeşitlilik için farklı gıdalar ekleyin'
      ]
    };
  }
} 