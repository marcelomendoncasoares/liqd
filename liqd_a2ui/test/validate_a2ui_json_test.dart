import 'package:liqd_a2ui/liqd_a2ui.dart';
import 'package:test/test.dart';

import 'test_manifest.dart';

void main() {
  test('validateA2uiJson does not double-apply createSurface state', () async {
    final manifest = TestManifest.basic();
    final validator = A2uiValidator(manifest);

    const create =
        '{"version":"v0.9","createSurface":{"surfaceId":"main","catalogId":"https://a2ui.org/specification/v0_9/basic_catalog.json","sendDataModel":true}}';

    final result = await validateA2uiJson(validator, create);
    expect(result.isValid, isTrue, reason: result.errors.toString());
  });
}
