# Gereksinimler Belgesi

## Giriş

Azerbaycan İş Pazarı Mobil Uygulaması, Azerbaycan pazarına özel olarak tasarlanmış, mavi yakalı işçiler ve işverenler arasında bağlantı kuran bir iş arama ve işe alım platformudur. Uygulama, tam zamanlı, yarı zamanlı, serbest çalışma, geçici ve günlük işler için hızlı ve kolay bir eşleştirme deneyimi sunacaktır. Flutter/Dart kullanılarak hem Android hem de iOS platformları için geliştirilecektir.

## Sözlük

- **Sistem**: Azerbaycan İş Pazarı Mobil Uygulaması
- **İş_Arayan**: İş arayan kullanıcı profili
- **İşveren**: İş ilanı yayınlayan ve başvuruları değerlendiren kullanıcı profili
- **İş_İlanı**: Sistemde yayınlanan iş fırsatı
- **Başvuru**: İş arayanın bir iş ilanına yaptığı müracaat
- **Mesajlaşma_Sistemi**: Kullanıcılar arası anlık iletişim modülü
- **Hizmet_Pazarı**: Yerel profesyonellerin hizmet sunduğu pazar yeri
- **Profil**: Kullanıcının sistem içindeki kimlik ve bilgi sayfası
- **Kategori**: İş veya hizmet türü sınıflandırması
- **Konum**: Coğrafi konum bilgisi
- **Bildirim_Sistemi**: Kullanıcılara anlık bildirim gönderen sistem
- **Kimlik_Doğrulama**: Kullanıcı giriş ve güvenlik sistemi

## Gereksinimler

### Gereksinim 1: Kullanıcı Kaydı ve Kimlik Doğrulama

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, platforma hızlı bir şekilde kaydolabilmek istiyorum, böylece iş arama veya işe alım sürecine başlayabilirim.

#### Kabul Kriterleri

1. THE Sistem SHALL isim, soy isim, telefon numarası, şifre ve opsiyonel e-posta alanları içeren kayıt formu sunmalıdır
2. WHEN bir kullanıcı kayıt formunu doldurduğunda, THE Sistem SHALL 1 dakika içinde kayıt işlemini tamamlamalıdır
3. THE Sistem SHALL şifre için minimum 8 karakter, en az bir büyük harf ve bir rakam gerektirmelidir
4. WHEN bir kullanıcı kayıt olduğunda, THE Sistem SHALL kullanıcıdan İş_Arayan veya İşveren profil tipi seçmesini istemelidir
5. THE Sistem SHALL telefon numarası veya e-posta ile giriş seçenekleri sunmalıdır
6. WHEN bir kullanıcı giriş yaptığında, THE Kimlik_Doğrulama SHALL telefon numarası veya e-posta ile şifre kombinasyonunu doğrulamalıdır
7. WHEN bir kullanıcı giriş yaptığında, THE Kimlik_Doğrulama SHALL kullanıcı kimliğini doğrulamalı ve oturum oluşturmalıdır
8. THE Sistem SHALL Azerbaycan Türkçesi dilinde arayüz sunmalıdır

**Not:** OTP/doğrulama kodu özelliği gelecek bir sürümde eklenecektir. Şu aşamada kullanıcılar doğrulama kodu olmadan direkt giriş yapabilecektir.

### Gereksinim 2: İş Arayan Profil Yönetimi

**Kullanıcı Hikayesi:** Bir iş arayan olarak, profilimi oluşturup yönetebilmek istiyorum, böylece işverenlere kendimi en iyi şekilde tanıtabilirim.

#### Kabul Kriterleri

