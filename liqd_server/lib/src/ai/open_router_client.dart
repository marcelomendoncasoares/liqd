import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Client for OpenRouter's OpenAI-compatible chat completions API.
class OpenRouterClient {
  OpenRouterClient({
    required this.apiKey,
    this.siteUrl,
    this.appName,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String apiKey;
  final String? siteUrl;
  final String? appName;
  final http.Client _http;

  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  Future<String> chat({
    required String model,
    required List<Map<String, dynamic>> messages,
    double? temperature,
    int? maxTokens,
  }) async {
    final response = await _http.post(
      Uri.parse(_baseUrl),
      headers: _headers(),
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': ?temperature,
        'max_tokens': ?maxTokens,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenRouterException(response.statusCode, response.body);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw OpenRouterException(200, 'No choices in response');
    }
    final message = choices.first['message'] as Map<String, dynamic>?;
    return message?['content'] as String? ?? '';
  }

  Stream<String> streamChat({
    required String model,
    required List<Map<String, dynamic>> messages,
    double? temperature,
    int? maxTokens,
  }) async* {
    final request = http.Request('POST', Uri.parse(_baseUrl));
    request.headers.addAll(_headers());
    request.body = jsonEncode({
      'model': model,
      'messages': messages,
      'stream': true,
      'temperature': ?temperature,
      'max_tokens': ?maxTokens,
    });

    final response = await _http.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      throw OpenRouterException(response.statusCode, body);
    }

    var buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
      while (buffer.contains('\n')) {
        final index = buffer.indexOf('\n');
        final line = buffer.substring(0, index).trim();
        buffer = buffer.substring(index + 1);

        if (line.isEmpty || line.startsWith(':')) {
          continue;
        }
        if (!line.startsWith('data: ')) {
          continue;
        }

        final data = line.substring(6).trim();
        if (data == '[DONE]') {
          return;
        }

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>?;
          if (choices == null || choices.isEmpty) {
            continue;
          }
          final delta = choices.first['delta'] as Map<String, dynamic>?;
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            yield content;
          }
        } on FormatException {
          continue;
        }
      }
    }
  }

  Map<String, String> _headers() => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': ?siteUrl,
        'X-OpenRouter-Title': ?appName,
      };

  void close() => _http.close();
}

class OpenRouterException implements Exception {
  OpenRouterException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'OpenRouterException($statusCode): $body';
}
