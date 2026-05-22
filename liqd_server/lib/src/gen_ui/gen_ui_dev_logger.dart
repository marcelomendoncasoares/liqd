import 'dart:math' as math;

import 'package:serverpod/serverpod.dart';

/// Dev-only logging helpers for large GenUI payloads.
abstract final class GenUiDevLogger {
  /// Avoid truncation in consoles that cap single log line length.
  static const _chunkSize = 256;

  static void logLongText(
    Session session,
    String text, {
    LogLevel level = LogLevel.info,
    String? header,
  }) {
    if (text.isEmpty) {
      session.log(header ?? '(empty)', level: level);
      return;
    }

    if (text.length <= _chunkSize && header == null) {
      session.log(text, level: level);
      return;
    }

    if (text.length <= _chunkSize) {
      session.log('$header\n$text', level: level);
      return;
    }

    final partCount = (text.length / _chunkSize).ceil();
    if (header != null) {
      session.log(header, level: level);
    }

    for (var index = 0; index < partCount; index++) {
      final start = index * _chunkSize;
      final end = math.min(start + _chunkSize, text.length);
      session.log(
        '[${index + 1}/$partCount] ${text.substring(start, end)}',
        level: level,
      );
    }
  }
}
