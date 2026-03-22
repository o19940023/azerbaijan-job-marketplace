import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/model_configuration.dart';

/// Client for communicating with Groq API (OpenAI-compatible REST).
/// 
/// Tries models in priority order; falls back on rate-limit (429) or
/// server errors (5xx). Stops immediately on client errors (4xx ≠ 429).
class GeminiClient {
  final http.Client _httpClient = http.Client();

  /// Priority-ordered model list — fastest/cheapest first.
  static const List<String> _models = [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'mixtral-8x7b-32768',
    'gemma2-9b-it',
    'llama3-70b-8192',
    'llama3-8b-8192',
  ];

  GeminiClient();

  /// Sends a chat completion request and returns the assistant's text.
  /// Automatically retries with next model on rate-limit or server errors.
  Future<String> sendChatCompletion(
    List<Map<String, String>> messages,
  ) async {
    final apiKey = ModelConfiguration.apiKey;
    final baseUrl = ModelConfiguration.baseUrl;

    String? lastError;

    for (final modelId in _models) {
      try {
        developer.log(
          'Trying model: $modelId',
          name: 'GeminiClient',
        );

        final response = await _httpClient
            .post(
              Uri.parse(baseUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $apiKey',
              },
              body: jsonEncode({
                'model': modelId,
                'messages': messages,
                'temperature': ModelConfiguration.defaultTemperature,
                'max_tokens': ModelConfiguration.defaultMaxTokens,
              }),
            )
            .timeout(
              const Duration(seconds: ModelConfiguration.timeoutSeconds),
            );

        // ── Success ──────────────────────────────────
        if (response.statusCode == 200) {
          // Use bodyBytes → utf8 to handle non-ASCII correctly
          final bodyDecoded = utf8.decode(response.bodyBytes);
          return _parseResponse(bodyDecoded, modelId);
        }

        // ── Rate limited → try next model ────────────
        if (response.statusCode == 429) {
          developer.log(
            'Rate limited on $modelId — trying next',
            name: 'GeminiClient',
          );
          lastError = 'Rate limited ($modelId)';
          continue;
        }

        // ── Server error → try next model ────────────
        if (response.statusCode >= 500) {
          developer.log(
            'Server error ${response.statusCode} on $modelId — trying next',
            name: 'GeminiClient',
          );
          lastError = 'Server error ${response.statusCode} ($modelId)';
          continue;
        }

        // ── Client error (400, 401, 403…) → stop ─────
        developer.log(
          'Client error ${response.statusCode}: ${response.body}',
          name: 'GeminiClient',
          level: 1000,
        );
        return 'Bağışlayın, sorğu xətası baş verdi (${response.statusCode}).';
      } on Exception catch (e) {
        developer.log(
          'Exception with $modelId: $e',
          name: 'GeminiClient',
          error: e,
        );
        lastError = e.toString();
        continue; // Network / timeout → try next model
      }
    }

    // All models exhausted
    developer.log(
      'All models exhausted. Last error: $lastError',
      name: 'GeminiClient',
      level: 1000,
    );
    return 'Bağışlayın, bütün AI modelləri hal-hazırda məşğuldur. '
        'Bir az sonra yenidən cəhd edin.';
  }

  /// Parses the OpenAI-compatible response body and extracts content text.
  String _parseResponse(String body, String modelId) {
    try {
      developer.log('Raw response ($modelId): $body', name: 'GeminiClient');
      final data = jsonDecode(body) as Map<String, dynamic>;

      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        developer.log(
          'Empty choices from $modelId',
          name: 'GeminiClient',
          level: 900,
        );
        return 'Bağışlayın, AI cavab verə bilmədi.';
      }

      final content =
          (choices[0]['message']?['content'] as String?)?.trim() ?? '';

      if (content.isEmpty) {
        return 'Bağışlayın, AI boş cavab qaytardı.';
      }

      developer.log(
        'Success with $modelId (${content.length} chars)',
        name: 'GeminiClient',
      );
      return content;
    } catch (e) {
      developer.log(
        'Response parse error: $e',
        name: 'GeminiClient',
        error: e,
        level: 1000,
      );
      return 'Bağışlayın, cavab emal edilərkən xəta baş verdi.';
    }
  }

  void dispose() {
    _httpClient.close();
  }
}