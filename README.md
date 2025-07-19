![SmartMealLogo](https://github.com/user-attachments/assets/08c000c8-3dbc-4b8d-a88e-b8444787a73c)
# Takım Bilgileri 

## Takım İsmi / Ürün İsmi  
**Yapay Zeka78 / SMART MEAL**

## Takım Üyeleri  
- **Batuhan Kayahan** – Product Owner _(aktif)_  
- **Gökçe Beyza Gökçek** – Scrum Master _(aktif)_  
- **Emine Suna Yılmaz** – Developer _(aktif)_  
- **Hasan Kılınç** – Developer _(aktif)_  
- **Selimhan Gitmişoğlu** – Developer _(aktif)_

## Product Backlog URL  
TRELLO ->   https://trello.com/invite/b/6867fded2e088c5262e56975/ATTIc3ee26c08786121322ef76a28f231160FD36EDE6/smart-meal


EXCEL SPREADSHEET ->  https://docs.google.com/spreadsheets/d/1oJFwlWX4NKyk2JQHONkodrRFCN9Rr_mQ/edit?usp=sharing&ouid=104963067556918109812&rtpof=true&sd=true

# Ürün Bilgileri 

<details open>
<summary><strong>Ürün Açıklaması</strong></summary>

Günümüzde beslenme, kişisel sağlık yönetiminin temel taşlarından biri haline gelmiştir. Ancak insanlar, ellerindeki malzemelerle sağlıklı ve dengeli bir öğün hazırlamakta, ya da yediklerinin kendi sağlık verilerine uygun olup olmadığını anlamakta zorlanmaktadır.

**SmartMeal**, bu soruna yapay zekâ destekli kişiselleştirilmiş bir çözüm sunar.

Kullanıcının beslenme tipi (örneğin vegan, ketojenik), alerjileri, sağlık hedefleri (zayıflama, kas kazanımı vb.) gibi verileri doğrultusunda, her gün kendisine özel yemek önerileri sunar.

Ayrıca kullanıcı, sadece elindeki malzemeleri yazarak ya da seçerek, sistemin kendisine en uygun ve sağlıklı yemeği önermesini sağlayabilir. Yapay zekâ, görseli analiz ederek besin içeriklerini ve sağlık açısından uygunluğunu da değerlendirir.

Minimalist ve kullanıcı dostu tasarımı ile SmartMeal, kişisel sağlıkla uyumlu bir yaşam tarzı benimsemek isteyen herkes için hem pratik bir asistan hem de motive edici bir rehber olmayı hedefler.

</details>
---
<details>
<summary><strong>Ürün Özellikleri</strong></summary>

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

#### Navigasyon

Ana sayfada modüller:

- Kişisel yemek önerisi  
- Elimdeki malzemelerle tarif  
- Yemeği analiz et  
- Profil ve sağlık bilgileri

Tüm sayfalar arasında hızlı ve sezgisel geçiş için Flutter navigasyon sistemi kullanılmıştır.


</details>

---- 
# Hedef Kullanıcılar

<details open>
<summary><strong>Kullanıcı Grupları</strong></summary>

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

</details>

# 📍 SPRINT 1

<details>
<summary><strong> Sprint Planı</strong></summary>

**Sprint içinde tamamlanması tahmin edilen puan:** 100 Puan

**Puan tamamlama mantığı:**  
SMART MEAL toplamda 300 puanlık bir geliştirme yüküne sahiptir. Proje üç sprint’e bölünerek planlandığı için her sprintte yaklaşık 100 puanlık iş tamamlanması hedeflenmiştir. Sprint 1’de temel altyapı, kullanıcı girişi, profil oluşturma, veri bağlantıları ve navigasyon sistemleri geliştirildiği için bu sprintin yükü 100 puan olarak belirlenmiştir. Her bir sprintte eşit bir ağırlıklandırmanın iş bölümü açısından adil olacağına karar verilmiştir.

</details>

<details>
<summary><strong> Daily Scrum</strong></summary>

Daily Scrum toplantıları, ekip üyelerinin okul ve iş yoğunlukları göz önünde bulundurularak Google Meet üzerinden çevrim içi olarak gerçekleştirilmiştir. Her toplantı sonrasında günlük görev durumları ve ilerlemeler, ekip içi kayıt amacıyla WhatsApp üzerinden yazılı olarak paylaşılmıştır.  
Toplantı notları, görev güncellemeleri ve iletişim akışına dair gerekli dokümanlar eklenmiştir.

### 🗨️ Sprint 1 – WhatsApp & Google Meet Toplantı Kayıtları  
📎 Toplantı ekran görüntüleri ve yazışmalar için:  
👉 [WhatsApp Görsellerine Buradan Ulaşabilirsiniz](https://drive.google.com/drive/folders/1MRBDttWCSHXecd63y1qjKrfANuVOTHiz?usp=drive_link)

</details>

<details>
<summary><strong> Sprint Board Updates</strong></summary>

Trello üzerinde oluşturulan sprint planı, proje yönetimini görsel ve işlevsel olarak takip etmeye olanak tanımaktadır. Görevler, To Do (Yapılacaklar), In Progress (Devam Edenler), Done (Tamamlananlar) ve Gelecek Süreçler olmak üzere dört temel sütun altında kategorize edilmiştir. Bu yapı sayesinde, görevler sadece frontend/backend olarak teknik ayrımlarla değil, uygulamanın genel işlevselliğine göre dağıtılmıştır. Her kart, bireysel sorumlulara atanmış ve ekip içi ilerlemeyi şeffaf şekilde yansıtacak şekilde yapılandırılmıştır. Henüz planlanmamış ama ileriki sprintlerde yapılması planlanan işler ise “Gelecek Süreçler” sütununda toplanarak proje vizyonunun devamlılığı güvence altına alınmıştır. Bu sistem, ekip içinde iş takibini kolaylaştırmak ve sprint verimliliğini artırmak amacıyla kullanılmıştır.

<img width="1145" alt="Ekran Resmi 2025-07-06 15 21 41" src="https://github.com/user-attachments/assets/32fe0854-1689-4afb-85bf-7324b224e69d" />

</details>

<details>
<summary><strong> Sprint Katılımcıları</strong></summary>

- Batuhan Kayahan – Product Owner  
- Gökçe Beyza Gökçek – Scrum Master  
- Emine Suna Yılmaz – Developer  
- Hasan Kılınç – Developer  
- Selimhan Gitmişoğlu – Developer  

</details>

<details>
<summary><strong> Sprint Review</strong></summary>

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

Burndown chart aşağıda verilmiştir: 

![output (1)](https://github.com/user-attachments/assets/427f1e70-d89e-406d-9aa0-2df6db199471)


</details>

<details>
<summary><strong> Ürün Durumu</strong></summary>

Ürün görüntüleri aşağıda sunulmuştur:

![WhatsApp Image 2025-07-03 at 18 17 31](https://github.com/user-attachments/assets/e95f88ab-bdaf-457f-b3a6-3f24920a1230)  
![WhatsApp Image 2025-07-03 at 18 17 32](https://github.com/user-attachments/assets/16e7f634-3840-4ec5-9b13-20b807f9eeab)  
![WhatsApp Image 2025-07-03 at 18 17 33](https://github.com/user-attachments/assets/49f12705-314c-41aa-bbfa-12d4149d5c26)  
![WhatsApp Image 2025-07-03 at 18 17 34](https://github.com/user-attachments/assets/6e96561e-8754-4be1-942d-d04a4c63125d)  
![WhatsApp Image 2025-07-03 at 18 17 34 (1)](https://github.com/user-attachments/assets/b34caf55-bbf2-48ce-8718-c635b6f352e6)  
![WhatsApp Image 2025-07-03 at 18 17 35](https://github.com/user-attachments/assets/75c0ca1e-bed9-4e62-99a8-4ad5d2565220)  
![WhatsApp Image 2025-07-04 at 21 55 59](https://github.com/user-attachments/assets/d0798221-c57a-4d5d-a03c-f3b046120f1b)  
![WhatsApp Image 2025-07-04 at 21 55 59 (1)](https://github.com/user-attachments/assets/65226543-372d-421b-86a3-b8cef33a02b8)

</details>

<details>
<summary><strong> Sprint Retrospective</strong></summary>

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

# 📍 SPRINT 2

<details>
<summary><strong> Sprint Planı</strong></summary>

**Sprint içinde tamamlanması tahmin edilen puan:** 100 Puan

**Puan tamamlama mantığı:**  
SMART MEAL toplamda 300 puanlık bir geliştirme yüküne sahiptir. Proje üç sprint’e bölünerek planlandığı için her sprintte yaklaşık 100 puanlık iş tamamlanması hedeflenmiştir. Sprint 2’de yeni özelliklerin geliştirilmesi, entegrasyonlarının sağlanması ve farklılık sağlayacak yenilikçi bakış açılarının artırılması hedeflenmiştir. Her bir sprintte eşit bir ağırlıklandırmanın iş bölümü açısından adil olacağına karar verilmiştir.

</details>

<details>
<summary><strong> Daily Scrum Toplantıları</strong></summary>

Daily Scrum toplantıları, ekip üyelerinin okul ve iş yoğunlukları göz önünde bulundurularak Google Meet üzerinden çevrim içi olarak haftada 1 gerçekleştirilmiştir. Çevrimiçi toplantılar dışında haftaiçleri ekip içinde haberleşmek amacıyla WhatsApp üzerinden iletişim gerçekleştirilmiştir.

Toplantı notları, görev güncellemeleri ve iletişim akışına dair gerekli dokümanlar aşağıdaki linke eklenmiştir.

</details>

<details>
<summary><strong> Sprint Board Updates</strong></summary>

Geçtiğimiz sprintte belirlenmiş olan proje yönetim aracı **TRELLO**, bu sprint boyunca da kullanılmaya devam edilmiştir. Kişilere atanan görevler, önceki sprintte tamamlananlar ve ilerleyiş görülebilmektedir. Bu sistem, ekip içinde iş takibini kolaylaştırmak ve sprint verimliliğini artırmak amacıyla kullanılmıştır.

</details>

<details>
<summary><strong> Sprint Katılımcıları</strong></summary>

- **Batuhan Kayahan** – Product Owner  
- **Gökçe Beyza Gökçek** – Scrum Master  
- **Emine Suna Yılmaz** – Developer  
- **Hasan Kılınç** – Developer  

</details>

<details>
<summary><strong> Sprint Review</strong></summary>

- Uygulama isminin Smart Meal'dan Smeal olarak güncellenmesi  
- Logonun ve uygulama iconunun güncellenmesi  
- Kayıt ekranı, Giriş ekranı, Ana sayfa, Profil ekranı UI tasarımı yenilendi  
- “Elimdeki Malzemelerle Tarif” ekranına AI entegrasyonu yapıldı  
- Tarif içeriklerinin AI tarafından otomatik oluşturulması sağlandı  
- Profil güncelleme ekranı geliştirildi  
- Profile avatar seçme özelliği eklendi  
- 6 adet emoji temelli avatar tanımlandı  
- Profil görseli değiştirme alanı ayarlara eklendi  
- Kayıt ekranına “Alerjiler” alanı eklendi  
- Alerji etkenlerinin uygulama içi entegrasyonu sağlandı  
- “Beslenme Türleri” seçenekleri genişletildi  
- Günlük su tüketimi takibi özelliği eklendi  
- Günlük adım sayar özelliği eklendi  
- Kullanıcının kan tahlili bilgilerini ekleyebileceği alan oluşturuldu  
- Erken tanı sistemi geliştirildi  
- Kanser hastalıkları için erken teşhis analizi altyapısı oluşturuldu  
- Haftalık pop-up sorularla erken tanı taraması yapılması sağlandı  
- Geçmiş analiz sonuçlarının görüntülenmesi özelliği eklendi  

</details>

<details>
<summary><strong> Ürün Durumu</strong></summary>

Ürünümüzün güncel durumu aşağıda fotoğraflarla gösterilmektedir:

<!-- Gerekli görselleri bu alana ekleyebilirsiniz -->

</details>

<details>
<summary><strong> Sprint Retrospective</strong></summary>


**⚠️ Zorlayıcı Noktalar**  
- Ekip içi iletişim aksaklıkları  
- İşlerin geç tamamlanması  
- Gerekli aksiyonların zamanında alınmaması  
- Teknik alanda yaşanan aksaklıklar sebebiyle süreçlerin uzaması  

**✅ İyi Giden Noktalar**  
- Ekibin içerisinde oldukça toleranslı davranılması  
- Herkesin yaratıcı şekilde katkıda bulunması  
- Fikir geliştirme ve uygulama özgürlüğünün bulunması  
- Sınırlandırıcı değil, esnek bir çalışma ortamının belirlenmesi  
- Ekip üyelerinin birbirine destek olmaya çalışması  

**📌 Alınan Kararlar**  
- Kontrol noktaları sıkılaştırılacak  
- Daha sıkı bir çalışma sürecine girileceği için toplantılarda bu durum vurgulanacak  
- Çalışma ve toplantılara maksimum uyum bekleniyor  
- Ekibin duygusal dayanıklılığının artırılması gerekiyor  

</details>


