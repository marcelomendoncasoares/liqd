import 'dart:convert';

/// Converts NDJSON A2UI lines from the server into markdown-fenced chunks for genui.
abstract final class NdjsonAdapter {
  /// Wraps each complete NDJSON line in a markdown JSON fence for genui transport.
  static String ndjsonToGenuiChunk(String chunk) {
    final buffer = StringBuffer();
    for (final line in chunk.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      buffer.writeln('```json');
      buffer.writeln(trimmed);
      buffer.writeln('```');
    }
    return buffer.toString();
  }

  /// Parses a validated A2UI message map to a single NDJSON line.
  static String toNdjsonLine(Map<String, dynamic> message) =>
      jsonEncode(message);
}
