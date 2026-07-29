# Bugfix Requirements Document

## Introduction

İş ilanı sisteminde iki kritik kullanıcı deneyimi sorunu tespit edilmiştir:

1. **Tehsil (Eğitim Seviyesi) Görünmüyor**: İş veren ilan oluştururken tehsil kategorisi seçiyor (örn: ali, orta, vs.) ancak iş arayan ilana baktığında bu bilgi görünmüyor. İş arayan ilanın eğitim gereksinimini göremediği için hangi işlere başvurabileceğini bilemiyor.

2. **İş Saati Seçimi Manuel**: İş veren ilan verirken iş saati aralığını manuel olarak yazıyor (örn: "09:00 - 18:00"). Bu kullanıcı deneyimi açısından kötü ve hatalara açık. iPhone'lardaki gibi kaydırmalı (slider/picker) bir tasarım olmalı ki kullanıcı kolayca başlangıç ve bitiş saatlerini seçebilsin.

Bu buglar, iş arayanların doğru bilgiye erişememesine ve iş verenlerin kötü kullanıcı deneyimi yaşamasına neden oluyor.

## Bug Analysis

### Current Behavior (Defect)

**Bug 1: Tehsil Bilgisi Görünmüyor**

1.1 WHEN iş veren ilan oluştururken tehsil seviyesi seçer (örn: "Ali", "Orta", "Peşə") THEN sistem bu bilgiyi veritabanına kaydeder ancak iş arayan ilan detayında bu bilgiyi göremez

1.2 WHEN iş arayan bir iş ilanının detaylarını görüntüler THEN tehsil gereksinimi bilgisi eksik olduğu için iş arayan başvuru yapıp yapamayacağını bilemez

**Bug 2: İş Saati Manuel Giriliyor**

1.3 WHEN iş veren ilan oluştururken iş saati aralığını girmek ister THEN sistem manuel text input gösterir ve kullanıcı "09:00 - 18:00" formatında manuel yazmalıdır

1.4 WHEN kullanıcı iş saatini manuel yazarken THEN yanlış format girme riski vardır (örn: "9-18", "09.00-18.00", "9:00-6:00 PM")

1.5 WHEN kullanıcı mobil cihazda iş saati girmek ister THEN klavye açılır ve kullanıcı deneyimi kötüdür, çünkü kaydırmalı saat seçici daha hızlı ve kolay olurdu

### Expected Behavior (Correct)

**Bug 1: Tehsil Bilgisi Görünmeli**

2.1 WHEN iş veren ilan oluştururken tehsil seviyesi seçer THEN sistem bu bilgiyi veritabanına kaydeder VE iş arayan ilan detayında bu bilgiyi görebilir

2.2 WHEN iş arayan bir iş ilanının detaylarını görüntüler THEN tehsil gereksinimi açıkça görüntülenir (örn: "Təhsil: Ali" veya "Təhsil: Vacib deyil")

2.3 WHEN tehsil bilgisi "Vacib deyil" veya null ise THEN sistem yine de bu bilgiyi gösterir ("Təhsil: Vacib deyil" şeklinde)

**Bug 2: İş Saati Picker ile Seçilmeli**

2.4 WHEN iş veren ilan oluştururken iş saati aralığını girmek ister THEN sistem kaydırmalı saat seçici (time picker) gösterir

2.5 WHEN kullanıcı başlangıç saati seçer THEN iOS/Android native time picker veya custom cupertino-style picker açılır ve kullanıcı kolayca saat seçer

2.6 WHEN kullanıcı bitiş saati seçer THEN aynı şekilde picker ile seçim yapar ve format tutarlılığı garanti edilir

2.7 WHEN kullanıcı her iki saati de seçer THEN sistem otomatik olarak "09:00 - 18:00" formatında birleştirir ve gösterir

2.8 WHEN seçilen saatler veritabanına kaydedilir THEN format her zaman tutarlıdır (HH:mm - HH:mm)

### Unchanged Behavior (Regression Prevention)

**Mevcut İlan Oluşturma Akışı**

3.1 WHEN iş veren diğer ilan bilgilerini girer (başlık, kategori, maaş, vb.) THEN bu alanlar şu anki gibi çalışmaya devam eder

3.2 WHEN iş veren ilan düzenler THEN mevcut tehsil ve iş saati bilgileri doğru şekilde yüklenir ve düzenlenebilir

3.3 WHEN iş veren ilanı kaydeder THEN tüm diğer alanlar (kategori, maaş, lokasyon, vb.) şu anki gibi kaydedilmeye devam eder

**Mevcut İlan Görüntüleme Akışı**

3.4 WHEN iş arayan ilan detayını görüntüler THEN mevcut tüm bilgiler (şirket adı, şehir, maaş, iş saati, vb.) şu anki gibi görüntülenmeye devam eder

3.5 WHEN iş arayan iş saati bilgisini görür THEN format "09:00 - 18:00" şeklinde gösterilmeye devam eder (sadece giriş yöntemi değişir)

**Veritabanı Yapısı**

3.6 WHEN sistem tehsil bilgisini kaydeder THEN `educationLevel` alanı şu anki gibi String olarak saklanmaya devam eder

3.7 WHEN sistem iş saati bilgisini kaydeder THEN `workingHours` alanı şu anki gibi String olarak saklanmaya devam eder

**Filtreleme ve Arama**

3.8 WHEN iş arayan tehsil seviyesine göre filtreler THEN mevcut filtreleme mantığı çalışmaya devam eder

3.9 WHEN iş arayan iş ilanlarını listeler THEN sıralama ve filtreleme şu anki gibi çalışmaya devam eder
