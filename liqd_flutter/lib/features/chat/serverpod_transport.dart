import 'package:genui/genui.dart';
import 'package:liqd_client/liqd_client.dart';

import '../../config/app_config.dart';

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

  final stream = client.genUiStream.chatStream(request);
  await for (final chunk in stream) {
    transport.addChunk(chunk);
  }
}
