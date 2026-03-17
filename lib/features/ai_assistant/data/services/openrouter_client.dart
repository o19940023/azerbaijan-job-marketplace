import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/model_configuration.dart';

/// Client for communicating with Groq API using OpenAI-compatible REST API
class GeminiClient {
  final http.Client _httpClient = http.Client();

  GeminiClient();

  /// Sends a chat completion request using Groq (OpenAI compatible) API
  Future<String> sendChatCompletion(
    List<Map<String, String>> messages,
  ) async {
    final apiKey = ModelConfiguration.apiKey;
    final modelId = ModelConfiguration.defaultModelId;
    final baseUrl = ModelConfiguration.baseUrl;

    try {
      // Groq OpenAI formatını tam dəstəkləyir
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
        
        // OpenAI formatından cavabı çıxarırıq
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final firstChoice = choices[0];
          final message = firstChoice['message'];
          if (message != null) {
            return message['content'] ?? 'Xəta: Mətn tapılmadı.';
          }
        }
        return 'Bağışlayın, AI cavab verə bilmədi.';
      } else {
        print('GROQ ERROR: ${response.statusCode} - ${response.body}');
        return 'Bağışlayın, AI xidmətində xəta baş verdi (Status: ${response.statusCode}).';
      }
    } catch (e) {
      developer.log('Groq API Exception', error: e);
      print('GROQ EXCEPTION: $e');
      return 'Bağışlayın, AI xidməti ilə əlaqə qurarkən xəta baş verdi.';
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
