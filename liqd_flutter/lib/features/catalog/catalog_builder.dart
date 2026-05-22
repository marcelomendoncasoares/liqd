import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:liqd_client/liqd_client.dart';

import '../../config/app_config.dart';
import 'reactive_stac_host.dart';
import 'stac_template_merger.dart';

/// Builds GenUI catalogs from server-side [UserWidget] entries.
abstract final class CatalogBuilder {
  /// GenUI basic catalog (Text, Button, Column, Row, …) plus user Stac widgets.
  static List<Catalog> buildCatalogs(List<UserWidget> widgets) {
    return [
      BasicCatalogItems.asCatalog(),
      _userCatalog(widgets),
    ];
  }

  static Catalog _userCatalog(List<UserWidget> widgets) {
    return Catalog(
      [
        for (final widget in widgets) catalogItemFromUserWidget(widget),
      ],
      catalogId: userCatalogId,
      systemPromptFragments: [
        'User Stac widgets (ScaffoldScreen, TextBlock, …): embed Stac JSON in '
            'component data fields like body.',
        'Stac interactivity: wrap body in setValue widget to init registry keys, '
            'bind text with {{key}}, and use onPressed setValue actions on elevatedButton.',
      ],
    );
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
