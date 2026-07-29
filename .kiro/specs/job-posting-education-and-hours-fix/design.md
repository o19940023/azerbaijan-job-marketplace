# İş İlanı Təhsil və İş Saatı Düzəlişi - Bugfix Design

## Overview

İş ilanı sistemində iki kritik kullanıcı deneyimi sorunu tespit edilmiştir. İlk bug, iş verenlerin seçtiği eğitim seviyesi bilgisinin iş arayanlara gösterilmemesidir - veri veritabanına kaydediliyor ancak UI'da görüntülenmiyor. İkinci bug, iş saati girişinin manuel text input ile yapılmasıdır, bu da kullanıcı deneyimini kötüleştiriyor ve format tutarsızlıklarına yol açıyor. Bu düzeltme, eğitim bilgisinin job detail ekranında görüntülenmesini ve iş saati girişinin iOS/Android native time picker veya Cupertino-style picker ile yapılmasını sağlayacaktır.

## Glossary

- **Bug_Condition_1 (C1)**: Eğitim seviyesi bilgisinin iş arayan tarafından görüntülenememesi durumu - `educationLevel` alanı veritabanında mevcut ancak `job_detail_screen.dart` içindeki "Detallar" bölümünde gösterilmiyor
- **Bug_Condition_2 (C2)**: İş saati girişinin manuel text input ile yapılması durumu - `_workingHoursController` bir `TextFormField` ile bağlı ve kullanıcı "09:00 - 18:00" formatını manuel yazıyor
- **Property_1 (P1)**: Eğitim seviyesi bilgisinin job detail ekranında görüntülenmesi - `_DetailRow` widget'ı ile "Təhsil" etiketi altında gösterilmeli
- **Property_2 (P2)**: İş saati girişinin time picker ile yapılması - başlangıç ve bitiş saatleri için ayrı picker'lar açılmalı ve format otomatik olarak "HH:mm - HH:mm" şeklinde oluşturulmalı
- **Preservation**: Mevcut ilan oluşturma, düzenleme, görüntüleme ve filtreleme akışlarının değişmeden korunması
- **educationLevel**: `JobModel` içindeki nullable String alan - "Ali", "Orta", "Vacib deyil" gibi değerler alır
- **workingHours**: `JobModel` içindeki nullable String alan - "09:00 - 18:00" formatında iş saati aralığını saklar
- **_DetailRow**: `job_detail_screen.dart` içindeki widget - iş detaylarını icon, label ve value ile gösterir
- **showTimePicker**: Flutter'ın native time picker dialog'u - iOS'ta Cupertino, Android'de Material Design picker gösterir

## Bug Details

### Bug Condition 1: Eğitim Seviyesi Görünmüyor

İş veren ilan oluştururken `create_job_screen.dart` içinde eğitim seviyesini seçiyor (dropdown ile "Ali", "Orta", "Vacib deyil" vb.). Bu değer `_selectedEducation` state değişkeninde tutuluyor ve `JobModel.educationLevel` alanına kaydediliyor. Ancak iş arayan `job_detail_screen.dart` ekranında ilan detaylarını görüntülediğinde, "Detallar" bölümünde `educationLevel` için bir `_DetailRow` widget'ı bulunmuyor. Sonuç olarak, iş arayan eğitim gereksinimini göremediği için hangi işlere başvurabileceğini bilemiyor.

**Formal Specification:**
```
FUNCTION isBugCondition1(input)
  INPUT: input of type JobDetailScreenView
  OUTPUT: boolean
  
  RETURN input.job.educationLevel IS NOT NULL
         AND input.job.educationLevel != ""
         AND NOT displayedInDetailsSection(input.job.educationLevel)
END FUNCTION
```

### Bug Condition 2: İş Saati Manuel Giriliyor

İş veren ilan oluştururken `create_job_screen.dart` içinde iş saati bilgisini girmek için bir `TextFormField` görüyor (hint: "məs. 09:00 - 18:00"). Kullanıcı bu alana manuel olarak yazıyor, bu da format hatalarına açık (örn: "9-18", "09.00-18.00", "9:00-6:00 PM"). Mobil cihazda klavye açılıyor ve kullanıcı deneyimi kötü. Modern mobil uygulamalarda (özellikle iOS) kaydırmalı time picker kullanılması bekleniyor.

**Formal Specification:**
```
FUNCTION isBugCondition2(input)
  INPUT: input of type CreateJobScreenView
  OUTPUT: boolean
  
  RETURN input.workingHoursInputType == "TextFormField"
         AND input.requiresManualTyping == true
         AND NOT usesTimePicker(input.workingHoursInput)
END FUNCTION
```

