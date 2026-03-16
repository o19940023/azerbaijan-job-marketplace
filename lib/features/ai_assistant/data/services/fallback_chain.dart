import 'dart:developer' as developer;
import '../config/model_configuration.dart';
import '../models/model_selection.dart';

/// Service responsible for managing fallback model sequences and error handling
/// Provides ordered fallback chains for each task type and determines retry logic
class FallbackChain {
  final ModelConfiguration _config;

  /// Creates a FallbackChain with the given configuration
  /// If no configuration is provided, uses default ModelConfiguration
  FallbackChain({ModelConfiguration? config})
      : _config = config ?? ModelConfiguration();

  /// Returns ordered list of fallback models for a task type
  /// Each chain contains at least 3 models (1 primary + 2 fallbacks)
  /// Requirement 4.1: Fallback chain depth
  List<String> getFallbackModels(TaskType taskType) {
    final Map<TaskType, List<String>> fallbackChains = {
      TaskType.profileUpdate: [
        'google/gemini-flash-1.5-8b', // Primary: agentic workflows
        '01-ai/yi-lightning', // Fallback 1: reasoning
        'openai/gpt-4o-mini', // Fallback 2: conversational
        'mistralai/mistral-small', // Fallback 3: creative
      ],
      TaskType.jobSearch: [
        '01-ai/yi-lightning', // Primary: reasoning
        'google/gemini-flash-1.5-8b', // Fallback 1: agentic workflows
        'openai/gpt-4o-mini', // Fallback 2: conversational
        'mistralai/mistral-small', // Fallback 3: creative
      ],
      TaskType.conversational: [
        'openai/gpt-4o-mini', // Primary: conversational
        'google/gemini-flash-1.5-8b', // Fallback 1: fast
        '01-ai/yi-lightning', // Fallback 2: reasoning
        'mistralai/mistral-small', // Fallback 3: creative
      ],
      TaskType.creative: [
        'mistralai/mistral-small', // Primary: creative writing
        'openai/gpt-4o-mini', // Fallback 1: conversational
        'google/gemini-flash-1.5-8b', // Fallback 2: agentic workflows
        '01-ai/yi-lightning', // Fallback 3: reasoning
      ],
    };

    return fallbackChains[taskType] ?? [];
  }

  /// Determines if error code should trigger fallback
  /// Requirements 4.3, 4.4, 4.5: Immediate fallback on specific errors
  /// 
  /// Returns true for:
  /// - 401 (Authentication error)
  /// - 429 (Rate limit error)
  /// - 400 with "content_filter" in response body
  bool shouldRetry(int statusCode, String responseBody) {
    // Requirement 4.3: 401 authentication error
    if (statusCode == 401) {
      developer.log(
        'Authentication error (401) - triggering fallback',
        name: 'FallbackChain',
        level: 900, // Warning level
      );
      return true;
    }

    // Requirement 4.4: 429 rate limit error
    if (statusCode == 429) {
      developer.log(
        'Rate limit error (429) - triggering fallback',
        name: 'FallbackChain',
        level: 900, // Warning level
      );
      return true;
    }

    // Requirement 4.5: 400 with content_filter
    if (statusCode == 400 && responseBody.toLowerCase().contains('content_filter')) {
      developer.log(
        'Content filter error (400) - triggering fallback',
        name: 'FallbackChain',
        level: 900, // Warning level
      );
      return true;
    }

    // For other errors, also trigger fallback
    if (statusCode >= 400) {
      developer.log(
        'Error $statusCode - triggering fallback',
        name: 'FallbackChain',
        level: 900, // Warning level
      );
      return true;
    }

    return false;
  }

  /// Returns localized error message for user display in Azerbaijani
  /// Requirements 4.6, 5.1, 5.2, 5.3, 5.4: Localized error messages
  /// 
  /// Error messages are user-friendly and do not expose technical details
  String getUserErrorMessage(int statusCode) {
    switch (statusCode) {
      case 401:
        // Requirement 5.1: Authentication error message
        return 'API açarı problemi. Zəhmət olmasa, tətbiq tərtibatçısı ilə əlaqə saxlayın.';

      case 429:
        // Requirement 5.2: Rate limit error message
        return 'Hazırda çox sayda sorğu var. Bir neçə dəqiqə sonra yenidən cəhd edin.';

      case 408:
      case 504:
        // Requirement 5.3: Network timeout error message
        return 'İnternet bağlantısı problemi. Zəhmət olmasa, bağlantınızı yoxlayın.';

      case 400:
      case 500:
      case 502:
      case 503:
        // Generic error for server issues
        // Requirement 5.4: No technical details exposed
        return 'Bağışlayın, hazırda AI xidməti müvəqqəti əlçatmazdır. Bir az sonra yenidən cəhd edin.';

      default:
        // Requirement 5.4: Generic error message for unexpected errors
        return 'Bağışlayın, bir xəta baş verdi. Zəhmət olmasa, yenidən cəhd edin.';
    }
  }

  /// Returns error message when all models in fallback chain fail
  /// Requirement 4.6: Final error message in Azerbaijani
  String getAllModelsFailedMessage() {
    return 'Bağışlayın, hazırda AI xidməti müvəqqəti əlçatmazdır. Bir az sonra yenidən cəhd edin.';
  }

  /// Logs fallback event with details
  /// Requirement 4.7: Fallback event logging
  void logFallbackEvent({
    required String failedModelId,
    required String fallbackModelId,
    required int statusCode,
    String? errorMessage,
  }) {
    developer.log(
      'Fallback triggered: $failedModelId (status: $statusCode) -> $fallbackModelId',
      name: 'FallbackChain',
      level: 900, // Warning level
      error: errorMessage,
    );
  }

  /// Logs when all models in the fallback chain have been exhausted
  /// Requirement 4.7: Fallback event logging
  void logAllModelsExhausted({
    required TaskType taskType,
    required List<String> attemptedModels,
  }) {
    developer.log(
      'All models exhausted for task type: $taskType. '
      'Attempted models: ${attemptedModels.join(", ")}',
      name: 'FallbackChain',
      level: 1000, // Error level
    );
  }

  /// Validates that a fallback chain has sufficient depth
  /// Returns true if chain has at least 3 models
  /// Requirement 4.1: Fallback chain depth validation
  bool validateChainDepth(List<String> chain) {
    return chain.length >= 3;
  }

  /// Gets the next model in the fallback chain
  /// Returns null if no more fallback models available
  String? getNextFallbackModel(
    List<String> fallbackChain,
    String currentModelId,
  ) {
    final currentIndex = fallbackChain.indexOf(currentModelId);
    
    if (currentIndex == -1 || currentIndex >= fallbackChain.length - 1) {
      return null;
    }

    return fallbackChain[currentIndex + 1];
  }
}
