import 'dart:convert';

import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class UserAppEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  Future<List<UserApp>> listApps(Session session) async {
    final authUserId = _requireAuthUserId(session);
    return UserApp.db.find(
      session,
      where: (t) => t.authUserId.equals(authUserId),
      orderBy: (t) => t.updatedAt.desc(),
    );
  }

  Future<UserApp?> getApp(Session session, int id) async {
    final authUserId = _requireAuthUserId(session);
    final app = await UserApp.db.findById(session, id);
    if (app == null || app.authUserId != authUserId) {
      return null;
    }
    return app;
  }

  Future<UserApp> saveApp(
    Session session, {
    int? id,
    required String title,
    required String surfaceStateJson,
  }) async {
    final authUserId = _requireAuthUserId(session);
    final now = DateTime.now().toUtc();
    final decoded = jsonDecode(surfaceStateJson);
    if (decoded is! Map<String, dynamic>) {
      throw ArgumentError('surfaceStateJson must decode to a JSON object.');
    }
    final surfaceState = decoded;

    if (id != null) {
      final existing = await UserApp.db.findById(session, id);
      if (existing == null || existing.authUserId != authUserId) {
        throw ArgumentError('App not found.');
      }
      return UserApp.db.updateRow(
        session,
        existing.copyWith(
          title: title,
          surfaceState: surfaceState,
          updatedAt: now,
        ),
      );
    }

    return UserApp.db.insertRow(
      session,
      UserApp(
        authUserId: authUserId,
        title: title,
        surfaceState: surfaceState,
        updatedAt: now,
      ),
    );
  }

  Future<bool> deleteApp(Session session, int id) async {
    final authUserId = _requireAuthUserId(session);
    final app = await UserApp.db.findById(session, id);
    if (app == null || app.authUserId != authUserId) {
      return false;
    }
    await UserApp.db.deleteRow(session, app);
    return true;
  }

  UuidValue _requireAuthUserId(Session session) {
    final userIdentifier = session.authenticated?.userIdentifier;
    if (userIdentifier == null) {
      throw ArgumentError('Authentication required.');
    }
    return UuidValue.fromString(userIdentifier);
  }
}
