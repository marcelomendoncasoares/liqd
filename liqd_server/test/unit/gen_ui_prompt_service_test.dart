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
          dataSchema: {
            'type': 'object',
            'properties': {
              'text': {'type': 'string'},
            },
          },
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
      expect(prompt, contains('functionCall'));
      expect(prompt, contains('incrementPath'));
      expect(prompt, contains('removeFromPath'));
      expect(prompt, contains('componentId'));
      expect(prompt, contains('AudioPlayer'));
      expect(prompt, contains('dataSchema'));
    });

    test('fewShotMessages provides valid counter example exchange', () {
      final messages = GenUiPromptService.fewShotMessages();
      expect(messages, hasLength(4));
      expect(messages[1]['content'], contains('incrementPath'));
      expect(messages.last['content'], contains('pushToPath'));
      expect(messages.last['content'], contains('removeFromPath'));
      expect(messages.last['content'], contains('componentId'));
      expect(messages.last['content'], contains('functionCall'));
    });

    test('includes edit instructions when isEdit is true', () {
      final prompt = GenUiPromptService.buildSystemPrompt([], isEdit: true);

      expect(prompt, contains('incrementally modify'));
      expect(prompt, contains('functionCall'));
      expect(prompt, contains('never event'));
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
      expect(messages[4]['content'], contains('Clear'));
      expect(messages.last['content'], contains('setPath'));
      expect(messages.last['content'], contains('clearBtn'));
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
