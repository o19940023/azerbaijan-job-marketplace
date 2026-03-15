# Codemagic CI/CD Kurulum Rehberi - Azerbaijan Job Marketplace

## 📋 Gerekli Dosyalar ve Bilgiler

### Android İçin Gerekli:
1. ✅ **Keystore dosyası**: `android/app/upload-keystore.jks` (MEVCUT)
2. ✅ **key.properties**: `android/key.properties` (MEVCUT)
3. ⚠️ **Google Play Service Account JSON** (OLUŞTURULMALI)

### iOS İçin Gerekli:
1. ⚠️ **Apple Developer Account** (Ücretli - $99/yıl)
2. ⚠️ **App Store Connect API Key** (OLUŞTURULMALI)
3. ⚠️ **Provisioning Profiles ve Certificates** (Codemagic otomatik oluşturabilir)

### Environment Variables:
1. ✅ `AZURE_TTS_API_KEY`: Azure TTS API anahtarı
2. ✅ `GITHUB_API_KEY`: GitHub AI model API anahtarı
3. ⚠️ `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`: Google Play JSON (OLUŞTURULMALI)

---

## 🔧 ADIM 1: Google Play Service Account Oluşturma

### 1.1 Google Cloud Console'da Service Account Oluştur

1. **Google Cloud Console'a git**: https://console.cloud.google.com/
2. **Proje seç** veya yeni proje oluştur
3. **IAM & Admin** → **Service Accounts** → **Create Service Account**
4. **Service account details**:
   - Name: `codemagic-publisher`
   - Description: `Service account for Codemagic CI/CD`
   - **CREATE** butonuna tıkla

5. **Grant this service account access to project**:
   - Role: `Service Account User`
   - **CONTINUE** → **DONE**

6. **Service account email'i kopyala** (örnek: `codemagic-publisher@project-id.iam.gserviceaccount.com`)

7. **Keys oluştur**:
   - Service account listesinde oluşturduğun hesabı bul
   - **Actions** (3 nokta) → **Manage keys**
   - **ADD KEY** → **Create new key**
   - **Key type**: JSON seç
   - **CREATE** → JSON dosyası indirilecek
   - ⚠️ **Bu dosyayı güvenli bir yerde sakla!**

### 1.2 Google Play Console'da İzinleri Ayarla

1. **Google Play Console'a git**: https://play.google.com/console/
2. **Users and permissions** → **Invite new users**
3. **Email address**: Service account email'ini yapıştır (adım 1.1.6)
4. **App permissions**:
   - Uygulamanı seç: `İş Tap` (com.is.tap)
   - **Releases** bölümünü işaretle:
     - ✅ View app information
     - ✅ Create and edit draft releases
     - ✅ Release to production, exclude devices, and use Play App Signing
     - ✅ Release to testing tracks
     - ✅ Manage testing tracks and edit tester lists
5. **Account permissions**: Hiçbir şey seçme (Admin yetkisi VERME!)
6. **Invite user** butonuna tıkla

### 1.3 İlk Sürümü Manuel Yükle (ÖNEMLİ!)

⚠️ **Google Play'e ilk yükleme manuel yapılmalı!**

1. Yerel bilgisayarında AAB dosyasını bul:
   ```
   azerbaijan_job_marketplace/build/app/outputs/bundle/release/app-release.aab
   ```

2. **Google Play Console** → **İş Tap** uygulaması → **Production** → **Create new release**
3. AAB dosyasını yükle
4. Release notes ekle
5. **Review release** → **Start rollout to Production**

---

## 🔧 ADIM 2: Codemagic'e Kayıt ve Repository Bağlama

### 2.1 Codemagic Hesabı Oluştur

1. https://codemagic.io/start/ adresine git
2. **Sign up with GitHub** ile giriş yap
3. GitHub'da Codemagic'e izin ver

### 2.2 Repository'yi Ekle

1. Codemagic dashboard'da **Apps** → **Add application**
2. **Connect repository** → **GitHub** seç
3. Repository listesinde `o19940023/azerbaijan-job-marketplace` seç
4. **Select project type**: **Flutter** seç
5. **Finish: Add application**

### 2.3 codemagic.yaml Dosyasını Tanıt

1. Repository eklendikten sonra **Check for configuration file** butonuna tıkla
2. Codemagic `codemagic.yaml` dosyasını otomatik bulacak

---

## 🔧 ADIM 3: Android Signing Ayarları

### 3.1 Keystore Dosyasını Yükle

