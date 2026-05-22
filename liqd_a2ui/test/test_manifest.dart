import 'package:liqd_a2ui/liqd_a2ui.dart';

abstract final class TestManifest {
  static CatalogManifest basic() {
    return CatalogManifest(
      catalogId: basicCatalogId,
      systemPrompt:
          'Test system prompt with createSurface and Button.child rules.',
      messageSchemaJson: const {
        'oneOf': [
          {'type': 'object', 'additionalProperties': true},
        ],
      },
    );
  }
}
