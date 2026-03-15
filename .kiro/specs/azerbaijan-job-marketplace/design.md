# Tasarım Belgesi: Azerbaycan İş Pazarı Mobil Uygulaması

## Genel Bakış

Azerbaycan İş Pazarı Mobil Uygulaması, Flutter/Dart kullanılarak geliştirilecek, cross-platform (Android ve iOS) bir iş arama ve işe alım platformudur. Uygulama, mavi yakalı işçiler ve işverenler arasında köprü kurarak, hızlı ve etkili bir eşleştirme deneyimi sunacaktır.

### Temel Mimari Prensipler

- **Cross-Platform**: Flutter framework kullanarak tek kod tabanından hem Android hem iOS uygulaması
- **Reactive Architecture**: BLoC (Business Logic Component) pattern ile state management
- **Clean Architecture**: Katmanlı mimari ile iş mantığının UI'dan ayrılması
- **Offline-First**: Yerel veri önbellekleme ile çevrimdışı çalışma desteği
- **Real-time Communication**: WebSocket tabanlı anlık mesajlaşma
- **Scalable Backend**: RESTful API ve Firebase servisleri

## Mimari

### Katmanlı Mimari Yapısı

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (UI Widgets, Screens, BLoC/Cubit)     │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│          Domain Layer                   │
│  (Entities, Use Cases, Repositories)    │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│           Data Layer                    │
│  (API, Local DB, Data Sources)         │
└─────────────────────────────────────────┘
```

### Onboarding ve Authentication Flow

**Uygulama Başlangıç Akışı:**

```
Splash Screen (2-3 saniye)
    ↓
User Type Selection Screen
    ↓
    ├─→ "İş Arıyorum" seçildi → Register Screen (Job Seeker)
    │                              ↓
    │                         Login Screen'e geçiş linki
    │
    └─→ "İşveren" seçildi → Register Screen (Employer)
                               ↓
                          Login Screen'e geçiş linki
```

**Register Screen Flow:**
1. Kullanıcı isim, soy isim, telefon, şifre girer
2. Opsiyonel olarak email ekleyebilir
3. Profil tipi (Job Seeker/Employer) otomatik seçili gelir
4. Form validasyonu gerçek zamanlı çalışır
5. Submit butonuna basıldığında kayıt işlemi başlar
6. Başarılı kayıt sonrası direkt home screen'e yönlendirilir

**Login Screen Flow:**
1. Kullanıcı telefon veya email girer
2. Şifre girer
3. Submit butonuna basıldığında giriş işlemi başlar
4. Başarılı giriş sonrası home screen'e yönlendirilir
5. "Şifremi Unuttum" linki ile şifre sıfırlama

**Error Handling:**
- Invalid credentials: "Telefon/email veya şifre hatalı"
- Duplicate phone: "Bu telefon numarası zaten kayıtlı"
- Duplicate email: "Bu email adresi zaten kayıtlı"
- Weak password: "Şifre en az 8 karakter, 1 büyük harf ve 1 rakam içermelidir"
- Invalid phone format: "Geçerli bir Azerbaycan telefon numarası girin (+994)"
- Network error: "İnternet bağlantısı yok"

### Teknoloji Stack

**Frontend (Mobile)**
- Flutter 3.x
- Dart 3.x
- flutter_bloc (State Management)
- dio (HTTP Client)
- hive (Local Database)
- firebase_messaging (Push Notifications)
- socket_io_client (Real-time Messaging)
- google_maps_flutter (Location Services)
- image_picker (Media Upload)
- shared_preferences (Local Storage)

**Backend Services**
- RESTful API (Node.js/Express veya Django)
- PostgreSQL (Primary Database)
- Redis (Caching & Session Management)
- Firebase Cloud Messaging (Push Notifications)
- Socket.IO (Real-time Messaging)
- AWS S3 veya Firebase Storage (File Storage)

## Bileşenler ve Arayüzler

### 1. Kimlik Doğrulama Modülü (Authentication Module)

**Sorumluluklar:**
- Kullanıcı kaydı ve girişi
- Token yönetimi
- Oturum kontrolü
- Şifre doğrulama ve güvenlik

**Not:** OTP/doğrulama kodu özelliği gelecek bir sürümde eklenecektir. Mevcut sürümde kullanıcılar telefon/email ve şifre ile direkt giriş yapabilecektir.

**Arayüzler:**

```dart
abstract class AuthRepository {
  Future<User> register(RegisterRequest request);
  Future<User> login(LoginRequest request);
  Future<void> logout();
  Future<bool> verifyToken(String token);
  Future<void> resetPassword(String identifier); // phone or email
}

class RegisterRequest {
  String firstName;
  String lastName;
  String phone; // +994 format, required
  String password; // min 8 chars, 1 uppercase, 1 digit
  String? email; // optional
  UserType userType; // JOB_SEEKER or EMPLOYER
}

class LoginRequest {
  String identifier; // phone or email
  String password;
}

class User {
  String id;
  String firstName;
  String lastName;
  String phone;
  String? email;
  UserType userType;
  DateTime createdAt;
  bool isVerified; // for future OTP implementation
}
```

**Validation Rules:**

```dart
class AuthValidation {
  // Phone: +994 format, 9 digits after country code
  static bool validatePhone(String phone) {
    final regex = RegExp(r'^\+994\d{9}$');
    return regex.hasMatch(phone);
  }
  
  // Password: min 8 chars, at least 1 uppercase, 1 digit
  static bool validatePassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }
  
  // Email: valid email format (optional)
  static bool validateEmail(String? email) {
    if (email == null || email.isEmpty) return true; // optional
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }
}
```

**UI Screens:**

```dart
// RegisterScreen: New user registration
class RegisterScreen extends StatefulWidget {
  // Form fields:
  // - First Name (required)
  // - Last Name (required)
  // - Phone (+994 format, required)
  // - Password (min 8 chars, 1 uppercase, 1 digit, required)
  // - Email (optional)
  // - User Type Selection (Job Seeker / Employer, required)
  // - Submit button
}

// LoginScreen: Existing user login
class LoginScreen extends StatefulWidget {
  // Form fields:
  // - Identifier (phone or email, required)
  // - Password (required)
  // - Submit button
  // - Forgot password link
}
```

### 2. Profil Yönetimi Modülü (Profile Module)

**Sorumluluklar:**
- İş arayan profil yönetimi
- İşveren profil yönetimi
- Profil fotoğrafı ve dosya yükleme
- Profil görüntüleme ve düzenleme

**Arayüzler:**

```dart
abstract class ProfileRepository {
  Future<JobSeekerProfile> getJobSeekerProfile(String userId);
  Future<EmployerProfile> getEmployerProfile(String userId);
  Future<void> updateJobSeekerProfile(JobSeekerProfile profile);
  Future<void> updateEmployerProfile(EmployerProfile profile);
  Future<String> uploadProfilePhoto(File photo);
  Future<String> uploadResume(File resume);
  Future<void> deleteProfile(String userId);
}

class JobSeekerProfile {
  String id;
  String userId;
  DateTime dateOfBirth;
  String? photoUrl;
  String? resumeUrl;
  List<WorkExperience> experiences;
  List<Education> educations;
  List<String> skills;
  List<JobCategory> preferredCategories;
  List<WorkType> preferredWorkTypes;
  Location location;
  SalaryRange? expectedSalary;
  
  // Name fields come from User entity
  String get fullName => '${user.firstName} ${user.lastName}';
  String get phone => user.phone;
  String? get email => user.email;
}

