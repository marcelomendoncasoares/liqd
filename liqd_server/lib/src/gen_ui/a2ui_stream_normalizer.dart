import 'dart:convert';

import 'component_patch_merger.dart';
import 'component_normalizer.dart';
import 'gen_ui_prompt_service.dart';

/// Ensures streamed LLM output contains valid, GenUI-parseable A2UI messages.
///
/// Repairs complete JSON blocks and injects missing [createSurface] messages.
class A2uiStreamNormalizer {
  A2uiStreamNormalizer({
    Set<String>? existingSurfaceIds,
    Map<String, Map<String, dynamic>>? existingSurfaces,
    Iterable<String>? userWidgetNames,
  }) : _existingSurfaceIds = existingSurfaceIds ?? const {},
       _existingSurfaces = existingSurfaces ?? const {},
       _userWidgetNames = {
         ...userCatalogComponentNames,
         if (userWidgetNames != null) ...userWidgetNames,
       };

  final _buffer = StringBuffer();
  final _createdSurfaces = <String>{};
  final Set<String> _existingSurfaceIds;
  final Map<String, Map<String, dynamic>> _existingSurfaces;
  final Set<String> _userWidgetNames;

  /// Feeds a chunk and returns zero or more normalized chunks to yield.
  List<String> process(String chunk) {
    _buffer.write(chunk);
    final output = <String>[];
    _drainCompleteJsonBlocks(output);
    return output;
  }

  /// Flushes any trailing content at end of stream.
  List<String> flush() {
    final output = <String>[];
    _drainCompleteJsonBlocks(output, flushRemaining: true);
    return output;
  }

  void _drainCompleteJsonBlocks(
    List<String> output, {
    bool flushRemaining = false,
  }) {
    var text = _buffer.toString();

    while (text.isNotEmpty) {
      final markdown = _findMarkdownJson(text);
      if (markdown != null) {
        if (markdown.start > 0) {
          output.add(text.substring(0, markdown.start));
        }
        output.addAll(_normalizeJsonBlock(markdown.content));
        text = text.substring(markdown.end);
        continue;
      }

      final trimmed = text.trimLeft();
      if (trimmed.startsWith('{')) {
        final balanced = _findBalancedJson(trimmed);
        if (balanced != null) {
          final leading = text.length - trimmed.length;
          if (leading > 0) {
            output.add(text.substring(0, leading));
          }
          output.addAll(_normalizeJsonBlock(balanced.content));
          text = text.substring(leading + balanced.end);
          continue;
        }
      }

      if (!flushRemaining) {
        break;
      }

      if (text.isNotEmpty) {
        output.add(text);
      }
      text = '';
    }

    _buffer
      ..clear()
      ..write(text);
  }

  List<String> _normalizeJsonBlock(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return ['```json\n$rawJson\n```'];
      }

      final output = <String>[];
      final update = decoded['updateComponents'];
      if (update is Map<String, dynamic>) {
        final surfaceId = update['surfaceId'] as String?;
        if (surfaceId != null &&
            !_createdSurfaces.contains(surfaceId) &&
            !_existingSurfaceIds.contains(surfaceId)) {
          _createdSurfaces.add(surfaceId);
          final components = update['components'];
          final catalogId = _catalogIdForComponents(components);
          output.add(
            '```json\n${jsonEncode({
              'version': 'v0.9',
              'createSurface': {
                'surfaceId': surfaceId,
                'catalogId': catalogId,
                if (catalogId == basicCatalogId) 'sendDataModel': true,
              },
            })}\n```',
          );
        }

        if (surfaceId != null && update['components'] is List) {
          update['components'] = ComponentNormalizer.normalizeJsonList(
            ComponentPatchMerger.mergeJsonComponents(
              existingSurface: _existingSurfaces[surfaceId],
              incoming: update['components'] as List,
            ),
          );
        }
      }

      if (decoded.containsKey('createSurface')) {
        final create = decoded['createSurface'];
        if (create is Map<String, dynamic>) {
          final surfaceId = create['surfaceId'] as String?;
          if (surfaceId != null && _existingSurfaceIds.contains(surfaceId)) {
            decoded.remove('createSurface');
            if (decoded.length <= 1 && decoded.containsKey('version')) {
              return output;
            }
          } else {
            create.putIfAbsent('catalogId', () => basicCatalogId);
            create.putIfAbsent('sendDataModel', () => true);
            if (surfaceId != null) {
              _createdSurfaces.add(surfaceId);
            }
          }
        }
      }

      decoded['version'] = 'v0.9';
      output.add('```json\n${jsonEncode(decoded)}\n```');
      return output;
    } on FormatException {
      return ['```json\n$rawJson\n```'];
    }
  }

  String _catalogIdForComponents(Object? components) {
    if (components is! List) {
      return basicCatalogId;
    }
    for (final item in components) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final name = item['component'] as String?;
      if (name != null && _userWidgetNames.contains(name)) {
        return userCatalogId;
      }
    }
    return basicCatalogId;
  }
}

_Match? _findMarkdownJson(String text) {
  final match = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(text);
  if (match == null) {
    return null;
  }
  return _Match(
    match.start,
    match.end,
    match.group(1) ?? '',
  );
}

_Match? _findBalancedJson(String input) {
  if (!input.startsWith('{')) {
    return null;
  }

  var balance = 0;
  var inString = false;
  var isEscaped = false;

  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (isEscaped) {
      isEscaped = false;
      continue;
    }
    if (char == r'\') {
      isEscaped = true;
      continue;
    }
    if (char == '"') {
      inString = !inString;
      continue;
    }
    if (!inString) {
      if (char == '{') {
        balance++;
      } else if (char == '}') {
        balance--;
        if (balance == 0) {
          return _Match(0, i + 1, input.substring(0, i + 1));
        }
      }
    }
  }
  return null;
}

class _Match {
  _Match(this.start, this.end, this.content);
  final int start;
  final int end;
  final String content;
}
