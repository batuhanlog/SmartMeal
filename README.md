# Takım Bilgileri

## Takım İsmi / Ürün İsmi  
**Yapay Zeka78 / SMART MEAL**

## Takım Üyeleri  
- **Batuhan Kayahan** – Product Owner _(aktif)_  
- **Gökçe Beyza Gökçek** – Scrum Master _(aktif)_  
- **Emine Suna Yılmaz** – Developer _(aktif)_  
- **Hasan Kılınç** – Developer _(aktif)_  
- **Selimhan Gitmişoğlu** – Developer _(aktif)_

# Ürün Bilgileri

## Ürün Açıklaması

Günümüzde beslenme, kişisel sağlık yönetiminin temel taşlarından biri haline gelmiştir. Ancak insanlar, ellerindeki malzemelerle sağlıklı ve dengeli bir öğün hazırlamakta, ya da yediklerinin kendi sağlık verilerine uygun olup olmadığını anlamakta zorlanmaktadır.

**SmartMeal**, bu soruna yapay zekâ destekli kişiselleştirilmiş bir çözüm sunar.

Kullanıcının beslenme tipi (örneğin vegan, ketojenik), alerjileri, sağlık hedefleri (zayıflama, kas kazanımı vb.) gibi verileri doğrultusunda, her gün kendisine özel yemek önerileri sunar.

Ayrıca kullanıcı, sadece elindeki malzemeleri yazarak ya da seçerek, sistemin kendisine en uygun ve sağlıklı yemeği önermesini sağlayabilir. Yapay zekâ, görseli analiz ederek besin içeriklerini ve sağlık açısından uygunluğunu da değerlendirir.

Minimalist ve kullanıcı dostu tasarımı ile SmartMeal, kişisel sağlıkla uyumlu bir yaşam tarzı benimsemek isteyen herkes için hem pratik bir asistan hem de motive edici bir rehber olmayı hedefler.

---

## Ürün Özellikleri

### 1. Giriş Sayfası: Profil Bazlı Kişiselleştirme

Kullanıcılar yaş, cinsiyet, boy, kilo, aktivite seviyesi, diyet tercihi, alerjiler ve sağlık hedefleri gibi bilgileri içeren detaylı bir profil oluşturur. Uygulama bu bilgiler doğrultusunda:

- Vücut kitle indeksi (BMI) hesaplaması yapar  
- Hedef doğrultusunda kalori ve makro besin ihtiyaçlarını belirler  
- Diyet etiketlerini oluşturur (ör. ketojenik, vegan, düşük karbonhidrat vs.)

---

### 2. Kişiselleştirilmiş Yemek Önerileri Sayfası

Uygulama, kullanıcı profilindeki bilgilerle **Gemini 2.0** kullanarak öneriler üretir. Her yemek önerisi:

- Toplam kalori, protein, karbonhidrat, yağ miktarı  
- Hazırlama süresi ve zorluk seviyesi  
- Tarifin neden uygun olduğu bilgisi  
- Gereken tüm malzemeler ve hazırlanış adımları içerir

Sistem, alerji ya da diyet dışı içerikleri filtreleyerek kişiye özel ve güvenli öneriler sunar.

---

### 3. AI ile Görsel Yemek Analizi Sayfası

Kullanıcı, yediği yemeğin fotoğrafını yükleyerek besin içerik analizi alabilir. Özellik demo aşamasında statik eşleştirme mantığıyla çalışır:

- Görsel alımı (kamera veya galeri)  
- Görüntü sınıflandırması  
- Kalori ve makro tahmini  
- Kullanıcıya özel uygunluk değerlendirmesi

Bu ekran, AI’nın temel besin tanıma gücünü deneyimletmeyi hedefler.

---

### 4. Elimdekiler ile Tarifler Sayfası

Kullanıcı elindeki malzemeleri metinle ya da butonlarla girer. Sistem, bu malzemelere göre Gemini ile tarif önerisi sunar:

- Eksik malzeme durumunda uyarı verir  
- Hazırlanabilirlik derecesini belirtir  
- Gerekli ek malzemeleri sıralar

---

### 5. Ek Özellikler

#### Tarif Detayları

- Kalori, protein, karbonhidrat, yağ gibi temel besin değerleri  
- Malzeme listesi ve ölçüleri  
- Adım adım hazırlanış yönergeleri  
- Kullanıcıya uygunluk açıklaması  

#### Geçmiş Takibi

- Daha önce görüntülenen tariflerin otomatik saklanması  
- Favorilere ekleme/çıkarma  
- Filtreleme ve yeniden erişim kolaylığı  

#### Ana Sayfa ve Navigasyon

Ana sayfada modüller:

- Kişisel yemek önerisi  
- Elimdeki malzemelerle tarif  
- Yemeği analiz et  
- Profil ve sağlık bilgileri

Tüm sayfalar arasında hızlı ve sezgisel geçiş için Flutter navigasyon sistemi kullanılmıştır.


