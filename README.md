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



# Hedef Kullanıcılar

**SmartMeal** uygulaması, farklı yaş gruplarından ve yaşam tarzlarından bireylere hitap eden, sağlık odaklı bir çözüm sunar.  
Hem bireysel hem de toplu kullanımda fayda sağlayabilecek kapsamlı bir yapıya sahiptir.

---

## 1. Öğrenciler

**Sağlıklı Yaşam Bilinci**  
Yoğun sınav dönemlerinde düzensiz beslenme riskine karşı, öğrencilere pratik ve dengeli yemek önerileri sunar.

**Bütçe Dostu & Pratik Çözümler**  
Elde mevcut malzemelerle yapılabilecek tarif önerileriyle ekonomik çözümler sağlar.

---

## 2. Çalışan Profesyoneller

**Zaman Yönetimi ve Hızlı Seçimler**  
Yoğun iş temposunda sağlıklı tercihler yapma süresini kısaltır, önerileriyle karar verme sürecini kolaylaştırır.

**Diyet Takibi ve Raporlama**  
Kilo kontrolü veya özel sağlık hedefleri olan bireylerin beslenme verilerini anlamlandırmasına yardımcı olur.

---

## 3. Belirli Gıdalara Hassasiyeti Olan Bireyler

**Alerji ve Duyarlılık Desteği**  
Gluten, laktoz, fıstık gibi hassasiyetlere özel filtreleme ve öneri sistemi sunar.

---

## 4. Sporcular ve Aktif Yaşam Tarzına Sahip Kullanıcılar

**Makro Takibi ve Hedef Odaklı Beslenme**  
Kas yapma, kilo alma veya yağ kaybı hedefleri doğrultusunda dengelenmiş tariflerle destek sağlar.

**Yüksek Proteinli / Düşük Karbonhidratlı Alternatifler**  
Kişisel hedeflere uygun tarif segmentasyonu içerir.

---

## 5. Farklı Diyet Tiplerini Takip Eden Bireyler

**Diyet Tipine Uygun Öneriler**  
Beslenme tercihi doğrultusunda tüm tarifler filtrelenir.

**Tarif Uyarlamaları**  
Tariflerdeki içerikler diyete göre otomatik olarak uyarlanır.

# 📍 SPRINT 1

<details>
<summary><strong>▶ Sprint Planı</strong></summary>

**Sprint içinde tamamlanması tahmin edilen puan:** 100 Puan

**Puan tamamlama mantığı:**  
NutriMuse projesi toplamda 300 puanlık bir geliştirme yüküne sahiptir. Proje üç sprint’e bölünerek planlandığı için her sprintte yaklaşık 100 puanlık iş tamamlanması hedeflenmiştir. Sprint 1’de temel altyapı, kullanıcı girişi, profil oluşturma, veri bağlantıları ve navigasyon sistemleri geliştirildiği için bu sprintin yükü 100 puan olarak belirlenmiştir.

</details>

<details>
<summary><strong>▶ Daily Scrum</strong></summary>

Daily Scrum toplantıları, ekip üyelerinin okul ve iş yoğunlukları göz önünde bulundurularak Google Meet üzerinden çevrim içi olarak gerçekleştirilmiştir. Her toplantı sonrasında günlük görev durumları ve ilerlemeler, ekip içi kayıt amacıyla WhatsApp üzerinden yazılı olarak paylaşılmıştır.  
Toplantı notları, görev güncellemeleri ve iletişim akışına dair gerekli dokümanlar .jpeg formatında eklenmiştir.

</details>

<details>
<summary><strong>▶ Sprint Katılımcıları</strong></summary>

- Batuhan Kayahan – Product Owner  
- Gökçe Beyza Gökçek – Scrum Master  
- Emine Suna Yılmaz – Developer  
- Hasan Kılınç – Developer  
- Selimhan Gitmişoğlu – Developer  

</details>

<details>
<summary><strong>▶ Sprint Review</strong></summary>

- Proje fikri belirlendi: Yapay zekâ destekli kişisel beslenme öneri uygulaması olarak karar verildi  
- Uygulama kapsamı, hedef kullanıcılar ve temel modüller tanımlandı  
- Geliştirme teknolojileri seçildi: Flutter, Firebase, Gemini API  
- GitHub repository oluşturuldu ve temel proje yapısı kuruldu  
- Flutter projesi başlatıldı ve klasör yapısı oluşturuldu  
- Firebase Auth entegrasyonu tamamlandı  
- Google ile giriş ve e-posta/şifre kayıt ekranları geliştirildi  
- Giriş sonrası yönlendirme akışı tamamlandı  
- Kullanıcı profil oluşturma formu geliştirildi (diyet tipi, hedef, yaş, kilo, alerjiler vb.)  
- Profil formunun Firebase’e veri yazma işlemi başarıyla tamamlandı  
- Ana menü ve alt navigasyon sistemi geliştirildi  
- Ana menüde 3 sekme tanımlandı: “Bugün Ne Yesem?”, “Yemeği Analiz Et”, “Elimdeki Malzemelerle Tarif”  
- “Bugün Ne Yesem?” sayfası dummy içerikle geliştirildi  
- Öneri detay sayfası oluşturuldu  
- Kullanıcı profil özet kartı entegre edildi  
- “Elimdeki Malzemelerle Tarif” sayfasının arayüzü tamamlandı  
- “Yemeği Fotoğrafla Analiz Et” sayfasının arayüzü tamamlandı  
- Sayfalar arası geçiş ve navigasyonlar tamamlandı  
- UI/UX düzenlemeleri yapıldı  
- Test kullanıcılarıyla Firestore veri akışı test edildi  

</details>

<details>
<summary><strong>▶ Ürün Durumu</strong></summary>

Ekran görüntüleri aşağıda sunulmuştur:

- Ana Sayfa  
- Giriş Ekranı  
- Kayıt Ekranı  
- Profil Oluşturma  
- Bugün Ne Yesem  
- Tarif Detayı  
- Elimdeki Malzemeler  
- Fotoğraflı Analiz Ekranı  

(Dosyalar Readme’ye eklenmiştir.)

</details>

<details>
<summary><strong>▶ Sprint Retrospective</strong></summary>

**Neler İyi Gitti?**
- Kararları birlikte verdik, neyi nasıl daha iyi yaparız odağı ön plandaydı  
- Ekip içi motivasyon yüksekti, destekleyici ve paylaşımcı bir yapı oluştu  
- Akşam buluşmaları odaklı ve verimliydi (Meet + WhatsApp)  
- Daily/weekly Scrum yapısı sürdürüldü  
- UI/UX’e erken odaklanmak görsel bütünlüğü sağladı  

**Zorlanılan Noktalar**
- Flutter kurulum sürecinde teknik sorunlar yaşandı  
- Zaman zaman çevrim içi olamama nedeniyle iletişim aksadı  
- WhatsApp mesaj trafiği bazı günler yoğunlaştı  
- Firebase auth entegrasyonunda teknik engeller çıktı  

**Aldığımız Kararlar**
- Her sprint için sabit haftalık toplantı günü belirlendi  
- WhatsApp mesajları Trello ile desteklenerek sadeleştirilecek  
- Mini retrospektifler düzenli hale getirilecek  
- “En İyi Katkı” sticker’ı uygulaması başlatılacak  

</details>



