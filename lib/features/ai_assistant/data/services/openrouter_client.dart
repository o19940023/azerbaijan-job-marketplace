import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import '../config/model_configuration.dart';
import '../models/model_selection.dart';
import 'fallback_chain.dart';
import 'model_selector.dart';

/// HTTP client for communicating with OpenRouter API
/// Handles request construction, response parsing, error detection, and fallback coordination
class OpenRouterClient {
  final http.Client _httpClient;
  final ModelSelector _modelSelector;
  final FallbackChain _fallbackChain;
  final ModelConfiguration _config;

  /// Creates an OpenRouterClient with optional dependencies
  /// If dependencies are not provided, creates default instances
  OpenRouterClient({
    http.Client? httpClient,
    ModelSelector? modelSelector,
    FallbackChain? fallbackChain,
    ModelConfiguration? config,
  })  : _httpClient = httpClient ?? http.Client(),
        _config = config ?? ModelConfiguration(),
        _modelSelector = modelSelector ?? ModelSelector(config: config),
        _fallbackChain = fallbackChain ?? FallbackChain(config: config);

  /// Sends a chat completion request with automatic model selection and fallback
  /// Returns the assistant's response text
  /// 
  /// Requirements: 1.1, 4.2, 4.6, 10.1
  Future<String> sendChatCompletion(
    List<Map<String, String>> messages,
  ) async {
    // Extract user message for model selection
    final userMessage = _extractUserMessage(messages);
    
    // Select optimal model based on message content
    final selection = _modelSelector.selectModel(userMessage);
    
    // Build fallback chain: primary + fallbacks
    final fallbackModels = [selection.modelId, ...selection.fallbackModels];
    
    // Try each model in the fallback chain
    for (int i = 0; i < fallbackModels.length; i++) {
      final modelId = fallbackModels[i];
      
      try {
        developer.log(
          'Attempting request with model: $modelId (attempt ${i + 1}/${fallbackModels.length})',
          name: 'OpenRouterClient',
        );
        
        final response = await _makeRequest(modelId, messages);
        
        // Check if response is successful
        if (response.statusCode == 200) {
          final content = _parseResponse(response);
          
          // Validate response content (Requirement 9.1, 9.2)
          if (content.isEmpty) {
            developer.log(
              'Empty response content from model: $modelId',
              name: 'OpenRouterClient',
              level: 900, // Warning
            );
            throw Exception('Empty response content');
          }
          
          return content;
        } else {
           // Log the error body for debugging
           developer.log(
             'Request failed: ${response.statusCode} - ${response.body}',
             name: 'OpenRouterClient',
             level: 1000,
           );
           
           // If Groq fails, maybe try OpenRouter as fallback if key is different? 
           // Currently logic assumes same key for all fallbacks which is not ideal for mixed providers.
        }
        
        // Handle error responses
        _logError(modelId, response);

        final errorBody = utf8.decode(response.bodyBytes);
        
        // Check if we should retry with fallback (Requirements 4.3, 4.4, 4.5)
        if (_fallbackChain.shouldRetry(response.statusCode, errorBody)) {
          if (i < fallbackModels.length - 1) {
            // Log fallback event (Requirement 4.7)
            _fallbackChain.logFallbackEvent(
              failedModelId: modelId,
              fallbackModelId: fallbackModels[i + 1],
              statusCode: response.statusCode,
              errorMessage: errorBody,
            );
            continue;
          }
        }
        
        // If this is the last model, return error message
        if (i == fallbackModels.length - 1) {
          _fallbackChain.logAllModelsExhausted(
            taskType: _modelSelector.selectModel(userMessage).fallbackModels.isEmpty
                ? TaskType.conversational
                : TaskType.conversational,
            attemptedModels: fallbackModels,
          );
          return _fallbackChain.getAllModelsFailedMessage();
        }
      } catch (e) {
        developer.log(
          'Exception during request with model: $modelId',
          name: 'OpenRouterClient',
          error: e,
          level: 1000, // Error
        );
        
        // Try fallback if available
        if (i < fallbackModels.length - 1) {
          _fallbackChain.logFallbackEvent(
            failedModelId: modelId,
            fallbackModelId: fallbackModels[i + 1],
            statusCode: 0,
            errorMessage: e.toString(),
          );
          continue;
        }
        
        // If this is the last model, return error message
        return _fallbackChain.getUserErrorMessage(0);
      }
    }
    
    // All models exhausted (Requirement 4.6)
    return _fallbackChain.getAllModelsFailedMessage();
  }

