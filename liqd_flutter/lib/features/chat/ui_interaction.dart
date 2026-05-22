import 'dart:convert';

import 'package:genui/genui.dart';

/// Helpers for GenUI UI interaction messages on the client submit stream.
abstract final class UiInteraction {
  static bool isUiInteraction(ChatMessage message) {
    return _decodeEnvelope(message) != null;
  }

  static bool isErrorFeedback(ChatMessage message) {
    final envelope = _decodeEnvelope(message);
    return envelope != null && envelope.containsKey('error');
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