class EmployerProfile {
  String id;
  String companyName;
  String industry;
  CompanySize size;
  String email;
  String phone;
  String? logoUrl;
  String description;
  Location location;
  String? website;
  Map<String, String> socialLinks;
  String? taxNumber;
}
```

### 3. İş İlanı Modülü (Job Posting Module)

**Sorumluluklar:**
- İş ilanı oluşturma ve yönetimi
- İş ilanı arama ve filtreleme
- İş ilanı görüntüleme
- Favori ilanlar

**Arayüzler:**

```dart
abstract class JobRepository {
  Future<String> createJob(JobPosting job);
  Future<void> updateJob(String jobId, JobPosting job);
  Future<void> deleteJob(String jobId);
  Future<JobPosting> getJob(String jobId);
  Future<List<JobPosting>> searchJobs(JobSearchCriteria criteria);
  Future<List<JobPosting>> getEmployerJobs(String employerId);
  Future<void> pauseJob(String jobId);
  Future<void> activateJob(String jobId);
  Future<void> addToFavorites(String userId, String jobId);
  Future<void> removeFromFavorites(String userId, String jobId);
  Future<List<JobPosting>> getFavorites(String userId);
}

class JobPosting {
  String id;
  String employerId;
  String title;
  String description;
  String requirements;
  String responsibilities;
  JobCategory category;
  WorkType workType;
  DayHourDetails? dayHourDetails; // For part-time/hourly jobs
  SalaryRange salary;
  Location location;
  ExperienceLevel experienceLevel;
  List<String> requiredSkills;
  EducationLevel? educationRequirement;
  JobStatus status; // ACTIVE, PAUSED, CLOSED
  DateTime createdAt;
  DateTime? expiresAt;
  int viewCount;
  int applicationCount;
}

class JobSearchCriteria {
  String? keyword;
  List<JobCategory>? categories;
  List<WorkType>? workTypes;
  Location? location;
  double? maxDistance; // in km
  SalaryRange? salaryRange;
  ExperienceLevel? experienceLevel;
  SortBy sortBy; // DATE, DISTANCE, SALARY
  int page;
  int pageSize;
}

enum WorkType {
  FULL_TIME,
  PART_TIME,
  FREELANCE,
  TEMPORARY,
  DAILY_HOURLY
}

enum JobStatus {
  ACTIVE,
  PAUSED,
  CLOSED
}
```

### 4. Başvuru Modülü (Application Module)

**Sorumluluklar:**
- İş başvurusu yapma
- Başvuru takibi
- Başvuru değerlendirme
- Başvuru durumu yönetimi

**Arayüzler:**

```dart
abstract class ApplicationRepository {
  Future<String> submitApplication(JobApplication application);
  Future<List<JobApplication>> getJobSeekerApplications(String jobSeekerId);
  Future<List<JobApplication>> getJobApplications(String jobId);
  Future<void> updateApplicationStatus(String applicationId, ApplicationStatus status);
  Future<JobApplication> getApplication(String applicationId);
  Future<void> addApplicationNote(String applicationId, String note);
  Future<void> addToFavoriteApplicants(String employerId, String applicationId);
  Future<bool> hasApplied(String jobSeekerId, String jobId);
}

class JobApplication {
  String id;
  String jobId;
  String jobSeekerId;
  String? coverLetter;
  String? resumeUrl;
  ApplicationStatus status;
  DateTime appliedAt;
  DateTime? viewedAt;
  DateTime? statusChangedAt;
  String? employerNote;
  bool isFavorite;
}

enum ApplicationStatus {
  PENDING,
  VIEWED,
  UNDER_REVIEW,
  ACCEPTED,
  REJECTED
}
```

### 5. Mesajlaşma Modülü (Messaging Module)

**Sorumluluklar:**
- Anlık mesajlaşma
- Mesaj geçmişi
- Dosya paylaşımı
- Mesaj bildirimleri

**Arayüzler:**

```dart
abstract class MessagingRepository {
  Future<String> sendMessage(Message message);
  Future<List<Conversation>> getConversations(String userId);
  Future<List<Message>> getMessages(String conversationId, int page, int pageSize);
  Future<void> markAsRead(String messageId);
  Future<void> deleteConversation(String conversationId);
  Future<void> blockUser(String userId, String blockedUserId);
  Future<void> unblockUser(String userId, String blockedUserId);
  Future<List<String>> getBlockedUsers(String userId);
  Stream<Message> messageStream(String conversationId);
}

class Message {
  String id;
  String conversationId;
  String senderId;
  String receiverId;
  MessageType type; // TEXT, IMAGE, FILE
  String content;
  String? fileUrl;
  String? fileName;
  MessageStatus status; // SENT, DELIVERED, READ
  DateTime sentAt;
  DateTime? deliveredAt;
  DateTime? readAt;
}

class Conversation {
  String id;
  String user1Id;
  String user2Id;
  Message? lastMessage;
  int unreadCount;
  DateTime updatedAt;
}

enum MessageType {
  TEXT,
  IMAGE,
  FILE
}

enum MessageStatus {
  SENT,
  DELIVERED,
  READ
}
```

### 6. Hizmet Pazarı Modülü (Service Marketplace Module)

**Sorumluluklar:**
- Hizmet profili yönetimi
- Hizmet arama ve filtreleme
- Hizmet sağlayıcı değerlendirme
- Fiyat teklifi yönetimi

**Arayüzler:**

```dart
abstract class ServiceRepository {
  Future<String> createServiceProfile(ServiceProfile profile);
  Future<void> updateServiceProfile(ServiceProfile profile);
  Future<ServiceProfile> getServiceProfile(String profileId);
  Future<List<ServiceProfile>> searchServices(ServiceSearchCriteria criteria);
  Future<void> updateAvailability(String profileId, bool isAvailable);
  Future<String> requestQuote(QuoteRequest request);
  Future<List<QuoteRequest>> getQuoteRequests(String serviceProviderId);
}

class ServiceProfile {
  String id;
  String userId;
  List<ServiceCategory> categories;
  int experienceYears;
  List<Location> workingAreas;
  PriceRange priceRange;
  List<String> portfolioPhotos;
  bool isAvailable;
  double averageRating;
  int reviewCount;
  String description;
}

class QuoteRequest {
  String id;
  String serviceProviderId;
  String requesterId;
  ServiceCategory category;
  String description;
  Location location;
  DateTime? preferredDate;
  QuoteStatus status;
  double? quotedPrice;
  DateTime createdAt;
}

enum ServiceCategory {
  PLUMBER,
  ELECTRICIAN,
  PAINTER,
  CARPENTER,
  MASON,
  CLEANING,
  MOVING,
  RENOVATION,
  OTHER
}

enum QuoteStatus {
  PENDING,
  QUOTED,
  ACCEPTED,
  REJECTED,
  COMPLETED
}
```

### 7. Değerlendirme ve Yorum Modülü (Review Module)

**Sorumluluklar:**
- Değerlendirme oluşturma
- Değerlendirme görüntüleme
- Ortalama puan hesaplama
- Uygunsuz içerik bildirimi

**Arayüzler:**

```dart
abstract class ReviewRepository {
  Future<String> createReview(Review review);
  Future<List<Review>> getReviews(String targetId, ReviewTargetType type);
  Future<double> getAverageRating(String targetId, ReviewTargetType type);
  Future<bool> canReview(String reviewerId, String targetId, ReviewTargetType type);
  Future<void> reportReview(String reviewId, String reason);
  Future<void> deleteReview(String reviewId);
}

