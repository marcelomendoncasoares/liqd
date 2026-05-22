/// Extracts complete JSON objects from streamed LLM text without mutation.
final class A2uiExtractor {
  final _buffer = StringBuffer();

  /// Feeds a chunk and returns zero or more complete JSON object strings.
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
        text = text.substring(markdown.end);
        final trimmed = markdown.content.trim();
        if (trimmed.isNotEmpty) {
          output.add(trimmed);
        }
        continue;
      }

      final trimmed = text.trimLeft();
      if (trimmed.startsWith('{')) {
        final balanced = _findBalancedJson(trimmed);
        if (balanced != null) {
          final leading = text.length - trimmed.length;
          text = text.substring(leading + balanced.end);
          output.add(balanced.content);
          continue;
        }
      }

      if (!flushRemaining) {
        break;
      }

      text = '';
    }

    _buffer
      ..clear()
      ..write(text);
  }
}

class _Match {
  _Match(this.start, this.end, this.content);
  final int start;
  final int end;
  final String content;
}

_Match? _findMarkdownJson(String text) {
  final match = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(text);
  if (match == null) {
    return null;
  }
  return _Match(match.start, match.end, match.group(1) ?? '');
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
