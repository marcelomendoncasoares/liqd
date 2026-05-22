import 'dart:convert';

import 'package:genui/genui.dart';

/// Handles simple UI actions locally without a server round-trip.
abstract final class LocalActionHandler {
  static bool tryHandle({
    required SurfaceController controller,
    required ChatMessage message,
  }) {
    final interactionJson = _extractInteractionJson(message);
    if (interactionJson == null) {
      return false;
    }

    try {
      final envelope = jsonDecode(interactionJson) as Map<String, dynamic>;
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
}
