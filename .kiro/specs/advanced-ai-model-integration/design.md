# Design Document: Advanced AI Model Integration

## Overview

This design implements a robust, multi-model AI service for the Azerbaijan Job Marketplace app by replacing the failing Azure-hosted models with OpenRouter API integration. The solution provides intelligent model selection, comprehensive fallback mechanisms, and cost optimization while maintaining backward compatibility with the existing AI assistant interface.

The current implementation experiences 401 authentication errors with Azure models (DeepSeek-V3, Mistral-large-2411, gpt-4o-mini). The new design leverages OpenRouter's unified API gateway to access multiple high-quality models (Z.ai GLM 4.7, Google Gemini 3 Flash Preview, Mistral Small Creative, OpenAI GPT-4o-mini) with intelligent selection based on task type, automatic fallback on failures, and cost-aware optimization.

Key design principles:
- **Reliability**: Multi-model fallback chain ensures service availability
- **Intelligence**: Task-aware model selection optimizes response quality
- **Cost-efficiency**: Prefer lower-cost models when capabilities are equivalent
- **Maintainability**: Configuration-driven approach for easy updates
- **Compatibility**: Maintains existing interface for seamless integration

## Architecture

### System Components

The architecture follows a layered approach with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│           AI Assistant Cubit (Existing)                 │
│         (Presentation/Business Logic Layer)             │
└────────────────────┬────────────────────────────────────┘
                     │ sendMessage(userMessage, profile, jobs)
                     │ resetChat()
                     ▼
┌─────────────────────────────────────────────────────────┐
│              AiService (Facade)                         │
│  - Maintains conversation history                       │
│  - Enriches messages with context                       │
│  - Delegates to OpenRouterClient                        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│           OpenRouterClient                              │
│  - HTTP communication with OpenRouter API               │
│  - Request/response handling                            │
│  - Error detection and retry logic                      │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        ▼                         ▼
┌──────────────────┐    ┌──────────────────────┐
│  ModelSelector   │    │  FallbackChain       │
│  - Task analysis │    │  - Ordered models    │
│  - Model choice  │    │  - Retry logic       │
│  - Cost calc     │    │  - Error handling    │
└──────────────────┘    └──────────────────────┘
        │                         │
        └────────────┬────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│              ModelConfiguration                         │
│  - Model metadata (ID, limits, costs, strengths)        │
│  - API credentials                                      │
│  - Timeout settings                                     │
└─────────────────────────────────────────────────────────┘
```

### Component Responsibilities

**AiService (Facade)**
- Maintains conversation history (list of messages with roles)
- Enriches user messages with profile and job context
- Initializes system prompt in Azerbaijani
- Provides backward-compatible interface (sendMessage, resetChat)
- Delegates actual API calls to OpenRouterClient

**OpenRouterClient**
- Manages HTTP communication with OpenRouter API
- Constructs properly formatted API requests
- Parses API responses and extracts message content
- Implements timeout handling (30 seconds)
- Coordinates with ModelSelector and FallbackChain
- Logs errors and fallback events

**ModelSelector**
- Analyzes user message to determine task type
- Selects optimal model based on task requirements
- Considers cost-effectiveness when multiple models are suitable
- Provides selection reasoning for logging
- Caches selection decisions within a session

**FallbackChain**
- Defines ordered sequence of models for each task type
- Implements retry logic when primary model fails
- Handles specific error codes (401, 429, 400 with content_filter)
- Returns user-friendly error messages when all models fail
- Logs which models were attempted and why they failed

**ModelConfiguration**
- Stores model metadata (identifier, token limits, costs, strengths)
- Provides API credentials and base URL
- Defines timeout and retry settings
- Allows easy updates without code changes

### Data Flow

1. **User Request**: AI Assistant Cubit calls `sendMessage(userMessage, userProfileJson, jobResultsJson)`
2. **Context Enrichment**: AiService enriches message with profile/job data and adds to conversation history
3. **Model Selection**: ModelSelector analyzes message and selects optimal model
4. **API Request**: OpenRouterClient constructs and sends HTTP POST to OpenRouter
5. **Response Handling**: 
   - Success (200): Parse response, add to history, return to caller
   - Failure: FallbackChain tries next model in sequence
6. **Fallback Loop**: Repeat steps 4-5 with fallback models until success or exhaustion
7. **Error Response**: If all models fail, return localized error message

## Components and Interfaces

### AiService

```dart
class AiService {
  final OpenRouterClient _client;
  final List<Map<String, String>> _messages;
  
