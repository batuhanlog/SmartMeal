# 🍽️ Sağlıklı Beslenme Asistanı

Flutter tabanlı, AI destekli kişisel beslenme asistanı uygulaması. Firebase ve Gemini AI entegrasyonu ile kullanıcılara özelleştirilmiş sağlıklı yemek önerileri sunar.

## 🌟 Özellikler

### 🔐 Kimlik Doğrulama
- Email/şifre ile kayıt ve giriş
- Google ile tek tıkla giriş
- Güvenli çıkış işlemi

### 👤 Kullanıcı Profili
- Detaylı profil oluşturma (yaş, kilo, boy, cinsiyet)
- BMI hesaplama ve kategorizasyon
- Beslenme tercihleri (vegan, vejetaryen, ketojenik, vb.)
- Aktivite seviyesi belirleme
- Alerji bilgileri

### 🤖 AI Destekli Özellikler
- **Kişisel Yemek Önerileri**: Profil bilgilerine göre özelleştirilmiş yemek tavsiyeleri
- **Fotoğraf Analizi**: Yemek fotoğraflarını analiz ederek besin değerleri ve sağlık skorları
- **Malzeme Bazlı Tarifler**: Mevcut malzemelerle yapılabilecek yemek tarifleri

### 📊 Takip ve Analiz
- Yemek geçmişi kayıtları
- Favori yemekler listesi
- Besin değerleri görüntüleme
- Kalori, protein, karbonhidrat takibi

### ⚙️ Gelişmiş Ayarlar
- Bildirim tercihleri
- Gizlilik ayarları
- Veri yönetimi (geçmiş temizleme, veri indirme)
- Hesap yönetimi

## 🛠️ Teknolojiler

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Authentication, Firestore)
- **AI**: Google Gemini AI
- **State Management**: setState (Simple state management)
- **Authentication**: Firebase Auth + Google Sign-In

## 📱 Kurulum

### Gereksinimler
- Flutter SDK (3.8.1+)
- Android Studio / VS Code
- Firebase projesi
- Gemini AI API anahtarı

### Adımlar

1. **Projeyi klonlayın**
```bash
git clone <repository-url>
cd project_x
```

2. **Bağımlılıkları yükleyin**
```bash
flutter pub get
```

3. **Firebase yapılandırması**
- Firebase Console'da yeni proje oluşturun
- Android/iOS uygulamaları ekleyin
- `google-services.json` dosyasını `android/app/` klasörüne ekleyin
- `GoogleService-Info.plist` dosyasını `ios/Runner/` klasörüne ekleyin

4. **Gemini AI API anahtarını ekleyin**
- `lib/services/gemini_service.dart` dosyasında API anahtarını güncelleyin
- Güvenlik için environment variables kullanın

5. **Uygulamayı çalıştırın**
```bash
flutter run
```

## 🏗️ Proje Yapısı

```
lib/
├── main.dart                      # Ana uygulama dosyası
├── auth_page.dart                 # Giriş/kayıt sayfası
├── home_page.dart                 # Ana sayfa
├── profile_page.dart              # Profil düzenleme
├── meal_suggestion_page.dart      # Yemek önerileri
├── food_photo_page.dart           # Fotoğraf analizi
├── ingredients_recipe_page.dart   # Malzeme bazlı tarifler
├── meal_history_page.dart         # Yemek geçmişi
├── settings_page.dart             # Ayarlar
├── firebase_options.dart          # Firebase yapılandırması
└── services/
    ├── gemini_service.dart        # Gemini AI servisi
    ├── google_sign_in_service.dart # Google giriş servisi
    └── error_handler.dart         # Hata yönetimi
```

## 🎨 UI/UX Özellikleri

- **Modern Material Design**: Temiz ve kullanıcı dostu arayüz
- **Renk Kodlaması**: Her özellik için farklı renk temaları
- **Responsive Tasarım**: Farklı ekran boyutlarına uyumlu
- **Emojili Başlıklar**: Görsel zenginlik için emoji kullanımı
- **Kartlı Tasarım**: Bilgileri düzenli kartlar halinde sunma
- **Loading States**: Kullanıcı deneyimi için yükleme göstergeleri

## 🔧 Yapılandırma

### Firebase Rules
Firestore güvenlik kuralları örneği:

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

### Environment Variables
Güvenlik için API anahtarlarını environment variables olarak kullanın:

```dart
// .env dosyası
GEMINI_API_KEY=your_gemini_api_key_here
```

## 🚀 Gelecek Özellikler

- [ ] Push bildirimleri
- [ ] Öğün planlama
- [ ] Su takibi
- [ ] Egzersiz entegrasyonu
- [ ] Sosyal özellikler (tarif paylaşımı)
- [ ] Dark mode
- [ ] Çoklu dil desteği
- [ ] Offline çalışma
- [ ] Widget desteği

## 🐛 Bilinen Sorunlar

- Google Sign-In Android yapılandırması gerekebilir
- Gemini AI API rate limiting'e tabi
- Fotoğraf analizi bazen yavaş olabilir

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için `LICENSE` dosyasına bakın.

## 📞 İletişim

- **Developer**: [Your Name]
- **Email**: [your.email@domain.com]
- **GitHub**: [github.com/username]

## 🙏 Teşekkürler

- Flutter ekibine harika framework için
- Firebase ekibine güçlü backend servisleri için
- Google'a Gemini AI API'si için
- Tüm açık kaynak katkıda bulunanlara

---

**Not**: Bu uygulama eğitim amaçlıdır. Tıbbi tavsiye yerine geçmez. Ciddi sağlık sorunları için lütfen bir sağlık profesyoneline danışın.
