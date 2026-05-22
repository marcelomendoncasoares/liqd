import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:liqd_client/liqd_client.dart';
import 'package:stac/stac.dart';

import '../../config/app_config.dart';
import 'stac_template_merger.dart';

/// Builds a GenUI [Catalog] from server-side [UserWidget] entries.
abstract final class CatalogBuilder {
  static Catalog fromUserWidgets(List<UserWidget> widgets) {
    return Catalog(
      [
        for (final widget in widgets) catalogItemFromUserWidget(widget),
      ],
      catalogId: userCatalogId,
      systemPromptFragments: [
        'Output A2UI v0.9 JSON messages: createSurface then updateComponents.',
        'Use catalogId "$userCatalogId". One component must have id "root".',
        'Embed Stac JSON only inside component data fields like body or children.',
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
