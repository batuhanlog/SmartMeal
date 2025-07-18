import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'services/gemini_service.dart';

class FoodPhotoPage extends StatefulWidget {
  const FoodPhotoPage({super.key});

  @override
  State<FoodPhotoPage> createState() => _FoodPhotoPageState();
}

class _FoodPhotoPageState extends State<FoodPhotoPage> {
  // --- YENİ RENK PALETİ ---
  final Color primaryColor = Colors.green.shade800;
  final Color secondaryColor = Colors.green.shade600;
  final Color backgroundColor = Colors.grey.shade100;

  File? _imageFile;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();

  Future<void> _takePhoto() async {
    // ... Bu fonksiyonun içeriği aynı kalıyor ...
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _analysisResult = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fotoğraf çekme hatası: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _pickFromGallery() async {
    // ... Bu fonksiyonun içeriği aynı kalıyor ...
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _analysisResult = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Galeri erişim hatası: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _analyzeFood() async {
    // ... Bu fonksiyonun içeriği aynı kalıyor ...
    if (_imageFile == null) return;
    setState(() => _isAnalyzing = true);
    try {
      final Uint8List imageBytes = await _imageFile!.readAsBytes();
      final result = await _geminiService.analyzeFoodPhoto(imageBytes);
      if(mounted) {
        setState(() {
        _analysisResult = {
          'foodName': result['food_name'] ?? 'Bilinmeyen Yemek',
          'calories': result['calories'] ?? 0,
          'protein': '${result['protein'] ?? 0}g',
          'carbs': '${result['carbs'] ?? 0}g',
          'fat': '${result['fat'] ?? 0}g',
          'confidence': (result['confidence'] ?? 0) / 100.0,
          'healthScore': result['health_score'] ?? 5,
          'analysis': result['analysis'] ?? 'Analiz yapılamadı',
          'recommendations': result['suggestions'] ?? ['Önerimiz bulunmuyor'],
        };
        _isAnalyzing = false;
      });
      }
    } catch (e) {
      if(mounted){
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analiz hatası: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // --- YARDIMCI FONKSİYONLAR SINIF İÇİNE ALINDI VE RENKLER GÜNCELLENDİ ---

  Widget _buildAnalysisResult() {
    if (_analysisResult == null) return const SizedBox.shrink();

    final result = _analysisResult!;
    final healthScore = result['healthScore'] as int;
    final confidence = result['confidence'] as double;

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(result['foodName'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _getHealthColor(healthScore), borderRadius: BorderRadius.circular(20)),
                  child: Text('Sağlık: $healthScore/10', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Güven: ${(confidence * 100).toInt()}%', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 16),
            
            if (result['analysis'] != null && result['analysis'].isNotEmpty) ...[
              Text('AI Analizi', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: primaryColor)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(result['analysis'], style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 16),
            ],
            
            Text('Besin Değerleri', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionInfo('Kalori', '${result['calories']}', Icons.local_fire_department, Colors.orange.shade600),
                _buildNutritionInfo('Protein', result['protein'], Icons.fitness_center, Colors.blue.shade600),
                _buildNutritionInfo('Karbonhidrat', result['carbs'], Icons.grain, Colors.brown.shade500),
                _buildNutritionInfo('Yağ', result['fat'], Icons.opacity, Colors.amber.shade600),
              ],
            ),
            const SizedBox(height: 16),
            
            Text('Beslenme Önerileri', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: primaryColor)),
            const SizedBox(height: 8),
            ...((result['recommendations'] as List<dynamic>).cast<String>().map((rec) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(child: Text(rec, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              ),
            )),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _imageFile = null;
                      _analysisResult = null;
                    }),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yeni Analiz'),
                    style: OutlinedButton.styleFrom(foregroundColor: primaryColor, side: BorderSide(color: primaryColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Analiz kaydedildi!'), backgroundColor: secondaryColor),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Kaydet'),
                    style: ElevatedButton.styleFrom(backgroundColor: secondaryColor, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionInfo(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Color _getHealthColor(int score) {
    if (score >= 8) return Colors.green.shade600;
    if (score >= 6) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Yemek Analizi'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
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
                    const Icon(Icons.camera_enhance, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      '🤖 AI ile Yemek Analizi',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yemeğinizin fotoğrafını çekin veya galeriden seçin!',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: double.infinity,
              height: 280,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Yemek fotoğrafı ekleyin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                      ],
                    ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Kamera'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galeri'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_imageFile != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeFood,
                    icon: _isAnalyzing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.psychology_outlined),
                    label: Text(_isAnalyzing ? '🤖 AI Analiz Yapıyor...' : '🚀 AI ile Analiz Et', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

            _buildAnalysisResult(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}