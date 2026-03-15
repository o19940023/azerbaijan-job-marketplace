# Azerbaijan Job Marketplace

A Flutter-based job marketplace application for Azerbaijan with AI assistant features.

## Features

- 🤖 AI Assistant with Azure TTS (Azerbaijani voice)
- 🎤 Voice recognition for Azerbaijani language
- 💼 Job posting and search
- 👤 User authentication (Job Seeker / Employer)
- 📱 Modern UI with professional animations
- 🌐 Firebase backend integration

## Setup

### Prerequisites

- Flutter SDK (latest stable version)
- Firebase account
- Azure Cognitive Services account (for TTS)
- GitHub API key (for AI features)

### Environment Variables

1. Copy `.env.example` to `.env`
2. Fill in your API keys:
   - `AZURE_TTS_API_KEY`: Your Azure Cognitive Services API key
   - `AZURE_TTS_REGION`: Your Azure region (default: eastus)
   - `GITHUB_API_KEY`: Your GitHub API key for AI models

### Build Commands

**Android (AAB for Play Store):**
```bash
flutter build appbundle --release --dart-define=AZURE_TTS_API_KEY=your_key --dart-define=GITHUB_API_KEY=your_key
```

**Android (APK for testing):**
```bash
flutter build apk --release --dart-define=AZURE_TTS_API_KEY=your_key --dart-define=GITHUB_API_KEY=your_key
```

**iOS:**
```bash
flutter build ios --release --dart-define=AZURE_TTS_API_KEY=your_key --dart-define=GITHUB_API_KEY=your_key
```

## Codemagic CI/CD

This project is configured for Codemagic. Add your environment variables in Codemagic settings:
- `AZURE_TTS_API_KEY`
- `GITHUB_API_KEY`

## License

All rights reserved.
