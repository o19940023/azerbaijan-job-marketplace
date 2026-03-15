# İşTap - Azərbaycan İş Bazarı

Azerbaycan pazarına özel, mavi yakalı işçiler ve işverenler için iş bulma ve işe alım platformu.

## 🚀 Özellikler

- ✅ Kullanıcı kaydı ve kimlik doğrulama
- ✅ İş arayan ve işveren profilleri
- ✅ İş ilanı oluşturma ve yönetimi
- ✅ İş arama ve filtreleme
- ✅ Başvuru yönetimi
- ✅ Anlık mesajlaşma
- ✅ Hizmet pazarı
- ✅ Konum tabanlı arama
- ✅ Bildirim sistemi
- ✅ Azerbaycan Türkçesi desteği

## 📱 Teknoloji Stack

- **Framework**: Flutter 3.x
- **Dil**: Dart 3.x
- **State Management**: BLoC Pattern
- **Mimari**: Clean Architecture
- **Networking**: Dio
- **Local Storage**: Hive, Shared Preferences, Secure Storage
- **Real-time**: Socket.IO
- **Maps**: Google Maps
- **Firebase**: Cloud Messaging, Crashlytics

## 🏗️ Proje Yapısı

```
lib/
├── core/                    # Temel altyapı
│   ├── constants/          # Sabitler
│   ├── errors/             # Hata yönetimi
│   ├── network/            # Network katmanı
│   ├── theme/              # Tema ve stil
│   ├── utils/              # Yardımcı fonksiyonlar
│   └── widgets/            # Ortak widget'lar
├── features/               # Özellikler (Clean Architecture)
│   ├── auth/              # Kimlik doğrulama
│   │   ├── data/          # Veri katmanı
│   │   ├── domain/        # İş mantığı katmanı
│   │   └── presentation/  # UI katmanı
│   ├── profile/           # Profil yönetimi
│   ├── jobs/              # İş ilanları
│   ├── applications/      # Başvurular
│   ├── messaging/         # Mesajlaşma
│   ├── services/          # Hizmet pazarı
│   ├── reviews/           # Değerlendirmeler
│   ├── notifications/     # Bildirimler
│   ├── analytics/         # Analitik
│   └── moderation/        # İçerik moderasyonu
├── injection_container.dart # Dependency Injection
└── main.dart               # Uygulama giriş noktası
```

## 🛠️ Kurulum

### Gereksinimler

- Flutter SDK (3.x veya üzeri)
- Dart SDK (3.x veya üzeri)
- Android Studio / VS Code
- Android SDK (Android için)
- Xcode (iOS için)

### Adımlar

1. Projeyi klonlayın:
```bash
git clone <repository-url>
cd azerbaijan_job_marketplace
```

2. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

3. Uygulamayı çalıştırın:
```bash
flutter run
```

## 📝 Geliştirme

### Kod Oluşturma

JSON serialization ve diğer kod oluşturma işlemleri için:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Test

```bash
# Tüm testleri çalıştır
flutter test

# Coverage raporu
flutter test --coverage
```

### Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 🌍 Yerelleştirme

Uygulama Azerbaycan Türkçesi dilinde geliştirilmiştir. Gelecekte Rusça ve İngilizce dil desteği eklenecektir.

## 📄 Lisans

Bu proje özel bir projedir ve telif hakkı koruması altındadır.

## 👥 Ekip

- Geliştirici: [İsim]
- Tasarımcı: [İsim]
- Proje Yöneticisi: [İsim]

## 📞 İletişim

Sorularınız için: [email@example.com]