1. THE Sistem SHALL İş_Arayan için ad, soyad, telefon, e-posta, doğum tarihi alanları içeren profil formu sunmalıdır
2. THE Sistem SHALL İş_Arayan için profil fotoğrafı yükleme imkanı sağlamalıdır
3. THE Sistem SHALL İş_Arayan için iş deneyimi ekleme özelliği sunmalıdır
4. THE Sistem SHALL İş_Arayan için eğitim bilgisi ekleme özelliği sunmalıdır
5. THE Sistem SHALL İş_Arayan için beceri ve yetenek listesi ekleme imkanı sağlamalıdır
6. THE Sistem SHALL İş_Arayan için tercih edilen iş kategorileri seçme özelliği sunmalıdır
7. THE Sistem SHALL İş_Arayan için tercih edilen çalışma şekli (tam zamanlı, yarı zamanlı, serbest, geçici, günlük) seçme imkanı sağlamalıdır
8. THE Sistem SHALL İş_Arayan için konum bilgisi ekleme özelliği sunmalıdır
9. THE Sistem SHALL İş_Arayan için özgeçmiş (CV) yükleme imkanı sağlamalıdır
10. WHEN İş_Arayan profil bilgilerini güncellediğinde, THE Sistem SHALL değişiklikleri anında kaydetmelidir
11. THE Sistem SHALL İş_Arayan için beklenen maaş aralığı (Manat cinsinden) belirtme özelliği sunmalıdır

### Gereksinim 3: İşveren Profil Yönetimi

**Kullanıcı Hikayesi:** Bir işveren olarak, şirket profilimi oluşturup yönetebilmek istiyorum, böylece iş arayanlara güvenilir bir işveren olduğumu gösterebilirim.

#### Kabul Kriterleri

1. THE Sistem SHALL İşveren için şirket adı, sektör, şirket büyüklüğü, telefon, e-posta alanları içeren profil formu sunmalıdır
2. THE Sistem SHALL İşveren için şirket logosu yükleme imkanı sağlamalıdır
3. THE Sistem SHALL İşveren için şirket açıklaması ekleme özelliği sunmalıdır
4. THE Sistem SHALL İşveren için şirket adresi ve konum bilgisi ekleme özelliği sunmalıdır
5. THE Sistem SHALL İşveren için web sitesi ve sosyal medya bağlantıları ekleme imkanı sağlamalıdır
6. WHEN İşveren profil bilgilerini güncellediğinde, THE Sistem SHALL değişiklikleri anında kaydetmelidir
7. THE Sistem SHALL İşveren için vergi numarası veya şirket kayıt numarası ekleme özelliği sunmalıdır

### Gereksinim 4: İş İlanı Oluşturma ve Yönetimi

**Kullanıcı Hikayesi:** Bir işveren olarak, iş ilanlarını hızlı ve kolay bir şekilde oluşturup yönetebilmek istiyorum, böylece uygun adayları bulabilirim.

#### Kabul Kriterleri

1. WHEN bir İşveren iş ilanı oluşturduğunda, THE Sistem SHALL 1 dakika içinde ilan yayınlama işlemini tamamlamalıdır
2. THE Sistem SHALL İşveren için ücretsiz iş ilanı yayınlama imkanı sağlamalıdır
3. THE Sistem SHALL iş başlığı, açıklama, gereksinimler, sorumluluklar alanları içeren ilan formu sunmalıdır
4. THE Sistem SHALL İşveren için iş kategorisi seçme özelliği sunmalıdır (tam zamanlı, yarı zamanlı, serbest çalışma, geçici, günlük/saatlik)
5. WHEN iş kategorisi yarı zamanlı veya günlük/saatlik seçildiğinde, THE Sistem SHALL gün ve saat detayları girme alanları sunmalıdır
6. THE Sistem SHALL İşveren için maaş aralığı (Manat cinsinden) belirtme özelliği sunmalıdır
7. THE Sistem SHALL İşveren için iş konumu ekleme özelliği sunmalıdır
8. THE Sistem SHALL İşveren için deneyim seviyesi (giriş, orta, üst) seçme imkanı sağlamalıdır
9. THE Sistem SHALL İşveren için eğitim gereksinimleri belirtme özelliği sunmalıdır
10. THE Sistem SHALL İşveren için gerekli beceri ve yetenekleri listeleme imkanı sağlamalıdır
11. WHEN İşveren bir ilanı yayınladığında, THE Sistem SHALL ilanı anında aktif hale getirmelidir
12. THE Sistem SHALL İşveren için yayınlanan ilanları düzenleme özelliği sunmalıdır
13. THE Sistem SHALL İşveren için ilanları duraklama ve silme imkanı sağlamalıdır
14. THE Sistem SHALL İşveren için aktif, duraklatılmış ve kapatılmış ilanları görüntüleme özelliği sunmalıdır
15. THE Sistem SHALL her ilan için başvuru sayısını göstermelidir