  AiService({OpenRouterClient? client}) 
    : _client = client ?? OpenRouterClient(),
      _messages = [];
  
  /// Sends a message to the AI assistant with optional context
  /// Returns the AI's response text
  Future<String> sendMessage(
    String userMessage, {
    String? userProfileJson,
    String? jobResultsJson,
  }) async;
  
  /// Clears conversation history and reinitializes system prompt
  void resetChat();
  
  /// Internal: Enriches user message with profile and job context
  String _enrichMessage(String message, String? profile, String? jobs);
  
  /// Internal: Initializes conversation with system prompt
  void _initChat();
}
```

### OpenRouterClient

```dart
class OpenRouterClient {
  final http.Client _httpClient;
  final ModelSelector _modelSelector;
  final ModelConfiguration _config;
  
  OpenRouterClient({
    http.Client? httpClient,
    ModelSelector? modelSelector,
    ModelConfiguration? config,
  });
  
  /// Sends a chat completion request with automatic model selection and fallback
  /// Returns the assistant's response text
  Future<String> sendChatCompletion(
    List<Map<String, String>> messages,
  ) async;
  
  /// Internal: Makes HTTP request to OpenRouter API for specific model
  Future<http.Response> _makeRequest(
    String modelId,
    List<Map<String, String>> messages,
  ) async;
  
  /// Internal: Parses successful API response
  String _parseResponse(http.Response response);
  
  /// Internal: Determines if error is retryable with fallback
  bool _shouldFallback(http.Response response);
  
  /// Internal: Logs error details for debugging
  void _logError(String modelId, http.Response response);
}
```

### ModelSelector

```dart
class ModelSelector {
  final ModelConfiguration _config;
  final Map<String, String> _selectionCache;
  
  ModelSelector({ModelConfiguration? config});
  
  /// Selects the best model for the given message
  /// Returns model ID and selection reason
  ModelSelection selectModel(String userMessage);
  
  /// Internal: Analyzes message to determine task type
  TaskType _analyzeTask(String userMessage);
  
  /// Internal: Calculates estimated cost for a model
  double _estimateCost(String modelId, int inputTokens, int outputTokens);
  
  /// Internal: Checks cache for similar request
  String? _getCachedSelection(String messageKey);
}

class ModelSelection {
  final String modelId;
  final String reason;
  final List<String> fallbackModels;
  
  ModelSelection({
    required this.modelId,
    required this.reason,
    required this.fallbackModels,
  });
}

enum TaskType {
  profileUpdate,    // Agentic workflow - profile modification
  jobSearch,        // Reasoning - job query processing
  conversational,   // General chat
  creative,         // Content generation
}
```

### FallbackChain

```dart
class FallbackChain {
  final ModelConfiguration _config;
  
  FallbackChain({ModelConfiguration? config});
  
  /// Returns ordered list of fallback models for a task type
  List<String> getFallbackModels(TaskType taskType);
  
  /// Determines if error code should trigger fallback
  bool shouldRetry(int statusCode, String responseBody);
  
  /// Returns localized error message for user display
  String getUserErrorMessage(int statusCode);
}
```

### ModelConfiguration

```dart
class ModelConfiguration {
  // API Configuration
  static const String baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String apiKey = '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';
  static const String appReferer = 'https://azerbaijan-job-marketplace.app';
  static const String appTitle = 'Azerbaijan Job Marketplace';
  
  // Request Configuration
  static const int timeoutSeconds = 30;
  static const int maxConversationMessages = 20;
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 2048;
  
  // Model Definitions
  final Map<String, ModelMetadata> models;
  
  ModelConfiguration() : models = _initializeModels();
  
