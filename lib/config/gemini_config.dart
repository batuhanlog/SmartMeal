import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // TODO: Bu API anahtarını güvenli bir şekilde saklayın (environment variables)
  // Gerçek projelerde .env dosyası veya Firebase Remote Config kullanın
  static const String _apiKey = 'AIzaSyCwFHmCA_uDLUQ79ifMvbrS--KZ6tUdUgc';
  
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

  // ...existing code...
}