### Gereksinim 5: İş Arama ve Filtreleme

**Kullanıcı Hikayesi:** Bir iş arayan olarak, ihtiyaçlarıma uygun işleri hızlıca bulabilmek istiyorum, böylece zaman kaybetmeden başvuru yapabilirim.

#### Kabul Kriterleri

1. THE Sistem SHALL İş_Arayan için anahtar kelime ile iş arama özelliği sunmalıdır
2. THE Sistem SHALL İş_Arayan için iş kategorisine göre filtreleme imkanı sağlamalıdır
3. THE Sistem SHALL İş_Arayan için konuma göre filtreleme özelliği sunmalıdır
4. THE Sistem SHALL İş_Arayan için maaş aralığına göre filtreleme imkanı sağlamalıdır
5. THE Sistem SHALL İş_Arayan için çalışma şekline göre (tam zamanlı, yarı zamanlı, serbest, geçici, günlük) filtreleme özelliği sunmalıdır
6. THE Sistem SHALL İş_Arayan için deneyim seviyesine göre filtreleme imkanı sağlamalıdır
7. THE Sistem SHALL İş_Arayan için yayınlanma tarihine göre sıralama özelliği sunmalıdır
8. WHEN İş_Arayan konum filtresi kullandığında, THE Sistem SHALL en yakın işleri öncelikli olarak göstermelidir
9. THE Sistem SHALL İş_Arayan için arama kriterlerini kaydetme ve hızlı erişim imkanı sağlamalıdır
10. THE Sistem SHALL İş_Arayan için kaydedilen arama kriterlerine uygun yeni ilanlar için bildirim göndermelidir

### Gereksinim 6: İş Başvurusu ve Takip

**Kullanıcı Hikayesi:** Bir iş arayan olarak, ilgilendiğim işlere hızlıca başvurabilmek ve başvurularımı takip edebilmek istiyorum.

#### Kabul Kriterleri

1. WHEN İş_Arayan bir iş ilanına başvurduğunda, THE Sistem SHALL başvuruyu anında kaydetmelidir
2. THE Sistem SHALL İş_Arayan için tek tıkla hızlı başvuru özelliği sunmalıdır
3. THE Sistem SHALL İş_Arayan için başvuru sırasında ek mesaj ekleme imkanı sağlamalıdır
4. THE Sistem SHALL İş_Arayan için başvuru sırasında özgeçmiş seçme veya yükleme özelliği sunmalıdır
5. WHEN İş_Arayan bir başvuru yaptığında, THE Sistem SHALL İşveren'e bildirim göndermelidir
6. THE Sistem SHALL İş_Arayan için yapılan tüm başvuruları görüntüleme özelliği sunmalıdır
7. THE Sistem SHALL her başvuru için durum bilgisi (beklemede, görüldü, değerlendiriliyor, kabul edildi, reddedildi) göstermelidir
8. WHEN başvuru durumu değiştiğinde, THE Sistem SHALL İş_Arayan'a bildirim göndermelidir
9. THE Sistem SHALL İş_Arayan için aynı ilana tekrar başvuruyu engellemeli ve uyarı göstermelidir
10. THE Sistem SHALL İş_Arayan için başvuruları tarihe göre sıralama imkanı sağlamalıdır

### Gereksinim 7: Başvuru Değerlendirme

**Kullanıcı Hikayesi:** Bir işveren olarak, gelen başvuruları değerlendirebilmek ve adaylarla iletişime geçebilmek istiyorum.

#### Kabul Kriterleri

