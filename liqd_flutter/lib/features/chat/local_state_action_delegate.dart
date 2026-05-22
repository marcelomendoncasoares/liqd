import 'package:flutter/widgets.dart';
import 'package:genui/genui.dart';

/// Swallows legacy `event` button actions so they never reach the LLM.
///
/// Interactive apps must use `functionCall` actions (see [LocalStateFunctions])
/// which run locally against the surface data model.
final class LocalStateActionDelegate implements ActionDelegate {
  const LocalStateActionDelegate();

  @override
  bool handleEvent(
    BuildContext context,
    UiEvent event,
    SurfaceContext genUiContext,
    Widget Function(SurfaceDefinition, Catalog, String, DataContext)
    buildWidget,
  ) {
    return event is UserActionEvent;
  }
}
