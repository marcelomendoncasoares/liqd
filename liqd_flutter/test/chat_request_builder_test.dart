import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:liqd_client/liqd_client.dart';
import 'package:liqd_flutter/features/chat/chat_request_builder.dart';
import 'package:liqd_flutter/features/chat/generation_cancel_token.dart';

void main() {
  group('buildChatRequestMessages', () {
    test('does not duplicate the latest user message already in history', () {
      final history = [
        GenUiChatMessage(role: 'user', content: 'Add a clear button'),
      ];
      final message = ChatMessage.user('Add a clear button');

      final result = buildChatRequestMessages(
        history: history,
        message: message,
      );

      expect(result, hasLength(1));
      expect(result.single.content, 'Add a clear button');
    });

    test('appends when the pending message differs from history', () {
      final history = [
        GenUiChatMessage(role: 'user', content: 'Build a calculator'),
      ];
      final message = ChatMessage.user('Add a clear button');

      final result = buildChatRequestMessages(
        history: history,
        message: message,
      );

      expect(result, hasLength(2));
      expect(result.last.content, 'Add a clear button');
    });
  });

  group('GenerationCancelToken', () {
    test('notifies listeners when cancelled', () {
      final token = GenerationCancelToken();
      var notified = false;
      token.onCancel(() => notified = true);

      token.cancel();

      expect(notified, isTrue);
      expect(token.isCancelled, isTrue);
    });

    test('runs listener immediately if already cancelled', () {
      final token = GenerationCancelToken()..cancel();
      var notified = false;

      token.onCancel(() => notified = true);

      expect(notified, isTrue);
    });
  });
}