  static Map<String, ModelMetadata> _initializeModels() {
    return {
      'yi-lightning': ModelMetadata(
        id: '01-ai/yi-lightning',
        name: 'Z.ai GLM 4.7',
        tokenLimit: 1000000,
        costPerMillionInputTokens: 0.0,
        costPerMillionOutputTokens: 0.0,
        strengths: ['reasoning', 'high-token-limit'],
      ),
      'gemini-flash': ModelMetadata(
        id: 'google/gemini-flash-1.5-8b',
        name: 'Google Gemini 3 Flash Preview',
        tokenLimit: 1000000,
        costPerMillionInputTokens: 0.0375,
        costPerMillionOutputTokens: 0.15,
        strengths: ['agentic-workflows', 'fast'],
      ),
      'mistral-small': ModelMetadata(
        id: 'mistralai/mistral-small',
        name: 'Mistral Small Creative',
        tokenLimit: 32000,
        costPerMillionInputTokens: 0.2,
        costPerMillionOutputTokens: 0.6,
        strengths: ['creative-writing', 'programming'],
      ),
      'gpt-4o-mini': ModelMetadata(
        id: 'openai/gpt-4o-mini',
        name: 'OpenAI GPT-4o-mini',
        tokenLimit: 128000,
        costPerMillionInputTokens: 0.15,
        costPerMillionOutputTokens: 0.6,
        strengths: ['conversational', 'fast'],
      ),
    };
  }
  
  ModelMetadata getModel(String key);
}

class ModelMetadata {
  final String id;
  final String name;
  final int tokenLimit;
  final double costPerMillionInputTokens;
  final double costPerMillionOutputTokens;
  final List<String> strengths;
  
  ModelMetadata({
    required this.id,
    required this.name,
    required this.tokenLimit,
    required this.costPerMillionInputTokens,
    required this.costPerMillionOutputTokens,
    required this.strengths,
  });
}
```

## Data Models

### Message Format

Messages follow the OpenAI chat completion format:

```dart
// Internal conversation history format
List<Map<String, String>> messages = [
  {
    'role': 'system',
    'content': 'System prompt in Azerbaijani...'
  },
  {
    'role': 'user',
    'content': '[İstifadəçi Profil Məlumatları: {...}]\n\nUser message'
  },
  {
    'role': 'assistant',
    'content': 'AI response'
  },
];
```

### API Request Format

```json
{
  "model": "01-ai/yi-lightning",
  "messages": [
    {"role": "system", "content": "..."},
    {"role": "user", "content": "..."}
  ],
  "temperature": 0.7,
  "max_tokens": 2048
}
```

### API Response Format

```json
{
  "id": "gen-1234567890",
  "model": "01-ai/yi-lightning",
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "AI response text"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 150,
    "completion_tokens": 200,
    "total_tokens": 350
  }
}
```

### Error Response Format

```json
{
  "error": {
    "message": "Invalid API key",
    "type": "invalid_request_error",
    "code": "invalid_api_key"
  }
}
```

### Model Selection Decision

```dart
class ModelSelection {
  final String modelId;           // e.g., "01-ai/yi-lightning"
  final String reason;             // e.g., "Job search query detected - using high reasoning model"
  final List<String> fallbackModels;  // e.g., ["google/gemini-flash-1.5-8b", "openai/gpt-4o-mini"]
}
```

### Cost Tracking

```dart
class CostEstimate {
  final String modelId;
  final int inputTokens;
  final int outputTokens;
  final double estimatedCost;
  final DateTime timestamp;
  
