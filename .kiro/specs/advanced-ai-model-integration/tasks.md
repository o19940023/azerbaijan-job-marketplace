# Implementation Plan: Advanced AI Model Integration

## Overview

This implementation replaces the failing Azure-hosted AI models with OpenRouter API integration, providing multi-model support with intelligent selection, automatic fallback, and cost optimization. The implementation follows a layered architecture with clear separation between configuration, model selection, API communication, and the existing AI assistant interface.

## Tasks

- [x] 1. Create model configuration and data structures
  - Create `lib/features/ai_assistant/data/models/model_metadata.dart` with ModelMetadata class
  - Create `lib/features/ai_assistant/data/models/model_selection.dart` with ModelSelection and TaskType enum
  - Create `lib/features/ai_assistant/data/models/cost_estimate.dart` with CostEstimate class
  - Create `lib/features/ai_assistant/data/config/model_configuration.dart` with all model definitions and API configuration
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 8.1, 8.2, 8.3_

- [ ]* 1.1 Write property test for model configuration
  - **Property 5: Model Metadata Completeness**
  - **Validates: Requirements 2.5, 2.6**

- [x] 2. Implement ModelSelector component
  - [x] 2.1 Create `lib/features/ai_assistant/data/services/model_selector.dart` with task analysis logic
    - Implement task type detection (profile update, job search, conversational, creative)
    - Implement model selection based on task type and model strengths
    - Implement cost calculation for model selection
    - Implement selection caching for performance
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 7.3, 7.4, 10.4_

  - [ ]* 2.2 Write property test for task-based model selection
    - **Property 6: Task-Based Model Selection**
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4**

  - [ ]* 2.3 Write property test for model selection logging
    - **Property 7: Model Selection Logging**
    - **Validates: Requirements 3.5**

  - [ ]* 2.4 Write unit tests for ModelSelector
    - Test profile update messages select Gemini Flash
    - Test job search messages select Yi Lightning
    - Test conversational messages select GPT-4o-mini
    - Test creative content messages select Mistral Small
    - Test cost-aware selection when capabilities are equal
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 7.3, 7.4_

- [x] 3. Implement FallbackChain component
  - [x] 3.1 Create `lib/features/ai_assistant/data/services/fallback_chain.dart` with fallback logic
    - Implement fallback model sequences for each task type
    - Implement error code detection (401, 429, 400 with content_filter)
    - Implement localized error messages in Azerbaijani
    - Implement fallback event logging
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 5.1, 5.2, 5.3, 5.4_

  - [ ]* 3.2 Write property test for fallback chain depth
    - **Property 8: Fallback Chain Depth**
    - **Validates: Requirements 4.1**

  - [ ]* 3.3 Write property test for automatic fallback
    - **Property 9: Automatic Fallback on Error**
    - **Validates: Requirements 4.2**

  - [ ]* 3.4 Write property test for immediate fallback on specific errors
    - **Property 10: Immediate Fallback on Specific Errors**
    - **Validates: Requirements 4.3, 4.4, 4.5**

  - [ ]* 3.5 Write unit tests for FallbackChain
    - Test each task type has at least 3 models
    - Test fallback order is correct
    - Test all models exhausted returns Azerbaijani error message
    - _Requirements: 4.1, 4.6_

- [ ] 4. Checkpoint - Review core components
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Implement OpenRouterClient
  - [x] 5.1 Create `lib/features/ai_assistant/data/services/openrouter_client.dart` with HTTP communication
    - Implement request construction with required headers (Authorization, HTTP-Referer, X-Title)
    - Implement request body formatting (model, messages, temperature, max_tokens)
    - Implement response parsing and content extraction
    - Implement timeout handling (30 seconds)
    - Implement error detection and fallback coordination
    - Implement UTF-8 decoding for Azerbaijani characters
    - Implement special tag preservation ([PROFILE_UPDATE], [JOB_SEARCH])
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 4.2, 4.3, 4.4, 4.5, 5.5, 5.6, 9.1, 9.2, 9.3, 9.5, 10.1, 10.2_

  - [ ]* 5.2 Write property test for required HTTP headers
    - **Property 1: Required HTTP Headers Present**
    - **Validates: Requirements 1.2, 1.3, 1.4**

  - [ ]* 5.3 Write property test for request body structure
    - **Property 2: Request Body Structure**
    - **Validates: Requirements 1.5**

  - [ ]* 5.4 Write property test for successful response parsing
    - **Property 3: Successful Response Parsing**
    - **Validates: Requirements 1.6**

  - [ ]* 5.5 Write property test for error logging
    - **Property 4: Error Logging on Failure**
    - **Validates: Requirements 1.7**

  - [ ]* 5.6 Write property test for UTF-8 decoding
    - **Property 25: UTF-8 Decoding**
    - **Validates: Requirements 9.5**

  - [ ]* 5.7 Write unit tests for OpenRouterClient
    - Test request includes all required headers
    - Test 401 error triggers immediate fallback
    - Test 429 error triggers immediate fallback
    - Test 400 with content_filter triggers immediate fallback
    - Test timeout after 30 seconds
    - Test special tags are preserved
    - Test empty response content triggers fallback
    - _Requirements: 1.2, 1.3, 1.4, 4.3, 4.4, 4.5, 5.6, 9.1, 9.2, 9.3_

