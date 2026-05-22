import 'dart:convert';

import 'package:genui/genui.dart';

/// Handles simple UI actions locally without a server round-trip.
abstract final class LocalActionHandler {
  static final _defaultDisplayPath = DataPath('/display');
  static final _countPath = DataPath('/count');

  /// Whether [message] is a GenUI UI interaction (button tap, etc.).
  static bool isUiInteraction(ChatMessage message) {
    return _decodeInteractionEnvelope(message) != null;
  }

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
      if (action is! Map) {
        return false;
      }
      return _handleAction(controller, _stringKeyMap(action));
    } on Object {
      return false;
    }
  }

  /// Swallows calculator button taps that should never reach the LLM.
  static bool shouldConsumeWithoutServer({
    required SurfaceController controller,
    required ChatMessage message,
  }) {
    final envelope = _decodeInteractionEnvelope(message);
    if (envelope == null) {
      return false;
    }

    final action = envelope['action'];
    if (action is! Map) {
      return false;
    }
    final actionMap = _stringKeyMap(action);
    final surfaceId = _resolveSurfaceId(controller, actionMap);
    if (surfaceId == null || !_isCalculatorLike(controller, surfaceId)) {
      return false;
    }

    final name = (actionMap['name'] as String?)?.toLowerCase() ?? '';
    if (_isCalculatorActionName(name)) {
      return true;
    }

    final sourceId = (actionMap['sourceComponentId'] as String?)?.toLowerCase();
    return sourceId != null &&
        (sourceId.startsWith('btn') || sourceId.contains('button'));
  }

  static bool _isCalculatorActionName(String name) {
    return const {
      'digit',
      'number',
      'input',
      'append',
      'appenddigit',
      'clear',
      'reset',
      'cleardisplay',
      'clear_display',
      'equals',
      'equal',
      'calculate',
      'evaluate',
      'compute',
      'decimal',
      'dot',
      'period',
      'point',
      'add',
      'plus',
      'subtract',
      'minus',
      'sub',
      'multiply',
      'mul',
      'times',
      'divide',
      'div',
      'operator',
      'op',
    }.contains(name);
  }

  static bool _isCalculatorLike(
    SurfaceController controller,
    String surfaceId,
  ) {
    if (surfaceId == 'calculator') {
      return true;
    }

    final definition = controller.registry.getSurface(surfaceId);
    if (definition == null) {
      return false;
    }

    for (final component in definition.components.values) {
      if (component.type != 'Text') {
        continue;
      }
      final text = component.properties['text'];
      if (text is Map && text['path'] == '/display') {
        return true;
      }
    }
    return false;
  }

  /// Appends [digit] to a calculator display string.
  static String appendDigit(String current, String digit) {
    if (digit == '.') {
      final segment = current.split(RegExp(r'[+\-*/]')).last;
      if (segment.contains('.')) {
        return current;
      }
      if (RegExp(r'[+\-*/]$').hasMatch(current)) {
        return '${current}0.';
      }
      return current == '0' ? '0.' : '$current.';
    }

    if (digit.length != 1 || !RegExp(r'^\d$').hasMatch(digit)) {
      return current;
    }
    if (current == '0') {
      return digit;
    }
    return current + digit;
  }

  static bool _handleAction(
    SurfaceController controller,
    Map<String, dynamic> action,
  ) {
    final name = (action['name'] as String?)?.toLowerCase() ?? '';

    if (name == 'increment') {
      return _handleIncrement(controller, action);
    }

    final surfaceId = _resolveSurfaceId(controller, action);
    if (surfaceId == null) {
      return false;
    }

    if (_isClearAction(name, action)) {
      return _updateDisplay(controller, surfaceId, '0');
    }

    if (_isEqualsAction(name, action)) {
      return _handleEquals(controller, action, surfaceId);
    }

    final label = _buttonLabelText(controller, surfaceId, action);
    if (label == '=') {
      return _handleEquals(controller, action, surfaceId);
    }

    final operator = _inferOperator(controller, surfaceId, name, action);
    if (operator != null) {
      return _appendOperator(controller, action, surfaceId, operator);
    }

    final digit = _inferDigit(controller, surfaceId, name, action);
    if (digit != null) {
      return _appendDigit(controller, action, surfaceId, digit);
    }

    if (_isCalculatorLike(controller, surfaceId)) {
      return true;
    }

    return false;
  }

  static bool _handleIncrement(
    SurfaceController controller,
    Map<String, dynamic> action,
  ) {
    final surfaceId = action['surfaceId'] as String? ?? 'counter';
    if (!controller.registry.hasSurface(surfaceId)) {
      return false;
    }

    final model = controller.store.getDataModel(surfaceId);
    final current = model.getValue<num>(_countPath) ?? 0;

    controller.handleMessage(
      UpdateDataModel(
        surfaceId: surfaceId,
        path: _countPath,
        value: current + 1,
      ),
    );
    return true;
  }

  static bool _handleEquals(
    SurfaceController controller,
    Map<String, dynamic> action,
    String surfaceId,
  ) {
    final displayPath = _displayPathFor(controller, surfaceId);
    var current = _readDisplay(controller, surfaceId, displayPath);
    current = current.replaceAll(RegExp(r'[+\-*/]+$'), '');
    if (current.isEmpty) {
      return true;
    }

    final result = _evaluateExpression(current);
    if (result == null) {
      return _writeDisplay(controller, surfaceId, displayPath, 'Error');
    }
    return _writeDisplay(
      controller,
      surfaceId,
      displayPath,
      _formatResult(result),
    );
  }

  static bool _appendDigit(
    SurfaceController controller,
    Map<String, dynamic> action,
    String surfaceId,
    String digit,
  ) {
    final displayPath = _displayPathFor(controller, surfaceId);
    final current = _readDisplay(controller, surfaceId, displayPath);
    final next = appendDigit(current, digit);
    return _writeDisplay(controller, surfaceId, displayPath, next);
  }

  static bool _appendOperator(
    SurfaceController controller,
    Map<String, dynamic> action,
    String surfaceId,
    String operator,
  ) {
    final displayPath = _displayPathFor(controller, surfaceId);
    final current = _readDisplay(controller, surfaceId, displayPath);
    if (current.isEmpty || current == '0') {
      return true;
    }

    final trimmed = RegExp(r'[+\-*/]$').hasMatch(current)
        ? current.substring(0, current.length - 1)
        : current;
    return _writeDisplay(
      controller,
      surfaceId,
      displayPath,
      '$trimmed$operator',
    );
  }

  static bool _updateDisplay(
    SurfaceController controller,
    String surfaceId,
    String value,
  ) {
    final displayPath = _displayPathFor(controller, surfaceId);
    return _writeDisplay(controller, surfaceId, displayPath, value);
  }

  static bool _writeDisplay(
    SurfaceController controller,
    String surfaceId,
    DataPath displayPath,
    String value,
  ) {
    controller.handleMessage(
      UpdateDataModel(
        surfaceId: surfaceId,
        path: displayPath,
        value: value,
      ),
    );
    return true;
  }

  static String _readDisplay(
    SurfaceController controller,
    String surfaceId,
    DataPath displayPath,
  ) {
    final value = controller.store
        .getDataModel(surfaceId)
        .getValue<Object?>(
          displayPath,
        );
    if (value == null) {
      return '0';
    }
    return value.toString();
  }

  static String? _resolveSurfaceId(
    SurfaceController controller,
    Map<String, dynamic> action,
  ) {
    final explicit = action['surfaceId'] as String?;
    if (explicit != null && controller.registry.hasSurface(explicit)) {
      return explicit;
    }

    for (final fallback in ['calculator', 'counter']) {
      if (controller.registry.hasSurface(fallback)) {
        return fallback;
      }
    }

    final active = controller.activeSurfaceIds;
    if (active.length == 1) {
      return active.first;
    }
    return null;
  }

  static DataPath _displayPathFor(
    SurfaceController controller,
    String surfaceId,
  ) {
    final definition = controller.registry.getSurface(surfaceId);
    if (definition == null) {
      return _defaultDisplayPath;
    }

    for (final component in definition.components.values) {
      if (component.type != 'Text') {
        continue;
      }
      final text = component.properties['text'];
      if (text is Map && text['path'] is String) {
        return DataPath(text['path'] as String);
      }
    }

    for (final path in ['/display', '/result', '/value', '/count']) {
      final model = controller.store.getDataModel(surfaceId);
      if (model.getValue<Object?>(DataPath(path)) != null) {
        return DataPath(path);
      }
    }

    return _defaultDisplayPath;
  }

  static bool _isClearAction(String name, Map<String, dynamic> action) {
    if (const {
      'clear',
      'reset',
      'cleardisplay',
      'clear_display',
      'c',
    }.contains(name)) {
      return true;
    }
    final sourceId = (action['sourceComponentId'] as String?)?.toLowerCase();
    return sourceId != null && sourceId.contains('clear');
  }

  static bool _isEqualsAction(String name, Map<String, dynamic> action) {
    if (const {
      'equals',
      'equal',
      'calculate',
      'evaluate',
      'compute',
    }.contains(name)) {
      return true;
    }
    final sourceId = (action['sourceComponentId'] as String?)?.toLowerCase();
    return sourceId != null &&
        (sourceId.contains('equal') ||
            sourceId.contains('equals') ||
            sourceId == 'btn=' ||
            sourceId.endsWith('eq'));
  }

  static String? _inferDigit(
    SurfaceController controller,
    String surfaceId,
    String name,
    Map<String, dynamic> action,
  ) {
    final context = _stringKeyMap(action['context']);
    for (final key in ['digit', 'value', 'number', 'char', 'key']) {
      final candidate = context[key]?.toString();
      if (candidate != null && _isDigitOrDot(candidate)) {
        return candidate;
      }
    }

    if (const {'decimal', 'dot', 'period', 'point'}.contains(name)) {
      return '.';
    }

    if (RegExp(r'^\d$').hasMatch(name)) {
      return name;
    }

    final fromName = RegExp(
      r'(?:digit|number|num|key|press|btn)[_\-]?(\d|dot|decimal|period)$',
      caseSensitive: false,
    ).firstMatch(name);
    if (fromName != null) {
      final token = fromName.group(1);
      if (token == 'dot' || token == 'decimal' || token == 'period') {
        return '.';
      }
      return token;
    }

    final sourceId = action['sourceComponentId'] as String?;
    if (sourceId != null) {
      final lower = sourceId.toLowerCase();
      if (lower == 'btndot' ||
          lower == 'btndecimal' ||
          lower == 'btnperiod' ||
          lower == 'btnpoint') {
        return '.';
      }
      final fromButton = RegExp(r'^btn(\d)$', caseSensitive: false).firstMatch(
        sourceId,
      );
      if (fromButton != null) {
        return fromButton.group(1);
      }
    }

    if (const {'digit', 'number', 'input', 'append', 'appenddigit'}.contains(
      name,
    )) {
      return context['digit']?.toString() ?? context['value']?.toString();
    }

    return _inferDigitFromLabel(controller, surfaceId, action);
  }

  static String? _inferDigitFromLabel(
    SurfaceController controller,
    String surfaceId,
    Map<String, dynamic> action,
  ) {
    final label = _buttonLabelText(controller, surfaceId, action);
    if (label != null && _isDigitOrDot(label)) {
      return label;
    }
    return null;
  }

  static String? _inferOperatorFromLabel(
    SurfaceController controller,
    String surfaceId,
    Map<String, dynamic> action,
  ) {
    final label = _buttonLabelText(controller, surfaceId, action);
    if (label != null && _isOperatorChar(label)) {
      return label;
    }
    return null;
  }

  static String? _buttonLabelText(
    SurfaceController controller,
    String surfaceId,
    Map<String, dynamic> action,
  ) {
    final sourceId = action['sourceComponentId'] as String?;
    if (sourceId == null) {
      return null;
    }

    final definition = controller.registry.getSurface(surfaceId);
    if (definition == null) {
      return null;
    }

    final button = definition.components[sourceId];
    if (button == null || button.type != 'Button') {
      return null;
    }

    final childId = button.properties['child'];
    if (childId is! String) {
      return null;
    }

    final label = definition.components[childId];
    if (label == null || label.type != 'Text') {
      return null;
    }

    final text = label.properties['text'];
    return text is String ? text : null;
  }

  static String? _inferOperator(
    SurfaceController controller,
    String surfaceId,
    String name,
    Map<String, dynamic> action,
  ) {
    final context = _stringKeyMap(action['context']);
    for (final key in ['operator', 'op', 'symbol']) {
      final candidate = context[key]?.toString();
      if (candidate != null && _isOperatorChar(candidate)) {
        return candidate;
      }
    }

    const nameOperators = {
      'add': '+',
      'plus': '+',
      'subtract': '-',
      'minus': '-',
      'sub': '-',
      'multiply': '*',
      'mul': '*',
      'times': '*',
      'divide': '/',
      'div': '/',
    };
    if (nameOperators.containsKey(name)) {
      return nameOperators[name];
    }

    if (name.length == 1 && _isOperatorChar(name)) {
      return name;
    }

    final sourceId = (action['sourceComponentId'] as String?)?.toLowerCase();
    if (sourceId != null) {
      const sourceOperators = {
        'btnadd': '+',
        'btnplus': '+',
        'btnsub': '-',
        'btnminus': '-',
        'btnmul': '*',
        'btnmultiply': '*',
        'btndiv': '/',
        'btndivide': '/',
      };
      if (sourceOperators.containsKey(sourceId)) {
        return sourceOperators[sourceId];
      }
    }

    if (const {'operator', 'op'}.contains(name)) {
      return context['operator']?.toString() ?? context['op']?.toString();
    }

    return _inferOperatorFromLabel(controller, surfaceId, action);
  }

  static bool _isDigitOrDot(String value) {
    return RegExp(r'^(\d|\.)$').hasMatch(value);
  }

  static bool _isOperatorChar(String value) {
    return value.length == 1 && RegExp(r'^[+\-*/]$').hasMatch(value);
  }

  static num? _evaluateExpression(String expression) {
    final sanitized = expression.replaceAll(' ', '');
    if (sanitized.isEmpty || !RegExp(r'^[\d.+\-*/]+$').hasMatch(sanitized)) {
      return null;
    }

    final tokens = <Object>[];
    final buffer = StringBuffer();
    for (var i = 0; i < sanitized.length; i++) {
      final char = sanitized[i];
      if (RegExp(r'[\d.]').hasMatch(char)) {
        buffer.write(char);
        continue;
      }
      if (buffer.isNotEmpty) {
        final number = num.tryParse(buffer.toString());
        if (number == null) {
          return null;
        }
        tokens.add(number);
        buffer.clear();
      }
      if (_isOperatorChar(char)) {
        tokens.add(char);
      } else {
        return null;
      }
    }
    if (buffer.isNotEmpty) {
      final number = num.tryParse(buffer.toString());
      if (number == null) {
        return null;
      }
      tokens.add(number);
    }
    if (tokens.isEmpty || tokens.first is! num) {
      return null;
    }

    var result = tokens.first as num;
    for (var i = 1; i < tokens.length; i += 2) {
      if (i + 1 >= tokens.length) {
        return null;
      }
      final op = tokens[i] as String;
      final next = tokens[i + 1] as num;
      final computed = switch (op) {
        '+' => result + next,
        '-' => result - next,
        '*' => result * next,
        '/' => next == 0 ? null : result / next,
        _ => null,
      };
      if (computed == null) {
        return null;
      }
      result = computed;
    }
    return result;
  }

  static String _formatResult(num value) {
    if (value is int || value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toString();
  }

  static Map<String, dynamic> _stringKeyMap(Object? value) {
    if (value is! Map) {
      return {};
    }
    return value.map(
      (key, nested) => MapEntry(key.toString(), nested),
    );
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
      if (decoded is Map) {
        return _stringKeyMap(decoded);
      }
    } on Object {
      // Ignore malformed interaction payloads.
    }
    return null;
  }
}
