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
      expect(messages, hasLength(4));
      expect(messages.last['content'], contains('createSurface'));
      expect(messages.last['content'], contains('updateDataModel'));
      expect(messages.last['content'], contains('updateComponents'));
      expect(messages.last['content'], contains('digit'));
    });

    test('includes edit instructions when isEdit is true', () {
      final prompt = GenUiPromptService.buildSystemPrompt([], isEdit: true);

      expect(prompt, contains('incrementally modify'));
      expect(prompt, contains('Do NOT emit createSurface'));
    });

    test('parseExistingSurfaceIds reads surface keys from JSON', () {
      final ids = GenUiPromptService.parseExistingSurfaceIds(
        '{"surfaces":{"calculator":{},"counter":{}}}',
      );

      expect(ids, containsAll(['calculator', 'counter']));
    });

    test('fewShotMessages includes edit example when requested', () {
      final messages = GenUiPromptService.fewShotMessages(includeEdit: true);

      expect(messages, hasLength(6));
      expect(messages[4]['content'], contains('clear button'));
      expect(messages.last['content'], contains('btnClear'));
      expect(messages.last['content'], contains('"root"'));
    });

    test('responseContainsA2ui detects A2UI message keys', () {
      expect(
        GenUiPromptService.responseContainsA2ui(
          'Here is the update: {"updateComponents":{}}',
        ),
        isTrue,
      );
      expect(
        GenUiPromptService.responseContainsA2ui(
          'Sure, I added a clear button.',
        ),
        isFalse,
      );
    });

    test('augmentUserMessageForEdit appends A2UI-only instruction', () {
      final augmented = GenUiPromptService.augmentUserMessageForEdit(
        'Add a clear button',
      );

      expect(augmented, contains('Add a clear button'));
      expect(augmented, contains('updateComponents'));
      expect(augmented, contains('No explanatory text'));
    });
  });
}