class Review {
  String id;
  String reviewerId;
  String targetId; // employerId or serviceProviderId
  ReviewTargetType targetType;
  int rating; // 1-5
  String? comment;
  DateTime createdAt;
  int helpfulCount;
  bool isReported;
}

enum ReviewTargetType {
  EMPLOYER,
  SERVICE_PROVIDER
}
```

### 8. Bildirim Modülü (Notification Module)

**Sorumluluklar:**
- Push bildirim gönderme
- Bildirim geçmişi
- Bildirim tercihleri
- Uygulama içi bildirimler

**Arayüzler:**

```dart
abstract class NotificationRepository {
  Future<void> sendNotification(NotificationData notification);
  Future<List<NotificationData>> getNotifications(String userId, int page, int pageSize);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> updatePreferences(String userId, NotificationPreferences preferences);
  Future<NotificationPreferences> getPreferences(String userId);
  Future<void> registerDeviceToken(String userId, String token);
}

class NotificationData {
  String id;
  String userId;
  NotificationType type;
  String title;
  String body;
  Map<String, dynamic>? data;
  bool isRead;
  DateTime createdAt;
}

class NotificationPreferences {
  bool enablePushNotifications;
  bool enableNewMessage;
  bool enableApplicationStatus;
  bool enableNewApplication;
  bool enableNewJobAlert;
  bool enableInAppNotifications;
}

enum NotificationType {
  NEW_MESSAGE,
  APPLICATION_STATUS_CHANGED,
  NEW_APPLICATION,
  NEW_JOB_ALERT,
  SYSTEM_ANNOUNCEMENT
}
```

### 9. Konum Servisi (Location Service)

**Sorumluluklar:**
- GPS konum tespiti
- Mesafe hesaplama
- Harita entegrasyonu
- Adres arama

**Arayüzler:**

```dart
abstract class LocationService {
  Future<Location> getCurrentLocation();
  Future<double> calculateDistance(Location from, Location to);
  Future<List<Location>> searchLocations(String query);
  Future<String> getAddressFromCoordinates(double lat, double lng);
  Future<Location?> getCoordinatesFromAddress(String address);
}

class Location {
  double latitude;
  double longitude;
  String? address;
  String? city;
  String? district;
  String? country;
}
```

### 10. Analitik Modülü (Analytics Module)

**Sorumluluklar:**
- İlan performans takibi
- Kullanıcı istatistikleri
- Raporlama
- Veri toplama

**Arayüzler:**

```dart
abstract class AnalyticsRepository {
  Future<JobAnalytics> getJobAnalytics(String jobId);
  Future<EmployerAnalytics> getEmployerAnalytics(String employerId);
  Future<JobSeekerAnalytics> getJobSeekerAnalytics(String jobSeekerId);
  Future<void> trackJobView(String jobId, String? userId);
  Future<void> trackProfileView(String profileId, String viewerId);
  Future<List<JobAnalytics>> getTopPerformingJobs(String employerId, int limit);
}

class JobAnalytics {
  String jobId;
  int viewCount;
  int applicationCount;
  double conversionRate;
  Map<DateTime, int> viewsOverTime;
  Map<DateTime, int> applicationsOverTime;
}

class EmployerAnalytics {
  String employerId;
  int totalJobs;
  int activeJobs;
  int totalApplications;
  double averageConversionRate;
  List<JobAnalytics> topJobs;
}

class JobSeekerAnalytics {
  String jobSeekerId;
  int profileViews;
  int totalApplications;
  Map<ApplicationStatus, int> applicationsByStatus;
}
```

### 11. İçerik Moderasyon Modülü (Content Moderation Module)

**Sorumluluklar:**
- İçerik filtreleme
- Spam tespiti
- Kullanıcı şikayetleri
- Otomatik moderasyon

**Arayüzler:**

```dart
abstract class ModerationRepository {
  Future<bool> checkContent(String content);
  Future<void> reportContent(ContentReport report);
  Future<List<ContentReport>> getPendingReports();
  Future<void> approveContent(String contentId);
  Future<void> rejectContent(String contentId, String reason);
  Future<void> banUser(String userId, Duration duration, String reason);
  Future<void> unbanUser(String userId);
  Future<bool> isUserBanned(String userId);
}

class ContentReport {
  String id;
  String reporterId;
  String contentId;
  ContentType contentType;
  String reason;
  ReportStatus status;
  DateTime createdAt;
}

enum ContentType {
  JOB_POSTING,
  PROFILE,
  MESSAGE,
  REVIEW
}

enum ReportStatus {
  PENDING,
  APPROVED,
  REJECTED
}
```

### 12. Mock Data Yönetimi ve Boş State Stratejisi

**Sorumluluklar:**
- Mock data'nın kaldırılması
- Gerçek API entegrasyonu hazırlığı
- Boş state UI yönetimi
- Kullanıcı deneyimi optimizasyonu

**Strateji:**

```dart
// Mock data kaldırılacak - gerçek API'den veri çekilecek
// MockData.jobs listesi artık kullanılmayacak

abstract class JobDataSource {
  // Real API implementation
  Future<List<JobPosting>> fetchJobs(JobSearchCriteria criteria);
  Future<JobPosting> fetchJobById(String jobId);
}

// Empty state handling
class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  
  // Different empty states:
  // - Employer: "Henüz ilan yok" + "İlk ilanı siz oluşturun" CTA
  // - Job Seeker: "Henüz ilan yok" + "İlanlar yayınlandığında burada görünecek"
  // - Search Results: "Arama sonucu bulunamadı" + "Farklı kriterler deneyin"
}

enum EmptyStateType {
  EMPLOYER_NO_JOBS,
  JOB_SEEKER_NO_JOBS,
  NO_SEARCH_RESULTS,
  NO_APPLICATIONS,
  NO_MESSAGES
}
```

**UI Tasarımı:**

```dart
// Employer Home - Empty State
class EmployerHomeEmptyState {
  // Icon: Briefcase icon
  // Title: "Henüz ilan yok"
  // Description: "İlk iş ilanınızı oluşturarak başlayın"
  // CTA Button: "İlan Oluştur"
}

// Job Seeker Home - Empty State
class JobSeekerHomeEmptyState {
  // Icon: Search icon
  // Title: "Henüz ilan yok"
  // Description: "İlanlar yayınlandığında burada görünecek"
  // Optional: "Profil tamamlama" reminder
}

// Search Results - Empty State
class SearchEmptyState {
  // Icon: Magnifying glass icon
  // Title: "Sonuç bulunamadı"
  // Description: "Farklı arama kriterleri deneyin"
  // Suggestions: Popular categories or recent searches
}
```

**Implementation Notes:**
- Mock data tamamen kaldırılacak
- API endpoint'leri hazır olana kadar boş state gösterilecek
- Loading states düzgün handle edilecek
- Error states için retry mekanizması eklenecek
- Skeleton loaders kullanılacak (shimmer effect)

## Veri Modelleri

### Ortak Veri Tipleri

```dart
class SalaryRange {
  double min;
  double max;
  String currency; // "AZN"
  SalaryPeriod period; // HOURLY, DAILY, MONTHLY
}

enum SalaryPeriod {
  HOURLY,
  DAILY,
  MONTHLY,
  YEARLY
}

class DayHourDetails {
  List<DayOfWeek> workDays;
  TimeRange workHours;
  int hoursPerWeek;
}

enum DayOfWeek {
  MONDAY,
  TUESDAY,
  WEDNESDAY,
  THURSDAY,
  FRIDAY,
  SATURDAY,
  SUNDAY
}

class TimeRange {
  String startTime; // "09:00"
  String endTime; // "18:00"
}

