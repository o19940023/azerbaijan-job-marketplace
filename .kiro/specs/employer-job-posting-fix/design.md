# İşveren İş İlanı Sistemi Bugfix Design

## Overview

İş ilanı sistemi şu anda kalıcı veri saklama olmadan çalışıyor ve tüm ilanlar MockData'dan geliyor. İşverenler ilan oluşturduğunda veriler kaybolup gidiyor. Bu bug, iş ilanı oluşturma, saklama ve görüntüleme akışının tamamen işlevsiz olmasına neden oluyor.

Fix stratejisi: Hive local storage entegrasyonu ile kalıcı veri saklama implementasyonu. Clean Architecture prensiplerine uygun olarak data layer, domain layer ve presentation layer'da gerekli değişiklikler yapılacak. MockData.jobs'daki mevcut veriler Hive'a migrate edilecek ve yeni oluşturulan ilanlar Hive'da saklanacak.

## Glossary

- **Bug_Condition (C)**: İş ilanı CRUD operasyonlarının (Create, Read, Update, Delete) kalıcı storage olmadan çalıştığı durum
- **Property (P)**: İş ilanı CRUD operasyonlarının Hive local storage ile kalıcı olarak çalışması
- **Preservation**: Mevcut UI fonksiyonalitesi (filtreleme, detay görüntüleme, başvuru, harita) ve MockData.jobs'daki verilerin korunması
- **JobPosting**: İş ilanı entity'si - başlık, açıklama, şirket, konum, maaş gibi bilgileri içerir
- **Hive**: Flutter için NoSQL local database - key-value storage
- **TypeAdapter**: Hive'ın custom object'leri serialize/deserialize etmek için kullandığı adapter
- **JobLocalDataSource**: Hive ile CRUD operasyonlarını gerçekleştiren data source sınıfı
- **JobRepository**: Domain layer'ın data layer'a erişim için kullandığı interface
- **employerId**: İşverenin unique identifier'ı - ilanları filtrelemek için kullanılır

## Bug Details

### Fault Condition

Bug, iş ilanı CRUD operasyonlarının herhangi birinde kalıcı storage kullanılmadığında ortaya çıkıyor. CreateJobScreen'de ilan oluşturulduğunda, EmployerHome'da ilanlar görüntülendiğinde, veya ilan güncellenip silindiğinde veriler memory'de kalıyor ve uygulama yeniden başlatıldığında kaybolup gidiyor.

**Formal Specification:**
```
FUNCTION isBugCondition(operation)
  INPUT: operation of type JobOperation (CREATE, READ, UPDATE, DELETE)
  OUTPUT: boolean
  
  RETURN operation IN [CREATE, READ, UPDATE, DELETE]
         AND NOT usesHiveStorage(operation)
         AND (operation == CREATE AND dataNotPersisted())
         OR (operation == READ AND onlyMockDataReturned())
         OR (operation == UPDATE AND changesNotSaved())
         OR (operation == DELETE AND dataNotRemoved())
END FUNCTION
```

### Examples

- **Create Bug**: İşveren "Software Developer" ilanı oluşturur → Kaydet butonuna basar → İlan memory'de kaybolur → EmployerHome'da görünmez
- **Read Bug**: İşveren EmployerHome'u açar → Sadece MockData.jobs'dan gelen sahte ilanlar görünür → Kendi oluşturduğu ilanlar görünmez
- **Update Bug**: İşveren mevcut ilanın maaş bilgisini günceller → Değişiklikler kaydedilmez → Uygulama yeniden başlatıldığında eski veri görünür
- **Delete Bug**: İşveren ilanını siler → İlan UI'dan kalkıyor gibi görünür → Uygulama yeniden başlatıldığında ilan tekrar görünür
- **Persistence Bug**: Uygulama kapatılıp açıldığında → Tüm oluşturulan ilanlar kaybolmuş → Sadece MockData.jobs kalıyor

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- İş ilanı detay görüntüleme (JobDetailScreen) aynı şekilde çalışmalı
- İş ilanı filtreleme (kategori, şehir, mesafe) mantığı değişmemeli
- İş başvuru sistemi aynı şekilde çalışmalı
- Harita üzerinde ilan görüntüleme fonksiyonalitesi korunmalı
- MockData.jobs'daki mevcut sahte ilanlar kaybolmamalı (Hive'a migrate edilmeli)

**Scope:**
İş ilanı CRUD operasyonları dışındaki tüm fonksiyonalite tamamen değişmeden kalmalıdır. Bu şunları içerir:
- İş arayan tarafındaki tüm görüntüleme ve filtreleme işlemleri
- Başvuru sistemi ve başvuru takibi
- Harita entegrasyonu ve konum bazlı arama
- UI/UX ve navigation akışı
- Authentication ve user management

## Hypothesized Root Cause

Bug description ve teknik çözüm önerisine dayanarak, en olası nedenler:

1. **Missing Data Layer**: Şu anda hiçbir local storage implementasyonu yok
   - JobLocalDataSource sınıfı mevcut değil
   - Hive setup ve initialization yapılmamış
   - JobPosting için TypeAdapter oluşturulmamış

