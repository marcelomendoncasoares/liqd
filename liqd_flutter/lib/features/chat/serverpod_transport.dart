import 'dart:async';

import 'package:genui/genui.dart';
import 'package:liqd_a2ui/liqd_a2ui.dart';
import 'package:liqd_client/liqd_client.dart';

import '../../config/app_config.dart';
import 'chat_request_builder.dart';
import 'gen_ui_stream_logger.dart';
import 'generation_cancel_token.dart';

const _flushTimeout = Duration(seconds: 5);

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

List<GenUiChatMessage> _buildRequestMessages({
  required List<GenUiChatMessage> history,
  required ChatMessage message,
}) => buildChatRequestMessages(history: history, message: message);

Future<void> _flushTransport(A2uiTransportAdapter transport) async {
  try {
    await transport.flush().timeout(_flushTimeout);
  } on TimeoutException {
    // Parser did not finish; avoid hanging the UI indefinitely.
  }
}

/// Streams OpenRouter responses from Serverpod into GenUI.
///
/// Returns the full raw model response accumulated from stream chunks.
Future<String> streamGenUiFromServer({
  required Client client,
  required A2uiTransportAdapter transport,
  required List<GenUiChatMessage> history,
  required ChatMessage message,
  required GenerationCancelToken cancelToken,
  required void Function(StreamSubscription<String> subscription)
  onSubscription,
  required String catalogManifestJson,
  String? model,
  String? existingSurfacesJson,
}) async {
  final messages = _buildRequestMessages(history: history, message: message);
  final request = GenUiChatRequest(
    model: model ?? defaultModel,
    messages: messages,
    existingSurfacesJson: existingSurfacesJson,
    catalogManifestJson: catalogManifestJson,
  );

  GenUiStreamLogger.logRequest(
    userMessage: message.text,
    existingSurfacesJson: existingSurfacesJson,
    model: request.model ?? defaultModel,
  );

  final rawResponse = StringBuffer();

  try {
    final stream = client.genUiStream.chatStream(request);
    final completer = Completer<void>();

    late StreamSubscription<String> subscription;
    var streamClosed = false;
    var finishInProgress = false;

    Future<void> finishStream({required bool flushTransport}) async {
      if (finishInProgress || completer.isCompleted) {
        return;
      }
      finishInProgress = true;
      streamClosed = true;

      if (flushTransport && !cancelToken.isCancelled) {
        await _flushTransport(transport);
      }

      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    void closeStream() {
      if (streamClosed) {
        return;
      }
      streamClosed = true;
      unawaited(subscription.cancel());
    }

    cancelToken.onCancel(() {
      closeStream();
      unawaited(finishStream(flushTransport: false));
    });

    subscription = stream.listen(
      (chunk) {
        if (cancelToken.isCancelled || streamClosed) {
          return;
        }
        rawResponse.write(chunk);
        GenUiStreamLogger.logRawChunk(chunk);
        try {
          transport.addChunk(NdjsonAdapter.ndjsonToGenuiChunk(chunk));
        } on StateError {
          // Transport input closed by flush(), dispose(), or hot reload.
          streamClosed = true;
        }
      },
      onDone: () => finishStream(flushTransport: true),
      onError: (Object error, StackTrace stackTrace) {
        streamClosed = true;
        if (cancelToken.isCancelled) {
          unawaited(finishStream(flushTransport: false));
          return;
        }
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
      cancelOnError: true,
    );
    onSubscription(subscription);

    if (cancelToken.isCancelled) {
      closeStream();
      await finishStream(flushTransport: false);
    }

    await completer.future;
    return rawResponse.toString();
  } on GenUiStreamException catch (error) {
    if (cancelToken.isCancelled) {
      return rawResponse.toString();
    }
    throw Exception(error.message);
  } catch (error) {
    if (cancelToken.isCancelled) {
      return rawResponse.toString();
    }
    throw Exception(_formatStreamError(error));
  }
}
