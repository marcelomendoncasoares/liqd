import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:liqd_client/liqd_client.dart';
import 'package:stac/stac.dart';

import '../../config/app_config.dart';
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
        final rendered = Stac.fromJson(merged, itemContext.buildContext);
        return rendered ??
            Text(
              'Failed to render ${widget.name}',
              style: TextStyle(color: itemContext.buildContext.errorColor),
            );
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

extension on BuildContext {
  Color? get errorColor => Theme.of(this).colorScheme.error;
}
