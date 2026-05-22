import 'dart:convert';

import 'package:genui/genui.dart' hide basicCatalogId;
import 'package:liqd_a2ui/liqd_a2ui.dart' hide basicCatalogId;

import '../../config/app_config.dart';
import 'catalog_builder.dart';
import 'local_state_functions.dart';

/// Builds a [CatalogManifest] from the live GenUI basic catalog.
abstract final class CatalogManifestBuilder {
  static CatalogManifest buildBasicManifest() {
    final catalog = CatalogBuilder.buildBasicCatalog();
    final promptBuilder = PromptBuilder.custom(
      catalog: catalog,
      allowedOperations: SurfaceOperations.createAndUpdate(dataModel: true),
      systemPromptFragments: const [
        'You are Liqd, an AI that builds interactive Flutter apps using A2UI v0.9.',
      ],
    );

    final schema = A2uiMessage.a2uiMessageSchema(catalog);
    final messageSchemaJson =
        jsonDecode(schema.toJson()) as Map<String, dynamic>;

    return CatalogManifest(
      catalogId: basicCatalogId,
      systemPrompt: promptBuilder.systemPromptJoined(),
      messageSchemaJson: messageSchemaJson,
      componentNames: catalog.items.map((item) => item.name).toList(),
      functionNames: LocalStateFunctions.all.map((fn) => fn.name).toList(),
    );
  }
}
