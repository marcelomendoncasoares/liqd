import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:genui/genui.dart';

import 'local_action_handler.dart';

/// Handles calculator-style UI events locally before they reach the LLM.
final class LocalCalculatorActionDelegate implements ActionDelegate {
  const LocalCalculatorActionDelegate({required this.controller});

  final SurfaceController controller;

  @override
  bool handleEvent(
    BuildContext context,
    UiEvent event,
    SurfaceContext genUiContext,
    Widget Function(SurfaceDefinition, Catalog, String, DataContext)
    buildWidget,
  ) {
    if (event is! UserActionEvent) {
      return false;
    }

    final message = ChatMessage.user(
      '',
      parts: [
        UiInteractionPart.create(
          jsonEncode({
            'version': 'v0.9',
            'action': {
              ...event.toMap(),
              surfaceIdKey: genUiContext.surfaceId,
            },
          }),
        ),
      ],
    );

    if (LocalActionHandler.isErrorFeedback(message)) {
      return true;
    }

    return LocalActionHandler.tryHandle(
          controller: controller,
          message: message,
        ) ||
        LocalActionHandler.shouldConsumeWithoutServer(
          controller: controller,
          message: message,
        );
  }
}
