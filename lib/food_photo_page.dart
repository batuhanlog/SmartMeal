import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'services/gemini_service.dart';
import 'services/calorie_calculator_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Bu versiyonda harici paket veya sorunlu shade kullanımı yoktur.

class FoodPhotoPage extends StatefulWidget {
  const FoodPhotoPage({super.key});

  @override
  State<FoodPhotoPage> createState() => _FoodPhotoPageState();
}

/// Sağlık durumuyla ilgili 3 farklı tipteki veriyi bir arada tutan
/// basit ve güvenli yardımcı sınıf.
class _HealthStatus {
  final String label;
  final Color color;
  final IconData icon;

  const _HealthStatus(this.label, this.color, this.icon);
}

class _FoodPhotoPageState extends State<FoodPhotoPage> {
  // Renk Paleti (Ana sayfayla uyumlu)
  final Color primaryColor = Colors.green.shade800;
  final Color backgroundColor = Colors.grey.shade100;

  // Durum Değişkenleri
  File? _imageFile;
  Uint8List? _imageBytes;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  Map<String, dynamic>? _calorieResult;
  Map<String, dynamic>? _userProfile;
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();
  final CalorieCalculatorService _calorieService = CalorieCalculatorService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && doc.exists) {
          setState(() => _userProfile = doc.data());
        }
      }
    } catch (e) {
      print('Profil yükleme hatası: $e');
    }
  }

  // --- LOGIC FONKSİYONLARI ---
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (photo == null) return;
      if (kIsWeb) {
        final bytes = await photo.readAsBytes();
        setState(() { 
          _imageBytes = bytes; 
          _imageFile = null; 
          _analysisResult = null;
          _calorieResult = null;
        });
      } else {
        setState(() { 
          _imageFile = File(photo.path); 
          _imageBytes = null; 
          _analysisResult = null;
          _calorieResult = null;
        });
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Fotoğraf çekme hatası: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() { 
          _imageBytes = bytes; 
          _imageFile = null; 
          _analysisResult = null;
          _calorieResult = null;
        });
      } else {
        setState(() { 
          _imageFile = File(image.path); 
          _imageBytes = null; 
          _analysisResult = null;
          _calorieResult = null;
        });
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Galeri erişim hatası: $e');
    }
  }

  Future<void> _analyzeFood() async {
    if (_imageFile == null && _imageBytes == null) return;
    setState(() => _isAnalyzing = true);
    try {
      Uint8List? imageBytes = _imageBytes ?? await _imageFile?.readAsBytes();
      if (imageBytes == null) throw Exception("Görsel verisi okunamadı.");
      
      // Paralel olarak hem yemek analizi hem de kalori hesaplama yap
      final results = await Future.wait([
        _geminiService.analyzeFoodPhoto(imageBytes),
        _calorieService.calculateCaloriesFromPhoto(imageBytes),
      ]);
      
      if (mounted) {
        setState(() {
          _analysisResult = {
            'foodName': results[0]['food_name'] ?? 'Bilinmeyen Yemek',
            'calories': results[0]['calories'] ?? 0,
            'protein': results[0]['protein'] ?? 0,
            'carbs': results[0]['carbs'] ?? 0,
            'fat': results[0]['fat'] ?? 0,
            'confidence': (results[0]['confidence'] ?? 0) / 100.0,
            'healthScore': results[0]['health_score'] ?? 5,
            'analysis': results[0]['analysis'] ?? 'Analiz yapılamadı.',
            'recommendations': results[0]['suggestions'] as List<dynamic>? ?? ['Öneri bulunmuyor.'],
          };
          _calorieResult = results[1];
        });
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Analiz hatası: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red.shade700));
  }

  // Günlük kalori hedefi hesaplama
  Map<String, dynamic>? _getDailyCalorieTarget() {
    if (_userProfile == null) return null;
    
    return _calorieService.calculateDailyCalorieNeeds(
      age: _userProfile!['age'] ?? 25,
      gender: _userProfile!['gender'] ?? 'Erkek',
      weight: _userProfile!['weight']?.toDouble() ?? 70.0,
      height: _userProfile!['height']?.toDouble() ?? 170.0,
      activityLevel: _userProfile!['activityLevel'] ?? 'Orta',
      goal: _userProfile!['goal'] ?? 'maintain',
    );
  }

  // --- ANA WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Yemek & Kalori Analizi'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildImagePicker(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            if (_analysisResult != null) _buildAnalysisResult(),
            if (_calorieResult != null) _buildCalorieResult(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- ARAYÜZ OLUŞTURMA FONKSİYONLARI ---

  Widget _buildImagePicker() {
    bool hasImage = _imageFile != null || _imageBytes != null;
    return hasImage
        ? ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: double.infinity,
              height: 300,
              child: kIsWeb
                  ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                  : Image.file(_imageFile!, fit: BoxFit.cover),
            ),
          )
        : Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu_rounded, size: 80, color: primaryColor.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('Yemeğinin fotoğrafını yükle', style: TextStyle(fontSize: 20, color: Colors.black54)),
                const SizedBox(height: 20),
                Text('Galeriden seç veya kamera ile çek', style: TextStyle(fontSize: 14, color: primaryColor)),
              ],
            ),
          );
  }

  Widget _buildActionButtons() {
    bool hasImage = _imageFile != null || _imageBytes != null;
    return hasImage
      ? SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _analyzeFood,
            icon: _isAnalyzing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome),
            label: Text(_isAnalyzing ? 'Analiz Ediliyor...' : 'Yemek & Kalori Analizi', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        )
      : Row(
          children: [
            Expanded(child: _buildChoiceButton(onPressed: _takePhoto, icon: Icons.camera_alt_outlined, label: 'Kamera')),
            const SizedBox(width: 16),
            Expanded(child: _buildChoiceButton(onPressed: _pickFromGallery, icon: Icons.photo_library_outlined, label: 'Galeri', isPrimary: true)),
          ],
        );
  }
  
  Widget _buildChoiceButton({required VoidCallback onPressed, required IconData icon, required String label, bool isPrimary = false}) {
    return isPrimary
      ? ElevatedButton.icon(
          onPressed: onPressed, icon: Icon(icon), label: Text(label),
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        )
      : OutlinedButton.icon(
          onPressed: onPressed, icon: Icon(icon), label: Text(label),
          style: OutlinedButton.styleFrom(foregroundColor: primaryColor, side: BorderSide(color: primaryColor), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        );
  }

  Widget _buildAnalysisResult() {
    final result = _analysisResult!;
    final healthStatus = _getHealthStatus(result['healthScore'] as int);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(result['foodName'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Column(
                children: [
                  Icon(healthStatus.icon, color: healthStatus.color, size: 28),
                  const SizedBox(height: 4),
                  Text(healthStatus.label, style: TextStyle(color: healthStatus.color, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              )
            ],
          ),
          const Divider(height: 32),
          
          _buildSectionTitle('Besin Değerleri', Icons.pie_chart_outline_rounded),
          const SizedBox(height: 16),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.2, mainAxisSpacing: 12, crossAxisSpacing: 12),
            children: [
              _buildNutritionInfo('Kalori', '${result['calories']}', Colors.orange),
              _buildNutritionInfo('Protein', '${result['protein']}g', Colors.blue),
              _buildNutritionInfo('Karbonhidrat', '${result['carbs']}g', Colors.purple),
              _buildNutritionInfo('Yağ', '${result['fat']}g', Colors.amber),
            ],
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('AI Asistan Diyor Ki', Icons.smart_toy_outlined),
          const SizedBox(height: 8),
          Text(result['analysis'], style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
          const SizedBox(height: 24),

          _buildSectionTitle('Tatlı Öneriler', Icons.lightbulb_outline_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: (result['recommendations'] as List<dynamic>).map((rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(children: [
                  Icon(Icons.check, size: 20, color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(child: Text(rec.toString(), style: const TextStyle(fontSize: 15, color: Colors.black54))),
                ]),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieResult() {
    final result = _calorieResult!;
    final dailyTarget = _getDailyCalorieTarget();
    final totalCalories = result['total_calories'] ?? 0;
    final targetCalories = dailyTarget?['target_calories'] ?? 2000;
    final percentage = (totalCalories / targetCalories * 100).clamp(0, 100);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('📊 Detaylı Kalori Analizi', Icons.calculate_outlined),
          const SizedBox(height: 20),

          // Günlük hedef karşılaştırması
          if (dailyTarget != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Günlük Hedef: ${targetCalories} kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Bu Öğün: $totalCalories kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage > 100 ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Günlük hedefinizin %${percentage.toStringAsFixed(1)}\'i',
                    style: TextStyle(
                      color: percentage > 100 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Toplam besin değerleri
          _buildSectionTitle('Toplam Besin Değerleri', Icons.analytics_outlined),
          const SizedBox(height: 16),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              childAspectRatio: 2.2, 
              mainAxisSpacing: 12, 
              crossAxisSpacing: 12
            ),
            children: [
              _buildNutritionInfo('Toplam Kalori', '${result['total_calories']}', Colors.orange),
              _buildNutritionInfo('Toplam Protein', '${result['total_protein']}g', Colors.blue),
              _buildNutritionInfo('Toplam Karbonhidrat', '${result['total_carbs']}g', Colors.purple),
              _buildNutritionInfo('Toplam Yağ', '${result['total_fat']}g', Colors.amber),
            ],
          ),
          const SizedBox(height: 20),

          // Yemek listesi
          _buildSectionTitle('Yemek Detayları', Icons.restaurant_menu_outlined),
          const SizedBox(height: 12),
          ...(result['foods'] as List<dynamic>).map((food) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food['name'] ?? 'Bilinmeyen',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        food['portion'] ?? '',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${food['calories']} kcal',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          )).toList(),
          const SizedBox(height: 20),

          // Öneriler
          if (result['recommendations'] != null) ...[
            _buildSectionTitle('Öneriler', Icons.lightbulb_outline_rounded),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: (result['recommendations'] as List<dynamic>).map((rec) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(children: [
                    Icon(Icons.check, size: 20, color: primaryColor),
                    const SizedBox(width: 12),
                    Expanded(child: Text(rec.toString(), style: const TextStyle(fontSize: 15, color: Colors.black54))),
                  ]),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- YARDIMCI WIDGET'LAR VE FONKSİYONLAR ---

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: Colors.grey.shade700, size: 22),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    ]);
  }
  
  _HealthStatus _getHealthStatus(int score) {
    if (score >= 8) return const _HealthStatus('Mükemmel!', Colors.green, Icons.sentiment_very_satisfied_rounded);
    if (score >= 6) return const _HealthStatus('İyi Seçim', Colors.blue, Icons.sentiment_satisfied_alt_rounded);
    if (score >= 4) return const _HealthStatus('Dikkat Et', Colors.orange, Icons.sentiment_neutral_rounded);
    return const _HealthStatus('Pek Değil', Colors.red, Icons.sentiment_very_dissatisfied_rounded);
  }

  Widget _buildNutritionInfo(String label, String value, Color color) {
    // DÜZELTME: Gelen rengi programatik olarak koyulaştırıyoruz.
    // Color.lerp(renk1, renk2, karışım_oranı)
    final Color darkColor = Color.lerp(color, Colors.black, 0.5)!;
    final Color veryDarkColor = Color.lerp(color, Colors.black, 0.7)!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: darkColor)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: veryDarkColor)),
        ],
      ),
    );
  }
}