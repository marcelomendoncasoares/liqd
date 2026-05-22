import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

import 'seed_widgets.dart';
import 'stac_validator.dart';

class WidgetCatalogEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  Future<List<UserWidget>> listMyWidgets(Session session) async {
    final authUserId = _requireAuthUserId(session);
    await _ensureSeeded(session, authUserId);
    return UserWidget.db.find(
      session,
      where: (t) => t.authUserId.equals(authUserId),
      orderBy: (t) => t.name,
    );
  }

  Future<UserWidget> createWidget(
    Session session, {
    required String name,
    required String description,
    Map<String, dynamic>? dataSchema,
    required Map<String, dynamic> stacJson,
  }) async {
    final authUserId = _requireAuthUserId(session);

    final validation = StacValidator.validate(stacJson);
    if (!validation.valid) {
      throw ArgumentError(validation.errors?.join(', ') ?? 'Invalid Stac JSON');
    }

    final existing = await UserWidget.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId) & t.name.equals(name),
    );
    if (existing != null) {
      throw ArgumentError('Widget with name "$name" already exists.');
    }

    return UserWidget.db.insertRow(
      session,
      UserWidget(
        authUserId: authUserId,
        name: name,
        description: description,
        dataSchema: dataSchema,
        stacJson: stacJson,
      ),
    );
  }

  Future<bool> deleteWidget(Session session, int id) async {
    final authUserId = _requireAuthUserId(session);
    final widget = await UserWidget.db.findById(session, id);
    if (widget == null || widget.authUserId != authUserId) {
      return false;
    }
    await UserWidget.db.deleteRow(session, widget);
    return true;
  }

  Future<void> seedDefaultsForUser(Session session) async {
    final authUserId = _requireAuthUserId(session);
    await _ensureSeeded(session, authUserId);
  }

  Future<void> _ensureSeeded(Session session, UuidValue authUserId) async {
    final count = await UserWidget.db.count(
      session,
      where: (t) => t.authUserId.equals(authUserId),
    );
    if (count > 0) {
      return;
    }

    for (final widget in SeedWidgets.defaults(authUserId: authUserId)) {
      await UserWidget.db.insertRow(session, widget);
    }
  }

  UuidValue _requireAuthUserId(Session session) {
    final userIdentifier = session.authenticated?.userIdentifier;
    if (userIdentifier == null) {
      throw ArgumentError('Authentication required.');
    }
    return UuidValue.fromString(userIdentifier);
  }
}