### Examples

**Bug 1 Örnekleri:**
- İş veren "Ali" eğitim seviyesi seçer → Veritabanına kaydedilir → İş arayan ilan detayında "Təhsil: Ali" görmez (BUG)
- İş veren "Orta xüsusi" seçer → Veritabanına kaydedilir → İş arayan ilan detayında eğitim bilgisi görünmez (BUG)
- İş veren "Vacib deyil" seçer → Veritabanına kaydedilir → İş arayan ilan detayında bu bilgi görünmez (BUG)
- İş veren eğitim seviyesi seçmez (null) → İş arayan ilan detayında "Təhsil: Vacib deyil" görmeli (EXPECTED)

**Bug 2 Örnekleri:**
- İş veren iş saati girmek ister → TextFormField görür → "09:00 - 18:00" manuel yazar (BUG - time picker olmalı)
- İş veren "9-18" yazar → Format tutarsız (BUG - picker ile önlenebilir)
- İş veren "09.00-18.00" yazar → Format tutarsız (BUG - picker ile önlenebilir)
- İş veren time picker ile başlangıç saati seçer (09:00) → Bitiş saati seçer (18:00) → Sistem otomatik "09:00 - 18:00" oluşturur (EXPECTED)

## Expected Behavior

### Bug 1: Eğitim Seviyesi Görüntülenmeli

İş arayan `job_detail_screen.dart` ekranında ilan detaylarını görüntülediğinde, "Detallar" bölümünde eğitim seviyesi bilgisi görüntülenmelidir. Bu bilgi, `_DetailRow` widget'ı kullanılarak şu şekilde gösterilmelidir:

```dart
if (currentJob.educationLevel != null && currentJob.educationLevel!.isNotEmpty)
  _DetailRow(
    icon: Icons.school_rounded,
    label: 'Təhsil',
    value: currentJob.educationLevel!,
  ),
```

Eğer `educationLevel` null veya boş ise, "Vacib deyil" olarak gösterilmelidir:

```dart
_DetailRow(
  icon: Icons.school_rounded,
  label: 'Təhsil',
  value: currentJob.educationLevel ?? 'Vacib deyil',
),
```

### Bug 2: İş Saati Picker ile Seçilmeli

İş veren `create_job_screen.dart` ekranında iş saati bilgisini girmek istediğinde, manuel text input yerine time picker kullanmalıdır. İki ayrı picker açılmalı:
1. Başlangıç saati için picker
2. Bitiş saati için picker

Seçilen saatler otomatik olarak "HH:mm - HH:mm" formatında birleştirilmeli ve `_workingHoursController`'a yazılmalıdır. UI'da kullanıcı seçilen saatleri görmeli ve değiştirmek için tekrar picker açabilmelidir.

### Preservation Requirements

**Unchanged Behaviors:**
- İş veren diğer ilan bilgilerini girer (başlık, kategori, maaş, lokasyon, vb.) - bu alanlar şu anki gibi çalışmaya devam eder
- İş veren ilan düzenler - mevcut eğitim ve iş saati bilgileri doğru şekilde yüklenir
- İş veren ilanı kaydeder - tüm diğer alanlar (kategori, maaş, lokasyon, vb.) şu anki gibi kaydedilir
- İş arayan ilan detayını görüntüler - mevcut tüm bilgiler (şirket adı, şehir, maaş, vb.) şu anki gibi görüntülenir
- İş arayan iş saati bilgisini görür - format "09:00 - 18:00" şeklinde gösterilmeye devam eder (sadece giriş yöntemi değişir)
- Veritabanı yapısı - `educationLevel` ve `workingHours` alanları String olarak saklanmaya devam eder
- Filtreleme ve arama - eğitim seviyesine göre filtreleme şu anki gibi çalışır

**Scope:**
Sadece iki değişiklik yapılacak:
1. `job_detail_screen.dart` içindeki "Detallar" bölümüne `educationLevel` için `_DetailRow` eklenmesi
2. `create_job_screen.dart` içindeki iş saati girişinin TextFormField'dan time picker'a dönüştürülmesi

Diğer tüm ekranlar, widget'lar ve iş mantığı değişmeden kalacak.

## Hypothesized Root Cause

### Bug 1: Eğitim Seviyesi Görünmüyor

