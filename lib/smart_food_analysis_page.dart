import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'services/gemini_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SmartFoodAnalysisPage extends StatefulWidget {
  const SmartFoodAnalysisPage({super.key});

  @override
  State<SmartFoodAnalysisPage> createState() => _SmartFoodAnalysisPageState();
}

class _SmartFoodAnalysisPageState extends State<SmartFoodAnalysisPage> with TickerProviderStateMixin {
  // Modern color palette
  final Color primaryColor = const Color(0xFF2E7D32);
  final Color secondaryColor = const Color(0xFF4CAF50);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color cardColor = Colors.white;
  final Color accentColor = const Color(0xFF81C784);

  File? _imageFile;
  Uint8List? _imageBytes;
  bool _isAnalyzing = false;
  bool _isExpanded = false;
  Map<String, dynamic>? _analysisResult;
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      
      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _imageBytes = null;
          _analysisResult = null;
          _isExpanded = false;
        });
        
        _showSuccessSnackBar('📸 Fotoğraf başarıyla çekildi!');
        _fadeController.forward();
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
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _imageBytes = bytes;
            _imageFile = null;
            _analysisResult = null;
            _isExpanded = false;
          });
        } else {
          setState(() {
            _imageFile = File(image.path);
            _imageBytes = null;
            _analysisResult = null;
            _isExpanded = false;
          });
        }
        
        _showSuccessSnackBar('🖼️ Fotoğraf başarıyla seçildi!');
        _fadeController.forward();
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

      final result = await _geminiService.analyzeFoodPhoto(imageBytes!);

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });
        
        _slideController.forward();
        
        if (result['error_type'] != null) {
          _showErrorSnackBar('⚠️ ${result['analysis']}');
        } else {
          _showSuccessSnackBar('🎉 AI analizi tamamlandı!');
        }
      }
    } catch (e) {
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
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _resetAnalysis() {
    setState(() {
      _imageFile = null;
      _imageBytes = null;
      _analysisResult = null;
      _isExpanded = false;
    });
    _fadeController.reset();
    _slideController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '🤖 Akıllı Yemek Analizi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_analysisResult != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
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
            if (_analysisResult != null) _buildAnalysisResults(),
            const SizedBox(height: 100), // Bottom navigation için alan
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'AI ile Yemek Keşfet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fotoğrafını çek, yemeğinin tarihini ve besin değerlerini öğren',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_imageFile == null && _imageBytes == null) ...[
            _buildPhotoButtons(),
          ] else ...[
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildSelectedImage(),
            ),
            const SizedBox(height: 20),
            _buildAnalyzeButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.camera_alt_rounded,
                title: 'Fotoğraf Çek',
                subtitle: 'Kamera ile yemek çek',
                color: primaryColor,
                onTap: _takePhoto,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.photo_library_rounded,
                title: 'Galeriden Seç',
                subtitle: 'Mevcut fotoğraf seç',
                color: accentColor,
                onTap: _pickFromGallery,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue.shade600, size: 30),
              const SizedBox(height: 12),
              Text(
                'İpucu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'En iyi sonuç için yemeği iyi ışıkta, yakın mesafeden ve net bir şekilde çekin.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _imageFile != null
            ? Image.file(
                _imageFile!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            : Image.memory(
                _imageBytes!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isAnalyzing ? null : _analyzeFood,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: _isAnalyzing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'AI Analiz Yapıyor...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_rounded, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'AI ile Analiz Et',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt_rounded, size: 20),
                label: const Text('Yeni Fotoğraf'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library_rounded, size: 20),
                label: const Text('Galeriden'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisResults() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildResultHeader(),
              const SizedBox(height: 20),
              _buildNutritionCard(),
              const SizedBox(height: 16),
              _buildExpandButton(),
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                _buildHistoricalInfo(),
                const SizedBox(height: 16),
                _buildRecipeCard(),
                const SizedBox(height: 16),
                _buildSuggestionsCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    final result = _analysisResult!;
    final isError = result['error_type'] != null;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isError ? Colors.red.shade200 : primaryColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: (isError ? Colors.red : primaryColor).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            result['emoji'] ?? '🍽️',
            style: const TextStyle(fontSize: 50),
          ),
          const SizedBox(height: 12),
          Text(
            result['food_name'] ?? 'Bilinmeyen',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isError ? Colors.red.shade700 : primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (result['confidence'] != null && result['confidence'] > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Güven: %${result['confidence']}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Analiz Tarihi: ${result['analysis_date']}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    final result = _analysisResult!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_dining, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                'Besin Değerleri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNutritionItem(
                  '🔥 Kalori',
                  '${result['calories'] ?? 0}',
                  'kcal',
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildNutritionItem(
                  '💪 Protein',
                  '${result['protein'] ?? 0}',
                  'g',
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNutritionItem(
                  '🌾 Karbonhidrat',
                  '${result['carbs'] ?? 0}',
                  'g',
                  Colors.amber,
                ),
              ),
              Expanded(
                child: _buildNutritionItem(
                  '🥑 Yağ',
                  '${result['fat'] ?? 0}',
                  'g',
                  Colors.green,
                ),
              ),
            ],
          ),
          if ((result['fiber'] ?? 0) > 0 || (result['sodium'] ?? 0) > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if ((result['fiber'] ?? 0) > 0)
                  Expanded(
                    child: _buildNutritionItem(
                      '🌿 Lif',
                      '${result['fiber'] ?? 0}',
                      'g',
                      Colors.lightGreen,
                    ),
                  ),
                if ((result['sodium'] ?? 0) > 0)
                  Expanded(
                    child: _buildNutritionItem(
                      '🧂 Sodyum',
                      '${result['sodium'] ?? 0}',
                      'mg',
                      Colors.grey,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (result['health_score'] != null && result['health_score'] > 0)
            _buildHealthScore(result['health_score']),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String title, String value, String unit, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              children: [
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScore(int score) {
    Color scoreColor;
    String scoreText;
    
    if (score >= 8) {
      scoreColor = Colors.green;
      scoreText = 'Çok Sağlıklı';
    } else if (score >= 6) {
      scoreColor = Colors.orange;
      scoreText = 'Sağlıklı';
    } else if (score >= 4) {
      scoreColor = Colors.amber;
      scoreText = 'Orta';
    } else {
      scoreColor = Colors.red;
      scoreText = 'Az Sağlıklı';
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite, color: scoreColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Sağlık Skoru: ',
            style: TextStyle(
              fontSize: 14,
              color: scoreColor.withOpacity(0.8),
            ),
          ),
          Text(
            '$score/10',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($scoreText)',
            style: TextStyle(
              fontSize: 12,
              color: scoreColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
        label: Text(_isExpanded ? 'Detayları Gizle' : 'Detayları Genişlet'),
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoricalInfo() {
    final result = _analysisResult!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_edu, color: Color(0xFF8B5CF6)),
              SizedBox(width: 8),
              Text(
                'Tarihi ve Kültürel Bilgiler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (result['historical_info'] != null && 
              result['historical_info'].toString().length > 10) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.menu_book, color: Color(0xFF8B5CF6), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tarihçe',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result['historical_info'],
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (result['cultural_significance'] != null && 
              result['cultural_significance'].toString().length > 10) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.public, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Kültürel Önemi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result['cultural_significance'],
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (result['traditional_preparation'] != null && 
              result['traditional_preparation'].toString().length > 10) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.restaurant, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Geleneksel Hazırlık',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result['traditional_preparation'],
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipeCard() {
    final result = _analysisResult!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant_menu, color: Color(0xFF1976D2)),
              SizedBox(width: 8),
              Text(
                'Tarif',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.1)),
            ),
            child: Text(
              result['recipe'] ?? 'Tarif bilgisi mevcut değil.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard() {
    final result = _analysisResult!;
    final suggestions = result['suggestions'] as List<dynamic>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text(
                'Beslenme Önerileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (suggestions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Şu an için öneri bulunmuyor.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