class WorkExperience {
  String companyName;
  String position;
  DateTime startDate;
  DateTime? endDate;
  bool isCurrentJob;
  String? description;
}

class Education {
  String institution;
  String degree;
  String fieldOfStudy;
  DateTime startDate;
  DateTime? endDate;
  bool isCurrent;
}

enum JobCategory {
  CONSTRUCTION,
  HOSPITALITY,
  RETAIL,
  MANUFACTURING,
  TRANSPORTATION,
  HEALTHCARE,
  CLEANING,
  SECURITY,
  WAREHOUSE,
  FOOD_SERVICE,
  OTHER
}

enum ExperienceLevel {
  ENTRY,
  MID,
  SENIOR
}

enum EducationLevel {
  NO_REQUIREMENT,
  HIGH_SCHOOL,
  VOCATIONAL,
  BACHELORS,
  MASTERS
}

enum CompanySize {
  SMALL, // 1-10
  MEDIUM, // 11-50
  LARGE, // 51-200
  ENTERPRISE // 200+
}

enum UserType {
  JOB_SEEKER,
  EMPLOYER
}

class PriceRange {
  double min;
  double max;
  String currency; // "AZN"
}
```

### Veritabanı Şeması

**Users Table**
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  phone VARCHAR(20) UNIQUE NOT NULL, -- +994 format
  email VARCHAR(255) UNIQUE, -- optional
  password_hash VARCHAR(255) NOT NULL, -- bcrypt hashed
  user_type VARCHAR(20) NOT NULL, -- JOB_SEEKER or EMPLOYER
  is_verified BOOLEAN DEFAULT FALSE, -- for future OTP
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_user_type ON users(user_type);
```

**Job_Seeker_Profiles Table**
```sql
CREATE TABLE job_seeker_profiles (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  date_of_birth DATE,
  photo_url TEXT,
  resume_url TEXT,
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  location_address TEXT,
  location_city VARCHAR(100),
  skills TEXT[], -- Array of skills
  preferred_categories TEXT[], -- Array of job categories
  preferred_work_types TEXT[], -- Array of work types
  expected_salary_min DECIMAL(10, 2),
  expected_salary_max DECIMAL(10, 2),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id)
);

CREATE INDEX idx_job_seeker_user_id ON job_seeker_profiles(user_id);
```

**Employer_Profiles Table**
```sql
CREATE TABLE employer_profiles (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  company_name VARCHAR(255) NOT NULL,
  industry VARCHAR(100),
  company_size VARCHAR(20),
  logo_url TEXT,
  description TEXT,
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  location_address TEXT,
  location_city VARCHAR(100),
  website VARCHAR(255),
  social_links JSONB,
  tax_number VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Job_Postings Table**
```sql
CREATE TABLE job_postings (
  id UUID PRIMARY KEY,
  employer_id UUID REFERENCES employer_profiles(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  requirements TEXT,
  responsibilities TEXT,
  category VARCHAR(50) NOT NULL,
  work_type VARCHAR(50) NOT NULL,
  day_hour_details JSONB,
  salary_min DECIMAL(10, 2),
  salary_max DECIMAL(10, 2),
  salary_currency VARCHAR(10) DEFAULT 'AZN',
  salary_period VARCHAR(20),
  location_lat DECIMAL(10, 8) NOT NULL,
  location_lng DECIMAL(11, 8) NOT NULL,
  location_address TEXT,
  location_city VARCHAR(100),
  experience_level VARCHAR(20),
  required_skills TEXT[],
  education_requirement VARCHAR(50),
  status VARCHAR(20) DEFAULT 'ACTIVE',
  view_count INTEGER DEFAULT 0,
  application_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP
);

CREATE INDEX idx_job_postings_status ON job_postings(status);
CREATE INDEX idx_job_postings_category ON job_postings(category);
CREATE INDEX idx_job_postings_location ON job_postings USING GIST(
  ll_to_earth(location_lat, location_lng)
);
```

**Applications Table**
```sql
CREATE TABLE applications (
  id UUID PRIMARY KEY,
  job_id UUID REFERENCES job_postings(id) ON DELETE CASCADE,
  job_seeker_id UUID REFERENCES job_seeker_profiles(id) ON DELETE CASCADE,
  cover_letter TEXT,
  resume_url TEXT,
  status VARCHAR(20) DEFAULT 'PENDING',
  is_favorite BOOLEAN DEFAULT FALSE,
  employer_note TEXT,
  applied_at TIMESTAMP DEFAULT NOW(),
  viewed_at TIMESTAMP,
  status_changed_at TIMESTAMP,
  UNIQUE(job_id, job_seeker_id)
);

CREATE INDEX idx_applications_job_id ON applications(job_id);
CREATE INDEX idx_applications_job_seeker_id ON applications(job_seeker_id);
CREATE INDEX idx_applications_status ON applications(status);
```

**Messages Table**
```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY,
  conversation_id UUID NOT NULL,
  sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES users(id) ON DELETE CASCADE,
  message_type VARCHAR(20) NOT NULL,
  content TEXT,
  file_url TEXT,
  file_name VARCHAR(255),
  status VARCHAR(20) DEFAULT 'SENT',
  sent_at TIMESTAMP DEFAULT NOW(),
  delivered_at TIMESTAMP,
  read_at TIMESTAMP
);

CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_receiver_id ON messages(receiver_id);
```

**Service_Profiles Table**
```sql
CREATE TABLE service_profiles (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  categories TEXT[] NOT NULL,
  experience_years INTEGER,
  working_areas JSONB, -- Array of locations
  price_min DECIMAL(10, 2),
  price_max DECIMAL(10, 2),
  price_currency VARCHAR(10) DEFAULT 'AZN',
  portfolio_photos TEXT[],
  is_available BOOLEAN DEFAULT TRUE,
  average_rating DECIMAL(3, 2) DEFAULT 0,
  review_count INTEGER DEFAULT 0,
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Reviews Table**
```sql
CREATE TABLE reviews (
  id UUID PRIMARY KEY,
  reviewer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  target_id UUID NOT NULL,
  target_type VARCHAR(20) NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  helpful_count INTEGER DEFAULT 0,
  is_reported BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(reviewer_id, target_id, target_type)
);

CREATE INDEX idx_reviews_target ON reviews(target_id, target_type);
```

**Notifications Table**
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  notification_type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
```

## Doğruluk Özellikleri (Correctness Properties)

*Bir özellik (property), bir sistemin tüm geçerli yürütmelerinde doğru olması gereken bir karakteristik veya davranıştır - esasen, sistemin ne yapması gerektiğine dair resmi bir ifadedir. Özellikler, insan tarafından okunabilir spesifikasyonlar ile makine tarafından doğrulanabilir doğruluk garantileri arasında köprü görevi görür.*


### Özellik 1: Kayıt Zorunlu Alanları Doğrulaması
*Her* geçerli kayıt isteği için, sistem isim, soy isim, telefon numarası ve şifre alanlarının dolu olmasını zorunlu kılmalıdır
**Doğrular: Gereksinim 1.1**

### Özellik 2: Telefon Numarası Format Doğrulaması
*Her* telefon numarası için, +994 formatına uymayan ve 9 haneli olmayan numaralar reddedilmelidir
**Doğrular: Gereksinim 1.1, 11.4**

### Özellik 3: Şifre Doğrulama Kuralları
*Her* şifre için, 8 karakterden kısa, büyük harf içermeyen veya rakam içermeyen şifreler reddedilmelidir
**Doğrular: Gereksinim 1.3**

### Özellik 4: Email Opsiyonelliği
*Her* kayıt isteği için, email alanı boş bırakılabilmeli ve kayıt işlemi başarıyla tamamlanmalıdır
**Doğrular: Gereksinim 1.1**

### Özellik 5: Kullanıcı Tipi Zorunluluğu
*Her* kayıt isteği için, kullanıcı tipi (İş_Arayan veya İşveren) belirtilmemişse kayıt reddedilmelidir
**Doğrular: Gereksinim 1.4**

### Özellik 6: Telefon veya Email ile Giriş
*Her* giriş isteği için, sistem hem telefon hem de email ile giriş yapabilmeyi desteklemelidir
**Doğrular: Gereksinim 1.5, 1.6**

### Özellik 7: Kimlik Doğrulama Oturum Oluşturma
*Her* geçerli giriş bilgisi için, sistem bir oturum oluşturmalı ve geçersiz bilgiler için oturum oluşturmamalıdır
**Doğrular: Gereksinim 1.7**

### Özellik 8: Tekrarlı Telefon Engelleme
*Her* kayıt isteği için, daha önce kullanılmış bir telefon numarası ile kayıt girişimi reddedilmelidir
**Doğrular: Gereksinim 1.1**

### Özellik 9: Tekrarlı Email Engelleme
*Her* kayıt isteği için, daha önce kullanılmış bir email adresi ile kayıt girişimi reddedilmelidir
**Doğrular: Gereksinim 1.1**

### Özellik 10: Profil Veri Bütünlüğü
*Her* İş_Arayan profili için, user entity'den gelen zorunlu alanlar (firstName, lastName, phone) mevcut olmalıdır
**Doğrular: Gereksinim 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 2.10, 2.11**

### Özellik 11: İşveren Profil Veri Bütünlüğü
*Her* İşveren profili için, tüm zorunlu alanlar (şirket adı, sektör, telefon, e-posta) mevcut olmalıdır
**Doğrular: Gereksinim 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7**

### Özellik 12: Yeni İlan Aktif Durumu
*Her* yeni oluşturulan iş ilanı için, ilanın durumu ACTIVE olmalıdır
**Doğrular: Gereksinim 4.11**

### Özellik 13: İlan Yönetim İşlemleri
*Her* iş ilanı için, düzenleme, duraklama ve silme işlemleri başarıyla gerçekleştirilmelidir
**Doğrular: Gereksinim 4.12, 4.13, 4.14**

### Özellik 14: Konum Bazlı Sıralama
*Her* konum filtreli arama için, sonuçlar kullanıcı konumuna olan mesafeye göre artan sırada sıralanmalıdır
**Doğrular: Gereksinim 5.8, 12.4**

### Özellik 15: Başvuru Kalıcılığı
*Her* geçerli iş başvurusu için, başvuru veritabanına kaydedilmeli ve sonradan sorgulanabilir olmalıdır
**Doğrular: Gereksinim 6.1**

### Özellik 16: Tekrarlı Başvuru Engelleme
*Her* kullanıcı ve iş ilanı çifti için, aynı kullanıcının aynı ilana birden fazla başvurusu reddedilmelidir
**Doğrular: Gereksinim 6.9**

### Özellik 17: Başvuru Durumu Otomatik Güncelleme
*Her* başvuru görüntüleme işlemi için, başvurunun durumu PENDING ise VIEWED olarak güncellenmelidir
**Doğrular: Gereksinim 7.4**

### Özellik 18: Mesaj Kalıcılığı
*Her* gönderilen mesaj için, mesaj veritabanına kaydedilmeli ve alıcı tarafından sorgulanabilir olmalıdır
**Doğrular: Gereksinim 8.2**

### Özellik 19: Engellenen Kullanıcı Mesaj Kısıtlaması
*Her* engellenmiş kullanıcı için, engelleyen kullanıcıya mesaj gönderme girişimi reddedilmelidir
**Doğrular: Gereksinim 8.13**

### Özellik 20: Bildirim Oluşturma
*Her* yeni mesaj, başvuru durumu değişikliği, yeni başvuru ve yeni ilan olayı için, ilgili kullanıcıya bildirim oluşturulmalıdır
**Doğrular: Gereksinim 10.2, 10.3, 10.4, 10.5**

### Özellik 21: Para Birimi Tutarlılığı
*Her* para birimi gösterimi için, değer Azerbaycan Manatı (AZN) cinsinden olmalıdır
**Doğrular: Gereksinim 11.2**

### Özellik 22: Telefon Numarası Doğrulama
*Her* telefon numarası için, Azerbaycan formatına (+994) uymayan numaralar reddedilmelidir
**Doğrular: Gereksinim 11.4**

### Özellik 23: Tekrarlı Değerlendirme Engelleme
*Her* kullanıcı ve hedef (işveren/hizmet sağlayıcı) çifti için, aynı kullanıcının aynı hedef için birden fazla değerlendirmesi reddedilmelidir
**Doğrular: Gereksinim 13.9**

### Özellik 24: Şifre Şifreleme
*Her* kaydedilen şifre için, şifre düz metin olarak değil, hash'lenmiş olarak saklanmalıdır
**Doğrular: Gereksinim 15.1**

### Özellik 25: Hesap Silme Veri Temizliği
*Her* hesap silme işlemi için, kullanıcının tüm kişisel verileri veritabanından kalıcı olarak silinmeli ve sonradan sorgulanamaz olmalıdır
**Doğrular: Gereksinim 15.7**

### Özellik 26: Çapraz Cihaz Veri Tutarlılığı
*Her* kullanıcı için, farklı cihazlardan erişildiğinde aynı veriler (profil, başvurular, mesajlar) görüntülenmelidir
**Doğrular: Gereksinim 17.2**

### Özellik 27: Yasaklı İçerik Filtreleme
*Her* yasaklı kelime içeren içerik için, içerik otomatik olarak moderasyon kuyruğuna gönderilmeli ve doğrudan yayınlanmamalıdır
**Doğrular: Gereksinim 20.4**


## Hata Yönetimi

### Hata Kategorileri

**1. Doğrulama Hataları (Validation Errors)**
- Geçersiz giriş verileri
- Eksik zorunlu alanlar
- Format hataları (e-posta, telefon)
- HTTP Status: 400 Bad Request

**2. Kimlik Doğrulama Hataları (Authentication Errors)**
- Geçersiz kimlik bilgileri
- Süresi dolmuş token
- Yetkisiz erişim
- HTTP Status: 401 Unauthorized

**3. Yetkilendirme Hataları (Authorization Errors)**
- Yetersiz izinler
- Başka kullanıcının verilerine erişim
- HTTP Status: 403 Forbidden

**4. Kaynak Bulunamadı Hataları (Not Found Errors)**
- Var olmayan kaynak
- Silinmiş içerik
- HTTP Status: 404 Not Found

**5. Çakışma Hataları (Conflict Errors)**
- Tekrarlı başvuru
- Tekrarlı değerlendirme
- Benzersizlik kısıtı ihlali
- HTTP Status: 409 Conflict

**6. Sunucu Hataları (Server Errors)**
- Veritabanı bağlantı hataları
- Üçüncü parti servis hataları
- Beklenmeyen hatalar
- HTTP Status: 500 Internal Server Error

### Hata Yanıt Formatı

```dart
class ErrorResponse {
  String code; // Unique error code
  String message; // User-friendly message in Azerbaijani
  String? details; // Technical details (optional)
  Map<String, dynamic>? fieldErrors; // Field-specific errors
  DateTime timestamp;
}
```

### Hata Kodları

```dart
enum ErrorCode {
  // Authentication
  INVALID_CREDENTIALS,
  TOKEN_EXPIRED,
  ACCOUNT_NOT_VERIFIED,
  ACCOUNT_SUSPENDED,
  
  // Validation
  INVALID_EMAIL,
  INVALID_PHONE,
  WEAK_PASSWORD,
  MISSING_REQUIRED_FIELD,
  INVALID_DATE_FORMAT,
  
  // Business Logic
  DUPLICATE_APPLICATION,
  DUPLICATE_REVIEW,
  JOB_NOT_ACTIVE,
  APPLICATION_LIMIT_REACHED,
  BLOCKED_USER,
  
  // Resources
  USER_NOT_FOUND,
  JOB_NOT_FOUND,
  APPLICATION_NOT_FOUND,
  CONVERSATION_NOT_FOUND,
  
  // Server
  DATABASE_ERROR,
  EXTERNAL_SERVICE_ERROR,
  UNKNOWN_ERROR
}
```

### Hata Yönetim Stratejisi

**Client-Side (Flutter)**
```dart
class ApiException implements Exception {
  final ErrorResponse error;
  ApiException(this.error);
}

// Global error handler
void handleError(dynamic error) {
  if (error is ApiException) {
    // Show user-friendly message
    showErrorDialog(error.error.message);
    
    // Log for debugging
    logger.error('API Error: ${error.error.code}', error);
  } else if (error is SocketException) {
    // Network error
    showErrorDialog('İnternet bağlantısı yok');
  } else {
    // Unknown error
    showErrorDialog('Beklenmeyen bir hata oluştu');
    logger.error('Unknown error', error);
  }
}
```

**Server-Side**
```dart
// Middleware for error handling
Future<Response> errorHandler(Request request, RequestHandler handler) async {
  try {
    return await handler(request);
  } on ValidationException catch (e) {
    return Response.json(
      statusCode: 400,
      body: ErrorResponse(
        code: e.code,
        message: e.message,
        fieldErrors: e.fieldErrors,
        timestamp: DateTime.now(),
      ),
    );
  } on AuthenticationException catch (e) {
    return Response.json(
      statusCode: 401,
      body: ErrorResponse(
        code: e.code,
        message: e.message,
        timestamp: DateTime.now(),
      ),
    );
  } catch (e) {
    logger.error('Unhandled error', e);
    return Response.json(
      statusCode: 500,
      body: ErrorResponse(
        code: 'UNKNOWN_ERROR',
        message: 'Sistem hatası oluştu',
        timestamp: DateTime.now(),
      ),
    );
  }
}
```

### Retry Stratejisi

**Network Requests**
- Otomatik retry: 3 deneme
- Exponential backoff: 1s, 2s, 4s
- Sadece idempotent istekler için (GET, PUT, DELETE)

**Real-time Messaging**
- WebSocket bağlantı kopması durumunda otomatik yeniden bağlanma
- Maksimum 5 deneme
- Exponential backoff: 2s, 4s, 8s, 16s, 32s

**File Uploads**
- Chunk-based upload ile kesintiye dayanıklılık
- Resume capability
- Maksimum 3 deneme

## Test Stratejisi

### İkili Test Yaklaşımı

Uygulama hem birim testleri hem de özellik tabanlı testler (property-based tests) kullanacaktır. Bu iki test türü birbirini tamamlar:

- **Birim Testler**: Belirli örnekler, kenar durumlar ve hata koşulları için
- **Özellik Tabanlı Testler**: Tüm girdiler için evrensel özellikler için

### Birim Test Stratejisi

**Test Kapsamı:**
- Widget testleri (UI bileşenleri)
- BLoC/Cubit testleri (State management)
- Repository testleri (Data layer)
- Use case testleri (Business logic)
- Utility function testleri

**Test Framework:**
- flutter_test (built-in)
- mocktail (Mocking)
- bloc_test (BLoC testing)

**Örnek Birim Testler:**
```dart
// Widget test - Register Screen
testWidgets('Register button should be disabled when required fields are empty', (tester) async {
  await tester.pumpWidget(RegisterScreen());
  
  final registerButton = find.byKey(Key('register_button'));
  expect(tester.widget<ElevatedButton>(registerButton).enabled, false);
});

testWidgets('Register screen should show error for invalid phone format', (tester) async {
  await tester.pumpWidget(RegisterScreen());
  
  await tester.enterText(find.byKey(Key('phone_field')), '123456789');
  await tester.tap(find.byKey(Key('register_button')));
  await tester.pump();
  
  expect(find.text('Geçerli bir Azerbaycan telefon numarası girin (+994)'), findsOneWidget);
});

// Widget test - Login Screen
testWidgets('Login screen should accept both phone and email', (tester) async {
  await tester.pumpWidget(LoginScreen());
  
  // Test with phone
  await tester.enterText(find.byKey(Key('identifier_field')), '+994501234567');
  expect(find.text('+994501234567'), findsOneWidget);
  
  // Test with email
  await tester.enterText(find.byKey(Key('identifier_field')), 'test@example.com');
  expect(find.text('test@example.com'), findsOneWidget);
});

// BLoC test
blocTest<AuthBloc, AuthState>(
  'emits [AuthLoading, AuthSuccess] when registration succeeds',
  build: () => AuthBloc(mockAuthRepository),
  act: (bloc) => bloc.add(RegisterRequested(
    firstName: 'John',
    lastName: 'Doe',
    phone: '+994501234567',
    password: 'Password123',
    userType: UserType.JOB_SEEKER,
  )),
  expect: () => [AuthLoading(), AuthSuccess(mockUser)],
);

blocTest<AuthBloc, AuthState>(
  'emits [AuthLoading, AuthError] when phone is duplicate',
  build: () => AuthBloc(mockAuthRepository),
  act: (bloc) => bloc.add(RegisterRequested(
    firstName: 'John',
    lastName: 'Doe',
    phone: '+994501234567', // already exists
    password: 'Password123',
    userType: UserType.JOB_SEEKER,
  )),
  expect: () => [
    AuthLoading(), 
    AuthError('Bu telefon numarası zaten kayıtlı')
  ],
);

// Repository test
test('should return user when registration is successful', () async {
  when(() => mockApiClient.post('/auth/register', any()))
      .thenAnswer((_) async => Response(data: mockUserJson, statusCode: 201));
  
  final result = await authRepository.register(RegisterRequest(
    firstName: 'John',
    lastName: 'Doe',
    phone: '+994501234567',
    password: 'Password123',
    userType: UserType.JOB_SEEKER,
  ));
  
  expect(result, isA<User>());
  expect(result.phone, '+994501234567');
  expect(result.firstName, 'John');
});

// Validation test
test('should validate phone number format correctly', () {
  expect(AuthValidation.validatePhone('+994501234567'), true);
  expect(AuthValidation.validatePhone('+994123456789'), true);
  expect(AuthValidation.validatePhone('994501234567'), false); // missing +
  expect(AuthValidation.validatePhone('+99450123456'), false); // too short
  expect(AuthValidation.validatePhone('+9945012345678'), false); // too long
});

test('should validate password requirements', () {
  expect(AuthValidation.validatePassword('Password123'), true);
  expect(AuthValidation.validatePassword('Pass123'), false); // too short
  expect(AuthValidation.validatePassword('password123'), false); // no uppercase
  expect(AuthValidation.validatePassword('Password'), false); // no digit
});

// Empty state test
testWidgets('Employer home should show empty state when no jobs', (tester) async {
  when(() => mockJobRepository.getEmployerJobs(any()))
      .thenAnswer((_) async => []);
  
  await tester.pumpWidget(EmployerHomeScreen());
  await tester.pumpAndSettle();
  
  expect(find.text('Henüz ilan yok'), findsOneWidget);
  expect(find.text('İlk ilanı siz oluşturun'), findsOneWidget);
  expect(find.byKey(Key('create_job_button')), findsOneWidget);
});

testWidgets('Job seeker home should show empty state when no jobs', (tester) async {
  when(() => mockJobRepository.searchJobs(any()))
      .thenAnswer((_) async => []);
  
  await tester.pumpWidget(JobSeekerHomeScreen());
  await tester.pumpAndSettle();
  
  expect(find.text('Henüz ilan yok'), findsOneWidget);
  expect(find.text('İlanlar yayınlandığında burada görünecek'), findsOneWidget);
});
```

### Özellik Tabanlı Test Stratejisi

**Test Framework:**
- Dart için: test + custom property test implementation veya QuickCheck-style library

**Konfigürasyon:**
- Her özellik testi minimum 100 iterasyon çalıştırılmalıdır
- Her test, tasarım belgesindeki özelliği referans almalıdır
- Tag formatı: **Feature: azerbaijan-job-marketplace, Property {numara}: {özellik metni}**

**Örnek Özellik Tabanlı Testler:**

```dart
// Property 2: Phone number format validation
test('Property 2: Phone number format validation', () {
  // Feature: azerbaijan-job-marketplace, Property 2: Phone validation
  final random = Random();
  
  for (int i = 0; i < 100; i++) {
    // Generate invalid phone numbers
    final invalidPhone1 = '994${random.nextInt(999999999)}'; // missing +
    expect(() => validatePhone(invalidPhone1), throwsA(isA<ValidationException>()));
    
    final invalidPhone2 = '+994${random.nextInt(99999999)}'; // too short
    expect(() => validatePhone(invalidPhone2), throwsA(isA<ValidationException>()));
    
    final invalidPhone3 = '+994${random.nextInt(9999999999)}'; // too long
    expect(() => validatePhone(invalidPhone3), throwsA(isA<ValidationException>()));
    
    // Generate valid phone number
    final validPhone = '+994${50 + random.nextInt(10)}${random.nextInt(9999999).toString().padLeft(7, '0')}';
    expect(() => validatePhone(validPhone), returnsNormally);
  }
});

// Property 3: Password validation rules
test('Property 3: Password validation rules', () {
  // Feature: azerbaijan-job-marketplace, Property 3: Password validation
  final random = Random();
  
  for (int i = 0; i < 100; i++) {
    // Generate invalid passwords
    final weakPassword = generateRandomString(random.nextInt(7) + 1); // < 8 chars
    expect(() => validatePassword(weakPassword), throwsA(isA<ValidationException>()));
    
    final noUpperCase = generateLowerCaseString(10);
    expect(() => validatePassword(noUpperCase), throwsA(isA<ValidationException>()));
    
    final noDigit = generateAlphaString(10);
    expect(() => validatePassword(noDigit), throwsA(isA<ValidationException>()));
    
    // Generate valid password
    final validPassword = generateValidPassword();
    expect(() => validatePassword(validPassword), returnsNormally);
  }
});

// Property 6: Phone or email login
test('Property 6: Phone or email login', () {
  // Feature: azerbaijan-job-marketplace, Property 6: Login with phone or email
  final random = Random();
  
  for (int i = 0; i < 100; i++) {
    // Test with phone
    final phone = generateValidPhone();
    final password = generateValidPassword();
    
    final loginWithPhone = login(LoginRequest(
      identifier: phone,
      password: password,
    ));
    expect(loginWithPhone, completes);
    
    // Test with email
    final email = generateValidEmail();
    final loginWithEmail = login(LoginRequest(
      identifier: email,
      password: password,
    ));
    expect(loginWithEmail, completes);
  }
});

// Property 8: Duplicate phone prevention
test('Property 8: Duplicate phone prevention', () {
  // Feature: azerbaijan-job-marketplace, Property 8: Duplicate phone
  final random = Random();
  
  for (int i = 0; i < 100; i++) {
    final phone = generateValidPhone();
    final password = generateValidPassword();
    
    // First registration should succeed
    final firstRegistration = register(RegisterRequest(
      firstName: 'John',
      lastName: 'Doe',
      phone: phone,
      password: password,
      userType: UserType.JOB_SEEKER,
    ));
    expect(firstRegistration, completes);
    
    // Second registration with same phone should fail
    expect(
      () => register(RegisterRequest(
        firstName: 'Jane',
        lastName: 'Smith',
        phone: phone, // duplicate
        password: generateValidPassword(),
        userType: UserType.EMPLOYER,
      )),
      throwsA(isA<ConflictException>())
    );
  }
});

// Property 9: Duplicate email prevention
test('Property 9: Duplicate email prevention', () {
  // Feature: azerbaijan-job-marketplace, Property 9: Duplicate email
  final random = Random();
  
  for (int i = 0; i < 100; i++) {
    final email = generateValidEmail();
    final password = generateValidPassword();
    
    // First registration should succeed
    final firstRegistration = register(RegisterRequest(
      firstName: 'John',
      lastName: 'Doe',
      phone: generateValidPhone(),
      password: password,
      email: email,
      userType: UserType.JOB_SEEKER,
    ));
    expect(firstRegistration, completes);
    
    // Second registration with same email should fail
    expect(
      () => register(RegisterRequest(
        firstName: 'Jane',
        lastName: 'Smith',
        phone: generateValidPhone(),
        password: generateValidPassword(),
        email: email, // duplicate
        userType: UserType.EMPLOYER,
      )),
      throwsA(isA<ConflictException>())
    );
  }
});

// Property 14: Location-based sorting
test('Property 14: Location-based sorting', () {
  // Feature: azerbaijan-job-marketplace, Property 14: Location sorting
  final random = Random();
  
  for (int i = 0; i < 100; i++) {
    // Generate random user location
    final userLocation = generateRandomLocation();
    
    // Generate random job postings with locations
    final jobs = List.generate(20, (_) => generateRandomJob());
    
    // Search with location filter
    final results = searchJobs(
      JobSearchCriteria(location: userLocation, sortBy: SortBy.DISTANCE)
    );
    
    // Verify results are sorted by distance
    for (int j = 0; j < results.length - 1; j++) {
      final dist1 = calculateDistance(userLocation, results[j].location);
      final dist2 = calculateDistance(userLocation, results[j + 1].location);
      expect(dist1, lessThanOrEqualTo(dist2));
    }
  }
});

// Property 16: Duplicate application prevention
test('Property 16: Duplicate application prevention', () {
  // Feature: azerbaijan-job-marketplace, Property 16: Duplicate prevention
  final random = Random();
  
  for (int i = 0; i < 100; i++) {
    final jobSeeker = generateRandomJobSeeker();
    final job = generateRandomJob();
    
    // First application should succeed
    final firstApplication = submitApplication(
      JobApplication(jobId: job.id, jobSeekerId: jobSeeker.id)
    );
    expect(firstApplication, completes);
    
    // Second application should fail
    expect(
      () => submitApplication(
        JobApplication(jobId: job.id, jobSeekerId: jobSeeker.id)
      ),
      throwsA(isA<ConflictException>())
    );
  }
});

// Property 24: Password hashing
test('Property 24: Password hashing', () {
  // Feature: azerbaijan-job-marketplace, Property 24: Password encryption
  final random = Random();
  
  for (int i = 0; i < 100; i++) {
    final password = generateValidPassword();
    final user = registerUser(RegisterRequest(
      firstName: 'John',
      lastName: 'Doe',
      phone: generateValidPhone(),
      password: password,
      userType: UserType.JOB_SEEKER,
    ));
    
    // Retrieve stored password from database
    final storedPassword = getStoredPassword(user.id);
    
    // Verify password is not stored in plaintext
    expect(storedPassword, isNot(equals(password)));
    
    // Verify password is hashed (bcrypt format)
    expect(storedPassword, matches(r'^\$2[aby]\$\d+\$.{53}$'));
  }
});
```


### Entegrasyon Testleri

**Test Kapsamı:**
- API endpoint testleri
- Veritabanı entegrasyon testleri
- Üçüncü parti servis entegrasyonları
- End-to-end akışlar

**Test Ortamı:**
- Test veritabanı (PostgreSQL)
- Mock external services (Firebase, Socket.IO)
- Test data seeding

### UI/Widget Testleri

**Test Kapsamı:**
- Ekran render testleri
- Kullanıcı etkileşim testleri
- Navigasyon testleri
- Form validasyon testleri

**Golden Tests:**
- Ekran görüntüsü karşılaştırma testleri
- Farklı ekran boyutları için
- Farklı tema modları için (light/dark)

### Performance Testleri

**Test Kapsamı:**
- Sayfa yükleme süreleri
- API response süreleri
- Veritabanı sorgu performansı
- Memory leak testleri

**Araçlar:**
- Flutter DevTools
- Firebase Performance Monitoring
- Custom performance metrics

### Test Coverage Hedefleri

- Birim test coverage: Minimum %80
- Widget test coverage: Minimum %70
- Integration test coverage: Kritik akışlar %100
- Property-based test: Tüm correctness properties

## Güvenlik Önlemleri

### Kimlik Doğrulama ve Yetkilendirme

**JWT Token Yapısı:**
```dart
class JWTPayload {
  String userId;
  UserType userType;
  DateTime issuedAt;
  DateTime expiresAt;
}
```

**Token Yönetimi:**
- Access token: 1 saat geçerlilik
- Refresh token: 30 gün geçerlilik
- Secure storage (flutter_secure_storage)
- Token rotation on refresh

**Şifre Güvenliği:**
- bcrypt hashing (cost factor: 12)
- Salt per password
- Minimum complexity requirements
- Password reset with time-limited tokens

### API Güvenliği

**Rate Limiting:**
- Login endpoint: 5 deneme / 15 dakika
- Registration: 3 deneme / saat
- API calls: 100 istek / dakika per user
- Message sending: 20 mesaj / dakika

**Input Validation:**
- Server-side validation (never trust client)
- SQL injection prevention (parameterized queries)
- XSS prevention (input sanitization)
- File upload validation (type, size, content)

**HTTPS/TLS:**
- Tüm API iletişimi HTTPS üzerinden
- Certificate pinning (mobile app)
- TLS 1.3 minimum

### Veri Güvenliği

**Encryption:**
- Passwords: bcrypt
- Sensitive data at rest: AES-256
- Data in transit: TLS 1.3

**Data Privacy:**
- GDPR/KVKK compliance
- User consent management
- Data retention policies
- Right to be forgotten implementation

**Access Control:**
- Role-based access control (RBAC)
- Resource ownership validation
- Principle of least privilege

### Mobil Uygulama Güvenliği

**Code Obfuscation:**
- Flutter build with obfuscation enabled
- ProGuard rules for Android
- Symbol stripping for iOS

**Secure Storage:**
- flutter_secure_storage for tokens
- Encrypted shared preferences
- Keychain (iOS) / Keystore (Android)

**Root/Jailbreak Detection:**
- Device integrity checks
- SafetyNet (Android)
- DeviceCheck (iOS)

## Deployment ve DevOps

### CI/CD Pipeline

**Build Pipeline:**
1. Code checkout
2. Dependency installation
3. Linting (dart analyze)
4. Unit tests
5. Widget tests
6. Integration tests
7. Build APK/IPA
8. Code signing
9. Upload to distribution

**Tools:**
- GitHub Actions / GitLab CI
- Fastlane (mobile deployment)
- Firebase App Distribution (beta testing)
- Google Play Console / App Store Connect

### Ortamlar

**Development:**
- Local development
- Mock services
- Test database

**Staging:**
- Pre-production environment
- Real services (test mode)
- Staging database

**Production:**
- Live environment
- Production services
- Production database
- High availability setup

### Monitoring ve Logging

**Application Monitoring:**
- Firebase Crashlytics (crash reporting)
- Firebase Performance Monitoring
- Custom analytics events

**Backend Monitoring:**
- Server health checks
- Database performance monitoring
- API response time tracking
- Error rate monitoring

**Logging:**
- Structured logging (JSON format)
- Log levels (DEBUG, INFO, WARN, ERROR)
- Centralized log aggregation
- Log retention policies

### Backup ve Disaster Recovery

**Database Backups:**
- Daily automated backups
- Point-in-time recovery
- Backup retention: 30 days
- Backup testing monthly

**Disaster Recovery Plan:**
- RTO (Recovery Time Objective): 4 hours
- RPO (Recovery Point Objective): 1 hour
- Failover procedures
- Regular DR drills

## Performans Optimizasyonu

### Mobile App Optimizations

**Image Optimization:**
- Lazy loading
- Image caching (cached_network_image)
- Thumbnail generation
- WebP format support

**List Performance:**
- ListView.builder for long lists
- Pagination (20 items per page)
- Pull-to-refresh
- Infinite scroll

**State Management:**
- BLoC pattern for efficient rebuilds
- Selective widget rebuilding
- Memoization for expensive computations

**Network Optimization:**
- Request batching
- Response caching
- Compression (gzip)
- Connection pooling

### Backend Optimizations

**Database:**
- Proper indexing
- Query optimization
- Connection pooling
- Read replicas for scaling

**Caching:**
- Redis for session storage
- API response caching
- Database query caching
- CDN for static assets

**API Design:**
- GraphQL for flexible queries (optional)
- Pagination for large datasets
- Field filtering
- Batch endpoints

## Yerelleştirme (Localization)

### Dil Desteği

**Mevcut:**
- Azerbaycan Türkçesi (az_AZ)

**Gelecek:**
- Rusça (ru_RU)
- İngilizce (en_US)

### Localization Implementation

```dart
// Using flutter_localizations
class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  String get appTitle => 'İş Pazarı';
  String get login => 'Giriş';
  String get register => 'Qeydiyyat';
  // ... more translations
}

// ARB files for translations
// app_az.arb
{
  "appTitle": "İş Pazarı",
  "login": "Giriş",
  "register": "Qeydiyyat"
}
```

### Kültürel Uyarlama

**Tarih ve Saat:**
- Format: GG.AA.YYYY
- Timezone: Asia/Baku (UTC+4)

**Para Birimi:**
- Symbol: ₼ veya AZN
- Format: 1.234,56 ₼

**Telefon Numarası:**
- Format: +994 XX XXX XX XX
- Validation: +994 ile başlamalı

**Adres:**
- Azerbaycan şehir ve bölge listesi
- Posta kodu formatı

## Sonuç

Bu tasarım belgesi, Azerbaycan İş Pazarı Mobil Uygulaması için kapsamlı bir teknik plan sunmaktadır. Flutter/Dart kullanılarak cross-platform bir çözüm geliştirilecek, clean architecture prensipleri ile sürdürülebilir ve ölçeklenebilir bir yapı oluşturulacaktır. Özellik tabanlı testler ile yazılım doğruluğu garanti altına alınacak, güvenlik önlemleri ile kullanıcı verileri korunacaktır.