**Root Cause**: `job_detail_screen.dart` dosyasının 600-650. satırları arasındaki "Detallar" bölümünde `educationLevel` için bir `_DetailRow` widget'ı eklenmemiş. Kod incelendiğinde şu satırlar görülüyor:

```dart
_SectionCard(
  title: 'Detallar',
  child: Column(
    children: [
      _DetailRow(icon: Icons.business_rounded, label: 'Şirkət', value: currentJob.companyName),
      _DetailRow(icon: Icons.location_city_rounded, label: 'Şəhər', value: currentJob.city),
      if (currentJob.district != null && currentJob.district!.isNotEmpty)
        _DetailRow(icon: Icons.map_rounded, label: 'Rayon', value: currentJob.district!),
      if (currentJob.address != null && currentJob.address!.isNotEmpty)
        _DetailRow(icon: Icons.pin_drop_rounded, label: 'Ünvan', value: currentJob.address!),
      if (currentJob.workingHours != null)
        _DetailRow(icon: Icons.schedule_rounded, label: 'İş saatı', value: currentJob.workingHours!),
      _DetailRow(icon: Icons.calendar_today_rounded, label: 'Tarix', value: currentJob.timeAgo),
    ],
  ),
),
```

`educationLevel` için bir satır yok. Oysa `JobModel` içinde `educationLevel` alanı mevcut ve `create_job_screen.dart` içinde kaydediliyor.

**Hypothesis**: Geliştirici `educationLevel` alanını `JobModel`'e eklemiş ve create ekranında dropdown ile seçim yapılmasını sağlamış, ancak detail ekranında bu bilgiyi göstermeyi unutmuş. Bu bir "unutma" hatası (oversight).

### Bug 2: İş Saati Manuel Giriliyor

**Root Cause**: `create_job_screen.dart` dosyasının 860-870. satırları arasında iş saati girişi için bir `TextFormField` kullanılıyor:

```dart
_buildLabel('İş saatı'),
TextFormField(
  controller: _workingHoursController,
  decoration: const InputDecoration(
    hintText: 'məs. 09:00 - 18:00',
  ),
),
```

Bu, kullanıcının manuel olarak yazmasını gerektiriyor. Modern mobil uygulamalarda (özellikle iOS) time picker kullanılması bekleniyor.

**Hypothesis**: Geliştirici başlangıçta hızlı bir çözüm olarak TextFormField kullanmış, ancak kullanıcı deneyimini iyileştirmek için time picker'a geçmeyi planlamış olabilir. Bu bir "teknik borç" (technical debt) durumu.

## Correctness Properties

Property 1: Bug Condition 1 - Eğitim Seviyesi Görüntülenmesi

_For any_ job detail view where the job has a non-null and non-empty educationLevel field, the fixed job_detail_screen SHALL display the education level in the "Detallar" section using a _DetailRow widget with the label "Təhsil" and the value from educationLevel field. If educationLevel is null or empty, it SHALL display "Vacib deyil".

**Validates: Requirements 2.1, 2.2, 2.3**

Property 2: Bug Condition 2 - İş Saati Picker ile Seçilmesi

_For any_ job creation or edit view where the employer wants to enter working hours, the fixed create_job_screen SHALL display time picker dialogs (one for start time, one for end time) instead of a manual text input field, and SHALL automatically format the selected times as "HH:mm - HH:mm" and store them in the workingHours field.

**Validates: Requirements 2.4, 2.5, 2.6, 2.7, 2.8**

Property 3: Preservation - Mevcut İlan Akışları

_For any_ job creation, editing, viewing, or filtering operation that does NOT involve the educationLevel display or workingHours input, the fixed code SHALL produce exactly the same behavior as the original code, preserving all existing functionality for other job fields (title, category, salary, location, benefits, requirements, etc.).

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File 1**: `lib/features/jobs/presentation/pages/job_detail_screen.dart`

**Function**: `build` method of `_JobDetailScreenState` class (around line 600-650)

**Specific Changes**:
1. **Add Education Level Display**: "Detallar" bölümündeki `_SectionCard` içine, `_DetailRow` widget'larının arasına eğitim seviyesi için yeni bir satır ekle:
   - Icon: `Icons.school_rounded`
   - Label: `'Təhsil'`
   - Value: `currentJob.educationLevel ?? 'Vacib deyil'`
   - Konum: `experienceLevel` satırından sonra (eğer varsa) veya `workingHours` satırından önce

2. **Conditional Display**: Eğitim seviyesi her zaman gösterilmeli (null ise "Vacib deyil" olarak), bu yüzden `if` koşulu gerekmez

