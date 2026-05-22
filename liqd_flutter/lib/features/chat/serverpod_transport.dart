import 'dart:async';

import 'package:genui/genui.dart';
import 'package:liqd_client/liqd_client.dart';

import '../../config/app_config.dart';
import 'generation_cancel_token.dart';

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

GenUiChatMessage _toGenUiMessage(ChatMessage message) {
  for (final part in message.parts) {
    final interaction = part.asUiInteractionPart;
    if (interaction != null) {
      return GenUiChatMessage(
        role: 'user',
        content: interaction.interaction,
      );
    }
  }
  return GenUiChatMessage(role: 'user', content: message.text);
}

/// Streams OpenRouter responses from Serverpod into GenUI.
Future<void> streamGenUiFromServer({
  required Client client,
  required A2uiTransportAdapter transport,
  required List<GenUiChatMessage> history,
  required ChatMessage message,
  required GenerationCancelToken cancelToken,
  required void Function(StreamSubscription<String> subscription)
  onSubscription,
  String? model,
}) async {
  final messages = [
    ...history,
    _toGenUiMessage(message),
  ];
  final request = GenUiChatRequest(
    model: model ?? defaultModel,
    messages: messages,
  );

  try {
    final stream = client.genUiStream.chatStream(request);
    final completer = Completer<void>();

    late StreamSubscription<String> subscription;
    subscription = stream.listen(
      (chunk) {
        if (cancelToken.isCancelled) {
          subscription.cancel();
          return;
        }
        transport.addChunk(chunk);
      },
      onDone: () async {
        if (!cancelToken.isCancelled) {
          await transport.flush();
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (cancelToken.isCancelled) {
          if (!completer.isCompleted) {
            completer.complete();
          }
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
      await subscription.cancel();
    }

    await completer.future;
  } on GenUiStreamException catch (error) {
    if (cancelToken.isCancelled) {
      return;
    }
    throw Exception(error.message);
  } catch (error) {
    if (cancelToken.isCancelled) {
      return;
    }
    throw Exception(_formatStreamError(error));
  }
}
