import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:liqd_a2ui/liqd_a2ui.dart';
import 'package:liqd_flutter/features/catalog/catalog_manifest_builder.dart';

void main() {
  test('dev counter A2UI sequence passes manifest schema validation', () async {
    final manifest = CatalogManifestBuilder.buildBasicManifest();
    final validator = A2uiValidator(manifest);

    final messages = [
      {
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'main',
          'catalogId': manifest.catalogId,
          'sendDataModel': true,
        },
      },
      {
        'version': 'v0.9',
        'updateDataModel': {
          'surfaceId': 'main',
          'path': '/count',
          'value': 0,
        },
      },
      {
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'main',
          'components': [
            {
              'id': 'root',
              'component': 'Column',
              'children': ['display', 'incrementBtn'],
            },
            {
              'id': 'display',
              'component': 'Text',
              'text': {'path': '/count'},
            },
            {
              'id': 'incrementBtn',
              'component': 'Button',
              'child': 'incrementLabel',
              'action': {
                'functionCall': {
                  'call': 'incrementPath',
                  'args': {'path': '/count'},
                  'returnType': 'void',
                },
              },
            },
            {
              'id': 'incrementLabel',
              'component': 'Text',
              'text': '+1',
            },
          ],
        },
      },
    ];

    for (final message in messages) {
      final result = await validateA2uiJson(validator, jsonEncode(message));
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
    }
  });
}