1. THE Sistem SHALL İşveren için her iş ilanına gelen başvuruları listeleme özelliği sunmalıdır
2. THE Sistem SHALL her başvuru için İş_Arayan'ın profil bilgilerini, özgeçmişini ve başvuru mesajını göstermelidir
3. THE Sistem SHALL İşveren için başvuruları filtreleme (yeni, görüldü, değerlendiriliyor, kabul edildi, reddedildi) imkanı sağlamalıdır
4. WHEN İşveren bir başvuruyu görüntülediğinde, THE Sistem SHALL başvuru durumunu otomatik olarak "görüldü" olarak işaretlemelidir
5. THE Sistem SHALL İşveren için başvuru durumunu değiştirme özelliği sunmalıdır
6. WHEN İşveren başvuru durumunu değiştirdiğinde, THE Sistem SHALL İş_Arayan'a bildirim göndermelidir
7. THE Sistem SHALL İşveren için başvuruları favorilere ekleme imkanı sağlamalıdır
8. THE Sistem SHALL İşveren için başvuruya not ekleme özelliği sunmalıdır
9. THE Sistem SHALL İşveren için başvuruyu doğrudan mesajlaşmaya yönlendirme imkanı sağlamalıdır
10. THE Sistem SHALL İşveren için başvuruları özgeçmiş kalitesine göre sıralama önerisi sunmalıdır

### Gereksinim 8: Anlık Mesajlaşma Sistemi

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, diğer kullanıcılarla anlık mesajlaşabilmek istiyorum, böylece iş detaylarını hızlıca konuşabilirim.

#### Kabul Kriterleri

1. THE Mesajlaşma_Sistemi SHALL İşveren ve İş_Arayan arasında bire bir mesajlaşma imkanı sağlamalıdır
2. WHEN bir kullanıcı mesaj gönderdiğinde, THE Mesajlaşma_Sistemi SHALL mesajı anında karşı tarafa iletmelidir
3. THE Mesajlaşma_Sistemi SHALL metin mesajı gönderme özelliği sunmalıdır
4. THE Mesajlaşma_Sistemi SHALL görsel (fotoğraf) gönderme imkanı sağlamalıdır
5. THE Mesajlaşma_Sistemi SHALL dosya (PDF, Word) gönderme özelliği sunmalıdır
6. WHEN bir kullanıcı çevrimdışı olduğunda, THE Sistem SHALL gelen mesajları saklayıp kullanıcı çevrimiçi olduğunda göstermelidir
7. THE Mesajlaşma_Sistemi SHALL her mesaj için gönderildi, iletildi, okundu durumlarını göstermelidir
8. THE Mesajlaşma_Sistemi SHALL kullanıcıların mesaj geçmişini görüntüleme imkanı sağlamalıdır
9. WHEN yeni bir mesaj geldiğinde, THE Sistem SHALL alıcıya anlık bildirim göndermelidir
10. THE Mesajlaşma_Sistemi SHALL kullanıcıların konuşmaları arama özelliği sunmalıdır
11. THE Mesajlaşma_Sistemi SHALL kullanıcıların belirli konuşmaları silme imkanı sağlamalıdır
12. THE Mesajlaşma_Sistemi SHALL kullanıcıların diğer kullanıcıları engelleme özelliği sunmalıdır
13. WHEN bir kullanıcı engellendiğinde, THE Mesajlaşma_Sistemi SHALL engellenen kullanıcının mesaj göndermesini engellemeli ve uyarı göstermelidir

### Gereksinim 9: Hizmet Pazarı

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, yerel profesyonelleri (tesisatçı, duvarcı, elektrikçi vb.) bulabilmek veya hizmet sunabilmek istiyorum.

#### Kabul Kriterleri

