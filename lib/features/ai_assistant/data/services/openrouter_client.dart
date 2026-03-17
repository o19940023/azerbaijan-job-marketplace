import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/model_configuration.dart';

/// Client for communicating with Groq API using OpenAI-compatible REST API
class GeminiClient {
  final http.Client _httpClient = http.Client();
  
  // Groq models for fallback
  final List<String> _models = [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'mixtral-8x7b-32768',
    'gemma2-9b-it',
    'llama3-70b-8192',
    'llama3-8b-8192',
  ];

  GeminiClient();

  /// Sends a chat completion request using Groq (OpenAI compatible) API
  Future<String> sendChatCompletion(
    List<Map<String, String>> messages,
  ) async {
    final apiKey = ModelConfiguration.apiKey;
    final baseUrl = ModelConfiguration.baseUrl;
    
    // Try each model in sequence
    for (final modelId in _models) {
      try {
        final requestBody = {
          'model': modelId,
          'messages': messages,
          'temperature': ModelConfiguration.defaultTemperature,
          'max_tokens': ModelConfiguration.defaultMaxTokens,
        };

        print('DEBUG GROQ: Calling API for $modelId at $baseUrl');
        
        final response = await _httpClient.post(
          Uri.parse(baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: ModelConfiguration.timeoutSeconds));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final firstChoice = choices[0];
            final message = firstChoice['message'];
            if (message != null) {
              return message['content'] ?? 'Xəta: Mətn tapılmadı.';
            }
          }
          // If 200 OK but no content, try next model? Usually shouldn't happen.
          return 'Bağışlayın, AI cavab verə bilmədi.';
        } else if (response.statusCode == 429) {
          // Rate limit exceeded, try next model
          print('GROQ RATE LIMIT ($modelId): ${response.body}');
          continue; // Try next model in loop
        } else {
          print('GROQ ERROR ($modelId): ${response.statusCode} - ${response.body}');
          // For other errors (500, 400), maybe try next model too?
          // Let's try next model for 5xx errors, but stop for 400 (bad request)
          if (response.statusCode >= 500) {
            continue;
          }
          return 'Bağışlayın, AI xidmətində xəta baş verdi (Status: ${response.statusCode}).';
        }
      } catch (e) {
        developer.log('Groq API Exception ($modelId)', error: e);
        print('GROQ EXCEPTION ($modelId): $e');
        // Network error, try next model
        continue;
      }
    }
    
    return 'Bağışlayın, bütün AI modelləri məşğuldur. Zəhmət olmasa bir az sonra yenidən cəhd edin.';
  }

  void dispose() {
    _httpClient.close();
  }
}
