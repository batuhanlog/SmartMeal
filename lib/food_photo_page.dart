import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'services/gemini_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FoodPhotoPage extends StatefulWidget {
  const FoodPhotoPage({super.key});

  @override
  State<FoodPhotoPage> createState() => _FoodPhotoPageState();
}

class _FoodPhotoPageState extends State<FoodPhotoPage> {
  // Modern color palette
  final Color primaryColor = const Color(0xFF2E7D32);
  final Color secondaryColor = const Color(0xFF4CAF50);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color cardColor = Colors.white;

  File? _imageFile;
  Uint8List? _imageBytes;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _imageBytes = null;
          _analysisResult = null;
        });
        
        _showSuccessSnackBar('Fotoğraf başarıyla çekildi! 📸');
      }
    } catch (e) {
      _showErrorSnackBar('Fotoğraf çekme hatası: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _imageBytes = bytes;
            _imageFile = null;
            _analysisResult = null;
          });
        } else {
          setState(() {
            _imageFile = File(image.path);
            _imageBytes = null;
            _analysisResult = null;
          });
        }
        
        _showSuccessSnackBar('Fotoğraf başarıyla seçildi! 🖼️');
      }
    } catch (e) {
      _showErrorSnackBar('Galeri erişim hatası: $e');
    }
  }

  Future<void> _analyzeFood() async {
    if (_imageFile == null && _imageBytes == null) {
      _showErrorSnackBar('Önce bir fotoğraf seçin veya çekin!');
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      Uint8List? imageBytes;

      if (_imageFile != null) {
        imageBytes = await _imageFile!.readAsBytes();
      } else if (_imageBytes != null) {
        imageBytes = _imageBytes!;
      }

      print('🔍 Analiz başlatılıyor...');
      final result = await _geminiService.analyzeFoodPhoto(imageBytes!);
      print('📊 Analiz sonucu: $result');

      if (mounted) {
        setState(() {
          _analysisResult = {
            'foodName': result['food_name'] ?? 'Bilinmeyen Yemek',
            'emoji': result['emoji'] ?? '🍽️',
            'calories': result['calories'] ?? 0,
            'protein': result['protein'] ?? 0,
            'carbs': result['carbs'] ?? 0,
            'fat': result['fat'] ?? 0,
            'fiber': result['fiber'] ?? 0,
            'sodium': result['sodium'] ?? 0,
            'sugar': result['sugar'] ?? 0,
            'confidence': result['confidence'] ?? 0,
            'healthScore': result['health_score'] ?? 5,
            'recipe': result['recipe'] ?? 'Tarif bulunamadı',
            'analysis': result['analysis'] ?? 'Analiz yapılamadı',
            'suggestions': result['suggestions'] ?? ['Önerimiz bulunmuyor'],
            'analysisDate': result['analysis_date'] ?? DateTime.now().toString().split(' ')[0],
            'error_type': result['error_type'], // Error type'ı da ekleyelim
            'historical_info': result['historical_info'] ?? 'Tarihi bilgi mevcut değil',
            'cultural_significance': result['cultural_significance'] ?? 'Kültürel bilgi mevcut değil',
            'traditional_preparation': result['traditional_preparation'] ?? 'Geleneksel tarif mevcut değil',
          };
          _isAnalyzing = false;
        });
        
        if (result['error_type'] == 'not_food') {
          _showErrorSnackBar('❌ Bu görsel yemek içermiyor');
        } else {
          _showSuccessSnackBar('🎉 AI analizi tamamlandı!');
        }
      }
    } catch (e) {
      print('❌ Analiz hatası: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _showErrorSnackBar('Analiz hatası: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _resetAnalysis() {
    setState(() {
      _imageFile = null;
      _imageBytes = null;
      _analysisResult = null;
    });
  }

  void _saveAnalysis() {
    if (_analysisResult != null) {
      _showSuccessSnackBar('✅ Analiz başarıyla kaydedildi!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '🤖 AI Yemek Analizi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_analysisResult != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetAnalysis,
              tooltip: 'Yeni Analiz',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildImageSection(),
            _buildActionButtons(),
            if (_isAnalyzing) _buildLoadingSection(),
            if (_analysisResult != null) _buildAnalysisResult(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryColor, secondaryColor],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.camera_enhance,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gemini AI ile Yemek Analizi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Yemeğinizin fotoğrafını çekin ve AI ile detaylı analiz alın!\nBesin değerleri, tarif ve sağlık önerileri',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      height: 300,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _imageFile != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ),
                  ),
                ],
              ),
            )
          : _imageBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_a_photo_outlined,
                        size: 64,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Yemek Fotoğrafı Ekleyin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kamera veya galeriden seçin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: (_imageFile == null && _imageBytes == null)
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Kamera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Galeri'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyzeFood,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.psychology_rounded),
                label: Text(
                  _isAnalyzing ? 'AI Analiz Yapıyor...' : '🚀 AI ile Analiz Et',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            '🤖 Gemini AI Çalışıyor...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yemeğiniz analiz ediliyor, lütfen bekleyin',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    if (_analysisResult == null) return const SizedBox.shrink();

    final result = _analysisResult!;
    
    // Yemek olmayan fotoğraf kontrolü
    if (result['error_type'] == 'not_food') {
      return Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.warning_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                '⚠️ Yemek Tespit Edilemedi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Bu görsel herhangi bir yemek içermiyor.\nLütfen yemek görseli atın.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                '💡 İpuçları:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...((result['suggestions'] as List<dynamic>?) ?? []).map((suggestion) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _resetAnalysis,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text(
                    'Yeni Fotoğraf Çek',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFoodHeader(result),
            const SizedBox(height: 24),
            _buildNutritionSection(result),
            const SizedBox(height: 24),
            _buildRecipeSection(result),
            const SizedBox(height: 24),
            _buildAnalysisSection(result),
            const SizedBox(height: 24),
            _buildSuggestionsSection(result),
            const SizedBox(height: 24),
            _buildActionButtonsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodHeader(Map<String, dynamic> result) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            result['emoji'],
            style: const TextStyle(fontSize: 32),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result['foodName'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildScoreChip('Güven: ${result['confidence']}%', Colors.blue),
                  const SizedBox(width: 8),
                  _buildScoreChip('Sağlık: ${result['healthScore']}/10', _getHealthColor(result['healthScore'])),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Analiz Tarihi: ${result['analysisDate']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNutritionSection(Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Besin Değerleri (100g)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildNutritionCard('Kalori', '${result['calories']}', 'kcal', Icons.local_fire_department, Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildNutritionCard('Protein', '${result['protein']}', 'g', Icons.fitness_center, Colors.blue)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildNutritionCard('Karbonhidrat', '${result['carbs']}', 'g', Icons.grain, Colors.brown)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildNutritionCard('Yağ', '${result['fat']}', 'g', Icons.opacity, Colors.amber)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildNutritionCard('Lif', '${result['fiber']}', 'g', Icons.eco, Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildNutritionCard('Sodyum', '${result['sodium']}', 'mg', Icons.water_drop, Colors.red)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionCard(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSection(Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '👨‍🍳 Tarif',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Text(
            result['recipe'],
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisSection(Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🤖 AI Analizi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            result['analysis'],
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsSection(Map<String, dynamic> result) {
    final suggestions = result['suggestions'] as List<dynamic>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 Beslenme Önerileri',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...suggestions.map((suggestion) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: Colors.amber.shade700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion.toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildActionButtonsSection() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _resetAnalysis,
            icon: const Icon(Icons.refresh),
            label: const Text('Yeni Analiz'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveAnalysis,
            icon: const Icon(Icons.save),
            label: const Text('Kaydet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getHealthColor(int score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    if (score >= 4) return Colors.deepOrange;
    return Colors.red;
  }
}
