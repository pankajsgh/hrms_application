import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/storage_config.dart';


// ============================================================
// CLASS 1: LOCAL DATASOURCE
// SQLite operations only
// ============================================================

class LocalDatasource {

 static void _requireLocalDatabase() {

    if (StorageConfig.mode == StorageMode.apiOnly) {
      throw UnsupportedError(
        'Local database is disabled in API-only mode.',
      );
    }
  }

  // GET DATA FROM SQLITE
  Future<List<Rec>> fetchData(
      Future<List<Rec>> Function() localQuery,
      ) async {
    _requireLocalDatabase();
    return await localQuery();
  }

  // ADD OR UPDATE DATA IN SQLITE
  Future<int> saveData(
      String table,
      Map<String, String> query,
      Map<String, Object?> data,
      ) async {
    _requireLocalDatabase();

    if (data.isEmpty) {
      throw ArgumentError('Cannot save empty data.');
    }

    // ADD
    if (query.isEmpty) {
      return await Db.db.insert(table, data);
    }

    // UPDATE
    final where = query.keys
        .map((key) => '$key = ?')
        .join(' AND ');

    final whereArgs = query.values.toList();

    final count = await Db.db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );

    if (count == 0) return 0;

    // Return ID when updating by ID.
    final id = int.tryParse(query['id'] ?? '');

    return id ?? count;
  }

  // DELETE DATA FROM SQLITE
  Future<int> deleteData(
      String table,
      Map<String, String> query,
      ) async {
    _requireLocalDatabase();

    if (query.isEmpty) {
      throw ArgumentError('Delete query cannot be empty.');
    }

    final where = query.keys
        .map((key) => '$key = ?')
        .join(' AND ');

    return await Db.db.delete(
      table,
      where: where,
      whereArgs: query.values.toList(),
    );
  }

  // DATABASE COUNT
  static Future<int> dbCount(String sql, [List<Object?>? args]) async {
    _requireLocalDatabase();

    final result = await Db.db.rawQuery(sql, args);

    if (result.isEmpty) return 0;

    return (result.first.values.first as num?)?.toInt() ?? 0;
  }


  static String dbIn(List<int> ids) {
    return '(${ids.isEmpty ? '-1' : ids.join(',')})';
  }

}



Future<List<int>?> scopeIds() async {
  if (Session.isHr) return null;

  final me = Session.empId;
  if (me == null) return [];

  if (StorageConfig.mode == StorageMode.apiOnly) {
    throw UnsupportedError(
      'Manager employee scope must be provided by the API '
          'when running in API-only mode.',
    );
  }

  if (Session.isManager) {
    final employees = await Db.db.query(
      'employees',
      columns: ['id'],
      where: "manager_id = ? AND status = 'Active'",
      whereArgs: [me],
    );

    return [
      me,
      ...employees.map((r) => (r['id'] as num).toInt()),
    ];
  }

  return [me];
}