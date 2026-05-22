import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

/// Debug logging for GenUI model streams and parsed A2UI messages.
abstract final class GenUiStreamLogger {
  static const _name = 'GenUiStream';

  static void logRequest({
    required String userMessage,
    required String? existingSurfacesJson,
    required String model,
  }) {
    if (!kDebugMode) {
      return;
    }
    developer.log(
      'Request model=$model user="${_truncate(userMessage, 200)}" '
      'hasExistingSurfaces=${existingSurfacesJson != null}',
      name: _name,
    );
    if (existingSurfacesJson != null) {
      developer.log(
        'Existing surfaces JSON:\n$existingSurfacesJson',
        name: _name,
      );
    }
  }

  static void logRawChunk(String chunk) {
    if (!kDebugMode) {
      return;
    }
    // Stream chunks are often partial; log without extra wrapping.
    developer.log(chunk, name: '$_name.raw');
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
    final containsA2ui = _responseContainsA2ui(rawResponse);
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
    developer.log(
      'Full model response:\n$rawResponse',
      name: '$_name.response',
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

  static bool _responseContainsA2ui(String response) {
    final lower = response.toLowerCase();
    return lower.contains('updatecomponents') ||
        lower.contains('createsurface') ||
        lower.contains('updatedatamodel') ||
        lower.contains('deletesurface');
  }

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...';
  }
}
