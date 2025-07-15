import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // TODO: Bu API anahtarını güvenli bir şekilde saklayın (environment variables)
  // Gerçek projelerde .env dosyası veya Firebase Remote Config kullanın
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
  
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;

  GeminiService() {
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('Lütfen Gemini API anahtarınızı ayarlayın!');
    }
    
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    _visionModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  // ...existing code...
}
