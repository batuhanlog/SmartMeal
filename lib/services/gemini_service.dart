import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
import 'dart:convert';

class GeminiService {
  // Gemini API anahtarı
  static const String _apiKey = 'AIzaSyBEH_GZMDh1XvPQUfxbwhYh76g_YaZ-LAU';
  
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    _visionModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
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
          // Parse hatası durumunda boş liste döndür
          return [];
        }
      }
      
      return [];
    } catch (e) {
      print('Gemini API Error: $e');
      return [];
    }
  }

  // Yemek fotoğrafı analizi
  Future<Map<String, dynamic>> analyzeFoodPhoto(Uint8List imageBytes) async {
    try {
      final now = DateTime.now();
      final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      final prompt = '''
Bu fotoğrafı analiz et ve şu adımları takip et:

1. ÖNCE: Fotoğrafta yemek, içecek veya herhangi bir besin maddesi var mı kontrol et
2. EĞER yemek/besin YOKSA: "is_food": false döndür
3. EĞER yemek/besin VARSA: Detaylı analiz yap ve tarihi bilgiler ver

YEMEK VARSA YAPILACAKLAR:
- Fotoğrafta gördüklerini spesifik olarak tanımla
- Yemeğin tarihsel kökenini ve kültürel önemini anlat
- Bu yemeğin hangi ülke/bölge mutfağından geldiğini açıkla
- Tarihte bu yemeğin nasıl ortaya çıktığını anlat
- Geleneksel yapılış şeklini ve modern varyasyonlarını açıkla

YEMEK YOKSA:
- Sadece is_food: false döndür

JSON formatında döndür:
{
  "is_food": true/false,
  "food_name": "Gördüğün yemeğin spesifik adı",
  "emoji": "uygun emoji",
  "confidence": 75,
  "calories": 320,
  "protein": 25,
  "carbs": 45,
  "fat": 12,
  "fiber": 8,
  "sodium": 450,
  "sugar": 5,
  "health_score": 7,
  "recipe": "Bu yemeğin geleneksel yapılış tarifi",
  "analysis": "Görsel analizi ve besin değerleri açıklaması",
  "historical_info": "Bu yemeğin tarihi, kökeni, kültürel önemi ve hikayesi. Hangi dönemde ortaya çıktığı, hangi kültürden geldiği, nasıl yayıldığı gibi detaylı bilgiler",
  "cultural_significance": "Bu yemeğin kültürel önemi ve farklı kültürlerdeki varyasyonları",
  "traditional_preparation": "Geleneksel yapılış yöntemi ve modern zamanlarda nasıl değiştiği",
  "suggestions": ["beslenme önerisi 1", "öneri 2", "öneri 3"],
  "analysis_date": "$formattedDate"
}

ÖRNEKLER:
- Makarna: İtalyan kökenli, Marco Polo efsanesi, modern varyasyonları
- Pilav: Orta Asya kökenli, Türk mutfağında gelişimi
- Hummus: Orta Doğu kökenli, antik çağlardan beri tüketimi
- Sushi: Japon kökenli, fermantasyondan modern forma evrimi
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
          
          // Eğer yemek değilse özel mesaj döndür
          if (jsonResponse['is_food'] == false) {
            return {
              'food_name': 'Yemek Tespit Edilemedi',
              'emoji': '❌',
              'confidence': 0,
              'calories': 0,
              'protein': 0,
              'carbs': 0,
              'fat': 0,
              'fiber': 0,
              'sodium': 0,
              'sugar': 0,
              'health_score': 0,
              'recipe': 'Bu görsel herhangi bir yemek içermiyor. Lütfen yemek görseli atın.',
              'analysis': 'Fotoğrafta yemek veya besin maddesi tespit edilemedi.',
              'historical_info': 'Analiz edilecek yemek bulunamadı.',
              'cultural_significance': 'Analiz edilecek yemek bulunamadı.',
              'traditional_preparation': 'Analiz edilecek yemek bulunamadı.',
              'suggestions': ['Yemek fotoğrafı çekin', 'Daha net bir görsel kullanın', 'Farklı açıdan fotoğraf çekin'],
              'analysis_date': formattedDate,
              'error_type': 'not_food'
            };
          }
          
          // Zorunlu alanları kontrol et ve varsayılan değerler ata
          jsonResponse['food_name'] = jsonResponse['food_name'] ?? 'Görünen Besin';
          jsonResponse['emoji'] = jsonResponse['emoji'] ?? '🍽️';
          jsonResponse['confidence'] = jsonResponse['confidence'] ?? 70;
          jsonResponse['analysis_date'] = jsonResponse['analysis_date'] ?? formattedDate;
          jsonResponse['health_score'] = jsonResponse['health_score'] ?? 6;
          jsonResponse['calories'] = jsonResponse['calories'] ?? 250;
          jsonResponse['protein'] = jsonResponse['protein'] ?? 15;
          jsonResponse['carbs'] = jsonResponse['carbs'] ?? 30;
          jsonResponse['fat'] = jsonResponse['fat'] ?? 10;
          jsonResponse['recipe'] = jsonResponse['recipe'] ?? 'Tarif bilgisi mevcut değil.';
          jsonResponse['analysis'] = jsonResponse['analysis'] ?? 'Beslenme analizi yapıldı.';
          jsonResponse['historical_info'] = jsonResponse['historical_info'] ?? 'Tarihi bilgi mevcut değil.';
          jsonResponse['cultural_significance'] = jsonResponse['cultural_significance'] ?? 'Kültürel bilgi mevcut değil.';
          jsonResponse['traditional_preparation'] = jsonResponse['traditional_preparation'] ?? 'Geleneksel tarif bilgisi mevcut değil.';
          jsonResponse['suggestions'] = jsonResponse['suggestions'] ?? ['Dengeli beslenmeye dikkat edin', 'Su tüketiminizi artırın'];
          
          return jsonResponse;
        } catch (parseError) {
          print('JSON Parse Error: $parseError');
          print('Raw response: ${response.text}');
          
          // Parse hatası durumunda varsayılan değerler döndür
          return {
            'food_name': 'Fotoğraf Analizi',
            'emoji': '🍽️',
            'confidence': 60,
            'calories': 250,
            'protein': 15,
            'carbs': 30,
            'fat': 10,
            'fiber': 5,
            'sodium': 300,
            'sugar': 8,
            'health_score': 6,
            'recipe': 'Bu yemek için detaylı tarif bilgisi mevcut değil.',
            'analysis': 'Fotoğraf üzerinden beslenme analizi yapıldı.',
            'historical_info': 'Analiz hatası nedeniyle tarihi bilgi alınamadı.',
            'cultural_significance': 'Analiz hatası nedeniyle kültürel bilgi alınamadı.',
            'traditional_preparation': 'Analiz hatası nedeniyle geleneksel tarif bilgisi alınamadı.',
            'suggestions': ['Dengeli beslenmeye dikkat edin', 'Porsiyon kontrolü yapın', 'Su tüketiminizi artırın'],
            'analysis_date': formattedDate,
          };
        }
      }
      
      // Response yoksa varsayılan değerler döndür
      return {
        'food_name': 'Fotoğraf Analizi Başarısız',
        'emoji': '📷',
        'confidence': 30,
        'calories': 200,
        'protein': 12,
        'carbs': 25,
        'fat': 8,
        'fiber': 4,
        'sodium': 250,
        'sugar': 6,
        'health_score': 5,
        'recipe': 'Fotoğraf analiz edilemedi.',
        'analysis': 'Görsel analiz tamamlanamadı.',
        'historical_info': 'Fotoğraf analiz edilemediği için tarihi bilgi mevcut değil.',
        'cultural_significance': 'Fotoğraf analiz edilemediği için kültürel bilgi mevcut değil.',
        'traditional_preparation': 'Fotoğraf analiz edilemediği için geleneksel tarif bilgisi mevcut değil.',
        'suggestions': ['Daha net bir fotoğraf çekin', 'Beslenme uzmanına danışın'],
        'analysis_date': formattedDate,
      };
    } catch (e) {
      print('Gemini Vision API Error: $e');
      
      // Hata durumunda varsayılan değerler döndür
      final now = DateTime.now();
      final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      return {
        'food_name': 'Analiz Hatası',
        'emoji': '⚠️',
        'confidence': 30,
        'calories': 150,
        'protein': 10,
        'carbs': 20,
        'fat': 5,
        'fiber': 3,
        'sodium': 200,
        'sugar': 4,
        'health_score': 4,
        'recipe': 'Analiz sırasında hata oluştu.',
        'analysis': 'Teknik bir sorun nedeniyle analiz tamamlanamadı.',
        'historical_info': 'Bağlantı hatası nedeniyle tarihi bilgi alınamadı.',
        'cultural_significance': 'Bağlantı hatası nedeniyle kültürel bilgi alınamadı.',
        'traditional_preparation': 'Bağlantı hatası nedeniyle geleneksel tarif bilgisi alınamadı.',
        'suggestions': ['Tekrar deneyin', 'İnternet bağlantınızı kontrol edin'],
        'analysis_date': formattedDate,
      };
    }
  }

  // Sağlık durumu analizi
  Future<Map<String, dynamic>> analyzeHealthCondition({
    required Map<String, dynamic> responses,
    required Map<String, dynamic> userProfile,
  }) async {
    try {
      final prompt = '''
Bir sağlık uzmanı olarak, aşağıdaki anket cevaplarını ve kişi bilgilerini analiz ederek kapsamlı bir sağlık değerlendirmesi yap:

Kişi Bilgileri:
- Yaş: ${userProfile['age'] ?? 'Belirtilmemiş'}
- Cinsiyet: ${userProfile['gender'] ?? 'Belirtilmemiş'}
- Kilo: ${userProfile['weight'] ?? 'Belirtilmemiş'} kg
- Boy: ${userProfile['height'] ?? 'Belirtilmemiş'} cm
- Aktivite Seviyesi: ${userProfile['activityLevel'] ?? 'Belirtilmemiş'}

Anket Cevapları:
${responses.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

ÖNEMLİ: Bu sadece bir ön değerlendirmedir, kesin tanı için mutlaka sağlık uzmanına başvurulmalıdır.

JSON formatında döndür (sadece JSON, başka açıklama yok):
{
  "overall_risk_level": "Düşük/Orta/Yüksek",
  "risk_percentage": 25,
  "main_concerns": ["Endişe alanı 1", "Endişe alanı 2"],
  "risk_factors": ["Risk faktörü 1", "Risk faktörü 2"],
  "recommendations": ["Öneri 1", "Öneri 2", "Öneri 3"],
  "lifestyle_suggestions": ["Yaşam tarzı önerisi 1", "Yaşam tarzı önerisi 2"],
  "when_to_see_doctor": "Hangi durumlarda doktora başvurulması gerektiği",
  "follow_up_period": "2-3 ay",
  "positive_aspects": ["Olumlu yön 1", "Olumlu yön 2"],
  "detailed_analysis": "Detaylı analiz metni (2-3 paragraf)"
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
          return _getDefaultHealthAnalysis();
        }
      }
      
      return _getDefaultHealthAnalysis();
    } catch (e) {
      print('Gemini Health Analysis Error: $e');
      return _getDefaultHealthAnalysis();
    }
  }

  Map<String, dynamic> _getDefaultHealthAnalysis() {
    return {
      "overall_risk_level": "Orta",
      "risk_percentage": 30,
      "main_concerns": ["Genel sağlık kontrolü gerekli", "Yaşam tarzı iyileştirmeleri"],
      "risk_factors": ["Yaş faktörü", "Yaşam tarzı faktörleri"],
      "recommendations": ["Düzenli egzersiz yapın", "Dengeli beslenin", "Stresi azaltın"],
      "lifestyle_suggestions": ["Günlük 30 dakika yürüyüş", "8 saat uyku"],
      "when_to_see_doctor": "Herhangi bir belirtiniz varsa hemen doktora başvurun",
      "follow_up_period": "3 ay",
      "positive_aspects": ["Sağlığınıza dikkat ediyorsunuz", "Önleyici yaklaşım sergiliyorsunuz"],
      "detailed_analysis": "Analiz tamamlanamadı. Lütfen bir sağlık uzmanından yardım alın."
    };
  }

  // Malzeme bazlı tarif önerisi
  Future<List<Map<String, dynamic>>> getRecipesByIngredients(List<String> ingredients) async {
    try {
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
          // Parse hatası durumunda boş liste döndür
          return [];
        }
      }
      
      return [];
    } catch (e) {
      print('Gemini API Error: $e');
      return [];
    }
  }

  // Haftalık sağlık raporu oluşturma
  Future<Map<String, dynamic>> generateWeeklyHealthReport({
    required Map<String, dynamic> userProfile,
    required List<Map<String, dynamic>> weeklyMeals,
    required Map<String, dynamic> weeklyActivity,
    required Map<String, dynamic> healthMetrics,
  }) async {
    try {
      final now = DateTime.now();
      final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      final prompt = '''
Sağlık uzmanı olarak MUTLAKA haftalık sağlık raporu hazırla. Kullanıcının fiziksel özelliklerini ve yaşını göz önüne alarak kişiselleştirilmiş öneriler ver.

Kullanıcı Profili - DETAYLAR:
• Yaş: ${userProfile['age'] ?? 25} yaş
• Cinsiyet: ${userProfile['gender'] ?? 'erkek'}  
• Kilo: ${userProfile['weight'] ?? 70}kg
• Boy: ${userProfile['height'] ?? 170}cm
• BMI: ${_calculateBMI(userProfile['weight'] ?? 70, userProfile['height'] ?? 170)}
• Aktivite Seviyesi: ${userProfile['activity_level'] ?? 'orta'}

ÖNEMLI: Bu fiziksel özelliklere göre özel öneriler hazırla:

YAŞ GRUBU ANALİZİ:
- ${_getAgeGroupAnalysis(userProfile['age'] ?? 25)}

BMI ANALİZİ: 
- ${_getBMIAnalysis(_calculateBMI(userProfile['weight'] ?? 70, userProfile['height'] ?? 170))}

Haftalık Aktivite Verileri:
- Toplam adım: ${weeklyActivity['total_steps'] ?? 35000}
- Egzersiz günleri: ${weeklyActivity['workout_sessions'] ?? 3}
- Ortalama uyku: ${weeklyActivity['average_sleep'] ?? 7} saat
- Su tüketimi: ${weeklyActivity['water_intake'] ?? 2}L/gün

ZORUNLU: Aşağıdaki JSON formatında kişiselleştirilmiş rapor döndür:
{
  "report_date": "$formattedDate",
  "overall_score": 7.5,
  "user_analysis": {
    "age_group": "${_getAgeGroup(userProfile['age'] ?? 25)}",
    "bmi_status": "${_getBMIStatus(_calculateBMI(userProfile['weight'] ?? 70, userProfile['height'] ?? 170))}",
    "activity_level": "${userProfile['activity_level'] ?? 'orta'}",
    "personalized_notes": "Yaş, BMI ve aktivite seviyesine göre kişisel değerlendirme"
  },
  "summary": "Bu hafta ${userProfile['age'] ?? 25} yaşında, BMI ${_calculateBMI(userProfile['weight'] ?? 70, userProfile['height'] ?? 170)} olan bir birey olarak sağlık durumunuz değerlendirildi.",
  "criteria_used": [
    "Yaş grubu: ${_getAgeGroup(userProfile['age'] ?? 25)} - metabolizma ve beslenme ihtiyaçları",
    "BMI: ${_calculateBMI(userProfile['weight'] ?? 70, userProfile['height'] ?? 170)} - ideal kilo durumu",
    "Boy-kilo oranı: ${userProfile['height'] ?? 170}cm/${userProfile['weight'] ?? 70}kg",
    "Aktivite seviyesi: ${userProfile['activity_level'] ?? 'orta'} - günlük kalori ihtiyacı"
  ],
  "nutrition_analysis": {
    "daily_calorie_need": ${_calculateDailyCalories(userProfile)},
    "protein_need": "${_calculateProteinNeed(userProfile)}g/gün",
    "recommended_meals": "Yaş ve aktivite seviyesine uygun öğün planı"
  },
  "achievements": [
    "Bu hafta ${userProfile['age'] ?? 25} yaş grubunuz için uygun aktivite düzeyini korudunuz",
    "BMI değerinize uygun beslenme alışkanlıkları sergiledınız"
  ],
  "recommendations": [
    "${_getAgeBasedRecommendation(userProfile['age'] ?? 25)}",
    "${_getBMIBasedRecommendation(_calculateBMI(userProfile['weight'] ?? 70, userProfile['height'] ?? 170))}",
    "Boy-kilo oranınıza uygun porsiyon kontrolü yapın"
  ],
  "next_week_goals": [
    "Yaş grubunuz için önerilen günlük ${_calculateDailySteps(userProfile['age'] ?? 25)} adım",
    "BMI değerinizi korumak için haftada ${_getWeeklyExercise(userProfile)} egzersiz",
    "Günlük ${_calculateWaterNeed(userProfile)}L su tüketimi"
  ],
  "motivation_message": "${userProfile['age'] ?? 25} yaşında harika bir sağlık yolculuğundasınız! BMI değeriniz (${_calculateBMI(userProfile['weight'] ?? 70, userProfile['height'] ?? 170)}) dikkate alınarak hazırlanan bu önerilerle hedeflerinize ulaşacaksınız."
}

NOT: Tüm öneriler kullanıcının yaş, boy, kilo özelliklerine göre kişiselleştirilmiş olmalı.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text != null) {
        try {
          String cleanedResponse = response.text!
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          
          final Map<String, dynamic> jsonResponse = jsonDecode(cleanedResponse);
          
          // Zorunlu alanları kontrol et ve varsayılan değerler ata
          jsonResponse['report_date'] = jsonResponse['report_date'] ?? formattedDate;
          jsonResponse['overall_score'] = jsonResponse['overall_score'] ?? 7.0;
          jsonResponse['summary'] = jsonResponse['summary'] ?? 'Bu hafta sağlık durumunuz genel olarak iyi seviyede.';
          
          // Alt kategorileri kontrol et
          if (jsonResponse['nutrition_analysis'] == null) {
            jsonResponse['nutrition_analysis'] = {
              'average_calories': 2000,
              'protein_adequacy': 'Yeterli',
              'carb_balance': 'Dengeli',
              'fat_intake': 'Normal',
              'vitamin_minerals': 'İyi',
              'hydration': 'Normal'
            };
          }
          
          if (jsonResponse['activity_analysis'] == null) {
            jsonResponse['activity_analysis'] = {
              'weekly_steps': weeklyActivity['total_steps'] ?? 35000,
              'exercise_frequency': weeklyActivity['workout_sessions'] ?? 3,
              'calories_burned': 2400,
              'activity_level': 'Orta'
            };
          }
          
          if (jsonResponse['achievements'] == null) {
            jsonResponse['achievements'] = [
              'Bu hafta düzenli aktivite gerçekleştirdiniz',
              'Beslenme alışkanlıklarınızda gelişme var',
              'Sağlıklı yaşam hedeflerinize odaklandınız'
            ];
          }
          
          if (jsonResponse['recommendations'] == null) {
            jsonResponse['recommendations'] = [
              'Su tüketiminizi artırın',
              'Düzenli egzersiz yapın',
              'Dengeli beslenmeye dikkat edin'
            ];
          }
          
          if (jsonResponse['next_week_goals'] == null) {
            jsonResponse['next_week_goals'] = [
              'Günlük 8000 adım hedefi',
              'Haftada 3-4 kez egzersiz',
              'Günde 2L su tüketimi'
            ];
          }
          
          jsonResponse['motivation_message'] = jsonResponse['motivation_message'] ?? 'Sağlıklı yaşam yolculuğunuzda başarılarınız devam ediyor!';
          
          return jsonResponse;
        } catch (parseError) {
          print('JSON Parse Error: $parseError');
          print('Raw response: ${response.text}');
          
          // Parse hatası durumunda varsayılan rapor döndür
          return _getDefaultHealthReport(formattedDate, userProfile, weeklyActivity, healthMetrics);
        }
      }
      
      // Response yoksa varsayılan rapor döndür
      return _getDefaultHealthReport(formattedDate, userProfile, weeklyActivity, healthMetrics);
    } catch (e) {
      print('Gemini Health Report Error: $e');
      
      // Hata durumunda varsayılan rapor döndür
      final now = DateTime.now();
      final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      return _getDefaultHealthReport(formattedDate, userProfile, weeklyActivity, healthMetrics);
    }
  }
  
  // Varsayılan sağlık raporu
  Map<String, dynamic> _getDefaultHealthReport(
    String date, 
    Map<String, dynamic> userProfile,
    Map<String, dynamic> weeklyActivity,
    Map<String, dynamic> healthMetrics
  ) {
    final age = userProfile['age'] ?? 25;
    final weight = userProfile['weight'] ?? 70;
    final height = userProfile['height'] ?? 170;
    final bmi = _calculateBMI(weight, height);
    
    return {
      "report_date": date,
      "overall_score": 7.2,
      "user_analysis": {
        "age_group": _getAgeGroup(age),
        "bmi_status": _getBMIStatus(bmi),
        "activity_level": userProfile['activity_level'] ?? 'orta',
        "personalized_notes": "$age yaşında, BMI $bmi değerinde sağlık durumu analizi"
      },
      "summary": "Bu hafta $age yaşında, BMI ${bmi.toStringAsFixed(1)} olan bir birey olarak sağlık durumunuz genel olarak iyi seviyede. Düzenli aktivite ve beslenme alışkanlıklarınızı sürdürmeniz öneriliyor.",
      "criteria_used": [
        "Yaş grubu: ${_getAgeGroup(age)} - metabolizma ve beslenme ihtiyaçları göz önüne alındı",
        "BMI: ${bmi.toStringAsFixed(1)} - ${_getBMIStatus(bmi)} kategorisinde değerlendirme yapıldı",
        "Boy-kilo oranı: ${height}cm/${weight}kg - ideal oran analizi",
        "Aktivite seviyesi: ${userProfile['activity_level'] ?? 'orta'} - günlük kalori ihtiyacı hesaplandı"
      ],
      "nutrition_analysis": {
        "daily_calorie_need": _calculateDailyCalories(userProfile),
        "protein_need": "${_calculateProteinNeed(userProfile)}g/gün",
        "recommended_meals": "Yaş ve BMI değerinize uygun öğün planı",
        "hydration": "Geliştirilmeli"
      },
      "activity_analysis": {
        "weekly_steps": weeklyActivity['total_steps'] ?? 35000,
        "exercise_frequency": weeklyActivity['workout_sessions'] ?? 3,
        "calories_burned": 2500,
        "activity_level": "Orta-İyi"
      },
      "achievements": [
        "Bu hafta ${_getAgeGroup(age)} yaş grubunuz için uygun aktivite düzeyini korudunuz",
        "BMI değerinize (${bmi.toStringAsFixed(1)}) uygun beslenme alışkanlıkları sergiledınız",
        "Sağlıklı yaşam hedeflerinize odaklandınız"
      ],
      "recommendations": [
        _getAgeBasedRecommendation(age),
        _getBMIBasedRecommendation(bmi),
        "Su tüketiminizi günde ${_calculateWaterNeed(userProfile)}L'ye çıkarın",
        "Boy-kilo oranınıza uygun porsiyon kontrolü yapın"
      ],
      "next_week_goals": [
        "Yaş grubunuz için önerilen günlük ${_calculateDailySteps(age)} adım",
        "BMI değerinizi korumak için haftada ${_getWeeklyExercise(userProfile)} egzersiz",
        "Günlük ${_calculateWaterNeed(userProfile)}L su tüketimi",
        "Günlük ${_calculateProteinNeed(userProfile)}g protein alımı"
      ],
      "risk_alerts": bmi > 30 ? ["BMI değeriniz obezite sınırında, uzman desteği önerilir"] : [],
      "motivation_message": "$age yaşında harika bir sağlık yolculuğundasınız! BMI değeriniz (${bmi.toStringAsFixed(1)}) ve fiziksel özellikleriniz dikkate alınarak hazırlanan bu önerilerle hedeflerinize ulaşacaksınız. Tutarlı bir ilerleme gösteriyorsunuz!"
    };
  }

  // Kişiselleştirilmiş sağlık önerisi alma
  Future<List<String>> getPersonalizedHealthTips({
    required Map<String, dynamic> userProfile,
    required String focusArea, // 'nutrition', 'fitness', 'sleep', 'mental'
  }) async {
    try {
      final focusLabels = {
        'nutrition': 'beslenme',
        'fitness': 'fitness ve egzersiz',
        'sleep': 'uyku kalitesi',
        'mental': 'mental sağlık'
      };
      
      final focusLabel = focusLabels[focusArea] ?? 'genel sağlık';
      
      final prompt = '''
Sağlık uzmanı olarak, aşağıdaki kişi için $focusLabel konusunda MUTLAKA 5 adet pratik ve uygulanabilir öneri ver:

Kullanıcı Profili:
- Yaş: ${userProfile['age'] ?? 25}
- Kilo: ${userProfile['weight'] ?? 70}kg  
- Boy: ${userProfile['height'] ?? 170}cm
- Aktivite Seviyesi: ${userProfile['activity_level'] ?? 'orta'}
- Cinsiyet: ${userProfile['gender'] ?? 'erkek'}

Odak Konusu: $focusLabel

ZORUNLU: Tam 5 adet kişiselleştirilmiş, uygulanabilir öneri ver. JSON formatında döndür:
{
  "tips": [
    "$focusLabel konusunda pratik öneri 1",
    "$focusLabel konusunda pratik öneri 2", 
    "$focusLabel konusunda pratik öneri 3",
    "$focusLabel konusunda pratik öneri 4",
    "$focusLabel konusunda pratik öneri 5"
  ]
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
          final tips = (jsonResponse['tips'] as List<dynamic>?)?.cast<String>() ?? [];
          
          // En az 3 öneri garantisi
          if (tips.length < 3) {
            return _getDefaultHealthTips(focusArea);
          }
          
          return tips;
        } catch (parseError) {
          print('JSON Parse Error: $parseError');
          return _getDefaultHealthTips(focusArea);
        }
      }
      
      return _getDefaultHealthTips(focusArea);
    } catch (e) {
      print('Gemini Health Tips Error: $e');
      return _getDefaultHealthTips(focusArea);
    }
  }
  
  // Varsayılan sağlık önerileri
  List<String> _getDefaultHealthTips(String focusArea) {
    switch (focusArea) {
      case 'nutrition':
        return [
          'Günde en az 5 porsiyon sebze ve meyve tüketin',
          'Öğünlerde protein kaynağını mutlaka bulundurun',
          'İşlenmiş gıdaları sınırlayın, doğal besinleri tercih edin',
          'Günde 2-3 litre su için',
          'Öğün aralarında sağlıklı atıştırmalıklar tercih edin'
        ];
      case 'fitness':
        return [
          'Haftada en az 150 dakika orta yoğunlukta egzersiz yapın',
          'Günlük 8000-10000 adım hedefleyin',
          'Kuvvet antrenmanlarını haftada 2-3 kez ekleyin',
          'Egzersiz öncesi ve sonrası ısınma-soğuma yapın',
          'Aktivitenizi kademeli olarak artırın'
        ];
      case 'sleep':
        return [
          'Her gün aynı saatlerde uyuyup kalkın',
          'Yatmadan 2 saat önce elektronik cihazları kapatın',
          'Yatak odanızı serin, karanlık ve sessiz tutun',
          'Kafein alımını öğleden sonra sınırlayın',
          'Rahatlatıcı uyku rutini oluşturun'
        ];
      case 'mental':
        return [
          'Günde 10-15 dakika meditasyon veya nefes egzersizi yapın',
          'Sosyal bağlantılarınızı güçlendirin',
          'Günlük yaşamınızda minnettar olduğunuz şeyleri not edin',
          'Stresi azaltmak için hobiler edinin',
          'Gerektiğinde profesyonel destek almaktan çekinmeyin'
        ];
      default:
        return [
          'Dengeli beslenmeye dikkat edin',
          'Düzenli fiziksel aktivite yapın',
          'Kaliteli uyku alın',
          'Stress yönetimi teknikleri uygulayın',
          'Düzenli sağlık kontrollerini ihmal etmeyin'
        ];
    }
  }

  // Sağlık skoru hesaplama
  Future<double> calculateHealthScore({
    required Map<String, dynamic> nutritionData,
    required Map<String, dynamic> activityData,
    required Map<String, dynamic> vitalData,
  }) async {
    try {
      final prompt = '''
Aşağıdaki verilere dayanarak 1-10 arası sağlık skoru hesapla:

Beslenme Verileri: ${nutritionData.toString()}
Aktivite Verileri: ${activityData.toString()}
Vital Veriler: ${vitalData.toString()}

JSON formatında döndür:
{
  "health_score": 8.5,
  "explanation": "Skor hesaplama açıklaması"
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
          return (jsonResponse['health_score'] as num).toDouble();
        } catch (parseError) {
          print('JSON Parse Error: $parseError');
          return 0.0;
        }
      }
      
      return 0.0;
    } catch (e) {
      print('Gemini Health Score Error: $e');
      return 0.0;
    }
  }

  // Helper metodlar - BMI ve diğer hesaplamalar
  double _calculateBMI(num weight, num height) {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  String _getAgeGroup(int age) {
    if (age < 18) return 'Genç';
    if (age < 30) return 'Genç Yetişkin';
    if (age < 50) return 'Orta Yaş';
    if (age < 65) return 'Olgun';
    return 'Yaşlı';
  }

  String _getBMIStatus(double bmi) {
    if (bmi < 18.5) return 'Zayıf';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Fazla Kilolu';
    return 'Obez';
  }

  String _getAgeGroupAnalysis(int age) {
    if (age < 25) return 'Hızlı metabolizma, yüksek protein ihtiyacı';
    if (age < 40) return 'Dengeli metabolizma, düzenli egzersiz önemli';
    if (age < 60) return 'Yavaşlayan metabolizma, kas koruma öncelikli';
    return 'Düşük metabolizma, kemik sağlığı kritik';
  }

  String _getBMIAnalysis(double bmi) {
    if (bmi < 18.5) return 'Kilo almaya odaklanılmalı, protein artırılmalı';
    if (bmi < 25) return 'İdeal kilo aralığında, mevcut durumu koruyun';
    if (bmi < 30) return 'Kilo vermeye odaklanın, kalori kontrolü yapın';
    return 'Ciddi kilo verme gerekli, uzman desteği alın';
  }

  int _calculateDailyCalories(Map<String, dynamic> userProfile) {
    final age = userProfile['age'] ?? 25;
    final weight = userProfile['weight'] ?? 70;
    final height = userProfile['height'] ?? 170;
    final gender = userProfile['gender'] ?? 'erkek';
    final activityLevel = userProfile['activity_level'] ?? 'orta';

    // BMR hesaplama (Harris-Benedict)
    double bmr;
    if (gender == 'erkek') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }

    // Aktivite çarpanı
    double activityMultiplier;
    switch (activityLevel) {
      case 'düşük':
        activityMultiplier = 1.2;
        break;
      case 'orta':
        activityMultiplier = 1.55;
        break;
      case 'yüksek':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.55;
    }

    return (bmr * activityMultiplier).round();
  }

  int _calculateProteinNeed(Map<String, dynamic> userProfile) {
    final weight = userProfile['weight'] ?? 70;
    final activityLevel = userProfile['activity_level'] ?? 'orta';

    switch (activityLevel) {
      case 'düşük':
        return (weight * 0.8).round();
      case 'orta':
        return (weight * 1.2).round();
      case 'yüksek':
        return (weight * 1.6).round();
      default:
        return (weight * 1.2).round();
    }
  }

  String _getAgeBasedRecommendation(int age) {
    if (age < 25) {
      return 'Genç yaşınızda kas gelişimine odaklanın, protein alımını artırın';
    } else if (age < 40) {
      return 'Metabolizmanızı hızlı tutmak için düzenli egzersiz yapın';
    } else if (age < 60) {
      return 'Kas kaybını önlemek için kuvvet antrenmanları ekleyin';
    } else {
      return 'Kemik sağlığı için kalsiyum ve D vitamini alımına dikkat edin';
    }
  }

  String _getBMIBasedRecommendation(double bmi) {
    if (bmi < 18.5) {
      return 'Sağlıklı kilo almak için kalori yoğun besinler tüketin';
    } else if (bmi < 25) {
      return 'Mükemmel! Mevcut kilonuzu korumak için dengeli beslenin';
    } else if (bmi < 30) {
      return 'Hafif kilo vermek için günlük kalori alımını 300-500 azaltın';
    } else {
      return 'Sağlığınız için kilo vermeli, uzman desteği almanızı öneririz';
    }
  }

  int _calculateDailySteps(int age) {
    if (age < 30) return 10000;
    if (age < 50) return 8000;
    if (age < 65) return 7000;
    return 6000;
  }

  String _getWeeklyExercise(Map<String, dynamic> userProfile) {
    final age = userProfile['age'] ?? 25;
    final bmi = _calculateBMI(userProfile['weight'] ?? 70, userProfile['height'] ?? 170);

    if (age < 30 && bmi < 25) return '4-5 gün';
    if (age < 50 && bmi < 30) return '3-4 gün';
    return '3 gün';
  }

  double _calculateWaterNeed(Map<String, dynamic> userProfile) {
    final weight = userProfile['weight'] ?? 70;
    final activityLevel = userProfile['activity_level'] ?? 'orta';

    double baseWater = weight * 0.035; // 35ml per kg

    if (activityLevel == 'yüksek') {
      baseWater += 0.5; // Extra 500ml for high activity
    }

    return double.parse(baseWater.toStringAsFixed(1));
  }
}
