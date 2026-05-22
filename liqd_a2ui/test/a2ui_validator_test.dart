import 'package:liqd_a2ui/liqd_a2ui.dart';
import 'package:test/test.dart';

import 'test_manifest.dart';

void main() {
  group('A2uiValidator', () {
    late CatalogManifest manifest;
    late A2uiValidator validator;

    setUp(() {
      manifest = TestManifest.basic();
      validator = A2uiValidator(manifest);
    });

    test('accepts valid create/update sequence', () async {
      final create =
          '''
{"version":"v0.9","createSurface":{"surfaceId":"main","catalogId":"${manifest.catalogId}","sendDataModel":true}}
''';
      final dataModel = '''
{"version":"v0.9","updateDataModel":{"surfaceId":"main","path":"/count","value":0}}
''';
      final components = '''
{"version":"v0.9","updateComponents":{"surfaceId":"main","components":[{"id":"root","component":"Column","children":["display","incrementBtn"]},{"id":"display","component":"Text","text":{"path":"/count"}},{"id":"incrementBtn","component":"Button","child":"incrementLabel","action":{"functionCall":{"call":"incrementPath","args":{"path":"/count"},"returnType":"void"}}},{"id":"incrementLabel","component":"Text","text":"+1"}]}}
''';

      for (final message in [create, dataModel, components]) {
        final result = await validateA2uiJson(validator, message.trim());
        expect(result.isValid, isTrue, reason: result.errors.toString());
      }
    });

    test('rejects updateComponents before createSurface', () {
      final result = validator.validateJson(
        '{"version":"v0.9","updateComponents":{"surfaceId":"main","components":[{"id":"root","component":"Column","children":[]}]}}',
      );

      expect(result.isValid, isFalse);
      expect(result.errors.single, contains('unknown surface'));
    });

    test('rejects orphan components', () {
      validator.seedExistingSurfaces(['main']);
      final result = validator.validateJson(
        '{"version":"v0.9","updateComponents":{"surfaceId":"main","components":[{"id":"root","component":"Column","children":["btn"]},{"id":"btn","component":"Button","child":"missingLabel"}]}}',
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors,
        anyElement(contains('missing child "missingLabel"')),
      );
    });

    test('skips redundant createSurface on edit', () async {
      validator.seedExistingSurfaces(['main']);
      final result = await validateA2uiJson(
        validator,
        '{"version":"v0.9","createSurface":{"surfaceId":"main","catalogId":"${manifest.catalogId}","sendDataModel":true}}',
      );

      expect(result.skipped, isTrue);
    });

    test('schema failure does not register surface state', () async {
      final strictManifest = CatalogManifest(
        catalogId: basicCatalogId,
        systemPrompt: 'test',
        messageSchemaJson: const {
          'type': 'object',
          'required': ['version', 'createSurface', 'extraRequiredField'],
        },
      );
      final strictValidator = A2uiValidator(strictManifest);
      const create =
          '{"version":"v0.9","createSurface":{"surfaceId":"main","catalogId":"https://a2ui.org/specification/v0_9/basic_catalog.json","sendDataModel":true}}';

      final failed = await validateA2uiJson(strictValidator, create);
      expect(failed.isValid, isFalse);

      final update = await validateA2uiJson(
        strictValidator,
        '{"version":"v0.9","updateDataModel":{"surfaceId":"main","path":"/count","value":0}}',
      );
      expect(update.isValid, isFalse);
      expect(update.errors.single, contains('unknown surface'));
    });

    test('rejects unreachable components', () {
      validator.seedExistingSurfaces(['main']);
      final result = validator.validateJson(
        '{"version":"v0.9","updateComponents":{"surfaceId":"main","components":[{"id":"root","component":"Column","children":[]},{"id":"orphan","component":"Text","text":"Hi"}]}}',
      );

      expect(result.isValid, isFalse);
      expect(result.errors, anyElement(contains('not reachable from root')));
    });
  });

  group('GenUiChatAssembler', () {
    test('buildSystemPrompt includes edit instructions when requested', () {
      final manifest = TestManifest.basic();
      final prompt = GenUiChatAssembler.buildSystemPrompt(
        manifest,
        isEdit: true,
      );

      expect(prompt, contains('COMPLETE components array'));
      expect(prompt, contains('Do NOT emit createSurface'));
    });

    test('parseExistingSurfaceIds reads surface keys', () {
      final ids = GenUiChatAssembler.parseExistingSurfaceIds(
        '{"surfaces":{"main":{},"settings":{}}}',
      );
      expect(ids, containsAll(['main', 'settings']));
    });
  });

  group('NdjsonAdapter', () {
    test('wraps NDJSON lines in markdown fences', () {
      final chunk = NdjsonAdapter.ndjsonToGenuiChunk(
        '{"version":"v0.9","createSurface":{"surfaceId":"main"}}\n',
      );
      expect(chunk, contains('```json'));
      expect(chunk, contains('createSurface'));
    });
  });
}
