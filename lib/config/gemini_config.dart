import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // TODO: Bu API anahtarını güvenli bir şekilde saklayın (environment variables)
  // Gerçek projelerde .env dosyası veya Firebase Remote Config kullanın
  static const String _apiKey = 'AIzaSyBIJkKmiCZjlcKTIfsI25gs0NLxPhG94Fs';
  
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