1. THE Sistem SHALL Hizmet_Pazarı modülü sunmalıdır
2. THE Sistem SHALL kullanıcıların hizmet kategorisi seçerek profesyonel arama imkanı sağlamalıdır
3. THE Sistem SHALL Azerbaycan'a özgü hizmet kategorileri (tesisatçı, duvarcı, elektrikçi, boyacı, marangoz, temizlik, nakliye, tadilat) sunmalıdır
4. THE Sistem SHALL kullanıcıların hizmet profili oluşturma özelliği sunmalıdır
5. THE Sistem SHALL hizmet profili için hizmet türü, deneyim yılı, çalışma bölgesi, fiyat aralığı alanları içermelidir
6. THE Sistem SHALL hizmet sağlayıcıların portföy fotoğrafları yükleme imkanı sağlamalıdır
7. THE Sistem SHALL kullanıcıların konuma göre yakındaki hizmet sağlayıcıları bulma özelliği sunmalıdır
8. THE Sistem SHALL hizmet sağlayıcılar için müsaitlik durumu (uygun, meşgul) gösterme imkanı sağlamalıdır
9. WHEN bir kullanıcı hizmet sağlayıcıya ulaşmak istediğinde, THE Sistem SHALL doğrudan mesajlaşmaya yönlendirmelidir
10. THE Sistem SHALL hizmet sağlayıcılar için değerlendirme ve yorum sistemi sunmalıdır
11. THE Sistem SHALL hizmet arayanların fiyat teklifi isteme özelliği sağlamalıdır

### Gereksinim 10: Bildirim Sistemi

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, önemli olaylar hakkında zamanında bilgilendirilmek istiyorum.

#### Kabul Kriterleri

1. THE Bildirim_Sistemi SHALL kullanıcılara anlık push bildirimleri gönderme imkanı sağlamalıdır
2. WHEN yeni bir mesaj geldiğinde, THE Bildirim_Sistemi SHALL kullanıcıya bildirim göndermelidir
3. WHEN bir başvuru durumu değiştiğinde, THE Bildirim_Sistemi SHALL İş_Arayan'a bildirim göndermelidir
4. WHEN yeni bir başvuru geldiğinde, THE Bildirim_Sistemi SHALL İşveren'e bildirim göndermelidir
5. WHEN kaydedilen arama kriterlerine uygun yeni bir ilan yayınlandığında, THE Bildirim_Sistemi SHALL İş_Arayan'a bildirim göndermelidir
6. THE Sistem SHALL kullanıcıların bildirim tercihlerini yönetme özelliği sunmalıdır
7. THE Sistem SHALL kullanıcıların bildirim geçmişini görüntüleme imkanı sağlamalıdır
8. THE Sistem SHALL kullanıcıların belirli bildirim türlerini kapatma özelliği sunmalıdır
9. WHEN kullanıcı uygulama içinde olduğunda, THE Bildirim_Sistemi SHALL bildirimleri uygulama içi banner olarak göstermelidir
10. THE Bildirim_Sistemi SHALL bildirimleri Azerbaycan Türkçesi dilinde göndermelidir

### Gereksinim 11: Yerelleştirme ve Para Birimi

**Kullanıcı Hikayesi:** Bir Azerbaycan kullanıcısı olarak, uygulamayı kendi dilimde ve yerel para biriminde kullanabilmek istiyorum.

#### Kabul Kriterleri

1. THE Sistem SHALL tüm arayüz metinlerini Azerbaycan Türkçesi dilinde sunmalıdır
2. THE Sistem SHALL tüm para birimi gösterimlerini Azerbaycan Manatı (AZN veya ₼) cinsinden göstermelidir
3. THE Sistem SHALL tarih formatını Azerbaycan standardına (GG.AA.YYYY) uygun göstermelidir
4. THE Sistem SHALL telefon numarası formatını Azerbaycan standardına (+994) uygun doğrulamalıdır
5. THE Sistem SHALL Azerbaycan'a özgü iş kategorileri ve sektörler sunmalıdır
6. THE Sistem SHALL Azerbaycan şehir ve bölge listesi sunmalıdır
7. THE Sistem SHALL sayı formatını Azerbaycan standardına (nokta ayırıcı) uygun göstermelidir

### Gereksinim 12: Konum Tabanlı Özellikler

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, konumuma yakın iş fırsatlarını ve hizmet sağlayıcıları bulabilmek istiyorum.

#### Kabul Kriterleri

