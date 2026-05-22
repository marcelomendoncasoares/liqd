/// Result of applying a model stream to the GenUI preview.
enum GenUiUpdateOutcomeKind {
  /// The preview surface or data model changed.
  applied,

  /// The model returned prose or empty content with no A2UI.
  noA2ui,

  /// The response mentioned A2UI but nothing could be parsed.
  unparsedA2ui,

  /// A2UI was parsed but the preview did not change.
  notApplied,

  /// GenUI rejected an A2UI message during validation.
  validationFailed,

  /// The user cancelled generation.
  cancelled,
}

/// User-visible feedback for a GenUI generation attempt.
final class GenUiUpdateOutcome {
  const GenUiUpdateOutcome({
    required this.kind,
    required this.message,
    this.detail,
  });

  final GenUiUpdateOutcomeKind kind;
  final String message;
  final String? detail;

  bool get isWarning =>
      kind != GenUiUpdateOutcomeKind.applied &&
      kind != GenUiUpdateOutcomeKind.cancelled;

  /// Evaluates whether the stream produced a valid preview update.
  static GenUiUpdateOutcome evaluate({
    required String rawResponse,
    required int parsedMessageCount,
    required List<String> parsedMessageTypes,
    required bool surfaceUpdated,
    required bool wasCancelled,
  }) {
    if (wasCancelled) {
      return const GenUiUpdateOutcome(
        kind: GenUiUpdateOutcomeKind.cancelled,
        message: 'Generation stopped.',
      );
    }

    final containsA2ui = responseContainsA2ui(rawResponse);
    final dataModelUpdated = parsedMessageTypes.contains('UpdateDataModel');
    final applied = surfaceUpdated || dataModelUpdated;

    if (applied) {
      return const GenUiUpdateOutcome(
        kind: GenUiUpdateOutcomeKind.applied,
        message: '',
      );
    }

    if (!containsA2ui && parsedMessageCount == 0) {
      return GenUiUpdateOutcome(
        kind: GenUiUpdateOutcomeKind.noA2ui,
        message:
            'The model replied with text only. The preview was not updated.',
        detail: _prosePreview(rawResponse),
      );
    }

    if (containsA2ui && parsedMessageCount == 0) {
      return const GenUiUpdateOutcome(
        kind: GenUiUpdateOutcomeKind.unparsedA2ui,
        message:
            'The model sent UI data that could not be parsed. '
            'The preview was not updated.',
      );
    }

    return const GenUiUpdateOutcome(
      kind: GenUiUpdateOutcomeKind.notApplied,
      message:
          'The update was invalid or incomplete. '
          'The preview was not changed.',
    );
  }

  static GenUiUpdateOutcome validationFailed({
    required String message,
    String? surfaceId,
    String? path,
  }) {
    final location = [
      if (surfaceId != null && surfaceId.isNotEmpty) 'surface $surfaceId',
      if (path != null && path.isNotEmpty) 'path $path',
    ].join(', ');

    return GenUiUpdateOutcome(
      kind: GenUiUpdateOutcomeKind.validationFailed,
      message: location.isEmpty
          ? 'Invalid UI update: $message'
          : 'Invalid UI update ($location): $message',
      detail: message,
    );
  }

  static bool responseContainsA2ui(String response) {
    final lower = response.toLowerCase();
    return lower.contains('updatecomponents') ||
        lower.contains('createsurface') ||
        lower.contains('updatedatamodel') ||
        lower.contains('deletesurface');
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
