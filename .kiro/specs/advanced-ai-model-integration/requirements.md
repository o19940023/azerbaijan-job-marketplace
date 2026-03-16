# Requirements Document

## Introduction

This feature integrates advanced AI models into the Azerbaijan Job Marketplace app's AI assistant to replace failing models and provide better intelligence, higher token limits, and improved cost-effectiveness. The current implementation experiences 401 authentication errors with Azure-hosted models (DeepSeek-V3, Mistral-large-2411, gpt-4o-mini). The new implementation will use OpenRouter API with multiple high-quality models optimized for different use cases.

## Glossary

- **AI_Assistant**: The voice-enabled AI assistant feature in the Azerbaijan Job Marketplace app that helps users with job search, profile completion, and general queries
- **OpenRouter**: The API gateway service that provides unified access to multiple AI models from different providers
- **Model_Selector**: The component responsible for choosing the appropriate AI model based on task type and user context
- **API_Client**: The HTTP client that communicates with the OpenRouter API endpoint
- **Fallback_Chain**: The ordered sequence of alternative models to try when the primary model fails
- **Token_Limit**: The maximum number of tokens (input + output) available for a model within its quota period
- **Cost_Optimizer**: The logic that selects models based on cost-effectiveness for different task types

## Requirements

### Requirement 1: OpenRouter API Integration

**User Story:** As a developer, I want to integrate OpenRouter API, so that the AI assistant can access multiple high-quality AI models through a unified interface.

#### Acceptance Criteria

1. THE API_Client SHALL use the OpenRouter base URL "https://openrouter.ai/api/v1/chat/completions"
2. WHEN making API requests, THE API_Client SHALL include the authorization header with format "Bearer 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"
3. WHEN making API requests, THE API_Client SHALL include the "HTTP-Referer" header with the app identifier
4. WHEN making API requests, THE API_Client SHALL include the "X-Title" header with value "Azerbaijan Job Marketplace"
5. THE API_Client SHALL send requests with proper JSON structure including model, messages, temperature, and max_tokens fields
6. WHEN the API returns status code 200, THE API_Client SHALL parse the response and extract the assistant message content
7. IF the API returns a non-200 status code, THEN THE API_Client SHALL log the error details including status code and response body

### Requirement 2: Multi-Model Configuration

**User Story:** As a system administrator, I want to configure multiple AI models with different capabilities, so that the assistant can choose the best model for each task.

#### Acceptance Criteria

1. THE Model_Selector SHALL support configuration for Z.ai GLM 4.7 model with identifier "01-ai/yi-lightning"
2. THE Model_Selector SHALL support configuration for Google Gemini 3 Flash Preview model with identifier "google/gemini-flash-1.5-8b"
3. THE Model_Selector SHALL support configuration for Mistral Small Creative model with identifier "mistralai/mistral-small"
4. THE Model_Selector SHALL support configuration for OpenAI GPT-5.2 Chat model with identifier "openai/gpt-4o-mini"
5. WHEN a model is configured, THE Model_Selector SHALL store its token limit, cost per million input tokens, and cost per million output tokens
6. THE Model_Selector SHALL maintain model metadata including strengths (programming, creative writing, conversational, agentic workflows)

### Requirement 3: Intelligent Model Selection

**User Story:** As a user, I want the AI assistant to automatically select the best model for my request, so that I get optimal responses while minimizing costs.

#### Acceptance Criteria

1. WHEN the user request contains profile update commands, THE Model_Selector SHALL select Google Gemini 3 Flash Preview for its agentic workflow capabilities
2. WHEN the user request contains job search queries, THE Model_Selector SHALL select Z.ai GLM 4.7 for its strong reasoning and high token limit
3. WHEN the user request is conversational or general inquiry, THE Model_Selector SHALL select OpenAI GPT-5.2 Chat for its fast conversational abilities
4. WHERE creative content generation is needed, THE Model_Selector SHALL select Mistral Small Creative
5. WHEN model selection is complete, THE Model_Selector SHALL log the selected model name and reason for selection

### Requirement 4: Fallback Mechanism

**User Story:** As a user, I want the AI assistant to continue working even if one model fails, so that I always receive responses to my queries.

#### Acceptance Criteria

1. THE Fallback_Chain SHALL define a primary model and at least two fallback models for each task type
2. WHEN the primary model returns an error response, THE API_Client SHALL attempt the request with the next model in the Fallback_Chain
3. WHEN a model fails with status code 401, THE API_Client SHALL immediately try the next model without retrying the failed model
4. WHEN a model fails with status code 429 (rate limit), THE API_Client SHALL try the next model in the Fallback_Chain
5. WHEN a model fails with status code 400 and error message contains "content_filter", THE API_Client SHALL try the next model in the Fallback_Chain
6. IF all models in the Fallback_Chain fail, THEN THE API_Client SHALL return a user-friendly error message in Azerbaijani language
7. WHEN a fallback occurs, THE API_Client SHALL log which model failed and which fallback model was used

