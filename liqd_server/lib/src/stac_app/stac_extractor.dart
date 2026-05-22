import 'dart:convert';

/// Extracts a Stac widget tree from an LLM response.
abstract final class StacExtractor {
  static Map<String, dynamic>? extract(String response) {
    final fencePattern = RegExp(
      r'```(?:json|stac)?\s*\n([\s\S]*?)\n```',
      multiLine: true,
    );
    for (final match in fencePattern.allMatches(response)) {
      final parsed = _tryParseStac(match.group(1)!.trim());
      if (parsed != null) {
        return parsed;
      }
    }

    return _tryParseStac(response.trim());
  }

  static Map<String, dynamic>? _tryParseStac(String text) {
    if (text.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic> && decoded.containsKey('type')) {
        return decoded;
      }
    } on FormatException {
      // Fall through.
    }
    return null;
  }
}
