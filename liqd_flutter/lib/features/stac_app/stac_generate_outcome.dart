/// Result of a Stac generation attempt.
enum StacGenerateOutcomeKind {
  applied,
  noStac,
  validationFailed,
}

final class StacGenerateOutcome {
  const StacGenerateOutcome({
    required this.kind,
    required this.message,
    this.detail,
  });

  final StacGenerateOutcomeKind kind;
  final String message;
  final String? detail;

  bool get isWarning => kind != StacGenerateOutcomeKind.applied;

  static StacGenerateOutcome evaluate({
    required Map<String, dynamic>? stacJson,
    required List<String>? validationErrors,
    required String rawResponse,
  }) {
    if (stacJson != null) {
      return const StacGenerateOutcome(
        kind: StacGenerateOutcomeKind.applied,
        message: '',
      );
    }

    if (validationErrors != null && validationErrors.isNotEmpty) {
      return StacGenerateOutcome(
        kind: StacGenerateOutcomeKind.validationFailed,
        message:
            'The model returned invalid Stac JSON. The preview was not updated.',
        detail: validationErrors.join('\n'),
      );
    }

    return StacGenerateOutcome(
      kind: StacGenerateOutcomeKind.noStac,
      message:
          'The model replied without Stac JSON. The preview was not updated.',
      detail: _prosePreview(rawResponse),
    );
  }

  static String? _prosePreview(String rawResponse) {
    final trimmed = rawResponse.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    const maxLength = 200;
    if (trimmed.length <= maxLength) {
      return trimmed;
    }
    return '${trimmed.substring(0, maxLength)}...';
  }
}