### Requirement 5: Error Handling and Resilience

**User Story:** As a user, I want clear error messages when the AI assistant encounters problems, so that I understand what went wrong and can take appropriate action.

#### Acceptance Criteria

1. WHEN the API_Client receives a 401 authentication error, THE AI_Assistant SHALL display "API açarı problemi. Zəhmət olmasa, tətbiq tərtibatçısı ilə əlaqə saxlayın."
2. WHEN the API_Client receives a 429 rate limit error from all models, THE AI_Assistant SHALL display "Hazırda çox sayda sorğu var. Bir neçə dəqiqə sonra yenidən cəhd edin."
3. WHEN the API_Client receives a network timeout error, THE AI_Assistant SHALL display "İnternet bağlantısı problemi. Zəhmət olmasa, bağlantınızı yoxlayın."
4. WHEN the API_Client receives an unexpected error, THE AI_Assistant SHALL display a generic error message without exposing technical details
5. WHEN any error occurs, THE API_Client SHALL log the full error details for debugging purposes
6. THE API_Client SHALL implement a timeout of 30 seconds for each API request

### Requirement 6: Backward Compatibility

**User Story:** As a developer, I want the new AI service to maintain the same interface as the old service, so that existing code continues to work without modifications.

#### Acceptance Criteria

1. THE API_Client SHALL maintain the existing sendMessage method signature with parameters userMessage, userProfileJson, and jobResultsJson
2. THE API_Client SHALL maintain the existing resetChat method for clearing conversation history
3. THE API_Client SHALL continue to support the system prompt in Azerbaijani language for job marketplace context
4. THE API_Client SHALL continue to support message enrichment with user profile data and job results
5. THE API_Client SHALL maintain the conversation history in the same format as the previous implementation

### Requirement 7: Cost Monitoring and Optimization

**User Story:** As a system administrator, I want to monitor AI API costs, so that I can optimize spending and stay within budget.

#### Acceptance Criteria

1. THE Cost_Optimizer SHALL calculate estimated cost for each API request based on input and output token counts
2. WHEN a request is completed, THE Cost_Optimizer SHALL log the model used, token counts, and estimated cost
3. THE Cost_Optimizer SHALL prefer lower-cost models when multiple models have similar capabilities for a task
4. WHEN selecting between models with similar capabilities, THE Cost_Optimizer SHALL choose the model with the lowest cost per token
5. THE Cost_Optimizer SHALL maintain a running total of estimated costs per session

### Requirement 8: Configuration Management

**User Story:** As a developer, I want to easily update API keys and model configurations, so that I can adapt to changes without modifying code.

#### Acceptance Criteria

1. THE API_Client SHALL read the OpenRouter API key from a configuration constant
2. WHERE the API key needs to be updated, THE API_Client SHALL allow key replacement through a single configuration point
3. THE Model_Selector SHALL read model configurations from a structured data format
4. WHEN a new model needs to be added, THE Model_Selector SHALL support adding the model through configuration without code changes
5. THE API_Client SHALL validate that the API key is not empty before making requests

### Requirement 9: Response Quality Validation

**User Story:** As a user, I want to receive complete and properly formatted responses, so that the AI assistant provides useful information.

#### Acceptance Criteria

1. WHEN the API returns a response, THE API_Client SHALL verify that the response contains a valid message content field
2. IF the response message is empty or null, THEN THE API_Client SHALL treat it as an error and try the fallback model
3. THE API_Client SHALL preserve special formatting markers in responses including [PROFILE_UPDATE] and [JOB_SEARCH] tags
4. WHEN the response contains JSON blocks, THE API_Client SHALL ensure the JSON is properly formatted and complete
5. THE API_Client SHALL decode UTF-8 response bodies to properly handle Azerbaijani characters

### Requirement 10: Performance Optimization

**User Story:** As a user, I want fast AI responses, so that I can have smooth conversations with the assistant.

#### Acceptance Criteria

1. THE API_Client SHALL reuse HTTP client connections for multiple requests
2. THE API_Client SHALL set appropriate timeout values to prevent indefinite waiting
3. WHEN multiple requests are made in sequence, THE API_Client SHALL maintain conversation context efficiently
4. THE Model_Selector SHALL cache model selection decisions for similar request types within a session
5. THE API_Client SHALL limit conversation history to the most recent 20 messages to reduce token usage
