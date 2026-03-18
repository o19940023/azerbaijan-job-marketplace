# Acil İlan Ödeme Sorunu Bugfix Tasarımı

## Overview

İşveren yeni ilan paylaşırken "acil ilan" seçeneğini seçip ödeme yaptığında, para karttan çekilmesine rağmen WebView siyah ekran gösteriyor, uygulama donuyor veya kapanıyor, ve ilan normal (acil olmayan) olarak kaydediliyor. Bu kritik bug hem kullanıcı deneyimini bozuyor hem de hukuki sorun yaratıyor (para çekilip servis verilmiyor).

Sorun iki ana bileşende:
1. **WebView Navigation**: Epoint ödeme başarılı olduğunda success URL'e yönlendiriyor, ancak WebView navigation delegate bu yönlendirmeyi düzgün algılamıyor ve siyah ekran oluşuyor
2. **Firestore Güncelleme**: Webhook veya checkPaymentStatus çağrısı başarısız oluyor, bu yüzden `isUrgent: true` güncellemesi Firestore'a yazılmıyor

Bu tasarım, WebView navigation mantığını düzelterek ve Firestore güncelleme garantisini sağlayarak sorunu çözecek.

## Glossary

- **Bug_Condition (C)**: Ödeme başarılı olduğunda (para çekildiğinde) WebView'in siyah ekran göstermesi ve Firestore'un güncellenmemesi durumu
- **Property (P)**: Ödeme başarılı olduğunda WebView'in düzgün kapanması ve ilanın `isUrgent: true` olarak güncellenmesi
- **Preservation**: Ödeme iptal edildiğinde veya başarısız olduğunda mevcut davranışın korunması
- **PaymentWebViewScreen**: `lib/features/jobs/presentation/pages/payment_webview_screen.dart` dosyasındaki Epoint ödeme sayfasını gösteren WebView ekranı
- **NavigationDelegate**: WebView'in sayfa yönlendirmelerini yakalayan ve kontrol eden delegate
- **urgentPaymentCallback**: Backend'deki `/api/urgentPaymentCallback` endpoint'i - Epoint webhook'unun çağırdığı servis
- **checkPaymentStatus**: Backend'deki `/api/checkPaymentStatus` endpoint'i - Ödeme durumunu kontrol eden fallback servisi
- **ClientHandler**: Epoint'in ödeme sonrası gösterdiği ara sayfa - bazen burada takılıp kalıyor
- **isUrgent**: Firestore'daki job dokümanında ilanın acil olup olmadığını belirten boolean alan
- **urgentUntil**: Firestore'daki job dokümanında acil ilanın ne zamana kadar geçerli olduğunu belirten timestamp

## Bug Details

### Bug Condition

Bug, kullanıcı acil ilan için ödeme yaptığında ve Epoint ödeme işlemini başarıyla tamamladığında ortaya çıkıyor. WebView, Epoint'in success URL'ine yönlendirmeyi algılayamıyor ve siyah ekran gösteriyor. Aynı zamanda, backend webhook veya status check çağrısı başarısız oluyor, bu yüzden Firestore güncellemesi gerçekleşmiyor.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type PaymentFlowEvent
  OUTPUT: boolean
  
  RETURN input.paymentStatus == 'success'
         AND input.moneyCharged == true
         AND (input.webViewState == 'black_screen' OR input.webViewState == 'frozen')
         AND input.firestoreUpdated == false
         AND input.jobIsUrgent == false
