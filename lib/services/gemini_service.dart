import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
import 'dart:convert';

class GeminiService {
  // TODO: Bu API anahtarını güvenli bir şekilde saklayın (environment variables)
  // Gerçek kullanım için: https://console.cloud.google.com/apis/credentials
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
  
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;

  GeminiService() {
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      // Eğer API anahtarı ayarlanmamışsa mock data kullan
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

  // Yemek önerisi alma
  Future<List<Map<String, dynamic>>> getMealSuggestions({
    required String dietType,
    required double bmi,
    required String activityLevel,
    required int age,
    String? allergies,
  }) async {
    try {
      // API anahtarı ayarlanmamışsa mock data döndür
      if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        return _getMockMealSuggestions(dietType, bmi);
      }

      final prompt = '''
Bir beslenme uzmanı olarak, aşağıdaki kişi için 5 adet sağlıklı yemek önerisi hazırla:

Kişi Bilgileri:
- Beslenme Türü: $dietType
- BMI: ${bmi.toStringAsFixed(1)}
- Aktivite Seviyesi: $activityLevel
- Yaş: $age
${allergies != null ? '- Alerjiler: $allergies' : ''}

Her yemek için kişiselleştirilmiş öneriler ver. Farklı çeşitlerde yemekler (ana yemek, salata, çorba, atıştırmalık) öner.

JSON formatında döndür (sadece JSON, başka açıklama yok):
[
  {
    "name": "Yemek Adı",
    "emoji": "🍽️",
    "calories": 320,
    "protein": 25,
    "carbs": 30,
    "fat": 12,
    "prep_time": 20,
    "difficulty": "Kolay",
    "ingredients": ["malzeme1", "malzeme2", "malzeme3"],
    "instructions": ["adım1", "adım2", "adım3"],
    "health_benefits": ["fayda1", "fayda2"]
  }
]
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text != null) {
        try {
          // JSON'u temizle ve parse et
          String cleanedResponse = response.text!
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          
          final List<dynamic> jsonResponse = jsonDecode(cleanedResponse);
          return jsonResponse.cast<Map<String, dynamic>>();
        } catch (parseError) {
          print('JSON Parse Error: $parseError');
          print('Raw response: ${response.text}');
          // Parse hatası durumunda mock data döndür
          return _getMockMealSuggestions(dietType, bmi);
        }
      }
      
      return _getMockMealSuggestions(dietType, bmi);
    } catch (e) {
      print('Gemini API Error: $e');
      return _getMockMealSuggestions(dietType, bmi);
    }
  }

  // Yemek fotoğrafı analizi
  Future<Map<String, dynamic>> analyzeFoodPhoto(Uint8List imageBytes) async {
    try {
      // API anahtarı ayarlanmamışsa mock data döndür
      if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        return _getMockFoodAnalysis();
      }

      final prompt = '''
Bu yemek fotoğrafını detaylı analiz et ve aşağıdaki bilgileri ver:

1. Yemeğin adını tespit et
2. Tahmini besin değerlerini hesapla
3. Sağlık skorunu değerlendir (1-10)
4. Beslenme önerileri ver

JSON formatında döndür:
{
  "food_name": "Tespit edilen yemek adı",
  "emoji": "🍽️",
  "confidence": 85,
  "calories": 320,
  "protein": 25,
  "carbs": 45,
  "fat": 12,
  "health_score": 7,
  "analysis": "Bu yemek hakkında detaylı analiz",
  "suggestions": ["öneri1", "öneri2", "öneri3"]
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
          // JSON'u temizle ve parse et
          String cleanedResponse = response.text!
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          
          final Map<String, dynamic> jsonResponse = jsonDecode(cleanedResponse);
          return jsonResponse;
        } catch (parseError) {
          print('JSON Parse Error: $parseError');
          print('Raw response: ${response.text}');
          // Parse hatası durumunda mock data döndür
          return _getMockFoodAnalysis();
        }
      }
      
      return _getMockFoodAnalysis();
    } catch (e) {
      print('Gemini Vision API Error: $e');
      return _getMockFoodAnalysis();
    }
  }

  // Malzeme bazlı tarif önerisi
  Future<List<Map<String, dynamic>>> getRecipesByIngredients(List<String> ingredients) async {
    try {
      // API anahtarı ayarlanmamışsa mock data döndür
      if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        return _getMockRecipes(ingredients);
      }

      final prompt = '''
Elimde şu malzemeler var: ${ingredients.join(', ')}

Bu malzemelerle yapabileceğim 3-5 farklı yemek tarifi öner. Eksik malzemeler varsa belirt.

JSON formatında döndür:
[
  {
    "name": "Yemek Adı",
    "emoji": "🍽️",
    "prep_time": 25,
    "difficulty": "Kolay",
    "missing_ingredients": ["eksik malzeme1", "eksik malzeme2"],
    "instructions": ["adım1", "adım2", "adım3"],
    "calories": 280,
    "description": "Yemek hakkında kısa açıklama"
  }
]
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text != null) {
        try {
          // JSON'u temizle ve parse et
          String cleanedResponse = response.text!
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          
          final List<dynamic> jsonResponse = jsonDecode(cleanedResponse);
          return jsonResponse.cast<Map<String, dynamic>>();
        } catch (parseError) {
          print('JSON Parse Error: $parseError');
          print('Raw response: ${response.text}');
          // Parse hatası durumunda mock data döndür
          return _getMockRecipes(ingredients);
        }
      }
      
      return _getMockRecipes(ingredients);
    } catch (e) {
      print('Gemini API Error: $e');
      return _getMockRecipes(ingredients);
    }
  }

  // Mock data functions
  List<Map<String, dynamic>> _getMockMealSuggestions(String dietType, double bmi) {
    List<Map<String, dynamic>> suggestions = [];

    // BMI'ye göre öneriler
    if (bmi < 18.5) {
      suggestions.addAll([
        {
          "name": "Fıstık Ezmeli Protein Smoothie",
          "emoji": "🥤",
          "calories": 450,
          "protein": 22,
          "carbs": 35,
          "fat": 18,
          "prep_time": 5,
          "difficulty": "Kolay",
          "ingredients": ["Muz", "Fıstık ezmesi", "Protein tozu", "Süt", "Bal"],
          "instructions": ["Tüm malzemeleri blender'e at", "2 dakika karıştır", "Soğuk servis et"],
          "health_benefits": ["Kilo almaya yardımcı", "Yüksek protein", "Sağlıklı yağlar"]
        },
        {
          "name": "Avokado Toast Deluxe",
          "emoji": "🥑",
          "calories": 380,
          "protein": 15,
          "carbs": 28,
          "fat": 22,
          "prep_time": 10,
          "difficulty": "Kolay",
          "ingredients": ["Tam buğday ekmeği", "Avokado", "Yumurta", "Feta peyniri"],
          "instructions": ["Ekmeği kızart", "Avokado'yu ez", "Yumurtayı haşla", "Hepsini birleştir"],
          "health_benefits": ["Sağlıklı yağlar", "Protein zengin", "Lif kaynağı"]
        }
      ]);
    } else if (bmi > 25) {
      suggestions.addAll([
        {
          "name": "Izgara Tavuk Quinoa Salatası",
          "emoji": "🥗",
          "calories": 320,
          "protein": 35,
          "carbs": 25,
          "fat": 8,
          "prep_time": 25,
          "difficulty": "Orta",
          "ingredients": ["Tavuk göğsü", "Quinoa", "Karışık yeşillik", "Domates", "Salatalık"],
          "instructions": ["Tavuğu marine et", "Izgarada pişir", "Quinoa haşla", "Salatayı hazırla"],
          "health_benefits": ["Düşük kalori", "Yüksek protein", "Tok tutucu"]
        },
        {
          "name": "Sebze Çorbası Detox",
          "emoji": "🍲",
          "calories": 180,
          "protein": 8,
          "carbs": 22,
          "fat": 4,
          "prep_time": 30,
          "difficulty": "Kolay",
          "ingredients": ["Brokoli", "Havuç", "Soğan", "Kereviz", "Sebze suyu"],
          "instructions": ["Sebzeleri doğra", "Suyun içinde haşla", "Blender'dan geçir", "Baharatla tatlandır"],
          "health_benefits": ["Çok düşük kalori", "Vitaminler", "Antioksidan"]
        }
      ]);
    } else {
      suggestions.addAll([
        {
          "name": "Somon Teriyaki Bowl",
          "emoji": "🐟",
          "calories": 380,
          "protein": 28,
          "carbs": 32,
          "fat": 15,
          "prep_time": 20,
          "difficulty": "Orta",
          "ingredients": ["Somon fileto", "Teriyaki sos", "Esmer pirinç", "Buharda sebze"],
          "instructions": ["Salmonu marine et", "Izgarada pişir", "Pirinci haşla", "Bowl'u hazırla"],
          "health_benefits": ["Omega-3", "Dengeli beslenme", "Kalp sağlığı"]
        },
        {
          "name": "Mercimek Köftesi",
          "emoji": "🧆",
          "calories": 280,
          "protein": 18,
          "carbs": 35,
          "fat": 8,
          "prep_time": 40,
          "difficulty": "Orta",
          "ingredients": ["Kırmızı mercimek", "Bulgur", "Soğan", "Baharat", "Yeşillik"],
          "instructions": ["Mercimeği haşla", "Bulgurla karıştır", "Baharatla tat ver", "Köfte şekli ver"],
          "health_benefits": ["Bitkisel protein", "Lif zengin", "Vegan dostu"]
        }
      ]);
    }

    // Diet type'a göre ek öneriler
    if (dietType.toLowerCase().contains('vegan') || dietType.toLowerCase().contains('vegetarian')) {
      suggestions.add({
        "name": "Quinoa Buddha Bowl",
        "emoji": "🥗",
        "calories": 420,
        "protein": 18,
        "carbs": 55,
        "fat": 12,
        "prep_time": 25,
        "difficulty": "Kolay",
        "ingredients": ["Quinoa", "Nohut", "Ispanak", "Avokado", "Tahini"],
        "instructions": ["Quinoa pişir", "Nohut kızart", "Sebzeleri hazırla", "Tahini sos yap"],
        "health_benefits": ["Tam protein", "Bitkisel", "Antioksidan zengin"]
      });
    }

    return suggestions.take(5).toList();
  }

  Map<String, dynamic> _getMockFoodAnalysis() {
    final List<Map<String, dynamic>> mockResults = [
      {
        "food_name": "Karışık Salata",
        "emoji": "🥗",
        "confidence": 88,
        "calories": 150,
        "protein": 5,
        "carbs": 12,
        "fat": 8,
        "health_score": 9,
        "analysis": "Çok sağlıklı bir seçim! Vitamin ve mineral açısından zengin, düşük kalorili ve lif dolu.",
        "suggestions": [
          "Protein eklemek için tavuk veya ton balığı ekleyebilirsiniz",
          "Daha doyurucu olmak için avokado ekleyin",
          "Zeytinyağı ile omega-3 alımınızı artırın"
        ]
      },
      {
        "food_name": "Tavuk Döner",
        "emoji": "🥙",
        "confidence": 92,
        "calories": 420,
        "protein": 25,
        "carbs": 35,
        "fat": 18,
        "health_score": 6,
        "analysis": "Orta kalori değerinde, protein açısından zengin ama yağ oranı yüksek.",
        "suggestions": [
          "Yanında taze salata tüketin",
          "Az yağlı versiyonu tercih edin",
          "Porsiyon kontrolü yapın",
          "Ayranla tüketirseniz sindirim kolaylaşır"
        ]
      },
      {
        "food_name": "Pizza Margherita",
        "emoji": "🍕",
        "confidence": 95,
        "calories": 580,
        "protein": 18,
        "carbs": 65,
        "fat": 24,
        "health_score": 4,
        "analysis": "Yüksek kalori ve karbonhidrat içeriği var. Sık tüketilmemesi önerilen bir yemek.",
        "suggestions": [
          "Sebzeli pizza tercih edin",
          "İnce hamur seçin",
          "Yarım porsiyon yeterli olabilir",
          "Yanında salata tüketin"
        ]
      }
    ];

    // Random result for demo
    mockResults.shuffle();
    return mockResults.first;
  }

  List<Map<String, dynamic>> _getMockRecipes(List<String> ingredients) {
    return [
      {
        "name": "Hızlı Omlet",
        "emoji": "🍳",
        "prep_time": 10,
        "difficulty": "Kolay",
        "missing_ingredients": [],
        "instructions": [
          "Yumurtaları çırpın",
          "Tavaya yağ ekleyin",
          "Çırpılmış yumurtaları dökün",
          "Malzemeleri ekleyin",
          "Katlayın ve servis edin"
        ],
        "calories": 280,
        "description": "Hızlı ve besleyici kahvaltı alternatifi"
      },
      {
        "name": "Sebze Sote",
        "emoji": "🥬",
        "prep_time": 15,
        "difficulty": "Kolay",
        "missing_ingredients": ["Zeytinyağı"],
        "instructions": [
          "Sebzeleri doğrayın",
          "Tavada zeytinyağını ısıtın",
          "Sebzeleri ekleyin",
          "Baharatlarla tatlandırın",
          "Al dente pişirin"
        ],
        "calories": 120,
        "description": "Hafif ve sağlıklı sebze yemeği"
      },
      {
        "name": "Karışık Salata",
        "emoji": "🥗",
        "prep_time": 5,
        "difficulty": "Çok Kolay",
        "missing_ingredients": ["Salata sosu"],
        "instructions": [
          "Sebzeleri yıkayın",
          "Doğrayın",
          "Karıştırın",
          "Sos ekleyin",
          "Servis edin"
        ],
        "calories": 80,
        "description": "Taze ve vitamin dolu salata"
      }
    ];
  }
}
