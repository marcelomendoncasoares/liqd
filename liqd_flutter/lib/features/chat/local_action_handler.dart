import 'dart:convert';

import 'package:genui/genui.dart';

/// Handles simple UI actions locally without a server round-trip.
abstract final class LocalActionHandler {
  /// Whether [message] is a GenUI client-side error report (not a user prompt).
  static bool isErrorFeedback(ChatMessage message) {
    final envelope = _decodeInteractionEnvelope(message);
    return envelope != null && envelope.containsKey('error');
  }

  static bool tryHandle({
    required SurfaceController controller,
    required ChatMessage message,
  }) {
    final envelope = _decodeInteractionEnvelope(message);
    if (envelope == null) {
      return false;
    }

    try {
      final action = envelope['action'];
      if (action is! Map<String, dynamic>) {
        return false;
      }

      final name = action['name'] as String?;
      if (name == null) {
        return false;
      }

      return switch (name) {
        'increment' => _handleIncrement(controller, action),
        _ => false,
      };
    } on Object {
      return false;
    }
  }

  static bool _handleIncrement(
    SurfaceController controller,
    Map<String, dynamic> action,
  ) {
    final surfaceId = action['surfaceId'] as String? ?? 'counter';
    if (!controller.registry.hasSurface(surfaceId)) {
      return false;
    }

    final path = DataPath('/count');
    final model = controller.store.getDataModel(surfaceId);
    final current = model.getValue<num>(path) ?? 0;
    final next = current + 1;

    controller.handleMessage(
      UpdateDataModel(
        surfaceId: surfaceId,
        path: path,
        value: next,
      ),
    );
    return true;
  }

  static String? _extractInteractionJson(ChatMessage message) {
    for (final part in message.parts) {
      final interaction = part.asUiInteractionPart;
      if (interaction != null) {
        return interaction.interaction;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _decodeInteractionEnvelope(ChatMessage message) {
    final interactionJson = _extractInteractionJson(message);
    if (interactionJson == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(interactionJson);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on Object {
      // Ignore malformed interaction payloads.
    }
    return null;
  }
}
