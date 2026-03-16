import '../models/model_metadata.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/services/remote_config_service.dart';

/// Configuration for OpenRouter API and available AI models
class ModelConfiguration {
  // API Configuration
  /// API base URL - Automatically detected based on API Key or Model
  static String get baseUrl {
    // 1. Prioritize manual override from Remote Config (if provided)
    final remoteBaseUrl = RemoteConfigService().getAiBaseUrl();
    if (remoteBaseUrl.isNotEmpty) {
      return remoteBaseUrl;
    }

    // 2. Auto-detect Groq Key (starts with "gsk_")
    if (apiKey.startsWith('gsk_')) {
      return 'https://api.groq.com/openai/v1/chat/completions';
    }

    // 3. Auto-detect Google Gemini (starts with "AIza")
    // Note: Gemini uses a different API structure, so this is just a placeholder logic.
    // Usually OpenRouter handles Gemini models via standard interface.
    
    // 4. Default to OpenRouter
    return 'https://openrouter.ai/api/v1/chat/completions';
  }

  /// OpenRouter API key
  /// Priority: Remote Config > .env
  static String get apiKey {
    final remoteKey = RemoteConfigService().openRouterApiKey;
    if (remoteKey.isNotEmpty) {
      return remoteKey;
    }
    return dotenv.env['OPENROUTER_API_KEY'] ?? '';
  }

  /// Default AI Model ID
  /// Priority: Remote Config > Default Constant
  static String get defaultModelId {
    final remoteId = RemoteConfigService().getAiModelId();
    if (remoteId.isNotEmpty) {
      return remoteId;
    }
    return 'google/gemini-flash-1.5-8b';
  }


  /// Application referer for API requests
  static const String appReferer = 'https://azerbaijan-job-marketplace.app';

  /// Application title for API requests
  static const String appTitle = 'Azerbaijan Job Marketplace';

  // Request Configuration
  /// Timeout for API requests in seconds
  static const int timeoutSeconds = 30;

  /// Maximum number of messages to keep in conversation history
  static const int maxConversationMessages = 20;

  /// Default temperature for model responses (0.0 - 1.0)
  static const double defaultTemperature = 0.7;

  /// Default maximum tokens for model responses
  static const int defaultMaxTokens = 2048;

  // Model Definitions
  /// Map of model keys to their metadata
  final Map<String, ModelMetadata> models;

  /// Creates a ModelConfiguration with initialized models
  ModelConfiguration() : models = _initializeModels();

  /// Initializes all available models with their metadata
  static Map<String, ModelMetadata> _initializeModels() {
    // Dynamic default model from Remote Config
    final dynamicDefaultModelId = defaultModelId;
    final dynamicDefaultModelName = RemoteConfigService().getAiModelName();

    return {
      'default': ModelMetadata(
        id: dynamicDefaultModelId,
        name: dynamicDefaultModelName.isNotEmpty ? dynamicDefaultModelName : 'Default AI Model',
        tokenLimit: 1000000,
        costPerMillionInputTokens: 0.0,
        costPerMillionOutputTokens: 0.0,
        strengths: ['versatile', 'remote-config'],
      ),
      'yi-lightning': const ModelMetadata(
        id: '01-ai/yi-lightning',
        name: 'Z.ai GLM 4.7',
        tokenLimit: 1000000,
        costPerMillionInputTokens: 0.0,
        costPerMillionOutputTokens: 0.0,
        strengths: ['reasoning', 'high-token-limit'],
      ),
      'gemini-flash': const ModelMetadata(
        id: 'google/gemini-flash-1.5-8b',
        name: 'Google Gemini 3 Flash Preview',
        tokenLimit: 1000000,
        costPerMillionInputTokens: 0.0375,
        costPerMillionOutputTokens: 0.15,
        strengths: ['agentic-workflows', 'fast'],
      ),
      'mistral-small': const ModelMetadata(
        id: 'mistralai/mistral-small',
        name: 'Mistral Small Creative',
        tokenLimit: 32000,
        costPerMillionInputTokens: 0.2,
        costPerMillionOutputTokens: 0.6,
        strengths: ['creative-writing', 'programming'],
      ),
      'gpt-4o-mini': const ModelMetadata(
        id: 'openai/gpt-4o-mini',
        name: 'OpenAI GPT-4o-mini',
        tokenLimit: 128000,
        costPerMillionInputTokens: 0.15,
        costPerMillionOutputTokens: 0.6,
        strengths: ['conversational', 'fast'],
      ),
    };
  }

  /// Gets model metadata by key
  /// Throws [ArgumentError] if model key is not found
  ModelMetadata getModel(String key) {
    final model = models[key];
    if (model == null) {
      throw ArgumentError('Model not found: $key. Available models: ${models.keys.join(", ")}');
    }
    return model;
  }

  /// Gets model metadata by full model ID
  /// Returns null if not found
  ModelMetadata? getModelById(String id) {
    return models.values.firstWhere(
      (model) => model.id == id,
      orElse: () => throw ArgumentError('Model ID not found: $id'),
    );
  }

  /// Validates that the API key is configured
  /// Throws [StateError] if API key is empty
  static void validateApiKey() {
    if (apiKey.isEmpty) {
      throw StateError('OpenRouter API key is not configured');
    }
  }

  /// Gets all available model IDs
  List<String> get allModelIds => models.values.map((m) => m.id).toList();

  /// Gets all available model keys
  List<String> get allModelKeys => models.keys.toList();

  @override
  String toString() {
    return 'ModelConfiguration(models: ${models.length}, '
        'timeout: ${timeoutSeconds}s, maxMessages: $maxConversationMessages)';
  }
}
