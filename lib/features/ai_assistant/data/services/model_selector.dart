import 'dart:developer' as developer;
import '../config/model_configuration.dart';
import '../models/model_metadata.dart';
import '../models/model_selection.dart';

/// Service responsible for selecting the optimal AI model based on task type
/// and cost considerations
class ModelSelector {
  final ModelConfiguration _config;
  final Map<String, String> _selectionCache = {};

  /// Creates a ModelSelector with the given configuration
  /// If no configuration is provided, uses default ModelConfiguration
  ModelSelector({ModelConfiguration? config})
      : _config = config ?? ModelConfiguration();

  /// Selects the best model for the given user message
  /// Returns a ModelSelection with the chosen model, reason, and fallback chain
  ///
  /// The selection process:
  /// 1. Analyzes the message to determine task type
  /// 2. Selects primary model based on task type and model strengths
  /// 3. Considers cost when multiple models have similar capabilities
  /// 4. Builds fallback chain for reliability
  /// 5. Caches the selection for performance
  ModelSelection selectModel(String userMessage) {
    // Check cache first for performance (Requirement 10.4)
    final cacheKey = _getCacheKey(userMessage);
    final cachedModelId = _selectionCache[cacheKey];
    
    if (cachedModelId != null) {
      developer.log(
        'Using cached model selection: $cachedModelId',
        name: 'ModelSelector',
      );
      return _buildSelection(cachedModelId, 'Cached selection', userMessage);
    }

    // If provider is Groq (gsk_ key), force using Remote Config model ID
    // This prevents sending OpenRouter-specific model IDs to Groq API
    if (ModelConfiguration.apiKey.startsWith('gsk_')) {
      var overrideId = ModelConfiguration.defaultModelId;
      
      // Safety check: if model ID looks like non-Groq (e.g. google/openai), force a Groq model
      // This handles cases where Remote Config might fail or return default OpenRouter model
      if (overrideId.contains('google/') || 
          overrideId.contains('openai/') || 
          overrideId.contains('mistralai/') || 
          overrideId.contains('anthropic/')) {
        developer.log(
          'Detected non-Groq model ID ($overrideId) with Groq Key. Forcing llama3-70b-8192',
          name: 'ModelSelector',
        );
        overrideId = 'llama3-70b-8192';
      }

      developer.log(
        'Provider detected: Groq (gsk_ key). Using model: $overrideId',
        name: 'ModelSelector',
      );
      
      final selection = ModelSelection(
        modelId: overrideId,
        reason: 'Groq provider detected - using configured model (no fallbacks)',
        fallbackModels: [], // No fallbacks for Groq as they require different API keys
      );
      
      _selectionCache[cacheKey] = selection.modelId;
      return selection;
    }

    // Analyze task type
    final taskType = _analyzeTask(userMessage);
    
    // Select model based on task type
    final selection = _selectModelForTask(taskType, userMessage);
    
    // Cache the selection
    _selectionCache[cacheKey] = selection.modelId;
    
    // Log selection (Requirement 3.5)
    developer.log(
      'Selected model: ${_config.getModelById(selection.modelId)?.name} '
      '(${selection.modelId}) - Reason: ${selection.reason}',
      name: 'ModelSelector',
    );
    
    return selection;
  }

  /// Analyzes the user message to determine the task type
  /// Returns the detected TaskType
  TaskType _analyzeTask(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    // Profile update detection (Requirement 3.1)
    // Look for profile-related keywords in Azerbaijani and English
    if (_containsAny(lowerMessage, [
      'profil',
      'profile',
      'doldur',
      'fill',
      'yaxşılaşdır',
      'improve',
      'yenilə',
      'update',
      'düzəlt',
      'edit',
      'məlumat',
      'information',
      '[profile_update]',
    ])) {
      return TaskType.profileUpdate;
    }

    // Job search detection (Requirement 3.2)
    // Look for job search keywords in Azerbaijani and English
    if (_containsAny(lowerMessage, [
      'iş tap',
      'find job',
      'iş axtar',
      'search job',
      'vakansiya',
      'vacancy',
      'iş elanı',
      'job posting',
      'işə qəbul',
      'hiring',
      '[job_search]',
      'developer',
      'mühendis',
      'engineer',
    ])) {
      return TaskType.jobSearch;
    }

    // Creative content detection (Requirement 3.4)
    // Look for creative writing keywords
    if (_containsAny(lowerMessage, [
      'yaz',
      'write',
      'yarat',
      'create',
      'hazırla',
      'prepare',
      'cv',
      'resume',
      'bio',
      'məktub',
      'letter',
      'təsvir',
      'description',
    ])) {
      return TaskType.creative;
    }

    // Default to conversational (Requirement 3.3)
    return TaskType.conversational;
  }