2. **Repository Implementation Eksikliği**: Domain layer ile data layer arasında bağlantı yok
   - JobRepositoryImpl sınıfı local storage kullanmıyor
   - CRUD methods sadece mock data döndürüyor veya hiç implement edilmemiş

3. **Use Case Implementation Eksikliği**: Business logic layer'da kalıcı storage kullanımı yok
   - CreateJob, GetEmployerJobs, UpdateJob, DeleteJob use case'leri eksik veya yanlış implement edilmiş
   - Use case'ler repository'yi çağırmıyor veya yanlış çağırıyor

4. **Presentation Layer Integration Eksikliği**: UI katmanı local storage ile entegre değil
   - CreateJobScreen kaydet butonunda use case çağrılmıyor
   - EmployerHome ve JobSeekerHome sadece MockData.jobs kullanıyor
   - State management (Bloc/Cubit) local storage ile senkronize değil

## Correctness Properties

Property 1: Fault Condition - İş İlanı CRUD Operasyonları Kalıcı Storage Kullanmalı

_For any_ iş ilanı CRUD operasyonu (CREATE, READ, UPDATE, DELETE) gerçekleştirildiğinde, fixed implementation Hive local storage kullanarak veriyi kalıcı olarak saklamalı, okumalı, güncellemeli veya silmelidir. Uygulama yeniden başlatıldığında veriler korunmalı ve erişilebilir olmalıdır.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6**

Property 2: Preservation - İlan Dışı Fonksiyonalite Korunmalı

_For any_ iş ilanı CRUD operasyonu dışındaki işlem (detay görüntüleme, filtreleme, başvuru, harita görüntüleme), fixed code orijinal kod ile tamamen aynı davranışı üretmelidir. MockData.jobs'daki mevcut veriler kaybolmamalı ve Hive'a migrate edilmelidir.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**

## Fix Implementation

### Changes Required

Root cause analizimiz doğruysa, aşağıdaki değişiklikler gereklidir:

**1. Hive Setup ve Initialization**

**File**: `lib/main.dart`

**Specific Changes**:
- Hive.initFlutter() çağrısı ekle (main fonksiyonunda)
- JobPostingAdapter'ı register et
- Jobs box'ını aç ve initialize et
- MockData.jobs'u Hive'a migrate et (ilk çalıştırmada)

**2. Data Layer - TypeAdapter**

**File**: `lib/features/jobs/data/models/job_model.dart`

**Specific Changes**:
- JobPosting için HiveObject extend et
- @HiveType ve @HiveField annotation'ları ekle
- TypeAdapter generate et (build_runner ile)
- toEntity() ve fromEntity() method'ları implement et

**3. Data Layer - Local DataSource**

**File**: `lib/features/jobs/data/datasources/job_local_datasource.dart`

**Specific Changes**:
- JobLocalDataSource abstract class oluştur
- JobLocalDataSourceImpl implement et
- CRUD methods: createJob(), getJobs(), getJobById(), updateJob(), deleteJob()
- Hive box operations ile implement et

**4. Data Layer - Repository Implementation**

**File**: `lib/features/jobs/data/repositories/job_repository_impl.dart`

**Specific Changes**:
- JobRepositoryImpl'i güncelle veya oluştur
- JobLocalDataSource'u inject et
- CRUD methods'u local datasource'a delegate et
- Error handling ekle

**5. Domain Layer - Use Cases**

**Files**: 
- `lib/features/jobs/domain/usecases/create_job.dart`
- `lib/features/jobs/domain/usecases/get_employer_jobs.dart`
- `lib/features/jobs/domain/usecases/get_all_jobs.dart`
- `lib/features/jobs/domain/usecases/update_job.dart`
- `lib/features/jobs/domain/usecases/delete_job.dart`

**Specific Changes**:
- Her use case için class oluştur
- Repository'yi inject et
- call() method'u implement et
- Business logic ekle (örn: employerId filtreleme)

**6. Presentation Layer - State Management**

**File**: `lib/features/jobs/presentation/bloc/job_bloc.dart` veya `job_cubit.dart`

**Specific Changes**:
- JobBloc/Cubit oluştur veya güncelle
- Use case'leri inject et
- Events/Methods: CreateJobEvent, LoadEmployerJobsEvent, LoadAllJobsEvent, UpdateJobEvent, DeleteJobEvent
- States: JobInitial, JobLoading, JobLoaded, JobError
- Event handler'ları use case'leri çağıracak şekilde implement et

**7. Presentation Layer - UI Integration**

**File**: `lib/features/jobs/presentation/pages/create_job_screen.dart`

**Specific Changes**:
- BlocProvider ekle
- Kaydet butonunda CreateJobEvent dispatch et
- BlocListener ile success/error handling
- Loading state göster

**File**: `lib/features/jobs/presentation/pages/employer_home.dart`

**Specific Changes**:
- BlocProvider ekle
- initState'de LoadEmployerJobsEvent dispatch et
- BlocBuilder ile job listesini render et
- Pull-to-refresh ekle

**File**: `lib/features/jobs/presentation/pages/job_seeker_home.dart`