  /// Makes HTTP request to OpenRouter API for specific model
  /// Requirements: 1.2, 1.3, 1.4, 1.5, 5.6, 10.2
  Future<http.Response> _makeRequest(
    String modelId,
    List<Map<String, String>> messages,
  ) async {
    // Validate API key (Requirement 8.5)
    ModelConfiguration.validateApiKey();
    
    // Construct request with required headers (Requirements 1.2, 1.3, 1.4)
    final headers = {
      'Authorization': 'Bearer ${ModelConfiguration.apiKey}',
      'Content-Type': 'application/json',
    };
    
    // OpenRouter specific headers
    if (ModelConfiguration.baseUrl.contains('openrouter')) {
      headers['HTTP-Referer'] = ModelConfiguration.appReferer;
      headers['X-Title'] = ModelConfiguration.appTitle;
    }
    
    // Construct request body (Requirement 1.5)
    final Map<String, dynamic> requestBody = {
      'model': modelId,
      'messages': messages,
      'temperature': ModelConfiguration.defaultTemperature,
      'max_tokens': ModelConfiguration.defaultMaxTokens,
    };

    // Groq requires different parameter handling sometimes (e.g. strict JSON mode or different max_tokens)
    if (ModelConfiguration.baseUrl.contains('groq')) {
       // Groq doesn't need extra headers like HTTP-Referer, but they are harmless.
       // Ensure model ID is correct for Groq
    }

    final body = jsonEncode(requestBody);
    
    developer.log(
      'Making request to OpenRouter API with model: $modelId',
      name: 'OpenRouterClient',
    );

    // DEBUG: Log configuration
    developer.log(
      'DEBUG CONFIG: BaseURL=${ModelConfiguration.baseUrl}, Model=$modelId',
      name: 'OpenRouterClient',
    );
    
    final uri = Uri.parse(ModelConfiguration.baseUrl);
    
    // Make HTTP POST request with timeout (Requirement 5.6, 10.2)
    final response = await _httpClient
        .post(
          uri,
          headers: headers,
          body: body,
        )
        .timeout(
          Duration(seconds: ModelConfiguration.timeoutSeconds),
          onTimeout: () {
            developer.log(
              'Request timeout after ${ModelConfiguration.timeoutSeconds} seconds',
              name: 'OpenRouterClient',
              level: 900, // Warning
            );
            return http.Response(
              jsonEncode({'error': {'message': 'Request timeout'}}),
              408, // Request Timeout
            );
          },
        );
    
    return response;
  }

  /// Parses successful API response and extracts message content
  /// Requirements: 1.6, 9.3, 9.5
  String _parseResponse(http.Response response) {
    try {
      // Decode UTF-8 response body for Azerbaijani characters (Requirement 9.5)
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedBody) as Map<String, dynamic>;
      
      // Extract message content from response structure (Requirement 1.6)
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        developer.log(
          'No choices in response',
          name: 'OpenRouterClient',
          level: 900, // Warning
        );
        return '';
      }
      
      final firstChoice = choices[0] as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>?;
      if (message == null) {
        developer.log(
          'No message in first choice',
          name: 'OpenRouterClient',
          level: 900, // Warning
        );
        return '';
      }
      
      final content = message['content'] as String?;
      if (content == null) {
        developer.log(
          'No content in message',
          name: 'OpenRouterClient',
          level: 900, // Warning
        );
        return '';
      }
      
      // Special tags are preserved as-is (Requirement 9.3)
      // [PROFILE_UPDATE], [JOB_SEARCH] tags are not modified
      
      return content;
    } catch (e) {
      developer.log(
        'Error parsing response',
        name: 'OpenRouterClient',
        error: e,
        level: 1000, // Error
      );
      return '';
    }
  }

  /// Logs error details for debugging
  /// Requirements: 1.7, 5.5
  void _logError(String modelId, http.Response response) {
    try {
      // Decode response body for error details
      final decodedBody = utf8.decode(response.bodyBytes);
      
      // Use debugPrint to ensure visibility in logs
      print('AI API ERROR [$modelId]: Status ${response.statusCode}');
      print('AI API ERROR BODY: $decodedBody');
      
      developer.log(
        'API error from model: $modelId',
        name: 'OpenRouterClient',
        error: {
          'statusCode': response.statusCode,
          'responseBody': decodedBody,
          'headers': response.headers,
        },
        level: 1000, // Error
      );
    } catch (e) {
      print('AI API ERROR LOGGING FAILED: $e');
      developer.log(
        'Error logging API error',
        name: 'OpenRouterClient',
        error: e,
        level: 1000, // Error
      );
    }
  }

  /// Extracts user message from messages list for model selection
  String _extractUserMessage(List<Map<String, String>> messages) {
    // Find the last user message
    for (int i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      if (message['role'] == 'user') {
        return message['content'] ?? '';
      }
    }
    
    // If no user message found, return empty string
    return '';
  }

  /// Disposes resources
  void dispose() {
    _httpClient.close();
  }
}