**File 2**: `lib/features/jobs/presentation/pages/create_job_screen.dart`

**Function**: `build` method of `_CreateJobScreenState` class (around line 860-870)

**Specific Changes**:
1. **Remove TextFormField**: İş saati için olan `TextFormField` widget'ını kaldır

2. **Add Time Picker UI**: Yerine iki buton ekle:
   - Başlangıç saati butonu: Tıklandığında `showTimePicker` açar, seçilen saati state'e kaydeder
   - Bitiş saati butonu: Tıklandığında `showTimePicker` açar, seçilen saati state'e kaydeder

3. **Add State Variables**: İki yeni state değişkeni ekle:
   - `TimeOfDay? _startTime`
   - `TimeOfDay? _endTime`

4. **Add Helper Method**: Seçilen saatleri "HH:mm - HH:mm" formatına çeviren ve `_workingHoursController`'a yazan bir method ekle:
   ```dart
   void _updateWorkingHours() {
     if (_startTime != null && _endTime != null) {
       final start = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
       final end = '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';
       _workingHoursController.text = '$start - $end';
     }
   }
   ```

5. **Add Time Picker Method**: `showTimePicker` dialog'unu açan bir method ekle:
   ```dart
   Future<void> _pickTime(bool isStartTime) async {
     final picked = await showTimePicker(
       context: context,
       initialTime: isStartTime 
         ? (_startTime ?? TimeOfDay(hour: 9, minute: 0))
         : (_endTime ?? TimeOfDay(hour: 18, minute: 0)),
     );
     if (picked != null) {
       setState(() {
         if (isStartTime) {
           _startTime = picked;
         } else {
           _endTime = picked;
         }
         _updateWorkingHours();
       });
     }
   }
   ```

6. **Initialize from Existing Job**: `initState` içinde, eğer `widget.existingJob` varsa ve `workingHours` doluysa, bu değeri parse edip `_startTime` ve `_endTime`'a yükle:
   ```dart
   if (job.workingHours != null && job.workingHours!.contains(' - ')) {
     final parts = job.workingHours!.split(' - ');
     if (parts.length == 2) {
       // Parse "09:00" to TimeOfDay
       final startParts = parts[0].split(':');
       final endParts = parts[1].split(':');
       if (startParts.length == 2 && endParts.length == 2) {
         _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
         _endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
       }
     }
   }
   ```

## Testing Strategy

### Validation Approach

Testing stratejisi iki aşamalı bir yaklaşım izler: önce bug'ları göstermek için düzeltme öncesi testler yazılır, sonra düzeltmenin doğru çalıştığını ve mevcut davranışları koruduğunu doğrulamak için testler çalıştırılır.

### Exploratory Bug Condition Checking

**Goal**: Düzeltme yapılmadan ÖNCE bug'ları göstermek. Root cause analizini doğrulamak veya reddetmek. Eğer reddedersek, yeniden hipotez kurmamız gerekir.

**Test Plan**: Widget testleri yazarak `job_detail_screen.dart` ve `create_job_screen.dart` ekranlarını test et. Düzeltme yapılmamış kodda testleri çalıştır ve hataları gözlemle.

**Test Cases**:
1. **Education Level Not Displayed Test**: `job_detail_screen.dart` için widget testi yaz. `educationLevel = "Ali"` olan bir `JobModel` oluştur. Ekranı render et. "Təhsil" label'ını ara. Test başarısız olmalı (düzeltme öncesi kod'da bu label yok).

2. **Working Hours Manual Input Test**: `create_job_screen.dart` için widget testi yaz. İş saati alanını bul. `TextFormField` olduğunu doğrula. Test başarılı olmalı (düzeltme öncesi kod'da TextFormField var). Ancak bu, bug'ın varlığını gösterir.

3. **Education Level Null Display Test**: `job_detail_screen.dart` için widget testi yaz. `educationLevel = null` olan bir `JobModel` oluştur. Ekranı render et. "Təhsil: Vacib deyil" text'ini ara. Test başarısız olmalı (düzeltme öncesi kod'da eğitim seviyesi hiç gösterilmiyor).