**Specific Changes**:
- BlocProvider ekle
- initState'de LoadAllJobsEvent dispatch et
- BlocBuilder ile job listesini render et
- Filtreleme mantığını koru

## Testing Strategy

### Validation Approach

Testing stratejisi iki aşamalı: önce unfixed code'da bug'ı göster (exploratory), sonra fixed code'da düzgün çalıştığını ve mevcut fonksiyonaliteyi bozmadığını doğrula (fix checking + preservation checking).

### Exploratory Fault Condition Checking

**Goal**: Fix implement edilmeden ÖNCE bug'ı göster. Root cause analizini doğrula veya çürüt. Çürütürsek, yeniden hipotez kurmamız gerekir.

**Test Plan**: CRUD operasyonlarını simulate eden testler yaz. Unfixed code'da çalıştır ve failure'ları gözlemle. Hive storage kullanılmadığını doğrula.

**Test Cases**:
1. **Create Job Test**: İlan oluştur → Hive'da kayıtlı olup olmadığını kontrol et (unfixed code'da fail edecek)
2. **Read Employer Jobs Test**: employerId ile ilanları oku → Sadece mock data dönüyor mu kontrol et (unfixed code'da fail edecek)
3. **Update Job Test**: İlan güncelle → Hive'da güncellenmiş mi kontrol et (unfixed code'da fail edecek)
4. **Delete Job Test**: İlan sil → Hive'dan silinmiş mi kontrol et (unfixed code'da fail edecek)
5. **Persistence Test**: Uygulama restart → Veriler korunmuş mu kontrol et (unfixed code'da fail edecek)

**Expected Counterexamples**:
- createJob() çağrıldığında veri Hive'a yazılmıyor
- getEmployerJobs() sadece MockData.jobs döndürüyor
- updateJob() ve deleteJob() Hive'ı güncellememiyor
- Possible causes: Hive setup yok, TypeAdapter yok, repository implementation eksik

### Fix Checking

**Goal**: Bug condition'ın olduğu tüm inputlar için fixed function'ın expected behavior'ı ürettiğini doğrula.

**Pseudocode:**
```
FOR ALL operation WHERE isBugCondition(operation) DO
  result := performJobOperation_fixed(operation)
  ASSERT usesHiveStorage(result)
  ASSERT dataPersisted(result)
END FOR
```

**Test Cases**:
- Create job → Hive'da kayıtlı olmalı
- Read jobs → Hive'dan okunmalı (mock + real data)
- Update job → Hive'da güncellenmiş olmalı
- Delete job → Hive'dan silinmiş olmalı
- App restart → Veriler korunmuş olmalı

### Preservation Checking

**Goal**: Bug condition'ın OLMADĞI tüm inputlar için fixed function'ın original function ile aynı sonucu ürettiğini doğrula.

**Pseudocode:**
```
FOR ALL operation WHERE NOT isBugCondition(operation) DO
  ASSERT originalBehavior(operation) = fixedBehavior(operation)
END FOR
```

**Testing Approach**: Property-based testing preservation checking için önerilir çünkü:
- Input domain'de otomatik olarak çok sayıda test case üretir
- Manuel unit test'lerin kaçırabileceği edge case'leri yakalar
- Non-buggy inputlar için behavior'ın değişmediğine dair güçlü garantiler sağlar

**Test Plan**: Önce unfixed code'da non-CRUD operasyonların davranışını gözlemle, sonra bu davranışı capture eden property-based testler yaz.

**Test Cases**:
1. **Job Detail Preservation**: İlan detay görüntüleme → Aynı şekilde çalışmalı
2. **Filtering Preservation**: Kategori/şehir/mesafe filtreleme → Aynı mantık çalışmalı
3. **Application Preservation**: İlana başvuru → Aynı sistem çalışmalı
4. **Map Preservation**: Harita görüntüleme → Aynı fonksiyonalite çalışmalı
5. **MockData Preservation**: MockData.jobs → Hive'a migrate edilmiş ve erişilebilir olmalı

### Unit Tests

- JobLocalDataSource CRUD operasyonlarını test et
- JobRepositoryImpl'in datasource'u doğru çağırdığını test et
- Her use case'in repository'yi doğru çağırdığını test et
- Bloc/Cubit'in use case'leri doğru çağırdığını ve state'i doğru güncellediğini test et
- Edge cases: boş liste, null değerler, invalid employerId

### Property-Based Tests

- Random JobPosting entity'leri generate et → Create → Read → Verify equality
- Random employerId'ler generate et → Filter jobs → Verify correct filtering
- Random update operations generate et → Update → Read → Verify changes persisted
- Random delete operations generate et → Delete → Read → Verify not exists
- Preservation: Random non-CRUD operations → Verify behavior unchanged

### Integration Tests

- Full flow: Create job → Navigate to EmployerHome → Verify job appears
- Full flow: Create job → Restart app → Verify job still exists
- Full flow: Create job → Update → Delete → Verify all operations work
- Full flow: Job seeker views all jobs → Verify both mock and real jobs appear
- Full flow: Filter jobs by category → Verify filtering works with Hive data
- Migration flow: First app launch → MockData.jobs migrated to Hive → Verify all data present
