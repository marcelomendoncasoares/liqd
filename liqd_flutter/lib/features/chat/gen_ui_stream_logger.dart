import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

import 'gen_ui_update_outcome.dart';

/// Debug logging for GenUI model streams and parsed A2UI messages.
abstract final class GenUiStreamLogger {
  static const _name = 'GenUiStream';

  /// Flutter DevTools / VM service truncates large single [developer.log] payloads.
  static const _chunkSize = 256;

  static void logRequest({
    required String userMessage,
    required String? existingSurfacesJson,
    required String model,
  }) {
    if (!kDebugMode) {
      return;
    }
    developer.log(
      'Request model=$model hasExistingSurfaces=${existingSurfacesJson != null}',
      name: _name,
    );
    _logLongText(
      name: _name,
      text: userMessage,
      header: 'User message:',
    );
    if (existingSurfacesJson != null) {
      _logLongText(
        name: _name,
        text: existingSurfacesJson,
        header: 'Existing surfaces JSON:',
      );
    }
  }

  static void logRawChunk(String chunk) {
    if (!kDebugMode) {
      return;
    }
    _logLongText(name: '$_name.raw', text: chunk);
  }

  static void logStreamComplete({
    required String rawResponse,
    required int parsedMessageCount,
    required List<String> parsedMessageTypes,
    required bool surfaceUpdated,
  }) {
    if (!kDebugMode) {
      return;
    }
    final containsA2ui = GenUiUpdateOutcome.responseContainsA2ui(rawResponse);
    developer.log(
      'Stream complete (${rawResponse.length} chars, '
      'containsA2ui=$containsA2ui, parsedMessages=$parsedMessageCount, '
      'surfaceUpdated=$surfaceUpdated)',
      name: _name,
    );
    developer.log(
      'Parsed A2UI types: ${parsedMessageTypes.isEmpty ? "(none)" : parsedMessageTypes.join(", ")}',
      name: _name,
    );
    _logLongText(
      name: '$_name.response',
      text: rawResponse,
      header: 'Full model response (${rawResponse.length} chars):',
    );
    if (!containsA2ui) {
      developer.log(
        'WARNING: Model response has no updateComponents/createSurface/updateDataModel. '
        'The preview will not change.',
        name: _name,
        level: 900,
      );
    } else if (!surfaceUpdated) {
      developer.log(
        'WARNING: Response contained A2UI markers but no surface update event fired. '
        'JSON may be malformed or failed validation.',
        name: _name,
        level: 900,
      );
    }
  }

  static void logParsedMessage(A2uiMessage message) {
    if (!kDebugMode) {
      return;
    }
    final detail = switch (message) {
      UpdateComponents(:final surfaceId, :final components) =>
        'surfaceId=$surfaceId components=${components.length}',
      CreateSurface(:final surfaceId, :final catalogId) =>
        'surfaceId=$surfaceId catalogId=$catalogId',
      UpdateDataModel(:final surfaceId) => 'surfaceId=$surfaceId',
      DeleteSurface(:final surfaceId) => 'surfaceId=$surfaceId',
    };
    developer.log(
      'Parsed ${message.runtimeType}${detail.isEmpty ? '' : ' ($detail)'}',
      name: '$_name.a2ui',
    );
  }

  static void logError(Object error, [StackTrace? stackTrace]) {
    if (!kDebugMode) {
      return;
    }
    developer.log(
      'Stream error: $error',
      name: _name,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  static void _logLongText({
    required String name,
    required String text,
    String? header,
  }) {
    if (text.isEmpty) {
      developer.log(header ?? '(empty)', name: name);
      return;
    }

    if (text.length <= _chunkSize && header == null) {
      developer.log(text, name: name);
      return;
    }

    if (text.length <= _chunkSize) {
      developer.log('$header\n$text', name: name);
      return;
    }

    final partCount = (text.length / _chunkSize).ceil();
    if (header != null) {
      developer.log(header, name: name);
    }

    for (var index = 0; index < partCount; index++) {
      final start = index * _chunkSize;
      final end = math.min(start + _chunkSize, text.length);
      developer.log(
        '[${index + 1}/$partCount] ${text.substring(start, end)}',
        name: name,
      );
    }
  }
}
