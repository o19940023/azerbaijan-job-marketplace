import '../../../../core/services/remote_config_service.dart';

/// Configuration for Groq AI API
class ModelConfiguration {
  /// Groq API Key - Reads from Remote Config with local fallback
  static String get apiKey {
    final remoteKey = RemoteConfigService().groqApiKey;
    if (remoteKey.isNotEmpty) return remoteKey;
    return ''; // Secret removed for GitHub push protection
  }

  /// Default AI Model ID - Reads from Remote Config with local fallback
  static String get defaultModelId {
    final remoteId = RemoteConfigService().getAiModelId();
    if (remoteId.isNotEmpty) return remoteId;
    return 'llama-3.3-70b-versatile';
  }

  /// API Base URL - Reads from Remote Config with local fallback
  static String get baseUrl {
    final remoteUrl = RemoteConfigService().getAiBaseUrl();
    if (remoteUrl.isNotEmpty) return remoteUrl;
    return 'https://api.groq.com/openai/v1/chat/completions';
  }

  /// Timeout for API requests in seconds
  static const int timeoutSeconds = 30;

  /// Maximum number of messages to keep in conversation history
  static const int maxConversationMessages = 20;

  /// Default temperature for model responses
  static const double defaultTemperature = 0.7;

  /// Default maximum tokens
  static const int defaultMaxTokens = 4096;
}
