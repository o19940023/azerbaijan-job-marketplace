# Bugfix Requirements Document

## Introduction

İşveren iş ilanı sistemi şu anda çalışmıyor. İşverenler ilan oluşturduğunda veriler kaydedilmiyor ve sadece MockData.jobs'dan gelen sahte veriler görüntüleniyor. Bu bug, iş ilanı oluşturma, saklama ve görüntüleme akışının tamamen işlevsiz olmasına neden oluyor. İşverenler ilan oluşturabilmeli, bu ilanlar kalıcı olarak saklanmalı ve hem işverenler hem de iş arayanlar tarafından görüntülenebilmelidir.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN işveren CreateJobScreen'de yeni bir iş ilanı oluşturup kaydet butonuna bastığında THEN ilan gerçekten kaydedilmiyor ve kaybolup gidiyor

1.2 WHEN işveren EmployerHome sayfasında kendi ilanlarını görüntülemeye çalıştığında THEN sadece MockData.jobs'dan gelen sahte veriler görünüyor ve kendi oluşturduğu ilanlar görünmüyor

1.3 WHEN iş arayan JobSeekerHome sayfasında iş ilanlarını görüntülediğinde THEN sadece MockData.jobs'dan gelen sahte veriler görünüyor ve işverenlerin oluşturduğu gerçek ilanlar görünmüyor

1.4 WHEN işveren kendi ilanını düzenlemeye veya silmeye çalıştığında THEN bu işlemler gerçekleşmiyor çünkü veriler kalıcı olarak saklanmıyor

1.5 WHEN uygulama yeniden başlatıldığında THEN önceden oluşturulan tüm ilanlar kaybolmuş oluyor

### Expected Behavior (Correct)

2.1 WHEN işveren CreateJobScreen'de yeni bir iş ilanı oluşturup kaydet butonuna bastığında THEN ilan Hive local storage'a kaydedilmeli ve kalıcı olarak saklanmalı

2.2 WHEN işveren EmployerHome sayfasında kendi ilanlarını görüntülediğinde THEN Hive'dan kendi employerId'sine ait gerçek ilanlar yüklenmeli ve görüntülenmeli

2.3 WHEN iş arayan JobSeekerHome sayfasında iş ilanlarını görüntülediğinde THEN Hive'dan tüm aktif ilanlar (hem gerçek hem de mock data) yüklenmeli ve görüntülenmeli

2.4 WHEN işveren kendi ilanını düzenlediğinde THEN değişiklikler Hive'da güncellenmeli ve kalıcı olarak saklanmalı

2.5 WHEN işveren kendi ilanını sildiğinde THEN ilan Hive'dan silinmeli ve artık hiçbir listede görünmemeli

2.6 WHEN uygulama yeniden başlatıldığında THEN Hive'da saklanan tüm ilanlar korunmalı ve tekrar yüklenebilmeli

### Unchanged Behavior (Regression Prevention)

3.1 WHEN iş arayan iş ilanı detaylarını görüntülediğinde THEN mevcut JobDetailScreen fonksiyonalitesi değişmeden çalışmaya devam etmeli

3.2 WHEN kullanıcı iş ilanlarını kategoriye, şehre veya mesafeye göre filtrelediğinde THEN mevcut filtreleme mantığı değişmeden çalışmaya devam etmeli

3.3 WHEN iş arayan bir ilana başvurduğunda THEN mevcut başvuru sistemi değişmeden çalışmaya devam etmeli

3.4 WHEN kullanıcı harita üzerinde iş ilanlarını görüntülediğinde THEN mevcut harita fonksiyonalitesi değişmeden çalışmaya devam etmeli

3.5 WHEN MockData.jobs'daki mevcut sahte ilanlar görüntülendiğinde THEN bu ilanlar da Hive'a eklenmeli ve diğer gerçek ilanlarla birlikte görüntülenmeli (veri kaybı olmamalı)
