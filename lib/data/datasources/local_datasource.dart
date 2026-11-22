import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';


class LocalDatasource {
  static Future<List<Rec>> fetchData(String table, Map<String, String> query) async {
    final db = Db.db;
    String? where;
    List<Object?> whereArgs = [];

    if (query.containsKey('id')) {
      where = 'id = ?';
      whereArgs = [int.tryParse(query['id']!) ?? query['id']];
    } else if (query.containsKey('employee_id')) {
      where = 'employee_id = ?';
      whereArgs = [int.tryParse(query['employee_id']!) ?? query['employee_id']];
    } else if (query.containsKey('q') && query['q']!.isNotEmpty) {
      final q = query['q']!;
      where = 'name LIKE ? OR code LIKE ? OR department LIKE ?';
      whereArgs = ['%$q%', '%$q%', '%$q%'];
    }

    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: query['order_by'],
    );
  }

  static Future<int> saveData(String table, Map<String, String> query, Map<String, Object?> data) async {
    final db = Db.db;
    final idStr = query['id'] ?? data['id']?.toString();
    final id = idStr != null ? int.tryParse(idStr) : null;

    if (id == null) {
      return await db.insert(table, data);
    } else {
      await db.update(table, data, where: 'id = ?', whereArgs: [id]);
      return id;
    }
  }

  static Future<int> deleteData(String table, Map<String, String> query) async {
    final db = Db.db;
    final idStr = query['id'];
    if (idStr == null) return 0;
    final id = int.tryParse(idStr);
    if (id == null) return 0;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