END FUNCTION
```

### Examples

- **Örnek 1**: İşveren 1 günlük acil ilan seçer, 1 AZN ödeme yapar, kart onaylanır, para çekilir → WebView siyah ekran gösterir, uygulama donuyor → Kullanıcı uygulamayı kapatıp tekrar açtığında ilan normal olarak paylaşılmış (acil değil)

- **Örnek 2**: İşveren 5 günlük acil ilan seçer, 3 AZN ödeme yapar, ödeme başarılı → WebView ClientHandler sayfasında takılıp kalıyor, kapanmıyor → Kullanıcı geri tuşuna basıyor, ilan listesine dönüyor → İlan normal olarak görünüyor, para çekilmiş ama acil özelliği yok

- **Örnek 3**: İşveren 10 günlük acil ilan seçer, 5 AZN ödeme yapar, Epoint success sayfasına yönlendiriyor → WebView siyah ekran, hiçbir şey olmuyor → Kullanıcı bekliyor ama hiçbir şey değişmiyor → Sonunda uygulamayı kapatıyor

- **Edge Case**: İşveren ödeme yapar, ağ bağlantısı kesilir → Ödeme başarılı ama webhook gelmez → checkPaymentStatus de çağrılamaz → İlan normal olarak kalır (beklenen davranış: retry mekanizması olmalı)

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Ödeme iptal edildiğinde (kullanıcı geri tuşuna bastığında) WebView kapanmalı ve "Ödəniş ləğv edildi" mesajı gösterilmeli
- Ödeme başarısız olduğunda (kart reddedildiğinde) error URL'e yönlendirme algılanmalı ve hata mesajı gösterilmeli
- Normal (acil olmayan) ilan oluşturma akışı hiç etkilenmemeli
- Webhook başarılı çalıştığında Firestore güncellemesi yapılmalı

**Scope:**
Acil ilan ödeme akışı dışındaki tüm işlemler tamamen etkilenmemeli. Bu şunları içerir:
- Normal ilan oluşturma
- İlan düzenleme (acil özelliği olmadan)
- Diğer ödeme gerektirmeyen işlemler
- Başarısız ödeme senaryoları (zaten çalışıyor)

## Hypothesized Root Cause

Bug açıklamasına ve kod analizine dayanarak, en olası sorunlar:

1. **WebView Navigation Delegate Mantık Hatası**: `PaymentWebViewScreen`'deki `onNavigationRequest` callback'i success URL'i doğru algılamıyor
   - Epoint, success durumunda `payment-success.html` veya `ClientHandler` sayfasına yönlendiriyor
   - Mevcut kod sadece URL içinde 'success' kelimesi arıyor ama ClientHandler sayfasında takılıp kalıyor
   - `onPageFinished` callback'i kullanılmıyor, sadece loglama yapılıyor
   - WebView kapanmadığı için siyah ekran oluşuyor

2. **Firestore Güncelleme Garantisi Yok**: Backend webhook veya checkPaymentStatus başarısız olduğunda retry mekanizması yok
   - Webhook `/api/urgentPaymentCallback` çağrılmıyor veya başarısız oluyor
   - `checkPaymentStatus` çağrısı 2 saniye bekliyor ama bu yeterli olmayabilir
   - Eğer her iki çağrı da başarısız olursa, Firestore hiç güncellenmiyor
   - Kullanıcıya "başarılı" mesajı gösteriliyor ama arka planda güncelleme olmamış

3. **Race Condition**: İlan oluşturma ve ödeme akışı arasında timing sorunu
   - İlan önce `isUrgent: false` ile oluşturuluyor
   - Sonra ödeme yapılıyor
   - Webhook veya checkPaymentStatus çağrısı geç gelirse, kullanıcı zaten ekrandan çıkmış olabilir
   - WebView kapanmadığı için checkPaymentStatus çağrısı hiç yapılmıyor

4. **WebView State Management**: WebView'in lifecycle yönetimi eksik
   - WebView dispose edilmiyor veya yanlış zamanda dispose ediliyor
   - Siyah ekran, WebView'in render edilemediği bir durumda olmasından kaynaklanıyor olabilir
   - JavaScript execution tamamlanmadan WebView kapatılmaya çalışılıyor olabilir

## Correctness Properties

Property 1: Bug Condition - Ödeme Başarılı Olduğunda WebView Düzgün Kapanmalı

_For any_ ödeme akışı girişi where ödeme başarılı olur (para çekilir) ve Epoint success URL'ine yönlendirir, düzeltilmiş PaymentWebViewScreen SHALL success URL'i algılamalı, WebView'i düzgün kapatmalı (siyah ekran olmadan), ve `true` sonucu döndürmeli.

**Validates: Requirements 2.1, 2.2, 2.5**

Property 2: Bug Condition - Ödeme Başarılı Olduğunda Firestore Güncellemesi Garanti Edilmeli

_For any_ ödeme akışı girişi where ödeme başarılı olur ve WebView başarıyla kapanır, düzeltilmiş kod SHALL Firestore'da ilgili job dokümanını `isUrgent: true` ve doğru `urgentUntil` timestamp ile güncellemeli, webhook başarısız olsa bile checkPaymentStatus fallback'i kullanarak.

**Validates: Requirements 2.4**

Property 3: Preservation - İptal ve Hata Durumları Korunmalı

_For any_ ödeme akışı girişi where ödeme iptal edilir veya başarısız olur (bug condition geçerli değil), düzeltilmiş kod SHALL mevcut davranışı korumalı: WebView `false` sonucu ile kapanmalı, uygun hata/iptal mesajı gösterilmeli, ve Firestore güncellemesi yapılmamalı.

**Validates: Requirements 3.1, 3.2, 3.3**

Property 4: Preservation - Normal İlan Oluşturma Etkilenmemeli

_For any_ ilan oluşturma girişi where acil ilan seçeneği seçilmemiş (bug condition geçerli değil), düzeltilmiş kod SHALL tamamen aynı davranışı göstermeli: ödeme akışı başlatılmamalı, ilan normal olarak oluşturulmalı, ve hiçbir ödeme işlemi yapılmamalı.

**Validates: Requirements 3.5**

## Fix Implementation

### Changes Required

Root cause analizimizin doğru olduğunu varsayarak:

**File**: `lib/features/jobs/presentation/pages/payment_webview_screen.dart`

**Function**: `_PaymentWebViewScreenState` class ve `initState` method

**Specific Changes**:

1. **WebView Navigation Logic İyileştirmesi**: `onNavigationRequest` callback'ini düzelt
   - Success URL pattern matching'i genişlet: `payment-success.html`, `success`, `pay-successful` kontrollerine ek olarak
   - ClientHandler sayfasını özel olarak ele al: Bu sayfa görüldüğünde hemen kapatma, 2-3 saniye bekle ve sonra success olarak değerlendir
   - `onPageFinished` callback'ini kullan: Sayfa yüklenmesi tamamlandığında URL'i tekrar kontrol et
   - Timeout mekanizması ekle: 30 saniye içinde success/error algılanmazsa kullanıcıya seçenek sun

2. **onPageFinished Callback Kullanımı**: Sayfa yükleme tamamlandığında ek kontrol
   - URL'de success pattern varsa WebView'i kapat
   - ClientHandler sayfasında 3 saniye kaldıysa otomatik success olarak değerlendir
   - Kullanıcıya loading indicator göster

3. **State Management İyileştirmesi**: WebView state'ini düzgün yönet
   - `_isProcessingPayment` flag'i ekle: Ödeme işlenirken duplicate navigation'ları önle
   - `_paymentCompleted` flag'i ekle: Bir kez success algılandıktan sonra tekrar işleme
   - Dispose method'unda WebView controller'ı düzgün temizle

4. **Error Handling**: Timeout ve beklenmeyen durumlar için
   - 30 saniye timeout ekle
   - Timeout durumunda kullanıcıya dialog göster: "Ödeme işleniyor, lütfen bekleyin" veya "Manuel kontrol gerekli"
   - Kullanıcıya "Ödeme durumunu kontrol et" butonu sun

**File**: `lib/features/jobs/presentation/pages/create_job_screen.dart`

**Function**: `_submitJob` method içindeki ödeme akışı

**Specific Changes**:

1. **checkPaymentStatus Retry Mekanizması**: Tek seferlik çağrı yerine retry logic ekle
   - İlk çağrı 2 saniye sonra
   - Başarısız olursa 5 saniye sonra tekrar dene
   - Maksimum 3 deneme yap
   - Her denemede Firestore'u kontrol et: Eğer zaten güncellenmiş ise (webhook çalıştı) durdur

2. **Firestore Güncelleme Doğrulaması**: checkPaymentStatus'tan sonra Firestore'u kontrol et
   - Job dokümanını oku
   - `isUrgent` field'ını kontrol et
   - Eğer hala `false` ise kullanıcıya uyarı göster: "Ödeme alındı ama işlem tamamlanmadı, destek ekibiyle iletişime geçin"

3. **Loading State İyileştirmesi**: Kullanıcıya daha iyi feedback
   - "Ödeme işleniyor..." loading dialog'u göster
   - WebView kapandıktan sonra "Ödeme doğrulanıyor..." mesajı göster
   - checkPaymentStatus çağrıları sırasında progress göster

4. **Error Recovery**: Ödeme başarılı ama güncelleme başarısız senaryosu için
   - Kullanıcıya "Ödemeniz alındı, ilan 24 saat içinde acil olarak işaretlenecek" mesajı göster
   - Backend'e notification gönder (opsiyonel): Admin'e manuel müdahale gerektiğini bildir
   - Transaction ID'yi kullanıcıya göster: Destek talebi için referans

**File**: `backend/index.js`

**Function**: `/api/checkPaymentStatus` endpoint

**Specific Changes**:

1. **Idempotency Garantisi**: Aynı ödeme için birden fazla çağrı yapılabilir, her seferinde aynı sonucu dön
   - Firestore'u güncellemeden önce kontrol et: Zaten güncellenmiş mi?
   - Eğer güncellenmiş ise sadece success dön, tekrar güncelleme yapma

2. **Logging İyileştirmesi**: Debug için daha detaylı log
   - Her checkPaymentStatus çağrısını logla: timestamp, orderId, transaction
   - Firestore güncelleme başarılı/başarısız durumunu logla
   - Webhook çağrısı geldiğinde de logla: Hangi çağrı önce geldi?

3. **Webhook Timeout Handling**: Webhook gelmezse ne olacak?
   - checkPaymentStatus çağrısı geldiğinde webhook'u beklemeden direkt Epoint API'ye sor
   - Epoint'ten success dönerse hemen Firestore'u güncelle
   - Webhook sonra gelirse duplicate güncelleme yapma (idempotency)

## Testing Strategy

### Validation Approach

Test stratejisi iki aşamalı: önce bug'ı göstermek için düzeltilmemiş kodda counterexample'lar bul, sonra düzeltmenin doğru çalıştığını ve mevcut davranışı koruduğunu doğrula.

### Exploratory Bug Condition Checking

**Goal**: Düzeltme yapmadan ÖNCE bug'ı gösteren counterexample'ları bul. Root cause analizini doğrula veya çürüt. Çürütürsek, yeniden hipotez kur.

**Test Plan**: Gerçek Epoint ödeme akışını simüle eden testler yaz. WebView navigation event'lerini mock'la ve success URL'e yönlendirme simüle et. Düzeltilmemiş kodda çalıştır ve başarısızlıkları gözlemle.

**Test Cases**:
1. **Success URL Navigation Test**: Epoint'in payment-success.html'e yönlendirmesini simüle et (düzeltilmemiş kodda başarısız olacak - WebView kapanmayacak)
2. **ClientHandler Stuck Test**: Epoint'in ClientHandler sayfasına yönlendirmesini simüle et ve orada kalmasını test et (düzeltilmemiş kodda başarısız olacak - siyah ekran)
3. **Firestore Update Failure Test**: Webhook başarısız olduğunda checkPaymentStatus'un çağrılıp çağrılmadığını test et (düzeltilmemiş kodda başarısız olacak - güncelleme olmayacak)
4. **Timeout Test**: 30 saniye boyunca hiçbir success/error URL'i gelmediğinde ne olduğunu test et (düzeltilmemiş kodda başarısız olacak - sonsuz bekleme)

**Expected Counterexamples**:
- WebView navigation delegate success URL'i algılamıyor, `Navigator.pop(context, true)` çağrılmıyor
- Olası nedenler: URL pattern matching eksik, onPageFinished kullanılmıyor, ClientHandler özel durumu ele alınmıyor

### Fix Checking

**Goal**: Bug condition geçerli olan tüm girdiler için, düzeltilmiş fonksiyonun beklenen davranışı ürettiğini doğrula.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := handlePaymentFlow_fixed(input)
  ASSERT result.webViewClosed == true
  ASSERT result.webViewState != 'black_screen'
  ASSERT result.firestoreUpdated == true
  ASSERT result.jobIsUrgent == true
END FOR
```

