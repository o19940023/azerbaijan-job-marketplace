# Uygulama Planı: Azerbaycan İş Pazarı Mobil Uygulaması

## Genel Bakış

Bu uygulama planı, Flutter/Dart kullanarak Azerbaycan İş Pazarı Mobil Uygulamasının geliştirilmesi için adım adım görevleri içermektedir. Her görev, önceki görevler üzerine inşa edilecek şekilde tasarlanmıştır ve tüm kod entegre edilmiş durumda olacaktır.

## Görevler

- [x] 1. Proje yapısını ve temel altyapıyı oluştur
  - Flutter projesi oluştur (flutter create)
  - Klasör yapısını organize et (presentation, domain, data katmanları)
  - Gerekli bağımlılıkları pubspec.yaml'a ekle (flutter_bloc, dio, hive, firebase_messaging, socket_io_client, google_maps_flutter, image_picker, shared_preferences, flutter_secure_storage)
  - Clean Architecture katmanlarını oluştur
  - _Gereksinimler: Tüm gereksinimler için temel altyapı_

- [ ] 2. Veri modelleri ve entity'leri tanımla
  - [ ] 2.1 Ortak veri tiplerini oluştur (SalaryRange, Location, WorkExperience, Education, enums)
    - Dart class'ları olarak veri modellerini tanımla
    - JSON serialization/deserialization metodları ekle (toJson, fromJson)
    - _Gereksinimler: Tüm modüller için temel veri yapıları_
  
  - [ ] 2.2 User entity'sini güncelle
    - firstName, lastName alanları ekle (String, required)
    - phone alanı (String, required, unique, +994 format)
    - email alanı (String?, optional, unique)
    - password alanı kaldır (sadece backend'de hash olarak saklanacak)
    - userType alanı (UserType enum, required)
    - isVerified alanı (bool, default false - gelecek OTP için)
    - Validation logic ekle
    - _Gereksinimler: 1.1-1.4_
  
  - [ ] 2.3 RegisterRequest ve LoginRequest modellerini oluştur
    - RegisterRequest: firstName, lastName, phone, password, email?, userType
    - LoginRequest: identifier (phone or email), password
    - Validation metodları ekle
    - _Gereksinimler: 1.1-1.7_
  
  - [ ] 2.4 Profile entity'lerini oluştur (JobSeekerProfile, EmployerProfile)
    - Domain katmanında entity class'larını tanımla
    - User entity ile ilişkilendirme
    - Validation logic ekle
    - _Gereksinimler: 2.1-2.11, 3.1-3.7_
  
  - [ ] 2.3 Job ve Application entity'lerini oluştur (JobPosting, JobApplication)
    - Domain katmanında entity class'larını tanımla
    - İş ilanı ve başvuru için gerekli tüm alanları ekle
    - _Gereksinimler: 4.1-4.15, 6.1-6.10_
  
  - [ ] 2.4 Messaging ve Service entity'lerini oluştur (Message, Conversation, ServiceProfile)
    - Domain katmanında entity class'larını tanımla
    - Mesajlaşma ve hizmet pazarı için veri yapıları
    - _Gereksinimler: 8.1-8.13, 9.1-9.11_

- [ ] 3. Repository interface'lerini tanımla
  - [ ] 3.1 AuthRepository interface'ini güncelle
    - register metodunu güncelle (RegisterRequest parametresi)
    - login metodunu güncelle (LoginRequest parametresi)
    - OTP metodlarını kaldır (gelecek sürüm için)
    - Token doğrulama metodlarını tanımla
    - _Gereksinimler: 1.1-1.7_
  
  - [ ] 3.2 ProfileRepository interface'ini oluştur
    - İş arayan ve işveren profil yönetimi metodlarını tanımla
    - _Gereksinimler: 2.1-2.11, 3.1-3.7_
  
  - [ ] 3.3 JobRepository interface'ini oluştur
    - İş ilanı CRUD ve arama metodlarını tanımla
    - _Gereksinimler: 4.1-4.15, 5.1-5.10_
  
  - [ ] 3.4 ApplicationRepository interface'ini oluştur
    - Başvuru yönetimi metodlarını tanımla
    - _Gereksinimler: 6.1-6.10, 7.1-7.10_
  
  - [ ] 3.5 MessagingRepository interface'ini oluştur
    - Mesajlaşma metodlarını tanımla
    - _Gereksinimler: 8.1-8.13_
  
  - [ ] 3.6 Diğer repository interface'lerini oluştur (ServiceRepository, ReviewRepository, NotificationRepository)
    - Hizmet pazarı, değerlendirme ve bildirim metodlarını tanımla
    - _Gereksinimler: 9.1-9.11, 13.1-13.10, 10.1-10.10_

- [ ] 4. Use case'leri uygula
  - [ ] 4.1 Authentication use case'lerini güncelle
    - RegisterUseCase: RegisterRequest ile kayıt
    - LoginUseCase: LoginRequest ile giriş (phone veya email)
    - LogoutUseCase: Oturum kapatma
    - Validation logic (telefon formatı, şifre kuralları, email formatı)
    - Error handling (duplicate phone/email, invalid credentials)
    - _Gereksinimler: 1.1-1.7_
  
  - [ ]* 4.2 Authentication use case'leri için özellik testleri yaz
    - **Özellik 2: Telefon Numarası Format Doğrulaması**
    - **Özellik 3: Şifre Doğrulama Kuralları**
    - **Özellik 4: Email Opsiyonelliği**
    - **Özellik 5: Kullanıcı Tipi Zorunluluğu**
    - **Özellik 6: Telefon veya Email ile Giriş**
    - **Özellik 8: Tekrarlı Telefon Engelleme**
    - **Özellik 9: Tekrarlı Email Engelleme**
    - **Doğrular: Gereksinim 1.1-1.7, 11.4**
  
  - [ ] 4.3 Profile use case'lerini oluştur (GetProfileUseCase, UpdateProfileUseCase)
    - Profil yönetimi iş mantığını uygula
    - _Gereksinimler: 2.1-2.11, 3.1-3.7_
  
  - [ ]* 4.4 Profile use case'leri için özellik testleri yaz
    - **Özellik 10: Profil Veri Bütünlüğü**
    - **Özellik 11: İşveren Profil Veri Bütünlüğü**
    - **Doğrular: Gereksinim 2.1-2.11, 3.1-3.7**
  
  - [ ] 4.5 Job use case'lerini oluştur (CreateJobUseCase, SearchJobsUseCase, ApplyToJobUseCase)
    - İş ilanı ve başvuru iş mantığını uygula
    - _Gereksinimler: 4.1-4.15, 5.1-5.10, 6.1-6.10_
  
  - [ ]* 4.6 Job use case'leri için özellik testleri yaz
    - **Özellik 12: Yeni İlan Aktif Durumu**
    - **Özellik 13: İlan Yönetim İşlemleri**
    - **Özellik 15: Başvuru Kalıcılığı**
    - **Özellik 16: Tekrarlı Başvuru Engelleme**
    - **Doğrular: Gereksinim 4.11, 4.12-4.14, 6.1, 6.9**

- [ ] 5. Data source'ları ve API client'ı uygula
  - [ ] 5.1 API client'ı oluştur (Dio ile)
    - Base URL konfigürasyonu
    - Interceptor'lar ekle (auth token, logging, error handling)
    - Request/response serialization
    - _Gereksinimler: Tüm API iletişimi için_
  
  - [ ] 5.2 Remote data source'ları uygula (AuthRemoteDataSource, ProfileRemoteDataSource, JobRemoteDataSource)
    - API endpoint'lerini çağır
    - Response'ları model'lere dönüştür
    - Hata yönetimi
    - _Gereksinimler: 1.1-1.8, 2.1-2.11, 3.1-3.7, 4.1-4.15_
  
  - [ ] 5.3 Local data source'ları uygula (Hive ile)
    - Hive box'larını oluştur
    - Offline veri saklama
    - Cache yönetimi
    - _Gereksinimler: 16.4, 17.1-17.6_

- [ ] 6. Repository implementasyonlarını oluştur
  - [ ] 6.1 AuthRepositoryImpl'i güncelle
    - Remote ve local data source'ları kullan
    - register metodunu uygula (RegisterRequest)
    - login metodunu uygula (LoginRequest - phone veya email)
    - Token yönetimi (secure storage)
    - Duplicate phone/email kontrolü
    - Şifre hashing (bcrypt)
    - Offline/online senkronizasyon
    - _Gereksinimler: 1.1-1.7_
  
  - [ ]* 6.2 AuthRepository için özellik testleri yaz
    - **Özellik 1: Kayıt Zorunlu Alanları Doğrulaması**
    - **Özellik 7: Kimlik Doğrulama Oturum Oluşturma**
    - **Özellik 24: Şifre Şifreleme**
    - **Doğrular: Gereksinim 1.1, 1.7, 15.1**
  
  - [ ] 6.3 ProfileRepositoryImpl'i uygula
    - Profil CRUD işlemleri
    - Dosya yükleme (fotoğraf, CV)
    - _Gereksinimler: 2.1-2.11, 3.1-3.7_
  
  - [ ] 6.4 JobRepositoryImpl'i uygula
    - İş ilanı CRUD işlemleri
    - Arama ve filtreleme
    - Favori yönetimi
    - Mock data kaldırma - gerçek API entegrasyonu
    - Boş state handling
    - _Gereksinimler: 4.1-4.15, 5.1-5.10_
  
  - [ ]* 6.5 JobRepository için özellik testleri yaz
    - **Özellik 13: İlan Yönetim İşlemleri**
    - **Özellik 14: Konum Bazlı Sıralama**
    - **Doğrular: Gereksinim 4.12-4.14, 5.8, 12.4**
  
  - [ ] 6.6 ApplicationRepositoryImpl'i uygula
    - Başvuru yönetimi
    - Durum güncellemeleri
    - _Gereksinimler: 6.1-6.10, 7.1-7.10_
  
  - [ ]* 6.7 ApplicationRepository için özellik testleri yaz
    - **Özellik 17: Başvuru Durumu Otomatik Güncelleme**
    - **Doğrular: Gereksinim 7.4**

- [ ] 7. Checkpoint - Temel altyapı tamamlandı
  - Tüm testlerin geçtiğinden emin ol
  - Kullanıcıya sorular varsa sor

- [ ] 7.5 Database migration için script hazırla
  - [ ] 7.5.1 Users table migration
    - first_name kolonu ekle (VARCHAR(100) NOT NULL)
    - last_name kolonu ekle (VARCHAR(100) NOT NULL)
    - email kolonu ekle (VARCHAR(255) UNIQUE, nullable)
    - phone kolonu güncelle (UNIQUE constraint ekle)
    - password_hash kolonu ekle (VARCHAR(255) NOT NULL)
    - user_type kolonu ekle (VARCHAR(20) NOT NULL)
    - is_verified kolonu ekle (BOOLEAN DEFAULT FALSE)
    - Index'ler ekle (phone, email, user_type)
    - _Gereksinimler: 1.1-1.4_
  
  - [ ] 7.5.2 Mevcut data migration
    - Eski phone_auth verilerini yeni yapıya taşı
    - Default değerler ata (firstName, lastName için)
    - Rollback script hazırla
    - _Gereksinimler: Data integrity_

- [ ] 8. State management (BLoC) katmanını oluştur
  - [ ] 8.1 AuthBloc'u güncelle
    - Events: RegisterRequested (RegisterRequest), LoginRequested (LoginRequest), LogoutRequested
    - States: AuthInitial, AuthLoading, AuthSuccess, AuthError
    - Error handling (duplicate phone/email, invalid credentials, weak password)
    - BLoC logic uygula
    - _Gereksinimler: 1.1-1.7_
  
  - [ ]* 8.2 AuthBloc için birim testleri yaz
    - Register success/failure testleri
    - Login success/failure testleri (phone ve email ile)
    - Duplicate phone/email error testleri
    - Weak password error testleri
    - Invalid credentials error testleri
    - _Gereksinimler: 1.1-1.7_
  
  - [ ] 8.3 ProfileBloc'u oluştur
    - Profil yönetimi için events ve states
    - _Gereksinimler: 2.1-2.11, 3.1-3.7_
  
  - [ ] 8.4 JobBloc ve JobSearchBloc'u oluştur
    - İş ilanı yönetimi ve arama için BLoC'lar
    - _Gereksinimler: 4.1-4.15, 5.1-5.10_
  
  - [ ] 8.5 ApplicationBloc'u oluştur
    - Başvuru yönetimi için BLoC
    - _Gereksinimler: 6.1-6.10, 7.1-7.10_

- [ ] 9. Temel UI bileşenlerini ve tema yapısını oluştur
  - [ ] 9.1 Tema konfigürasyonunu oluştur
    - Renkler, fontlar, spacing tanımla
    - Light/dark tema desteği
    - Azerbaycan Türkçesi localization dosyaları
    - _Gereksinimler: 1.6, 11.1-11.7_
  
  - [ ] 9.2 Ortak widget'ları oluştur
    - CustomButton (primary, secondary, disabled states)
    - CustomTextField (validation, error display)
    - LoadingIndicator (shimmer effect)
    - ErrorWidget (retry button)
    - EmptyStateWidget (farklı tipler için)
    - Accessibility desteği
    - _Gereksinimler: 16.9_
  
  - [ ] 9.3 EmptyStateWidget'ı oluştur
    - EmptyStateType enum (EMPLOYER_NO_JOBS, JOB_SEEKER_NO_JOBS, NO_SEARCH_RESULTS, NO_APPLICATIONS, NO_MESSAGES)
    - Her tip için farklı icon, title, description
    - Optional CTA button
    - _Gereksinimler: Mock data kaldırma stratejisi_
  
  - [ ] 9.4 Navigation yapısını kur
    - Route tanımlamaları
    - Navigation service
    - Deep linking desteği
    - _Gereksinimler: Tüm ekranlar için navigasyon_
  
  - [ ]* 9.5 EmptyStateWidget için widget testleri yaz
    - Her EmptyStateType için render testi
    - CTA button testi
    - Icon ve text gösterimi testi
    - _Gereksinimler: Mock data kaldırma stratejisi_

- [ ] 10. Authentication ekranlarını oluştur
  - [ ] 10.1 User Type Selection ekranını oluştur
    - UI tasarımı (İş Arıyorum / İşveren seçimi)
    - Seçim sonrası RegisterScreen'e yönlendirme
    - Seçilen user type'ı parametre olarak geçirme
    - _Gereksinimler: 1.4_
  
  - [ ] 10.2 RegisterScreen oluştur
    - Form alanları: İsim, Soy isim, Telefon (+994 format), Şifre, Email (opsiyonel)
    - User type otomatik seçili gelir (User Type Selection'dan)
    - Real-time form validation (telefon formatı, şifre kuralları)
    - Validation error mesajları (Azerbaycan Türkçesi)
    - Submit butonu (tüm zorunlu alanlar dolu olunca aktif)
    - "Zaten hesabınız var mı? Giriş yapın" linki ile LoginScreen'e geçiş
    - AuthBloc entegrasyonu
    - Error handling (duplicate phone/email, weak password, network error)
    - _Gereksinimler: 1.1-1.4_
  
  - [ ]* 10.3 RegisterScreen için widget testleri yaz
    - Form field validation testleri
    - Telefon format validation testi (+994)
    - Şifre validation testi (min 8 char, 1 uppercase, 1 digit)
    - Email opsiyonellik testi
    - Submit button state testi
    - Error message gösterimi testi
    - _Gereksinimler: 1.1-1.4_
  
  - [ ] 10.4 LoginScreen oluştur
    - Form alanları: Telefon/Email (tek input), Şifre
    - Identifier field hem telefon hem email kabul etmeli
    - Real-time form validation
    - Submit butonu
    - "Şifremi Unuttum" linki
    - "Hesabınız yok mu? Kayıt olun" linki ile RegisterScreen'e geçiş
    - AuthBloc entegrasyonu
    - Error handling (invalid credentials, network error)
    - _Gereksinimler: 1.5-1.7_
  
  - [ ]* 10.5 LoginScreen için widget testleri yaz
    - Telefon ile giriş testi
    - Email ile giriş testi
    - Invalid credentials error testi
    - Form validation testleri
    - _Gereksinimler: 1.5-1.7_
  
  - [ ] 10.6 PhoneAuthScreen'i kaldır
    - PhoneAuthScreen dosyasını sil
    - PhoneAuthScreen referanslarını kaldır
    - Navigation route'larını güncelle
    - _Not: OTP özelliği gelecek sürümde eklenecek_

- [ ] 11. Profile ekranlarını oluştur
  - [ ] 11.1 Job Seeker Profile ekranını oluştur
    - Profil bilgileri formu
    - Fotoğraf yükleme (image_picker)
    - CV yükleme
    - İş deneyimi ve eğitim ekleme
    - Beceri ve tercih seçimi
    - _Gereksinimler: 2.1-2.11_
  
  - [ ] 11.2 Employer Profile ekranını oluştur
    - Şirket bilgileri formu
    - Logo yükleme
    - Konum seçimi
    - _Gereksinimler: 3.1-3.7_
  
  - [ ]* 11.3 Profile ekranları için widget testleri yaz
    - Form field testleri
    - File upload testleri
    - _Gereksinimler: 2.1-2.11, 3.1-3.7_

- [ ] 12. Job posting ve search ekranlarını oluştur
  - [ ] 12.1 Job List ekranını güncelle
    - İş ilanları listesi (ListView.builder ile pagination)
    - Arama çubuğu
    - Filtre butonları
    - Pull-to-refresh
    - Mock data kaldırma - gerçek API'den veri çekme
    - EmptyStateWidget entegrasyonu (NO_SEARCH_RESULTS)
    - Loading state (shimmer effect)
    - Error state (retry button)
    - _Gereksinimler: 5.1-5.10, 14.1-14.10_
  
  - [ ] 12.2 Job Detail ekranını oluştur
    - İlan detayları
    - Başvuru butonu
    - Favori ekleme
    - Paylaşma
    - Konum haritası (google_maps_flutter)
    - _Gereksinimler: 4.1-4.15, 6.1-6.10_
  
  - [ ] 12.3 Job Search ve Filter ekranını oluştur
    - Kategori filtreleri
    - Konum filtreleri
    - Maaş aralığı filtreleri
    - Çalışma şekli filtreleri
    - Arama kriterlerini kaydetme
    - _Gereksinimler: 5.1-5.10_
  
  - [ ] 12.4 Create/Edit Job ekranını oluştur (İşveren için)
    - İş ilanı formu
    - Kategori ve çalışma şekli seçimi
    - Gün/saat detayları (part-time için)
    - Konum seçimi
    - _Gereksinimler: 4.1-4.15_
  
  - [ ]* 12.5 Job ekranları için widget testleri yaz
    - List rendering testleri
    - Filter functionality testleri
    - _Gereksinimler: 4.1-4.15, 5.1-5.10_

- [ ] 13. Application management ekranlarını oluştur
  - [ ] 13.1 My Applications ekranını oluştur (İş Arayan için)
    - Başvuru listesi
    - Durum filtreleri
    - Başvuru detayları
    - _Gereksinimler: 6.1-6.10_
  
  - [ ] 13.2 Job Applications ekranını oluştur (İşveren için)
    - İlana gelen başvurular
    - Başvuru değerlendirme
    - Durum güncelleme
    - Not ekleme
    - Favorilere ekleme
    - _Gereksinimler: 7.1-7.10_
  
  - [ ] 13.3 Application Detail ekranını oluştur
    - Başvuran profili
    - CV görüntüleme
    - Mesajlaşmaya yönlendirme
    - _Gereksinimler: 7.1-7.10_
  
  - [ ]* 13.4 Application ekranları için widget testleri yaz
    - Status update testleri
    - Filter testleri
    - _Gereksinimler: 6.1-6.10, 7.1-7.10_

- [ ] 14. Checkpoint - UI katmanı temel özellikleri tamamlandı
  - Tüm testlerin geçtiğinden emin ol
  - Kullanıcıya sorular varsa sor

- [ ] 15. Messaging modülünü uygula
  - [ ] 15.1 Socket.IO client'ı kur ve yapılandır
    - WebSocket bağlantısı
    - Event listeners
    - Reconnection logic
    - _Gereksinimler: 8.1-8.13_
  
  - [ ] 15.2 MessagingRepositoryImpl'i uygula
    - Real-time mesaj gönderme/alma
    - Mesaj geçmişi
    - Conversation yönetimi
    - Engelleme özelliği
    - _Gereksinimler: 8.1-8.13_
  
  - [ ]* 15.3 MessagingRepository için özellik testleri yaz
    - **Özellik 18: Mesaj Kalıcılığı**
    - **Özellik 19: Engellenen Kullanıcı Mesaj Kısıtlaması**
    - **Doğrular: Gereksinim 8.2, 8.13**
  
  - [ ] 15.4 MessagingBloc'u oluştur
    - Mesaj gönderme/alma events
    - Conversation listesi yönetimi
    - Real-time updates
    - _Gereksinimler: 8.1-8.13_
  
  - [ ] 15.5 Conversations List ekranını oluştur
    - Konuşma listesi
    - Okunmamış mesaj sayısı
    - Son mesaj önizlemesi
    - Arama özelliği
    - _Gereksinimler: 8.1-8.13_
  
  - [ ] 15.6 Chat ekranını oluştur
    - Mesaj listesi
    - Mesaj gönderme input'u
    - Dosya/fotoğraf gönderme
    - Mesaj durumları (sent, delivered, read)
    - Typing indicator
    - _Gereksinimler: 8.1-8.13_
  
  - [ ]* 15.7 Messaging ekranları için widget testleri yaz
    - Message sending testleri
    - File upload testleri
    - _Gereksinimler: 8.1-8.13_

- [ ] 16. Service Marketplace modülünü uygula
  - [ ] 16.1 ServiceRepositoryImpl'i uygula
    - Hizmet profili CRUD
    - Hizmet arama
    - Teklif yönetimi
    - _Gereksinimler: 9.1-9.11_
  
  - [ ] 16.2 ServiceBloc'u oluştur
    - Hizmet yönetimi için state management
    - _Gereksinimler: 9.1-9.11_
  
  - [ ] 16.3 Service List ekranını oluştur
    - Hizmet sağlayıcı listesi
    - Kategori filtreleri
    - Konum bazlı arama
    - _Gereksinimler: 9.1-9.11_
  
  - [ ] 16.4 Service Profile ekranını oluştur
    - Hizmet detayları
    - Portföy fotoğrafları
    - Değerlendirmeler
    - Teklif isteme
    - Mesajlaşma
    - _Gereksinimler: 9.1-9.11_
  
  - [ ] 16.5 Create/Edit Service Profile ekranını oluştur
    - Hizmet bilgileri formu
    - Kategori seçimi
    - Çalışma bölgeleri
    - Portföy yükleme
    - _Gereksinimler: 9.1-9.11_

- [ ] 17. Review ve Rating sistemini uygula
  - [ ] 17.1 ReviewRepositoryImpl'i uygula
    - Değerlendirme CRUD
    - Ortalama puan hesaplama
    - Şikayet yönetimi
    - _Gereksinimler: 13.1-13.10_
  
  - [ ]* 17.2 ReviewRepository için özellik testleri yaz
    - **Özellik 23: Tekrarlı Değerlendirme Engelleme**
    - **Doğrular: Gereksinim 13.9**
  
  - [ ] 17.3 Reviews List ekranını oluştur
    - Değerlendirme listesi
    - Yıldız puanları
    - Yorumlar
    - Sıralama
    - _Gereksinimler: 13.1-13.10_
  
  - [ ] 17.4 Write Review ekranını oluştur
    - Yıldız seçimi
    - Yorum yazma
    - Gönderme
    - _Gereksinimler: 13.1-13.10_

- [ ] 18. Notification sistemini uygula
  - [ ] 18.1 Firebase Cloud Messaging'i kur
    - Firebase projesi oluştur
    - Android ve iOS konfigürasyonu
    - FCM token yönetimi
    - _Gereksinimler: 10.1-10.10_
  
  - [ ] 18.2 NotificationRepositoryImpl'i uygula
    - Push notification gönderme
    - Notification geçmişi
    - Tercih yönetimi
    - Device token kaydı
    - _Gereksinimler: 10.1-10.10_
  
  - [ ]* 18.3 NotificationRepository için özellik testleri yaz
    - **Özellik 20: Bildirim Oluşturma**
    - **Doğrular: Gereksinim 10.2-10.5**
  
  - [ ] 18.4 NotificationBloc'u oluştur
    - Notification handling
    - Badge count yönetimi
    - _Gereksinimler: 10.1-10.10_
  
  - [ ] 18.5 Notifications ekranını oluştur
    - Bildirim listesi
    - Okundu işaretleme
    - Bildirime tıklama navigasyonu
    - _Gereksinimler: 10.1-10.10_
  
  - [ ] 18.6 Notification Settings ekranını oluştur
    - Bildirim tercihleri
    - Toggle switches
    - _Gereksinimler: 10.6-10.8_
  
  - [ ] 18.7 Background notification handler'ı uygula
    - Uygulama kapalıyken notification handling
    - Local notification gösterimi
    - _Gereksinimler: 10.1-10.10_

- [ ] 19. Location servisi ve harita entegrasyonunu uygula
  - [ ] 19.1 LocationService'i uygula
    - GPS konum alma (geolocator)
    - Mesafe hesaplama
    - Adres arama (geocoding)
    - _Gereksinimler: 12.1-12.8_
  
  - [ ] 19.2 Map ekranını oluştur
    - Google Maps entegrasyonu
    - İş ilanlarını haritada gösterme
    - Marker'lar ve info windows
    - Kullanıcı konumu
    - _Gereksinimler: 12.1-12.8_
  
  - [ ] 19.3 Location Picker widget'ı oluştur
    - Haritadan konum seçme
    - Adres arama
    - Profil ve ilan oluştururken kullanım
    - _Gereksinimler: 12.1-12.8_
  
  - [ ]* 19.4 LocationService için birim testleri yaz
    - Mesafe hesaplama testleri
    - Geocoding testleri
    - _Gereksinimler: 12.1-12.8_

- [ ] 20. Analytics ve Reporting modülünü uygula
  - [ ] 20.1 AnalyticsRepositoryImpl'i uygula
    - İlan performans takibi
    - Kullanıcı istatistikleri
    - Event tracking
    - _Gereksinimler: 18.1-18.8_
  
  - [ ] 20.2 Analytics Dashboard ekranını oluştur (İşveren için)
    - İlan görüntülenme grafikleri
    - Başvuru istatistikleri
    - Dönüşüm oranları
    - _Gereksinimler: 18.1-18.5_
  
  - [ ] 20.3 Job Seeker Analytics ekranını oluştur
    - Profil görüntülenme
    - Başvuru durumu istatistikleri
    - _Gereksinimler: 18.6-18.8_

- [ ] 21. Checkpoint - Tüm ana özellikler tamamlandı
  - Tüm testlerin geçtiğinden emin ol
  - Kullanıcıya sorular varsa sor

- [ ] 22. Content Moderation sistemini uygula
  - [ ] 22.1 ModerationRepositoryImpl'i uygula
    - İçerik kontrolü
    - Şikayet yönetimi
    - Kullanıcı engelleme
    - _Gereksinimler: 20.1-20.10_
  
  - [ ]* 22.2 ModerationRepository için özellik testleri yaz
    - **Özellik 27: Yasaklı İçerik Filtreleme**
    - **Doğrular: Gereksinim 20.4**
  
  - [ ] 22.3 Report Content özelliğini ekle
    - Report dialog
    - Sebep seçimi
    - Gönderme
    - _Gereksinimler: 20.1-20.10_

- [ ] 23. Security ve Privacy özelliklerini uygula
  - [ ] 23.1 Secure storage'ı kur (flutter_secure_storage)
    - Token saklama
    - Hassas veri şifreleme
    - _Gereksinimler: 15.1-15.10_
  
  - [ ]* 23.2 Security için özellik testleri yaz
    - **Özellik 25: Hesap Silme Veri Temizliği**
    - **Doğrular: Gereksinim 15.7**
  
  - [ ] 23.3 Privacy Settings ekranını oluştur
    - Gizlilik ayarları
    - Profil görünürlüğü
    - Veri silme
    - _Gereksinimler: 15.3-15.7_
  
  - [ ] 23.4 Biometric authentication'ı ekle (local_auth)
    - Parmak izi/yüz tanıma
    - Login için opsiyonel
    - _Gereksinimler: 19.7_

- [ ] 24. Localization ve Azerbaycan'a özel özellikler
  - [ ] 24.1 Localization dosyalarını tamamla
    - Tüm string'leri Azerbaycan Türkçesi'ne çevir
    - ARB dosyaları oluştur
    - _Gereksinimler: 11.1-11.7_
  
  - [ ]* 24.2 Localization için özellik testleri yaz
    - **Özellik 21: Para Birimi Tutarlılığı**
    - **Özellik 22: Telefon Numarası Doğrulama**
    - **Doğrular: Gereksinim 11.2, 11.4**
  
  - [ ] 24.3 Azerbaycan şehir ve kategori listelerini ekle
    - Şehir dropdown'ları
    - İş kategorileri
    - Hizmet kategorileri
    - _Gereksinimler: 11.5-11.6_
  
  - [ ] 24.4 Tarih ve para birimi formatlarını ayarla
    - DateFormat (GG.AA.YYYY)
    - NumberFormat (Manat)
    - Phone format (+994)
    - _Gereksinimler: 11.2-11.4, 11.7_

- [ ] 25. Performance optimizasyonları
  - [ ] 25.1 Image caching ve optimization
    - cached_network_image kullan
    - Thumbnail generation
    - Lazy loading
    - _Gereksinimler: 16.7_
  
  - [ ] 25.2 List performance optimizasyonu
    - Pagination uygula (20 item per page)
    - ListView.builder optimize et
    - Infinite scroll
    - _Gereksinimler: 16.2_
  
  - [ ] 25.3 API response caching
    - Cache stratejisi uygula
    - Stale-while-revalidate
    - _Gereksinimler: 16.6_
  
  - [ ]* 25.4 Performance testleri yaz
    - Widget build time testleri
    - Memory leak testleri
    - _Gereksinimler: 16.1-16.10_

- [ ] 26. Offline support ve data synchronization
  - [ ] 26.1 Offline data caching
    - Hive ile local storage
    - Offline mode detection
    - _Gereksinimler: 16.4-16.5, 17.1-17.6_
  
  - [ ] 26.2 Data synchronization logic
    - Online/offline senkronizasyon
    - Conflict resolution
    - _Gereksinimler: 17.2-17.4_
  
  - [ ]* 26.3 Data sync için özellik testleri yaz
    - **Özellik 26: Çapraz Cihaz Veri Tutarlılığı**
    - **Doğrular: Gereksinim 17.2**

- [ ] 27. Error handling ve logging
  - [ ] 27.1 Global error handler
    - Uncaught exception handling
    - Error reporting (Firebase Crashlytics)
    - User-friendly error messages
    - _Gereksinimler: Hata Yönetimi bölümü_
  
  - [ ] 27.2 Logging infrastructure
    - Logger konfigürasyonu
    - Log levels
    - Remote logging
    - _Gereksinimler: Monitoring bölümü_
  
  - [ ] 27.3 Retry mechanism
    - Network request retry
    - Exponential backoff
    - _Gereksinimler: Hata Yönetimi bölümü_

- [ ] 28. Home ve Discovery ekranlarını oluştur
  - [ ] 28.1 Home ekranını güncelle
    - Öne çıkan ilanlar
    - Yeni ilanlar
    - Önerilen işler
    - Popüler kategoriler
    - EmptyStateWidget entegrasyonu (user type'a göre)
    - Employer: EMPLOYER_NO_JOBS state
    - Job Seeker: JOB_SEEKER_NO_JOBS state
    - Loading ve error states
    - _Gereksinimler: 14.1-14.5_
  
  - [ ] 28.2 Search ekranını oluştur
    - Global arama
    - İş ve hizmet arama
    - Arama geçmişi
    - _Gereksinimler: 14.9-14.10_
  
  - [ ] 28.3 Favorites ekranını oluştur
    - Favori ilanlar
    - Kaydedilen aramalar
    - _Gereksinimler: 14.6-14.7_

- [ ] 29. Settings ve Profile Management ekranlarını oluştur
  - [ ] 29.1 Settings ekranını oluştur
    - Hesap ayarları
    - Bildirim ayarları
    - Gizlilik ayarları
    - Dil seçimi (gelecek için)
    - Hakkında
    - _Gereksinimler: 10.6-10.8, 15.3-15.7, 21.1-21.6_
  
  - [ ] 29.2 Account Management ekranını oluştur
    - Şifre değiştirme
    - Email/telefon güncelleme
    - Hesap silme
    - _Gereksinimler: 15.6-15.7_

- [ ] 30. Onboarding ve Tutorial ekranlarını oluştur
  - [ ] 30.1 Splash screen
    - App logo
    - Loading indicator
    - Auto-navigation (token varsa home, yoksa user type selection)
    - _Gereksinimler: 16.1_
  
  - [ ] 30.2 Onboarding screens (opsiyonel)
    - Uygulama tanıtımı
    - Özellik açıklamaları
    - Skip ve Next butonları
    - _Gereksinimler: Kullanıcı deneyimi_
  
  - [ ] 30.3 User type selection ekranını oluştur
    - İş Arayan / İşveren seçimi
    - Her seçenek için açıklama
    - Seçim sonrası RegisterScreen'e yönlendirme
    - Seçilen user type'ı parametre olarak geçirme
    - "Zaten hesabınız var mı? Giriş yapın" linki
    - _Gereksinimler: 1.4_

- [ ] 31. Checkpoint - UI tamamlandı
  - Tüm ekranların çalıştığından emin ol
  - Navigasyon akışlarını test et
  - Kullanıcıya sorular varsa sor

- [ ] 32. Integration testleri yaz
  - [ ]* 32.1 Authentication flow integration testleri
    - User Type Selection -> Register -> Home akışı
    - Register -> Login akışı
    - Duplicate phone/email error handling
    - Phone ve email ile login testleri
    - _Gereksinimler: 1.1-1.7_
  
  - [ ]* 32.2 Job posting ve application flow testleri
    - İlan oluşturma -> Arama -> Başvuru akışı
    - _Gereksinimler: 4.1-4.15, 5.1-5.10, 6.1-6.10_
  
  - [ ]* 32.3 Messaging flow testleri
    - Mesaj gönderme -> Alma -> Okuma akışı
    - _Gereksinimler: 8.1-8.13_

- [ ] 33. Platform-specific konfigürasyonlar
  - [ ] 33.1 Android konfigürasyonu
    - AndroidManifest.xml permissions
    - ProGuard rules
    - App signing
    - _Gereksinimler: Android platform_
  
  - [ ] 33.2 iOS konfigürasyonu
    - Info.plist permissions
    - App signing
    - Push notification certificates
    - _Gereksinimler: iOS platform_
  
  - [ ] 33.3 App icons ve splash screens
    - Android adaptive icons
    - iOS app icons
    - Splash screens
    - _Gereksinimler: Her iki platform_

- [ ] 34. Build ve deployment hazırlığı
  - [ ] 34.1 Environment konfigürasyonları
    - Development, staging, production
    - API endpoint'leri
    - Firebase konfigürasyonları
    - _Gereksinimler: Deployment_
  
  - [ ] 34.2 Build scripts
    - Android APK/AAB build
    - iOS IPA build
    - Version management
    - _Gereksinimler: Deployment_
  
  - [ ] 34.3 Store listing hazırlığı
    - App açıklamaları (Azerbaycan Türkçesi)
    - Screenshots
    - Privacy policy
    - Terms of service
    - _Gereksinimler: Store submission_

- [ ] 35. Final checkpoint ve testing
  - Tüm testlerin geçtiğinden emin ol
  - Manuel test senaryolarını çalıştır
  - Performance testleri yap
  - Kullanıcıya demo sun ve feedback al

## Notlar

- `*` ile işaretlenmiş görevler opsiyoneldir ve daha hızlı MVP için atlanabilir
- Her görev, önceki görevlerin tamamlanmasını gerektirir
- Checkpoint'lerde kullanıcıyla iletişime geçilmeli
- Özellik testleri, tasarım belgesindeki özellikleri doğrular
- Birim testler, belirli örnekler ve kenar durumlar için yazılır
- Her test, minimum 100 iterasyon ile çalıştırılmalıdır (özellik testleri için)
