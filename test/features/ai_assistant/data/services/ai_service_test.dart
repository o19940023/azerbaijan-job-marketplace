import 'package:flutter_test/flutter_test.dart';
import 'package:azerbaijan_job_marketplace/features/ai_assistant/data/services/ai_service.dart';
import 'package:azerbaijan_job_marketplace/features/ai_assistant/data/services/openrouter_client.dart';

// Simple mock implementation for testing
class MockOpenRouterClient extends OpenRouterClient {
  String? _nextResponse;
  Exception? _nextError;
  List<List<Map<String, String>>>? capturedMessages;

  MockOpenRouterClient() : super();

  void setNextResponse(String response) {
    _nextResponse = response;
    _nextError = null;
  }

  void setNextError(Exception error) {
    _nextError = error;
    _nextResponse = null;
  }

  @override
  Future<String> sendChatCompletion(List<Map<String, String>> messages) async {
    capturedMessages ??= [];
    capturedMessages!.add(List.from(messages));

    if (_nextError != null) {
      throw _nextError!;
    }
    return _nextResponse ?? 'Default response';
  }

  @override
  void dispose() {
    // Mock dispose
  }
}

void main() {
  group('AiService', () {
    late MockOpenRouterClient mockClient;
    late AiService aiService;

    setUp(() {
      mockClient = MockOpenRouterClient();
      mockClient.setNextResponse('AI response');
      aiService = AiService(client: mockClient);
    });

    group('Initialization', () {
      test('should initialize with system prompt in Azerbaijani', () {
        // Requirement 6.3: System prompt is in Azerbaijani
        final history = aiService.conversationHistory;
        
        expect(history.length, equals(1));
        expect(history[0]['role'], equals('system'));
        expect(history[0]['content'], contains('İşçi AI'));
        expect(history[0]['content'], contains('Azərbaycan dilində'));
        expect(history[0]['content'], contains('iş axtarışı'));
        expect(history[0]['content'], contains('PROFİL DOLDURMA'));
      });

      test('system prompt should contain job marketplace context', () {
        // Requirement 6.3: System prompt contains job marketplace context
        final history = aiService.conversationHistory;
        final systemPrompt = history[0]['content']!;
        
        expect(systemPrompt, contains('profil'));
        expect(systemPrompt, contains('[PROFILE_UPDATE]'));
        expect(systemPrompt, contains('[JOB_SEARCH]'));
        expect(systemPrompt, contains('İŞ AXTARIŞI'));
      });
    });

    group('sendMessage', () {
      test('should send message and add to conversation history', () async {
        // Requirement 6.1: Maintains conversation history
        mockClient.setNextResponse('AI response');

        final response = await aiService.sendMessage('Test message');

        expect(response, equals('AI response'));
        expect(aiService.messageCount, equals(3)); // system + user + assistant
        
        final history = aiService.conversationHistory;
        expect(history[1]['role'], equals('user'));
        expect(history[1]['content'], equals('Test message'));
        expect(history[2]['role'], equals('assistant'));
        expect(history[2]['content'], equals('AI response'));
      });

      test('should enrich message with profile context', () async {
        // Requirement 6.4: Message enrichment with profile context
        const profileJson = '{"name": "John", "skills": ["Flutter", "Dart"]}';
        
        mockClient.setNextResponse('AI response');

        await aiService.sendMessage(
          'Help me improve my profile',
          userProfileJson: profileJson,
        );

        final capturedMessages = mockClient.capturedMessages!.last;
        final userMessage = capturedMessages[1]['content']!;
        expect(userMessage, contains('[İstifadəçi Profil Məlumatları:'));
        expect(userMessage, contains(profileJson));
        expect(userMessage, contains('Help me improve my profile'));
      });

      test('should enrich message with job results context', () async {
        // Requirement 6.4: Message enrichment with job results
        const jobResultsJson = '{"jobs": [{"title": "Flutter Developer"}]}';
        
        mockClient.setNextResponse('AI response');

        await aiService.sendMessage(
          'Tell me about these jobs',
          jobResultsJson: jobResultsJson,
        );

        final capturedMessages = mockClient.capturedMessages!.last;
        final userMessage = capturedMessages[1]['content']!;
        expect(userMessage, contains('[İş Axtarış Nəticələri:'));
        expect(userMessage, contains(jobResultsJson));
        expect(userMessage, contains('Tell me about these jobs'));
      });

      test('should enrich message with both profile and job context', () async {
        // Requirement 6.4: Message enrichment with both contexts
        const profileJson = '{"name": "John"}';
        const jobResultsJson = '{"jobs": [{"title": "Developer"}]}';
        
        mockClient.setNextResponse('AI response');

        await aiService.sendMessage(
          'Which job fits my profile?',
          userProfileJson: profileJson,
          jobResultsJson: jobResultsJson,
        );

        final capturedMessages = mockClient.capturedMessages!.last;
        final userMessage = capturedMessages[1]['content']!;
        expect(userMessage, contains('[İstifadəçi Profil Məlumatları:'));
        expect(userMessage, contains('[İş Axtarış Nəticələri:'));
        expect(userMessage, contains('Which job fits my profile?'));
      });

      test('should handle invalid profile JSON gracefully', () async {
        // Requirement 6.4: Handles invalid JSON
        const invalidJson = '{invalid json}';
        
        mockClient.setNextResponse('AI response');

        await aiService.sendMessage(
          'Test message',
          userProfileJson: invalidJson,
        );

        final capturedMessages = mockClient.capturedMessages!.last;
        final userMessage = capturedMessages[1]['content']!;
        // Should not contain enrichment if JSON is invalid
        expect(userMessage, equals('Test message'));
      });

      test('should handle invalid job results JSON gracefully', () async {
        // Requirement 6.4: Handles invalid JSON
        const invalidJson = '{invalid json}';
        
        mockClient.setNextResponse('AI response');

        await aiService.sendMessage(
          'Test message',
          jobResultsJson: invalidJson,
        );

        final capturedMessages = mockClient.capturedMessages!.last;
        final userMessage = capturedMessages[1]['content']!;
        // Should not contain enrichment if JSON is invalid
        expect(userMessage, equals('Test message'));
      });

      test('should maintain conversation history in chronological order', () async {
        // Requirement 10.3: Conversation context preservation
        mockClient.setNextResponse('Response');

        await aiService.sendMessage('Message 1');
        await aiService.sendMessage('Message 2');
        await aiService.sendMessage('Message 3');

        final history = aiService.conversationHistory;
        
        // Should have: system + (user1, assistant1, user2, assistant2, user3, assistant3)
        expect(history.length, equals(7));
        expect(history[0]['role'], equals('system'));
        expect(history[1]['role'], equals('user'));
        expect(history[1]['content'], equals('Message 1'));
        expect(history[2]['role'], equals('assistant'));
        expect(history[3]['role'], equals('user'));
        expect(history[3]['content'], equals('Message 2'));
        expect(history[4]['role'], equals('assistant'));
        expect(history[5]['role'], equals('user'));
        expect(history[5]['content'], equals('Message 3'));
        expect(history[6]['role'], equals('assistant'));
      });
    });

    group('resetChat', () {
      test('should clear conversation history', () async {
        // Requirement 6.2: resetChat clears conversation history
        mockClient.setNextResponse('Response');

        // Add some messages
        await aiService.sendMessage('Message 1');
        await aiService.sendMessage('Message 2');
        
        expect(aiService.messageCount, greaterThan(1));

        // Reset chat
        aiService.resetChat();

        // Should only have system prompt
        expect(aiService.messageCount, equals(1));
        expect(aiService.conversationHistory[0]['role'], equals('system'));
      });

      test('should reinitialize system prompt after reset', () async {
        // Requirement 6.2: resetChat reinitializes system prompt
        mockClient.setNextResponse('Response');

        await aiService.sendMessage('Message 1');
        aiService.resetChat();

        final history = aiService.conversationHistory;
        expect(history.length, equals(1));
        expect(history[0]['role'], equals('system'));
        expect(history[0]['content'], contains('İşçi AI'));
      });

      test('should allow sending messages after reset', () async {
        // Requirement 6.2: Can continue conversation after reset
        mockClient.setNextResponse('Response');

        await aiService.sendMessage('Message 1');
        aiService.resetChat();
        await aiService.sendMessage('Message 2');

        expect(aiService.messageCount, equals(3)); // system + user + assistant
      });
    });

    group('Conversation History Limit', () {
      test('should enforce 20 message limit', () async {
        // Requirement 10.5: History limit of 20 messages
        mockClient.setNextResponse('Response');

        // Send 15 messages (30 messages total: 15 user + 15 assistant)
        for (int i = 0; i < 15; i++) {
          await aiService.sendMessage('Message $i');
        }

        // Should have system + 20 messages (oldest removed)
        expect(aiService.messageCount, equals(21)); // system + 20
        
        final history = aiService.conversationHistory;
        expect(history[0]['role'], equals('system'));
        
        // Check that oldest messages (0-4) were removed by checking user messages directly
        final userMessages = history
            .where((m) => m['role'] == 'user')
            .map((m) => m['content'])
            .toList();
        
        // Should not contain Message 0-4
        expect(userMessages, isNot(contains('Message 0')));
        expect(userMessages, isNot(contains('Message 1')));
        expect(userMessages, isNot(contains('Message 2')));
        expect(userMessages, isNot(contains('Message 3')));
        expect(userMessages, isNot(contains('Message 4')));
        
        // Should contain messages 5-14
        expect(userMessages, contains('Message 5'));
        expect(userMessages, contains('Message 14'));
      });

      test('should remove oldest user-assistant pairs when limit exceeded', () async {
        // Requirement 10.5: Removes oldest pairs
        mockClient.setNextResponse('Response');

        // Send 12 messages (24 messages total)
        for (int i = 0; i < 12; i++) {
          await aiService.sendMessage('Message $i');
        }

        final history = aiService.conversationHistory;
        
        // Should maintain user-assistant pairing
        for (int i = 1; i < history.length - 1; i += 2) {
          expect(history[i]['role'], equals('user'));
          expect(history[i + 1]['role'], equals('assistant'));
        }
      });

      test('should not remove system prompt when enforcing limit', () async {
        // Requirement 10.5: System prompt is preserved
        mockClient.setNextResponse('Response');

        // Send many messages
        for (int i = 0; i < 20; i++) {
          await aiService.sendMessage('Message $i');
        }

        final history = aiService.conversationHistory;
        
        // System prompt should always be first
        expect(history[0]['role'], equals('system'));
        expect(history[0]['content'], contains('İşçi AI'));
      });

      test('should handle limit enforcement correctly with odd number of messages', () async {
        // Requirement 10.5: Handles edge cases
        mockClient.setNextResponse('Response');

        // Send 11 messages (22 messages total: 11 user + 11 assistant)
        for (int i = 0; i < 11; i++) {
          await aiService.sendMessage('Message $i');
        }

        // Should have system + 20 messages
        expect(aiService.messageCount, equals(21));
      });
    });

    group('Backward Compatibility', () {
      test('should maintain sendMessage signature', () async {
        // Requirement 6.1: Backward-compatible signature
        mockClient.setNextResponse('Response');

        // Should accept all three parameters
        final response = await aiService.sendMessage(
          'Test message',
          userProfileJson: '{}',
          jobResultsJson: '{}',
        );

        expect(response, equals('Response'));
      });

      test('should work without optional parameters', () async {
        // Requirement 6.1: Optional parameters are truly optional
        mockClient.setNextResponse('Response');

        final response = await aiService.sendMessage('Test message');

        expect(response, equals('Response'));
      });

      test('should maintain resetChat method', () {
        // Requirement 6.2: resetChat method exists
        expect(() => aiService.resetChat(), returnsNormally);
      });
    });

    group('Error Handling', () {
      test('should propagate errors from OpenRouterClient', () async {
        // Should rethrow errors for caller to handle
        mockClient.setNextError(Exception('API error'));

        expect(
          () => aiService.sendMessage('Test'),
          throwsException,
        );
      });

      test('should maintain conversation state even after error', () async {
        // Conversation history should include failed user message
        mockClient.setNextError(Exception('API error'));

        try {
          await aiService.sendMessage('Test message');
        } catch (e) {
          // Expected error
        }

        // User message should be in history even though API call failed
        final history = aiService.conversationHistory;
        expect(history.length, equals(2)); // system + user
        expect(history[1]['role'], equals('user'));
        expect(history[1]['content'], equals('Test message'));
      });
    });

    group('Resource Management', () {
      test('should dispose client resources', () {
        // Should call dispose on client
        aiService.dispose();
        
        // Verify dispose was called (if client is a mock)
        // Note: This test verifies the method exists and can be called
        expect(() => aiService.dispose(), returnsNormally);
      });
    });
  });
}