4. **Time Picker Absence Test**: `create_job_screen.dart` için widget testi yaz. İş saati alanını bul. `showTimePicker` çağrısı yapılıp yapılmadığını kontrol et. Test başarısız olmalı (düzeltme öncesi kod'da time picker yok).

**Expected Counterexamples**:
- `job_detail_screen.dart` içinde "Təhsil" label'ı bulunamaz
- `create_job_screen.dart` içinde iş saati girişi `TextFormField` olarak bulunur
- Time picker dialog'u açılmaz

### Fix Checking

**Goal**: Düzeltme yapıldıktan sonra, bug koşullarının karşılandığı tüm girdiler için düzeltilmiş fonksiyonun beklenen davranışı ürettiğini doğrulamak.

**Pseudocode:**
```
FOR ALL jobDetailView WHERE isBugCondition1(jobDetailView) DO
  result := renderJobDetailScreen_fixed(jobDetailView)
  ASSERT result.contains("Təhsil")
  ASSERT result.educationLevelValue == jobDetailView.job.educationLevel OR "Vacib deyil"
END FOR

FOR ALL createJobView WHERE isBugCondition2(createJobView) DO
  result := renderCreateJobScreen_fixed(createJobView)
  ASSERT result.workingHoursInputType == "TimePicker"
  ASSERT result.usesTimePicker == true
  ASSERT result.workingHoursFormat == "HH:mm - HH:mm"
END FOR
```

### Preservation Checking

**Goal**: Bug koşullarının karşılanmadığı tüm girdiler için, düzeltilmiş fonksiyonun orijinal fonksiyonla aynı sonucu ürettiğini doğrulamak.

**Pseudocode:**
```
FOR ALL jobOperation WHERE NOT (isBugCondition1(jobOperation) OR isBugCondition2(jobOperation)) DO
  ASSERT originalJobFlow(jobOperation) = fixedJobFlow(jobOperation)
END FOR
```

**Testing Approach**: Property-based testing, preservation checking için önerilir çünkü:
- Otomatik olarak birçok test case'i üretir
- Manuel unit testlerin kaçırabileceği edge case'leri yakalar
- Tüm bug olmayan girdiler için davranışın değişmediğine dair güçlü garantiler sağlar

**Test Plan**: Düzeltme öncesi kod'da diğer alanların (başlık, kategori, maaş, lokasyon, vb.) davranışını gözlemle, sonra bu davranışı yakalayan property-based testler yaz.

**Test Cases**:
1. **Job Title Preservation**: İş başlığı girişinin ve görüntülenmesinin düzeltme sonrası aynı çalıştığını doğrula
2. **Salary Input Preservation**: Maaş girişinin düzeltme sonrası aynı çalıştığını doğrula
3. **Location Selection Preservation**: Lokasyon seçiminin düzeltme sonrası aynı çalıştığını doğrula
4. **Benefits Selection Preservation**: Yan haklar seçiminin düzeltme sonrası aynı çalıştığını doğrula
5. **Job Type Selection Preservation**: İş türü seçiminin düzeltme sonrası aynı çalıştığını doğrula
6. **Job Detail Display Preservation**: Diğer detayların (şirket adı, şehir, maaş, vb.) görüntülenmesinin düzeltme sonrası aynı olduğunu doğrula

### Unit Tests

- `job_detail_screen.dart` için widget testleri: Eğitim seviyesi gösterimini test et (null, "Ali", "Orta", "Vacib deyil" değerleri için)
- `create_job_screen.dart` için widget testleri: Time picker açılmasını test et, seçilen saatlerin doğru formatlanmasını test et
- Edge case testleri: Eğitim seviyesi boş string, iş saati sadece başlangıç saati seçilmiş (bitiş saati yok)
- Format testleri: Seçilen saatlerin "HH:mm - HH:mm" formatında olduğunu doğrula

### Property-Based Tests

- Random `JobModel` örnekleri oluştur (farklı `educationLevel` değerleri ile) ve her birinin detail ekranında doğru gösterildiğini doğrula
- Random saat çiftleri oluştur (başlangıç ve bitiş) ve her birinin doğru formatlandığını doğrula
- Random job oluşturma senaryoları oluştur ve diğer alanların (başlık, kategori, maaş, vb.) düzeltme sonrası aynı çalıştığını doğrula

### Integration Tests

- Tam iş oluşturma akışını test et: İş veren ilan oluşturur, eğitim seviyesi ve iş saati seçer, kaydeder, iş arayan detayları görüntüler
- İş düzenleme akışını test et: İş veren mevcut ilanı düzenler, eğitim seviyesi ve iş saati değiştirir, kaydeder, değişikliklerin yansıdığını doğrula
- Filtreleme akışını test et: İş arayan eğitim seviyesine göre filtreler, sonuçların doğru olduğunu doğrula
