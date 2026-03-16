/// Model metadata containing configuration and capabilities for an AI model
class ModelMetadata {
  /// Unique identifier for the model (e.g., "01-ai/yi-lightning")
  final String id;

  /// Human-readable name of the model
  final String name;

  /// Maximum number of tokens (input + output) the model can handle
  final int tokenLimit;

  /// Cost per million input tokens in USD
  final double costPerMillionInputTokens;

  /// Cost per million output tokens in USD
  final double costPerMillionOutputTokens;

  /// List of model strengths/capabilities
  /// Examples: 'reasoning', 'agentic-workflows', 'creative-writing', 'conversational', 'fast'
  final List<String> strengths;

  const ModelMetadata({
    required this.id,
    required this.name,
    required this.tokenLimit,
    required this.costPerMillionInputTokens,
    required this.costPerMillionOutputTokens,
    required this.strengths,
  });

  /// Checks if the model has a specific strength
  bool hasStrength(String strength) {
    return strengths.contains(strength);
  }

  /// Calculates estimated cost for a request
  double calculateCost({
    required int inputTokens,
    required int outputTokens,
  }) {
    final inputCost = (inputTokens / 1000000) * costPerMillionInputTokens;
    final outputCost = (outputTokens / 1000000) * costPerMillionOutputTokens;
    return inputCost + outputCost;
  }

  @override
  String toString() {
    return 'ModelMetadata(id: $id, name: $name, tokenLimit: $tokenLimit, '
        'inputCost: \$$costPerMillionInputTokens/M, outputCost: \$$costPerMillionOutputTokens/M, '
        'strengths: $strengths)';
  }
}