  /// Selects the optimal model for the given task type
  ModelSelection _selectModelForTask(TaskType taskType, String userMessage) {
    switch (taskType) {
      case TaskType.profileUpdate:
        // Requirement 3.1: Profile updates need agentic workflow capabilities
        return _buildSelection(
          'google/gemini-flash-1.5-8b',
          'Profile update detected - using model with agentic workflow capabilities',
          userMessage,
        );

      case TaskType.jobSearch:
        // Requirement 3.2: Job search needs strong reasoning and high token limit
        return _buildSelection(
          '01-ai/yi-lightning',
          'Job search query detected - using model with strong reasoning and high token limit',
          userMessage,
        );

      case TaskType.conversational:
        // Requirement 3.3: Conversational needs fast response
        return _buildSelection(
          'openai/gpt-4o-mini',
          'Conversational query detected - using fast conversational model',
          userMessage,
        );

      case TaskType.creative:
        // Requirement 3.4: Creative content needs creative writing capabilities
        return _buildSelection(
          'mistralai/mistral-small',
          'Creative content request detected - using model with creative writing capabilities',
          userMessage,
        );
    }
  }

  /// Builds a ModelSelection with the given model ID and reason
  /// Includes fallback models based on task type
  ModelSelection _buildSelection(
    String modelId,
    String reason,
    String userMessage,
  ) {
    final taskType = _analyzeTask(userMessage);
    final fallbackModels = _getFallbackModels(modelId, taskType);

    return ModelSelection(
      modelId: modelId,
      reason: reason,
      fallbackModels: fallbackModels,
    );
  }

  /// Gets fallback models for the given primary model and task type
  /// Returns a list of model IDs to try if the primary fails
  /// Ensures at least 2 fallback models (Requirement 4.1)
  List<String> _getFallbackModels(String primaryModelId, TaskType taskType) {
    // For Groq provider, avoid OpenRouter-specific fallbacks to prevent mismatched requests
    if (ModelConfiguration.baseUrl.contains('groq')) {
      return [];
    }
    // Define fallback chains based on task type
    // Each chain has primary + at least 2 fallbacks
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

    final chain = fallbackChains[taskType] ?? [];
    
    // Remove the primary model from the chain and return the rest as fallbacks
    return chain.where((id) => id != primaryModelId).toList();
  }

  /// Calculates estimated cost for using a model with given token counts
  /// Returns cost in USD (Requirement 7.1)
  double estimateCost(
    String modelId,
    int inputTokens,
    int outputTokens,
  ) {
    try {
      final model = _config.getModelById(modelId);
      if (model == null) {
        developer.log(
          'Model not found for cost estimation: $modelId',
          name: 'ModelSelector',
          level: 900, // Warning level
        );
        return 0.0;
      }

      // Cost formula: (inputTokens / 1,000,000 × inputCost) + (outputTokens / 1,000,000 × outputCost)
      final inputCost = (inputTokens / 1000000) * model.costPerMillionInputTokens;
      final outputCost = (outputTokens / 1000000) * model.costPerMillionOutputTokens;
      
      return inputCost + outputCost;
    } catch (e) {
      developer.log(
        'Error calculating cost: $e',
        name: 'ModelSelector',
        error: e,
        level: 1000, // Error level
      );
      return 0.0;
    }
  }

  /// Compares costs between two models for the same token counts
  /// Returns the model ID with lower cost (Requirement 7.3, 7.4)
  String selectCheaperModel(
    String modelId1,
    String modelId2,
    int inputTokens,
    int outputTokens,
  ) {
    final cost1 = estimateCost(modelId1, inputTokens, outputTokens);
    final cost2 = estimateCost(modelId2, inputTokens, outputTokens);

    if (cost1 <= cost2) {
      return modelId1;
    } else {
      return modelId2;
    }
  }

  /// Clears the selection cache
  /// Useful for testing or when starting a new session
  void clearCache() {
    _selectionCache.clear();
    developer.log('Selection cache cleared', name: 'ModelSelector');
  }

  /// Gets the number of cached selections
  int get cacheSize => _selectionCache.length;

  /// Helper method to check if a string contains any of the given keywords
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Generates a cache key from the user message
  /// Uses task type as the key for efficient caching
  String _getCacheKey(String userMessage) {
    final taskType = _analyzeTask(userMessage);
    return taskType.toString();
  }
}