1. THE Sistem SHALL kullanıcıların mevcut konumlarını tespit etme imkanı sağlamalıdır
2. WHEN kullanıcı konum izni verdiğinde, THE Sistem SHALL GPS kullanarak konumu belirlemelidir
3. THE Sistem SHALL kullanıcıların manuel olarak konum girme özelliği sunmalıdır
4. THE Sistem SHALL iş ilanlarını kullanıcı konumuna göre mesafe sırasıyla listeleme imkanı sağlamalıdır
5. THE Sistem SHALL her iş ilanı için kullanıcıya olan mesafeyi göstermelidir
6. THE Sistem SHALL kullanıcıların belirli bir yarıçap içindeki ilanları filtreleme özelliği sunmalıdır
7. THE Sistem SHALL harita üzerinde iş ilanlarını ve hizmet sağlayıcıları gösterme imkanı sağlamalıdır
8. THE Sistem SHALL Azerbaycan haritası ve şehir sınırlarını doğru göstermelidir

### Gereksinim 13: Değerlendirme ve Yorum Sistemi

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, işverenleri ve hizmet sağlayıcıları değerlendirebilmek ve diğer kullanıcıların yorumlarını görebilmek istiyorum.

#### Kabul Kriterleri

1. THE Sistem SHALL İş_Arayan'ların İşveren'leri değerlendirme imkanı sağlamalıdır
2. THE Sistem SHALL kullanıcıların hizmet sağlayıcıları değerlendirme özelliği sunmalıdır
3. THE Sistem SHALL 1-5 yıldız arası puanlama sistemi kullanmalıdır
4. THE Sistem SHALL kullanıcıların yorum metni yazma imkanı sağlamalıdır
5. WHEN bir kullanıcı değerlendirme yaptığında, THE Sistem SHALL değerlendirmeyi anında yayınlamalıdır
6. THE Sistem SHALL her İşveren ve hizmet sağlayıcı için ortalama puanı hesaplayıp göstermelidir
7. THE Sistem SHALL değerlendirmeleri tarihe göre sıralama özelliği sunmalıdır
8. THE Sistem SHALL kullanıcıların sadece gerçekten çalıştıkları veya hizmet aldıkları kişileri değerlendirmesini sağlamalıdır
9. THE Sistem SHALL her kullanıcının aynı kişi için sadece bir değerlendirme yapmasına izin vermelidir
10. THE Sistem SHALL uygunsuz yorumları bildirme imkanı sağlamalıdır

### Gereksinim 14: Arama ve Keşfet

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, platformda kolayca gezinebilmek ve ilgimi çeken içerikleri keşfedebilmek istiyorum.

#### Kabul Kriterleri

1. THE Sistem SHALL ana sayfada öne çıkan iş ilanlarını göstermelidir
2. THE Sistem SHALL ana sayfada yeni eklenen ilanları listelemelidir
3. THE Sistem SHALL kullanıcı profiline göre önerilen işleri gösterme imkanı sağlamalıdır
4. THE Sistem SHALL popüler kategorileri ana sayfada göstermelidir
5. THE Sistem SHALL kullanıcıların son görüntülediği ilanları kaydetme ve gösterme özelliği sunmalıdır
6. THE Sistem SHALL kullanıcıların ilanları favorilere ekleme imkanı sağlamalıdır
7. THE Sistem SHALL kullanıcıların favori ilanlarını görüntüleme özelliği sunmalıdır
8. THE Sistem SHALL kullanıcıların ilanları paylaşma (sosyal medya, mesajlaşma uygulamaları) imkanı sağlamalıdır
9. THE Sistem SHALL genel arama çubuğu sunmalıdır
10. WHEN kullanıcı arama yaptığında, THE Sistem SHALL hem iş ilanlarında hem hizmet sağlayıcılarda arama yapmalıdır

### Gereksinim 15: Güvenlik ve Gizlilik

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, kişisel bilgilerimin güvende olduğundan emin olmak istiyorum.

#### Kabul Kriterleri

