import 'package:flutter_test/flutter_test.dart';
import 'package:azerbaijan_job_marketplace/features/ai_assistant/data/services/fallback_chain.dart';
import 'package:azerbaijan_job_marketplace/features/ai_assistant/data/models/model_selection.dart';

void main() {
  group('FallbackChain', () {
    late FallbackChain fallbackChain;

    setUp(() {
      fallbackChain = FallbackChain();
    });

    group('getFallbackModels', () {
      test('returns at least 3 models for profileUpdate task', () {
        // Requirement 4.1: Fallback chain depth
        final models = fallbackChain.getFallbackModels(TaskType.profileUpdate);
        
        expect(models.length, greaterThanOrEqualTo(3));
        expect(models[0], equals('google/gemini-flash-1.5-8b'));
      });

      test('returns at least 3 models for jobSearch task', () {
        // Requirement 4.1: Fallback chain depth
        final models = fallbackChain.getFallbackModels(TaskType.jobSearch);
        
        expect(models.length, greaterThanOrEqualTo(3));
        expect(models[0], equals('01-ai/yi-lightning'));
      });

      test('returns at least 3 models for conversational task', () {
        // Requirement 4.1: Fallback chain depth
        final models = fallbackChain.getFallbackModels(TaskType.conversational);
        
        expect(models.length, greaterThanOrEqualTo(3));
        expect(models[0], equals('openai/gpt-4o-mini'));
      });

      test('returns at least 3 models for creative task', () {
        // Requirement 4.1: Fallback chain depth
        final models = fallbackChain.getFallbackModels(TaskType.creative);
        
        expect(models.length, greaterThanOrEqualTo(3));
        expect(models[0], equals('mistralai/mistral-small'));
      });
    });

    group('shouldRetry', () {
      test('returns true for 401 authentication error', () {
        // Requirement 4.3: 401 error triggers immediate fallback
        final shouldRetry = fallbackChain.shouldRetry(401, '{"error": "Unauthorized"}');
        
        expect(shouldRetry, isTrue);
      });

      test('returns true for 429 rate limit error', () {
        // Requirement 4.4: 429 error triggers immediate fallback
        final shouldRetry = fallbackChain.shouldRetry(429, '{"error": "Rate limit exceeded"}');
        
        expect(shouldRetry, isTrue);
      });

      test('returns true for 400 with content_filter', () {
        // Requirement 4.5: 400 with content_filter triggers immediate fallback
        final shouldRetry = fallbackChain.shouldRetry(
          400,
          '{"error": {"type": "content_filter", "message": "Content filtered"}}',
        );
        
        expect(shouldRetry, isTrue);
      });

      test('returns false for 200 success', () {
        final shouldRetry = fallbackChain.shouldRetry(200, '{"success": true}');
        
        expect(shouldRetry, isFalse);
      });

      test('returns true for other 4xx errors', () {
        final shouldRetry = fallbackChain.shouldRetry(404, '{"error": "Not found"}');
        
        expect(shouldRetry, isTrue);
      });

      test('returns true for 5xx server errors', () {
        final shouldRetry = fallbackChain.shouldRetry(500, '{"error": "Internal server error"}');
        
        expect(shouldRetry, isTrue);
      });
    });

    group('getUserErrorMessage', () {
      test('returns Azerbaijani message for 401 error', () {
        // Requirement 5.1: Authentication error message
        final message = fallbackChain.getUserErrorMessage(401);
        
        expect(message, contains('API açarı problemi'));
        expect(message, contains('tətbiq tərtibatçısı'));
      });

      test('returns Azerbaijani message for 429 error', () {
        // Requirement 5.2: Rate limit error message
        final message = fallbackChain.getUserErrorMessage(429);
        
        expect(message, contains('çox sayda sorğu'));
        expect(message, contains('yenidən cəhd edin'));
      });

      test('returns Azerbaijani message for timeout errors', () {
        // Requirement 5.3: Network timeout error message
        final message408 = fallbackChain.getUserErrorMessage(408);
        final message504 = fallbackChain.getUserErrorMessage(504);
        
        expect(message408, contains('İnternet bağlantısı'));
        expect(message504, contains('İnternet bağlantısı'));
      });

      test('returns generic Azerbaijani message for other errors', () {
        // Requirement 5.4: Generic error message without technical details
        final message = fallbackChain.getUserErrorMessage(500);
        
        expect(message, contains('Bağışlayın'));
        expect(message, isNot(contains('500')));
        expect(message, isNot(contains('error')));
      });
    });

    group('getAllModelsFailedMessage', () {
      test('returns Azerbaijani error message', () {
        // Requirement 4.6: Final error message in Azerbaijani
        final message = fallbackChain.getAllModelsFailedMessage();
        
        expect(message, contains('Bağışlayın'));
        expect(message, contains('AI xidməti'));
        expect(message, contains('yenidən cəhd edin'));
      });
    });

    group('validateChainDepth', () {
      test('returns true for chain with 3 models', () {
        // Requirement 4.1: Fallback chain depth validation
        final chain = ['model1', 'model2', 'model3'];
        
        expect(fallbackChain.validateChainDepth(chain), isTrue);
      });

      test('returns true for chain with more than 3 models', () {
        final chain = ['model1', 'model2', 'model3', 'model4'];
        
        expect(fallbackChain.validateChainDepth(chain), isTrue);
      });

      test('returns false for chain with less than 3 models', () {
        final chain = ['model1', 'model2'];
        
        expect(fallbackChain.validateChainDepth(chain), isFalse);
      });
    });

    group('getNextFallbackModel', () {
      test('returns next model in chain', () {
        final chain = ['model1', 'model2', 'model3'];
        
        final next = fallbackChain.getNextFallbackModel(chain, 'model1');
        
        expect(next, equals('model2'));
      });

      test('returns null when at end of chain', () {
        final chain = ['model1', 'model2', 'model3'];
        
        final next = fallbackChain.getNextFallbackModel(chain, 'model3');
        
        expect(next, isNull);
      });

      test('returns null when model not in chain', () {
        final chain = ['model1', 'model2', 'model3'];
        
        final next = fallbackChain.getNextFallbackModel(chain, 'model4');
        
        expect(next, isNull);
      });
    });
  });
}