  CostEstimate({
    required this.modelId,
    required this.inputTokens,
    required this.outputTokens,
    required this.estimatedCost,
    required this.timestamp,
  });
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Required HTTP Headers Present

*For any* API request made to OpenRouter, the request SHALL include all required headers: Authorization with Bearer token format, HTTP-Referer with app identifier, and X-Title with application name.

**Validates: Requirements 1.2, 1.3, 1.4**

### Property 2: Request Body Structure

*For any* API request, the JSON body SHALL contain all required fields: model (string), messages (array), temperature (number), and max_tokens (number).

**Validates: Requirements 1.5**

### Property 3: Successful Response Parsing

*For any* API response with status code 200 and valid structure, the client SHALL successfully extract the assistant message content from the choices array.

**Validates: Requirements 1.6**

### Property 4: Error Logging on Failure

*For any* API response with non-200 status code, the client SHALL log error details including the status code and response body.

**Validates: Requirements 1.7**

### Property 5: Model Metadata Completeness

*For any* configured model in the ModelConfiguration, the model SHALL have all required metadata fields: id, name, tokenLimit, costPerMillionInputTokens, costPerMillionOutputTokens, and strengths.

**Validates: Requirements 2.5, 2.6**

### Property 6: Task-Based Model Selection

*For any* user message, the ModelSelector SHALL analyze the task type and select a model whose strengths match the task requirements (profile updates → agentic workflows, job search → reasoning, conversational → fast response, creative → creative writing).

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

### Property 7: Model Selection Logging

*For any* model selection decision, the system SHALL log the selected model name and the reason for selection.

**Validates: Requirements 3.5**


### Property 8: Fallback Chain Depth

*For any* task type, the fallback chain SHALL contain at least 3 models (1 primary + 2 fallbacks).

**Validates: Requirements 4.1**

### Property 9: Automatic Fallback on Error

*For any* model that returns an error response, the client SHALL automatically attempt the request with the next model in the fallback chain without manual intervention.

**Validates: Requirements 4.2**

### Property 10: Immediate Fallback on Specific Errors

*For any* API response with status code 401, 429, or 400 with "content_filter" in the error message, the client SHALL immediately try the next fallback model without retrying the failed model.

**Validates: Requirements 4.3, 4.4, 4.5**

### Property 11: Final Error Message in Azerbaijani

*For any* scenario where all models in the fallback chain fail, the client SHALL return a user-friendly error message in Azerbaijani language.

**Validates: Requirements 4.6**

### Property 12: Fallback Event Logging

*For any* fallback occurrence, the system SHALL log which model failed and which fallback model was used.

**Validates: Requirements 4.7**

### Property 13: Error Message Safety

*For any* unexpected error, the displayed error message SHALL NOT contain technical details such as stack traces, API keys, or internal error codes.

**Validates: Requirements 5.4**

### Property 14: Comprehensive Error Logging

*For any* error that occurs, the system SHALL log the full error details including type, message, and context for debugging purposes.

**Validates: Requirements 5.5**


### Property 15: Message Enrichment

*For any* sendMessage call with userProfileJson or jobResultsJson parameters, the user message SHALL be enriched with the provided context data before being sent to the API.

**Validates: Requirements 6.4**

### Property 16: Cost Calculation Accuracy

*For any* API request with known input and output token counts, the cost optimizer SHALL calculate the estimated cost using the formula: (inputTokens / 1,000,000 × inputCost) + (outputTokens / 1,000,000 × outputCost).

**Validates: Requirements 7.1**

### Property 17: Cost Logging

*For any* completed API request, the system SHALL log the model used, input token count, output token count, and estimated cost.

**Validates: Requirements 7.2**

### Property 18: Cost-Aware Model Selection

*For any* scenario where multiple models have equivalent capabilities for a task, the ModelSelector SHALL prefer the model with the lowest cost per token.

**Validates: Requirements 7.3, 7.4**

### Property 19: Session Cost Accumulation

*For any* session with multiple API requests, the cost optimizer SHALL maintain a running total that equals the sum of all individual request costs.

**Validates: Requirements 7.5**

### Property 20: API Key Validation

*For any* API request attempt, the client SHALL validate that the API key is not empty before making the HTTP request.

**Validates: Requirements 8.5**

### Property 21: Configuration-Based Model Addition

*For any* new model added to the ModelConfiguration data structure, the model SHALL become available for selection without requiring code changes in the ModelSelector or FallbackChain.

**Validates: Requirements 8.4**


### Property 22: Response Content Validation

*For any* API response, the client SHALL verify that the response contains a valid, non-empty message content field before treating it as successful.

**Validates: Requirements 9.1, 9.2**

### Property 23: Special Tag Preservation

*For any* API response containing special formatting markers ([PROFILE_UPDATE], [JOB_SEARCH]), the client SHALL preserve these tags exactly as received without modification.

**Validates: Requirements 9.3**

### Property 24: JSON Block Validation

*For any* API response containing JSON blocks within the content, the client SHALL validate that the JSON is properly formatted and complete.

**Validates: Requirements 9.4**

### Property 25: UTF-8 Decoding

*For any* API response body, the client SHALL decode it as UTF-8 to properly handle Azerbaijani characters (ə, ı, ö, ü, ç, ş, ğ).

**Validates: Requirements 9.5**

### Property 26: Conversation Context Preservation

*For any* sequence of multiple requests within a session, the client SHALL maintain conversation history such that each subsequent request includes all previous messages in chronological order.

**Validates: Requirements 10.3**

### Property 27: Model Selection Caching

*For any* two user messages with the same task type within a session, the ModelSelector SHALL return the same model selection from cache without re-analyzing the second message.

**Validates: Requirements 10.4**

### Property 28: Conversation History Limit

*For any* conversation history, the client SHALL maintain at most 20 messages (excluding the system prompt), removing the oldest user-assistant pairs when the limit is exceeded.

**Validates: Requirements 10.5**



## Error Handling

### Error Categories

The system handles four categories of errors with distinct strategies:

**1. Authentication Errors (401)**
- Cause: Invalid or expired API key
- Handling: Immediate fallback to next model (no retry)
- User Message: "API açarı problemi. Zəhmət olmasa, tətbiq tərtibatçısı ilə əlaqə saxlayın."
- Logging: Full error details with API key status (masked)
- Recovery: Requires API key update in configuration

**2. Rate Limiting Errors (429)**
- Cause: Too many requests to a specific model
- Handling: Immediate fallback to next model
- User Message: "Hazırda çox sayda sorğu var. Bir neçə dəqiqə sonra yenidən cəhd edin." (only if all models exhausted)
- Logging: Model ID, rate limit details, retry-after header
- Recovery: Automatic via fallback chain

**3. Content Filter Errors (400 with content_filter)**
- Cause: Request or response violates content policy
- Handling: Immediate fallback to next model
- User Message: Generic error (no specific content filter mention)
- Logging: Model ID, filtered content indicators
- Recovery: Automatic via fallback chain

**4. Network Errors (Timeout, Connection)**
- Cause: Network connectivity issues or slow responses
- Handling: Timeout after 30 seconds, then fallback
- User Message: "İnternet bağlantısı problemi. Zəhmət olmasa, bağlantınızı yoxlayın."
- Logging: Network error type, duration, endpoint
- Recovery: User should check connection and retry


### Error Flow Diagram

```
API Request
    │
    ├─→ Success (200) ──→ Parse Response ──→ Validate Content
    │                                              │
    │                                              ├─→ Valid ──→ Return to User
    │                                              └─→ Invalid ──→ Try Fallback
    │
    ├─→ Auth Error (401) ──→ Log Error ──→ Try Fallback
    │
    ├─→ Rate Limit (429) ──→ Log Error ──→ Try Fallback
    │
    ├─→ Content Filter (400) ──→ Log Error ──→ Try Fallback
    │
    ├─→ Timeout ──→ Log Error ──→ Try Fallback
    │
    └─→ Other Error ──→ Log Error ──→ Try Fallback

Try Fallback
    │
    ├─→ More Models Available ──→ Select Next Model ──→ API Request
    │
    └─→ All Models Exhausted ──→ Return Localized Error Message
```

### Error Response Mapping

| Error Type | Status Code | Detection | User Message (Azerbaijani) |
|------------|-------------|-----------|----------------------------|
| Authentication | 401 | Status code | API açarı problemi. Zəhmət olmasa, tətbiq tərtibatçısı ilə əlaqə saxlayın. |
| Rate Limit | 429 | Status code | Hazırda çox sayda sorğu var. Bir neçə dəqiqə sonra yenidən cəhd edin. |
| Content Filter | 400 | "content_filter" in body | Bağışlayın, hazırda AI xidməti müvəqqəti əlçatmazdır. Bir az sonra yenidən cəhd edin. |
| Network Timeout | N/A | Exception | İnternet bağlantısı problemi. Zəhmət olmasa, bağlantınızı yoxlayın. |
| Invalid Response | 200 | Empty content | Bağışlayın, cavab alınmadı. Yenidən cəhd edin. |
| All Models Failed | Various | Fallback exhausted | Bağışlayın, hazırda AI xidməti müvəqqəti əlçatmazdır. Bir az sonra yenidən cəhd edin. |
| Unexpected | Any | Catch-all | Bağışlayın, bir xəta baş verdi. Zəhmət olmasa, yenidən cəhd edin. |

### Logging Strategy

All errors are logged with structured information for debugging:

```dart
// Error log format
{
  'timestamp': '2024-01-15T10:30:45Z',
  'component': 'OpenRouterClient',
  'errorType': 'RateLimitError',
  'statusCode': 429,
  'modelId': '01-ai/yi-lightning',
  'attemptNumber': 1,
  'fallbackModel': 'google/gemini-flash-1.5-8b',
  'requestId': 'req-abc123',
  'message': 'Rate limit exceeded for model',
  'responseBody': '{"error": {"message": "Rate limit exceeded"}}',
}
```

Sensitive information (API keys, user data) is never logged.



## Testing Strategy

### Dual Testing Approach

This feature requires both unit tests and property-based tests for comprehensive coverage:

**Unit Tests** focus on:
- Specific examples and edge cases
- Integration points between components
- Error conditions with known inputs
- Configuration validation
- Backward compatibility verification

**Property-Based Tests** focus on:
- Universal properties that hold for all inputs
- Comprehensive input coverage through randomization
- Invariants that must be maintained
- Behavior consistency across different scenarios

Both testing approaches are complementary and necessary. Unit tests catch concrete bugs with specific inputs, while property tests verify general correctness across a wide range of inputs.

### Property-Based Testing Configuration

**Framework**: Use the `test` package with custom property-based testing utilities, or integrate a Dart property testing library such as `dartz` or implement generators using `dart:math` for randomization.

**Test Configuration**:
- Minimum 100 iterations per property test (due to randomization)
- Each property test must reference its design document property
- Tag format: `@Tags(['feature:advanced-ai-model-integration', 'property:N'])`
- Comment format: `// Feature: advanced-ai-model-integration, Property N: [property text]`

**Example Property Test Structure**:

```dart
// Feature: advanced-ai-model-integration, Property 1: Required HTTP Headers Present
@Tags(['feature:advanced-ai-model-integration', 'property:1'])
test('All API requests include required headers', () async {
  final client = OpenRouterClient();
  
  for (int i = 0; i < 100; i++) {
    final messages = generateRandomMessages();
    final request = client.buildRequest(messages);
    
    expect(request.headers['Authorization'], startsWith('Bearer '));
    expect(request.headers['HTTP-Referer'], isNotEmpty);
    expect(request.headers['X-Title'], equals('Azerbaijan Job Marketplace'));
  }
});
```


### Unit Test Coverage

**AiService Tests**:
- ✓ sendMessage with profile context enriches message correctly
- ✓ sendMessage with job results enriches message correctly
- ✓ resetChat clears conversation history
- ✓ System prompt is in Azerbaijani and contains job marketplace context
- ✓ Conversation history maintains chronological order
- ✓ History limit of 20 messages is enforced

**OpenRouterClient Tests**:
- ✓ Request construction includes all required headers
- ✓ Request body contains model, messages, temperature, max_tokens
- ✓ Successful response (200) is parsed correctly
- ✓ Empty response content triggers fallback
- ✓ 401 error triggers immediate fallback
- ✓ 429 error triggers immediate fallback
- ✓ 400 with content_filter triggers immediate fallback
- ✓ Timeout after 30 seconds
- ✓ UTF-8 decoding handles Azerbaijani characters
- ✓ Special tags [PROFILE_UPDATE] and [JOB_SEARCH] are preserved

**ModelSelector Tests**:
- ✓ Profile update messages select Gemini Flash
- ✓ Job search messages select Yi Lightning
- ✓ Conversational messages select GPT-4o-mini
- ✓ Creative content messages select Mistral Small
- ✓ Model selection is logged with reason
- ✓ Selection caching works for similar requests
- ✓ Cost calculation is accurate
- ✓ Lower-cost model preferred when capabilities are equal

**FallbackChain Tests**:
- ✓ Each task type has at least 3 models
- ✓ Fallback order is correct for each task type
- ✓ All models exhausted returns Azerbaijani error message
- ✓ Fallback events are logged

**ModelConfiguration Tests**:
- ✓ All four models are configured (Yi Lightning, Gemini Flash, Mistral Small, GPT-4o-mini)
- ✓ Each model has complete metadata (id, name, tokenLimit, costs, strengths)
- ✓ API key is not empty
- ✓ Base URL is correct
- ✓ Timeout is 30 seconds


### Property Test Coverage

Each property from the Correctness Properties section must be implemented as a property-based test:

**Property 1-7**: API Request and Model Selection
- Generate random message content and verify headers, body structure, response parsing, error logging, model metadata, task-based selection, and selection logging

**Property 8-12**: Fallback Mechanism
- Generate random error scenarios and verify fallback chain depth, automatic fallback, immediate fallback on specific errors, final error messages, and fallback logging

**Property 13-14**: Error Handling
- Generate random error types and verify error message safety and comprehensive logging

**Property 15-19**: Context and Cost Management
- Generate random profile/job data and verify message enrichment, cost calculation, cost logging, cost-aware selection, and session cost accumulation

**Property 20-21**: Configuration Management
- Generate random configuration changes and verify API key validation and configuration-based model addition

**Property 22-25**: Response Validation
- Generate random API responses and verify content validation, special tag preservation, JSON block validation, and UTF-8 decoding

**Property 26-28**: Performance Optimization
- Generate random conversation sequences and verify context preservation, selection caching, and history limits

### Test Data Generators

Implement generators for property-based tests:

```dart
// Random message generator
List<Map<String, String>> generateRandomMessages({int count = 5}) {
  final random = Random();
  final roles = ['user', 'assistant'];
  final messages = <Map<String, String>>[];
  
  for (int i = 0; i < count; i++) {
    messages.add({
      'role': roles[random.nextInt(roles.length)],
      'content': generateRandomText(random.nextInt(100) + 10),
    });
  }
  
  return messages;
}

// Random task type message generator
String generateTaskMessage(TaskType type) {
  switch (type) {
    case TaskType.profileUpdate:
      return 'Profilimi doldur və yaxşılaşdır';
    case TaskType.jobSearch:
      return 'Mənə Flutter developer işi tap';
    case TaskType.conversational:
      return 'Salam, necəsən?';
    case TaskType.creative:
      return 'Mənə CV üçün bio yaz';
  }
}

// Random error response generator
http.Response generateErrorResponse(int statusCode, {String? errorType}) {
  final body = jsonEncode({
    'error': {
      'message': 'Error occurred',
      'type': errorType ?? 'api_error',
    }
  });
  
  return http.Response(body, statusCode);
}
```

### Integration Testing

Beyond unit and property tests, integration tests verify end-to-end functionality:

**Integration Test Scenarios**:
1. Complete conversation flow with multiple messages
2. Profile update command triggers correct model and response format
3. Job search command triggers correct model and response format
4. Fallback chain works with real API (using test API key)
5. Cost tracking across multiple requests
6. Conversation history management over 20+ messages
7. Error recovery from network issues
8. Azerbaijani character handling in requests and responses

### Mock Strategy

Use mocks for external dependencies:
- Mock `http.Client` for API requests
- Mock `ModelSelector` for deterministic model selection
- Mock `FallbackChain` for controlled fallback testing
- Use real implementations for `ModelConfiguration` and `AiService`

### Test Execution

```bash
# Run all tests
flutter test

# Run only unit tests
flutter test --exclude-tags property

# Run only property tests
flutter test --tags property

# Run tests for specific feature
flutter test --tags feature:advanced-ai-model-integration

# Run specific property test
flutter test --tags property:1
```

### Coverage Goals

- Unit test coverage: >90% for all components
- Property test coverage: All 28 properties implemented
- Integration test coverage: All critical user flows
- Edge case coverage: All error scenarios and boundary conditions

