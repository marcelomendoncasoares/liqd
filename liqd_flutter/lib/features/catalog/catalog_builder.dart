import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:liqd_client/liqd_client.dart';
import 'local_state_functions.dart';
import 'reactive_stac_host.dart';
import 'stac_template_merger.dart';

/// Builds GenUI catalogs from server-side [UserWidget] entries.
abstract final class CatalogBuilder {
  /// GenUI basic catalog (Text, Button, Column, Row, …) for A2UI generation.
  static Catalog buildBasicCatalog() {
    return BasicCatalogItems.asCatalog().copyWith(
      newFunctions: LocalStateFunctions.all,
      systemPromptFragments: [
        ...BasicCatalogItems.asCatalog().systemPromptFragments,
        LocalStateFunctions.systemPromptFragment,
      ],
    );
  }

  /// Catalogs registered on [SurfaceController] for rendering.
  ///
  /// User Stac widgets are kept in the widget catalog UI but excluded from
  /// GenUI generation until reintroduced via a dedicated catalog mode.
  static List<Catalog> buildCatalogs(List<UserWidget> widgets) {
    return [buildBasicCatalog()];
  }

  static CatalogItem catalogItemFromUserWidget(UserWidget widget) {
    return CatalogItem(
      name: widget.name,
      dataSchema: _parseSchema(widget.dataSchema),
      widgetBuilder: (itemContext) {
        final params = extractComponentData(itemContext.data);
        final merged = deepMergeStacTemplate(widget.stacJson, params);
        return ReactiveStacHost(stacJson: merged);
      },
    );
  }

  static Schema _parseSchema(Map<String, dynamic>? schemaMap) {
    if (schemaMap == null || schemaMap.isEmpty) {
      return S.object(properties: {});
    }
    return Schema.fromMap(schemaMap.cast<String, Object?>());
  }
}
