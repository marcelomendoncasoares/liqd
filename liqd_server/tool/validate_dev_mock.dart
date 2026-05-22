import 'dart:io';

import 'package:liqd_a2ui/liqd_a2ui.dart';
import 'package:liqd_server/src/gen_ui/gen_ui_dev_mock.dart';

/// Quick diagnostic: validate dev mock NDJSON against a minimal manifest.
Future<void> main() async {
  // Load manifest from stdin or use permissive schema
  final manifest = CatalogManifest(
    catalogId: basicCatalogId,
    systemPrompt: 'test',
    messageSchemaJson: const {
      'oneOf': [
        {'type': 'object', 'additionalProperties': true},
      ],
    },
  );

  final validator = A2uiValidator(manifest);
  var lineNum = 0;
  await for (final line in GenUiDevMock.streamCalculatorNdjson()) {
    lineNum++;
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final result = await validateA2uiJson(validator, trimmed);
    stdout.writeln(
      'Line $lineNum: valid=${result.isValid} errors=${result.errors}',
    );
  }
}
