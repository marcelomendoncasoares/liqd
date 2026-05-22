import 'package:genui/genui.dart';
import 'package:liqd_client/liqd_client.dart';

GenUiChatMessage toGenUiChatMessage(ChatMessage message) {
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

/// Builds the message list for [GenUiChatRequest], avoiding duplicate user text.
List<GenUiChatMessage> buildChatRequestMessages({
  required List<GenUiChatMessage> history,
  required ChatMessage message,
}) {
  final pending = toGenUiChatMessage(message);
  if (history.isEmpty) {
    return [pending];
  }

  final last = history.last;
  if (last.role == pending.role && last.content == pending.content) {
    return List<GenUiChatMessage>.from(history);
  }

  return [...history, pending];
}