- [ ] 6. Implement cost tracking and optimization
  - [ ] 6.1 Create `lib/features/ai_assistant/data/services/cost_optimizer.dart` with cost tracking
    - Implement cost calculation based on token counts
    - Implement cost logging for each request
    - Implement session cost accumulation
    - _Requirements: 7.1, 7.2, 7.5_

  - [ ]* 6.2 Write property test for cost calculation accuracy
    - **Property 16: Cost Calculation Accuracy**
    - **Validates: Requirements 7.1**

  - [ ]* 6.3 Write property test for cost logging
    - **Property 17: Cost Logging**
    - **Validates: Requirements 7.2**

  - [ ]* 6.4 Write property test for session cost accumulation
    - **Property 19: Session Cost Accumulation**
    - **Validates: Requirements 7.5**

- [x] 7. Implement AiService facade
  - [x] 7.1 Create `lib/features/ai_assistant/data/services/ai_service.dart` with conversation management
    - Implement conversation history management (list of messages)
    - Implement system prompt initialization in Azerbaijani
    - Implement message enrichment with profile and job context
    - Implement sendMessage method with backward-compatible signature
    - Implement resetChat method
    - Implement conversation history limit (20 messages)
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 10.3, 10.5_

  - [ ]* 7.2 Write property test for message enrichment
    - **Property 15: Message Enrichment**
    - **Validates: Requirements 6.4**

  - [ ]* 7.3 Write property test for conversation context preservation
    - **Property 26: Conversation Context Preservation**
    - **Validates: Requirements 10.3**

  - [ ]* 7.4 Write property test for conversation history limit
    - **Property 28: Conversation History Limit**
    - **Validates: Requirements 10.5**

  - [ ]* 7.5 Write unit tests for AiService
    - Test sendMessage with profile context enriches message correctly
    - Test sendMessage with job results enriches message correctly
    - Test resetChat clears conversation history
    - Test system prompt is in Azerbaijani
    - Test conversation history maintains chronological order
    - Test history limit of 20 messages is enforced
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 10.3, 10.5_

- [ ] 8. Checkpoint - Review service layer
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Integrate with existing AI assistant
  - [x] 9.1 Update `lib/features/ai_assistant/presentation/ai_assistant_cubit.dart` to use new AiService
    - Replace old AI service instantiation with new AiService
    - Update dependency injection if needed
    - Ensure backward compatibility with existing cubit methods
    - _Requirements: 6.1, 6.2, 6.3_

  - [ ]* 9.2 Write integration tests for AI assistant cubit
    - Test complete conversation flow with multiple messages
    - Test profile update command triggers correct model
    - Test job search command triggers correct model
    - Test error recovery from network issues
    - _Requirements: 3.1, 3.2, 4.2, 5.3_

- [ ] 10. Update dependency injection
  - [ ] 10.1 Update `lib/injection_container.dart` to register new services
    - Register ModelConfiguration as singleton
    - Register ModelSelector with ModelConfiguration dependency
    - Register FallbackChain with ModelConfiguration dependency
    - Register CostOptimizer as singleton
    - Register OpenRouterClient with dependencies
    - Register AiService with OpenRouterClient dependency
    - _Requirements: 8.1, 8.2_

- [ ] 11. Add configuration validation
  - [ ] 11.1 Add API key validation in ModelConfiguration
    - Implement validation that API key is not empty
    - Add validation error messages
    - _Requirements: 8.5_

  - [ ]* 11.2 Write property test for API key validation
    - **Property 20: API Key Validation**
    - **Validates: Requirements 8.5**

  - [ ]* 11.3 Write unit tests for ModelConfiguration
    - Test all four models are configured
    - Test each model has complete metadata
    - Test API key is not empty
    - Test base URL is correct
    - Test timeout is 30 seconds
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 8.5_

- [ ] 12. Final integration and testing
  - [ ] 12.1 Wire all components together
    - Verify all dependencies are properly injected
    - Verify existing AI assistant overlay works with new service
    - Test end-to-end flow from UI to API and back
    - _Requirements: 6.1, 6.2, 6.3_

  - [ ]* 12.2 Write end-to-end integration tests
    - Test complete conversation flow with real components
    - Test fallback chain works across multiple failures
    - Test cost tracking across multiple requests
    - Test Azerbaijani character handling in requests and responses
    - _Requirements: 4.2, 4.6, 7.2, 9.5_

- [ ] 13. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- The implementation uses Dart and follows Flutter best practices
- All property tests should run at least 100 iterations
- Property tests should be tagged with `@Tags(['feature:advanced-ai-model-integration', 'property:N'])`
- The design maintains backward compatibility with existing AI assistant interface
- Configuration-driven approach allows easy model updates without code changes
- Multi-model fallback ensures high availability even when individual models fail
