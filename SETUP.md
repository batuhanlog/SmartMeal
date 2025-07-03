# 🚀 Kurulum Talimatları

Bu doküman, **Sağlıklı Beslenme Asistanı** uygulamasını bilgisayarınızda çalıştırmak için gerekli adımları içerir.

## 📋 Gereksinimler

- **Flutter SDK** (3.8.1 veya üzeri)
- **Android Studio** veya **VS Code**
- **Git**
- **Firebase hesabı**
- **Google Cloud hesabı** (Gemini AI için)

## 🔧 Kurulum Adımları

### 1. 📥 Projeyi İndirin

```bash
git clone https://github.com/batuhanlog/ProjectX.git
cd ProjectX
```

### 2. 📦 Bağımlılıkları Yükleyin

```bash
flutter pub get
```

### 3. 🔥 Firebase Kurulumu

#### 3.1 Firebase Projesi Oluşturun
1. [Firebase Console](https://console.firebase.google.com/)'a gidin
2. "Add project" ile yeni proje oluşturun
3. Proje adını "saglikli-beslenme-asistani" yapın

#### 3.2 Firebase CLI Kurulumu
```bash
npm install -g firebase-tools
firebase login
```

#### 3.3 FlutterFire CLI Kurulumu
```bash
dart pub global activate flutterfire_cli
```

#### 3.4 Firebase'i Yapılandırın
```bash
flutterfire configure
```

#### 3.5 Authentication'ı Etkinleştirin
1. Firebase Console > Authentication > Get started
2. Sign-in methods sekmesinde:
   - **Email/Password** - Enable
   - **Google** - Enable (Android/iOS için SHA anahtarları gerekli)

#### 3.6 Firestore'u Etkinleştirin
1. Firebase Console > Firestore Database > Create database
2. **Test mode** ile başlayın
3. Rules'ı aşağıdaki ile değiştirin:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /meal_history/{historyId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /favorite_meals/{favoriteId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### 4. 🤖 Gemini AI Kurulumu

#### 4.1 API Anahtarı Alın
1. [Google AI Studio](https://makersuite.google.com/app/apikey)'ya gidin
2. "Create API Key" ile yeni anahtar oluşturun
3. Anahtarı kopyalayın

#### 4.2 API Anahtarını Ayarlayın
`lib/services/gemini_service.dart` dosyasında:

```dart
static const String _apiKey = 'YOUR_ACTUAL_GEMINI_API_KEY_HERE';
```

**⚠️ Güvenlik Uyarısı:** Gerçek projeler için API anahtarını environment variables veya Firebase Remote Config ile saklayın.

### 5. 📱 Google Sign-In Kurulumu

#### 5.1 Android Kurulumu
1. `android/app/google-services.json` dosyasının mevcut olduğundan emin olun
2. SHA-1 anahtarınızı alın:
```bash
cd android
./gradlew signingReport
```
3. Firebase Console > Project Settings > General sekmesinde SHA-1 anahtarını ekleyin

#### 5.2 iOS Kurulumu
1. `ios/Runner/GoogleService-Info.plist` dosyasının mevcut olduğundan emin olun
2. Xcode'da projeyi açın ve Bundle ID'yi kontrol edin

### 6. 🎯 Uygulamayı Çalıştırın

#### Önce analiz edin:
```bash
flutter analyze
```

#### Test edin:
```bash
flutter test
```

#### Çalıştırın:
```bash
flutter run
```

## 🔧 Sorun Giderme

### Firebase Bağlantı Sorunu
- `google-services.json` ve `GoogleService-Info.plist` dosyalarının doğru konumda olduğunu kontrol edin
- Package name'lerin Firebase projesiyle eşleştiğini kontrol edin

### Gemini AI API Sorunu
- API anahtarının doğru olduğunu kontrol edin
- Google AI Studio'da API'nin etkin olduğunu kontrol edin
- İnternet bağlantınızı kontrol edin

### Google Sign-In Sorunu
- SHA-1 anahtarlarının Firebase'de kayıtlı olduğunu kontrol edin
- Bundle ID'lerin doğru olduğunu kontrol edin

### Build Sorunu
```bash
flutter clean
flutter pub get
flutter run
```

## 📱 Platform Özel Notlar

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34
- Compile SDK: 34

### iOS
- Minimum iOS: 12.0
- Xcode 14.0 veya üzeri gerekli

## 🛡️ Güvenlik

- Firebase Security Rules'larını production'da sıkılaştırın
- API anahtarlarını güvenli şekilde saklayın
- User input'larını validate edin

## 📞 Destek

Sorunlarla karşılaştığınızda:

1. **GitHub Issues**: [Proje Issues](https://github.com/batuhanlog/ProjectX/issues)
2. **Flutter Dokümanları**: [Flutter.dev](https://flutter.dev)
3. **Firebase Dokümanları**: [Firebase.google.com](https://firebase.google.com/docs)

## 🎉 Başarılı Kurulum

Kurulum başarılı olduğunda:
- Uygulama açılır ve giriş ekranını gösterir
- Email/şifre veya Google ile giriş yapabilirsiniz
- AI özellikler çalışır (Gemini API anahtarı ayarlandıysa)

**İyi kullanımlar! 🍽️**
