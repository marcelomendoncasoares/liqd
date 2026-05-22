import 'package:liqd_server/src/gen_ui/gen_ui_prompt_service.dart';
import 'package:liqd_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

void main() {
  group('GenUiPromptService', () {
    test('includes A2UI protocol instructions and catalog ids', () {
      final prompt = GenUiPromptService.buildSystemPrompt([
        UserWidget(
          authUserId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000001',
          ),
          name: 'TextBlock',
          description: 'Shows text.',
          stacJson: {'type': 'text', 'data': '{{text}}'},
        ),
      ]);

      expect(prompt, contains('createSurface'));
      expect(prompt, contains('updateComponents'));
      expect(prompt, contains('updateDataModel'));
      expect(prompt, contains(basicCatalogId));
      expect(prompt, contains(userCatalogId));
      expect(prompt, contains('"id":"root"'));
      expect(prompt, contains('TextBlock'));
      expect(prompt, contains('Button'));
      expect(prompt, contains('sendDataModel'));
    });

    test('fewShotMessages provides valid counter example exchange', () {
      final messages = GenUiPromptService.fewShotMessages();
      expect(messages, hasLength(2));
      expect(messages.last['content'], contains('createSurface'));
      expect(messages.last['content'], contains('updateDataModel'));
      expect(messages.last['content'], contains('updateComponents'));
      expect(messages.last['content'], contains('increment'));
    });
  });
}
