import 'package:genui/genui.dart';
import 'package:liqd_client/liqd_client.dart';

import '../../config/app_config.dart';

String _formatStreamError(Object error) {
  if (error is GenUiStreamException) {
    return error.message;
  }

  final text = error.toString();

  if (error is ConnectionClosedException) {
    return 'The generation stream ended unexpectedly. '
        'Try Retry generation or restart the server after running '
        'serverpod generate.';
  }

  if (error is MethodStreamException) {
    return 'Streaming connection error: $text';
  }

  final genUiMatch = RegExp(
    r'GenUiStreamException\(message:\s*(.+)\)\s*$',
  ).firstMatch(text);
  if (genUiMatch != null) {
    return genUiMatch.group(1)!;
  }

  final jsonMessage = RegExp(
    r'"message"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"',
  ).firstMatch(text);
  if (jsonMessage != null) {
    return jsonMessage.group(1)!.replaceAll(r'\"', '"');
  }

  if (text.contains('OpenRouter API key')) {
    return text.replaceFirst('Exception: ', '');
  }

  if (text.contains('OpenRouter request failed')) {
    return text.replaceFirst('Exception: ', '');
  }

  return 'Streaming connection error: $error';
}

/// Streams OpenRouter responses from Serverpod into GenUI.
Future<void> streamGenUiFromServer({
  required Client client,
  required A2uiTransportAdapter transport,
  required List<GenUiChatMessage> history,
  String? model,
}) async {
  final request = GenUiChatRequest(
    model: model ?? defaultModel,
    messages: history,
  );

  try {
    final stream = client.genUiStream.chatStream(request);
    await for (final chunk in stream) {
      transport.addChunk(chunk);
    }
    await transport.flush();
  } on GenUiStreamException catch (error) {
    throw Exception(error.message);
  } catch (error) {
    throw Exception(_formatStreamError(error));
  }
}