1. THE Sistem SHALL kullanıcı şifrelerini şifrelenmiş olarak saklamalıdır
2. THE Sistem SHALL güvenli HTTPS bağlantısı kullanmalıdır
3. THE Sistem SHALL kullanıcıların gizlilik ayarlarını yönetme imkanı sağlamalıdır
4. THE Sistem SHALL kullanıcıların profil görünürlüğünü kontrol etme özelliği sunmalıdır
5. THE Sistem SHALL kullanıcıların telefon numarası ve e-posta görünürlüğünü ayarlama imkanı sağlamalıdır
6. THE Sistem SHALL kullanıcıların hesaplarını silme özelliği sunmalıdır
7. WHEN kullanıcı hesabını sildiğinde, THE Sistem SHALL tüm kişisel verileri kalıcı olarak silmelidir
8. THE Sistem SHALL şüpheli aktiviteleri tespit etme ve engelleme imkanı sağlamalıdır
9. THE Sistem SHALL kullanıcıların diğer kullanıcıları şikayet etme özelliği sunmalıdır
10. THE Sistem SHALL spam ve dolandırıcılık içeriklerini filtreleme mekanizması sağlamalıdır

### Gereksinim 16: Performans ve Kullanılabilirlik

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, uygulamanın hızlı ve sorunsuz çalışmasını istiyorum.

#### Kabul Kriterleri

1. WHEN uygulama başlatıldığında, THE Sistem SHALL 3 saniye içinde ana sayfayı yüklemelidir
2. WHEN kullanıcı bir sayfaya geçiş yaptığında, THE Sistem SHALL 1 saniye içinde sayfayı göstermelidir
3. WHEN kullanıcı arama yaptığında, THE Sistem SHALL 2 saniye içinde sonuçları göstermelidir
4. THE Sistem SHALL çevrimdışı modda temel özellikleri (profil görüntüleme, kaydedilen ilanlar) sunmalıdır
5. WHEN internet bağlantısı kesildiğinde, THE Sistem SHALL kullanıcıya bilgilendirici mesaj göstermelidir
6. THE Sistem SHALL düşük internet hızında da kullanılabilir olmalıdır
7. THE Sistem SHALL görsel içerikleri optimize ederek hızlı yükleme sağlamalıdır
8. THE Sistem SHALL hem Android hem iOS platformlarında tutarlı deneyim sunmalıdır
9. THE Sistem SHALL farklı ekran boyutlarına (telefon, tablet) uyumlu olmalıdır
10. THE Sistem SHALL erişilebilirlik standartlarına uygun olmalıdır

### Gereksinim 17: Veri Senkronizasyonu ve Yedekleme

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, verilerimin güvenli bir şekilde saklandığından ve farklı cihazlarda senkronize olduğundan emin olmak istiyorum.

#### Kabul Kriterleri

1. THE Sistem SHALL kullanıcı verilerini bulut sunucuda saklamalıdır
2. WHEN kullanıcı farklı bir cihazdan giriş yaptığında, THE Sistem SHALL tüm verilerini senkronize etmelidir
3. THE Sistem SHALL kullanıcı eylemlerini (başvuru, mesaj, favori) anında sunucuya kaydetmelidir
4. WHEN internet bağlantısı olmadığında, THE Sistem SHALL eylemleri yerel olarak saklamalı ve bağlantı kurulduğunda senkronize etmelidir
5. THE Sistem SHALL kullanıcı verilerinin düzenli yedeğini almalıdır
6. THE Sistem SHALL veri kaybı durumunda kurtarma mekanizması sağlamalıdır

### Gereksinim 18: Analitik ve Raporlama

**Kullanıcı Hikayesi:** Bir işveren olarak, iş ilanlarımın performansını görebilmek ve raporlar alabilmek istiyorum.

#### Kabul Kriterleri

1. THE Sistem SHALL İşveren için ilan görüntülenme sayısını göstermelidir
2. THE Sistem SHALL İşveren için ilan başvuru sayısını göstermelidir
3. THE Sistem SHALL İşveren için başvuru dönüşüm oranını hesaplayıp göstermelidir
4. THE Sistem SHALL İşveren için zaman içindeki performans grafiklerini sunmalıdır
5. THE Sistem SHALL İşveren için en çok görüntülenen ve başvuru alan ilanları göstermelidir
6. THE Sistem SHALL İş_Arayan için profil görüntülenme sayısını göstermelidir
7. THE Sistem SHALL İş_Arayan için başvuru durumu istatistiklerini sunmalıdır
8. THE Sistem SHALL kullanıcılara haftalık veya aylık özet raporları gönderme imkanı sağlamalıdır

