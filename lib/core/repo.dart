//
// import 'package:hrms/core/dio_client.dart';
// import 'package:hrms/core/storage_config.dart';
// import 'package:hrms/data/datasources/remote_datasource.dart';
//
// import 'common.dart';
// import 'db.dart';
// import 'session.dart';
//
//
// // ============================================================
// // STORAGE HELPERS
// // ============================================================
//
// bool get _isLocal => StorageConfig.mode != StorageMode.apiOnly;
//
// RemoteDatasource get _remote => RemoteDatasource(DioClient());
//
// void _requireLocalDatabase() {
//   if (!_isLocal) {
//     throw UnsupportedError(
//       'This operation requires SQLite and cannot run in API-only mode.',
//     );
//   }
// }
//
// // ============================================================
// // SQL HELPERS
// // ============================================================
//
// String dbIn(List<int> ids) {
//   return '(${ids.isEmpty ? '-1' : ids.join(',')})';
// }
//
// Future<int> dbCount(String sql, [List<Object?>? args]) async {
//   _requireLocalDatabase();
//
//   final rows = await Db.db.rawQuery(sql, args);
//
//   if (rows.isEmpty || rows.first.isEmpty) return 0;
//
//   final value = rows.first.values.first;
//
//   return value is num ? value.toInt() : 0;
// }
//
// // ============================================================
// // SAVE DATA
// // ADD + UPDATE
// // ============================================================
//
// Future<int> _localSaveData(
//     String table,
//     Map<String, String> query,
//     Map<String, Object?> data,
//     ) async
// {
//   _requireLocalDatabase();
//
//   if (data.isEmpty) {
//     throw ArgumentError('Cannot save empty data.');
//   }
//
//   // ADD
//   if (query.isEmpty) {
//     return Db.db.insert(table, data);
//   }
//
//   // UPDATE
//   final where = query.keys.map((key) => '$key = ?').join(' AND ');
//   final whereArgs = query.values.toList();
//
//   return Db.db.update(
//     table,
//     data,
//     where: where,
//     whereArgs: whereArgs,
//   );
// }
//
// Future<int> saveData(
//     String tableOrEndpoint,
//     Map<String, String> query,
//     Map<String, Object?> data,
//     ) async
// {
//   // LOCAL ONLY
//   if (StorageConfig.mode == StorageMode.localOnly) {
//     return _localSaveData(tableOrEndpoint, query, data);
//   }
//
//   // LOCAL + API
//   if (StorageConfig.mode == StorageMode.localAndApi) {
//     final localId = await _localSaveData(
//       tableOrEndpoint,
//       query,
//       data,
//     );
//
//     final remoteId = await _remote.saveData(
//       tableOrEndpoint,
//       query,
//       data,
//     );
//
//     return remoteId > 0 ? remoteId : localId;
//   }
//
//   // API ONLY
//   return _remote.saveData(
//     tableOrEndpoint,
//     query,
//     data,
//   );
// }
//
// // ============================================================
// // DELETE DATA
// // ============================================================
//
// Future<int> _localDeleteData(
//     String table,
//     Map<String, String> query,
//     ) async
// {
//   _requireLocalDatabase();
//
//   if (query.isEmpty) {
//     throw ArgumentError(
//       'Delete requires a condition. Empty query is not allowed.',
//     );
//   }
//
//   final where = query.keys.map((key) => '$key = ?').join(' AND ');
//   final whereArgs = query.values.toList();
//
//   return Db.db.delete(
//     table,
//     where: where,
//     whereArgs: whereArgs,
//   );
// }
//
// Future<int> deleteData(
//     String tableOrEndpoint,
//     Map<String, String> query,
//     ) async {
//   // LOCAL ONLY
//   if (StorageConfig.mode == StorageMode.localOnly) {
//     return _localDeleteData(tableOrEndpoint, query);
//   }
//
//   // LOCAL + API
//   if (StorageConfig.mode == StorageMode.localAndApi) {
//     final localCount = await _localDeleteData(
//       tableOrEndpoint,
//       query,
//     );
//
//     await _remote.deleteData(tableOrEndpoint, query);
//
//     return localCount;
//   }
//
//   // API ONLY
//   await _remote.deleteData(tableOrEndpoint, query);
//
//   return 0;
// }
//
// // ============================================================
// // QUERY WITH LOCAL FALLBACK
// // ============================================================
//
// Future<List<Rec>> queryOrLocal(
//     String endpoint,
//     Map<String, String> query,
//     Future<List<Rec>> Function() localQueryFn,
//     ) async {
//   // LOCAL ONLY
//   if (StorageConfig.mode == StorageMode.localOnly) {
//     return localQueryFn();
//   }
//
//   // API ONLY
//   if (StorageConfig.mode == StorageMode.apiOnly) {
//     return _remote.fetchData(endpoint, query);
//   }
//
//   // LOCAL + API
//   try {
//     return await _remote.fetchData(endpoint, query);
//   } catch (e) {
//     return localQueryFn();
//   }
// }