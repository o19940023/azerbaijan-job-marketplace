/// Cost estimate for an API request
class CostEstimate {
  /// The model identifier used for this request
  final String modelId;

  /// Number of input tokens consumed
  final int inputTokens;

  /// Number of output tokens generated
  final int outputTokens;

  /// Estimated cost in USD
  final double estimatedCost;

  /// Timestamp when the request was made
  final DateTime timestamp;

  const CostEstimate({
    required this.modelId,
    required this.inputTokens,
    required this.outputTokens,
    required this.estimatedCost,
    required this.timestamp,
  });

  /// Total tokens used (input + output)
  int get totalTokens => inputTokens + outputTokens;

  /// Cost per token in USD
  double get costPerToken => totalTokens > 0 ? estimatedCost / totalTokens : 0.0;

  @override
  String toString() {
    return 'CostEstimate(model: $modelId, tokens: $totalTokens '
        '(in: $inputTokens, out: $outputTokens), cost: \$${estimatedCost.toStringAsFixed(6)}, '
        'time: ${timestamp.toIso8601String()})';
  }

  /// Creates a copy with updated fields
  CostEstimate copyWith({
    String? modelId,
    int? inputTokens,
    int? outputTokens,
    double? estimatedCost,
    DateTime? timestamp,
  }) {
    return CostEstimate(
      modelId: modelId ?? this.modelId,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
