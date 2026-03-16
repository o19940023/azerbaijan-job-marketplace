/// Types of tasks that the AI assistant can handle
enum TaskType {
  /// Profile modification and updates (requires agentic workflow capabilities)
  profileUpdate,

  /// Job search and query processing (requires strong reasoning)
  jobSearch,

  /// General conversation and inquiries (requires fast conversational abilities)
  conversational,

  /// Content generation and creative writing
  creative,
}

/// Result of model selection process
class ModelSelection {
  /// The selected model identifier (e.g., "01-ai/yi-lightning")
  final String modelId;

  /// Human-readable reason for selecting this model
  final String reason;

  /// Ordered list of fallback model identifiers to try if primary fails
  final List<String> fallbackModels;

  const ModelSelection({
    required this.modelId,
    required this.reason,
    required this.fallbackModels,
  });

  @override
  String toString() {
    return 'ModelSelection(modelId: $modelId, reason: $reason, '
        'fallbacks: ${fallbackModels.length})';
  }
}