1. **Team settings** (sol menü) → **Code signing identities**
2. **Android keystores** tab'ına git
3. **Upload keystore**:
   - Dosya: `android/app/upload-keystore.jks` yükle
   - **Keystore password**: `istap2024`
   - **Key alias**: `upload`
   - **Key password**: `istap2024`
   - **Reference name**: `keystore_reference` (codemagic.yaml'da kullanılacak)
4. **Add keystore** butonuna tıkla

### 3.2 key.properties Dosyasını Kontrol Et

Yerel dosyan zaten doğru yapılandırılmış:
```properties
storePassword=istap2024
keyPassword=istap2024
keyAlias=upload
storeFile=upload-keystore.jks
```

---

## 🔧 ADIM 4: Environment Variables Ayarları

### 4.1 Variable Group Oluştur

1. **App settings** → **Environment variables** tab
2. **Add new group**: `app_credentials`

### 4.2 Azure TTS API Key Ekle

1. **Variable name**: `AZURE_TTS_API_KEY`
2. **Variable value**: [Azure TTS API anahtarınızı buraya girin]
3. **Group**: `app_credentials` seç
4. ✅ **Secure** işaretle
5. **Add** butonuna tıkla

### 4.3 GitHub API Key Ekle

1. **Variable name**: `GITHUB_API_KEY`
2. **Variable value**: [GitHub AI API anahtarınız]
3. **Group**: `app_credentials` seç
4. ✅ **Secure** işaretle
5. **Add** butonuna tıkla

### 4.4 Google Play Service Account JSON Ekle

1. **Variable name**: `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`
2. **Variable value**: Adım 1.1.7'de indirdiğin JSON dosyasının içeriğini kopyala-yapıştır
3. **Group**: `app_credentials` seç
4. ✅ **Secure** işaretle
5. **Add** butonuna tıkla

---

## 🔧 ADIM 5: iOS Ayarları (Opsiyonel - Şimdilik Atlanabilir)

iOS için Apple Developer Program üyeliği gerekli ($99/yıl). Şimdilik sadece Android'e odaklanabilirsiniz.

### iOS için gerekli adımlar (gelecekte):
1. Apple Developer hesabı oluştur
2. App Store Connect API Key oluştur
3. Codemagic'te iOS code signing ayarla
4. Provisioning profiles yapılandır

---

## 🔧 ADIM 6: codemagic.yaml Dosyasını Güncelle

Mevcut `codemagic.yaml` dosyası zaten hazır, sadece birkaç değişiklik yapmalıyız:


### 6.1 Android Workflow'u Kontrol Et

```yaml
workflows:
  android-workflow:
    name: Android Workflow
    max_build_duration: 120
    instance_type: mac_mini_m1
    environment:
      android_signing:
        - keystore_reference  # Adım 3.1'de verdiğin reference name
      groups:
        - app_credentials  # Adım 4.1'de oluşturduğun group
      vars:
        PACKAGE_NAME: "com.is.tap"
      flutter: stable
```

### 6.2 Publishing Ayarlarını Kontrol Et

```yaml
publishing:
  google_play:
    credentials: $GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
    track: internal  # veya: alpha, beta, production
    submit_as_draft: true  # İlk testler için draft olarak yükle
```

---

## 🚀 ADIM 7: İlk Build'i Başlat

### 7.1 Build Başlat

1. **App settings** → **Start new build**
2. **Workflow**: `android-workflow` seç
3. **Branch**: `main` seç
4. **Start new build** butonuna tıkla

### 7.2 Build Sürecini İzle

Build süreci yaklaşık 10-15 dakika sürer:
1. ✅ Clone repository
2. ✅ Set up environment
3. ✅ Get Flutter packages
4. ✅ Flutter analyze
5. ✅ Build AAB
6. ✅ Sign AAB
7. ✅ Upload to Google Play (internal track)

### 7.3 Build Sonuçlarını Kontrol Et

Build tamamlandığında:
- ✅ **Artifacts** bölümünde `app-release.aab` dosyasını göreceksin
- ✅ **Publishing** bölümünde Google Play yükleme durumunu göreceksin
- ✅ Email ile bildirim alacaksın

---

## 🔍 ADIM 8: Olası Hatalar ve Çözümleri

### Hata 1: "Keystore not found"
**Çözüm**: Adım 3.1'i tekrar kontrol et, reference name'in `codemagic.yaml`'daki ile aynı olduğundan emin ol.

### Hata 2: "Google Play API error"
**Çözüm**: 
- Service account'un doğru izinlere sahip olduğunu kontrol et (Adım 1.2)
- JSON dosyasının doğru kopyalandığını kontrol et (Adım 4.4)

### Hata 3: "Version code must be greater than previous"
**Çözüm**: `pubspec.yaml`'daki version'ı artır:
```yaml
version: 1.0.1+2  # +2 kısmı version code
```

### Hata 4: "Flutter analyze failed"
**Çözüm**: Yerel olarak `flutter analyze` çalıştır ve hataları düzelt.

---

## 📝 ADIM 9: Otomatik Build Trigger Ayarları

### 9.1 Automatic Build Triggering

1. **App settings** → **Build triggers**
2. **Trigger on push**: ✅ İşaretle
3. **Watched branch patterns**: `main` ekle
4. **Trigger on pull request update**: İsteğe bağlı

Artık `main` branch'e her push yaptığında otomatik build başlayacak!

---

## ✅ Kurulum Tamamlandı!

### Sonraki Adımlar:

1. **Test Build**: İlk build'i başlat ve sonuçları kontrol et
2. **Internal Testing**: Google Play Console'da internal test grubu oluştur
3. **Beta Testing**: Beta track'e yükle ve test kullanıcıları ekle
4. **Production**: Her şey hazır olduğunda production'a yükle

### Faydalı Linkler:

- Codemagic Dashboard: https://codemagic.io/apps
- Google Play Console: https://play.google.com/console/
- Codemagic Docs: https://docs.codemagic.io/

---

## 🎯 Özet Checklist

- [ ] Google Play Service Account oluşturuldu
- [ ] Service Account JSON dosyası indirildi
- [ ] Google Play Console'da izinler verildi
- [ ] İlk AAB manuel olarak yüklendi
- [ ] Codemagic hesabı oluşturuldu
- [ ] Repository bağlandı
- [ ] Keystore yüklendi
- [ ] Environment variables eklendi
- [ ] codemagic.yaml kontrol edildi
- [ ] İlk build başlatıldı
- [ ] Build başarılı oldu
- [ ] AAB Google Play'e yüklendi

**Tüm adımlar tamamlandığında, uygulamanız otomatik olarak build edilip Google Play'e yüklenecek!** 🚀
