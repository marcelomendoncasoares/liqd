import 'dart:convert';

import 'package:genui/genui.dart';

/// Helpers for GenUI UI interaction messages on the client submit stream.
/// Parsed GenUI validation error envelope from the submit stream.
final class GenUiValidationFeedback {
  const GenUiValidationFeedback({
    required this.code,
    required this.message,
    this.surfaceId,
    this.path,
  });

  final String code;
  final String message;
  final String? surfaceId;
  final String? path;
}

abstract final class UiInteraction {
  static bool isUiInteraction(ChatMessage message) {
    return _decodeEnvelope(message) != null;
  }

  static bool isErrorFeedback(ChatMessage message) {
    return parseErrorFeedback(message) != null;
  }

  static GenUiValidationFeedback? parseErrorFeedback(ChatMessage message) {
    final envelope = _decodeEnvelope(message);
    if (envelope == null || !envelope.containsKey('error')) {
      return null;
    }

    final error = envelope['error'];
    if (error is! Map) {
      return null;
    }

    final errorMap = error.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    return GenUiValidationFeedback(
      code: errorMap['code'] as String? ?? 'UNKNOWN',
      message: errorMap['message'] as String? ?? 'Validation failed',
      surfaceId: errorMap['surfaceId'] as String?,
      path: errorMap['path'] as String?,
    );
  }

  static Map<String, dynamic>? _decodeEnvelope(ChatMessage message) {
    for (final part in message.parts) {
      final interaction = part.asUiInteractionPart;
      if (interaction == null) {
        continue;
      }
      try {
        final decoded = jsonDecode(interaction.interaction);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } on Object {
        return null;
      }
    }
    return null;
  }
}