**Test Cases**:
1. **Success URL Detected**: payment-success.html'e yönlendirme → WebView kapanmalı, result=true
2. **ClientHandler Handled**: ClientHandler sayfası → 3 saniye bekle → WebView kapanmalı, result=true
3. **Firestore Updated**: Ödeme başarılı → checkPaymentStatus retry → Firestore `isUrgent: true`
4. **Timeout Recovery**: 30 saniye timeout → Kullanıcıya dialog → Manuel kontrol seçeneği

### Preservation Checking

**Goal**: Bug condition geçerli OLMAYAN tüm girdiler için, düzeltilmiş fonksiyonun orijinal fonksiyonla aynı sonucu ürettiğini doğrula.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT handlePaymentFlow_original(input) = handlePaymentFlow_fixed(input)
END FOR
```

**Testing Approach**: Property-based testing preservation checking için önerilir çünkü:
- Otomatik olarak input domain'inde birçok test case üretir
- Manuel unit testlerin kaçırabileceği edge case'leri yakalar
- Acil olmayan girdiler için davranışın değişmediğine dair güçlü garanti sağlar

**Test Plan**: Önce düzeltilmemiş kodda acil olmayan ilan oluşturma ve başarısız ödeme senaryolarını gözlemle, sonra bu davranışı yakalayan property-based testler yaz.

**Test Cases**:
1. **Payment Cancelled Preservation**: Kullanıcı geri tuşuna basıyor → WebView kapanmalı (result=false), "Ödəniş ləğv edildi" mesajı
2. **Payment Error Preservation**: Kart reddediliyor → error URL algılanmalı, WebView kapanmalı (result=false), hata mesajı
3. **Normal Job Creation Preservation**: Acil seçeneği seçilmemiş → Ödeme akışı başlamamalı, ilan normal oluşmalı
4. **Webhook Success Preservation**: Webhook başarılı çalışıyor → Firestore güncellemesi yapılmalı (mevcut davranış korunmalı)

### Unit Tests

- WebView navigation delegate'in success URL pattern'lerini doğru algıladığını test et
- ClientHandler sayfası algılandığında timeout logic'in çalıştığını test et
- checkPaymentStatus retry mekanizmasının doğru çalıştığını test et (1. deneme, 2. deneme, 3. deneme)
- Firestore güncelleme idempotency'sini test et (aynı ödeme için birden fazla güncelleme denemesi)
- Timeout durumunda kullanıcıya dialog gösterildiğini test et

### Property-Based Tests

- Rastgele ödeme durumları üret (success, error, cancelled, timeout) ve her durumda doğru davranışı doğrula
- Rastgele URL pattern'leri üret ve success/error algılamasının doğru çalıştığını doğrula
- Rastgele network delay'leri simüle et ve retry mekanizmasının çalıştığını doğrula
- Rastgele webhook/checkPaymentStatus sıralamaları test et (hangisi önce gelirse gelsin, sonuç aynı olmalı)

### Integration Tests

- Tam ödeme akışını test et: İlan oluştur → Acil seç → Ödeme yap → WebView aç → Success → WebView kapat → Firestore kontrol et
- Webhook ve checkPaymentStatus'un birlikte çalıştığını test et: Her ikisi de çağrıldığında duplicate güncelleme olmamalı
- Gerçek Epoint test ortamında end-to-end test yap (mümkünse)
- Kullanıcı akışını simüle et: Ödeme yap → Uygulama kapat → Tekrar aç → İlan acil olarak görünmeli