### Gereksinim 19: Mobil Platform Özellikleri

**Kullanıcı Hikayesi:** Bir mobil kullanıcı olarak, mobil cihazıma özgü özellikleri kullanabilmek istiyorum.

#### Kabul Kriterleri

1. THE Sistem SHALL kamera kullanarak fotoğraf çekme ve yükleme imkanı sağlamalıdır
2. THE Sistem SHALL galeriden fotoğraf seçme özelliği sunmalıdır
3. THE Sistem SHALL telefon rehberinden iletişim bilgisi alma imkanı sağlamalıdır
4. THE Sistem SHALL doğrudan telefon araması başlatma özelliği sunmalıdır
5. THE Sistem SHALL harita uygulamasını açarak yol tarifi alma imkanı sağlamalıdır
6. THE Sistem SHALL dosya yöneticisinden belge seçme özelliği sunmalıdır
7. THE Sistem SHALL biyometrik kimlik doğrulama (parmak izi, yüz tanıma) imkanı sağlamalıdır
8. THE Sistem SHALL cihaz bildirim ayarlarına uyumlu çalışmalıdır
9. THE Sistem SHALL arka planda çalışarak bildirimleri alabilmelidir
10. THE Sistem SHALL düşük pil modunda optimize edilmiş çalışma sağlamalıdır

### Gereksinim 20: İçerik Moderasyonu

**Kullanıcı Hikayesi:** Bir platform yöneticisi olarak, platformdaki içeriklerin kalitesini ve uygunluğunu kontrol edebilmek istiyorum.

#### Kabul Kriterleri

1. THE Sistem SHALL kullanıcıların uygunsuz içerik bildirme imkanı sağlamalıdır
2. WHEN bir içerik bildirildiğinde, THE Sistem SHALL bildirimi moderasyon kuyruğuna eklemelidir
3. THE Sistem SHALL yasaklı kelime ve ifadeleri otomatik olarak tespit etme mekanizması sağlamalıdır
4. WHEN yasaklı içerik tespit edildiğinde, THE Sistem SHALL içeriği yayınlamadan önce moderasyona göndermelidir
5. THE Sistem SHALL spam içerikleri otomatik olarak filtreleme imkanı sağlamalıdır
6. THE Sistem SHALL tekrarlayan uygunsuz davranış gösteren kullanıcıları otomatik olarak işaretlemelidir
7. THE Sistem SHALL moderatörlerin içerikleri onaylama veya reddetme özelliği sunmalıdır
8. WHEN bir içerik reddedildiğinde, THE Sistem SHALL kullanıcıya bildirim ve sebep göstermelidir
9. THE Sistem SHALL kullanıcıların geçici veya kalıcı olarak engellenme imkanı sağlamalıdır
10. THE Sistem SHALL moderasyon geçmişini kaydetme ve raporlama özelliği sunmalıdır

### Gereksinim 21: Çoklu Dil Desteği (Gelecek Özellik)

**Kullanıcı Hikayesi:** Bir kullanıcı olarak, gelecekte uygulamayı farklı dillerde kullanabilmek istiyorum.

#### Kabul Kriterleri

1. THE Sistem SHALL dil değiştirme özelliği için altyapı sunmalıdır
2. THE Sistem SHALL tüm arayüz metinlerini çeviri dosyalarından yükleme imkanı sağlamalıdır
3. THE Sistem SHALL kullanıcının seçtiği dili kaydetme ve hatırlama özelliği sunmalıdır
4. THE Sistem SHALL Azerbaycan Türkçesi, Rusça ve İngilizce dil seçenekleri için hazır olmalıdır
5. WHEN kullanıcı dil değiştirdiğinde, THE Sistem SHALL uygulamayı yeniden başlatmadan dili değiştirmelidir
6. THE Sistem SHALL tarih, saat ve para birimi formatlarını seçilen dile göre ayarlama imkanı sağlamalıdır
