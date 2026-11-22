import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/data/datasources/local_datasource.dart';
import 'package:hrms/data/repositories/repository_impl.dart';

class EmployeesRepository {

  Future<List<Rec>> employees({
    String q = '',
    bool activeOnly = false,
  }) async
  {
    final search = q.trim();

    final queryMap = {
      'q': search,
      'activeOnly': activeOnly.toString(),
    };

    return Repo.queryOrLocal(
        'employees',
         queryMap,
            () async {
      final where = <String>[];
      final args = <Object?>[];

      if (search.isNotEmpty) {
        where.add(
          '(e.name LIKE ? OR e.code LIKE ? OR e.department LIKE ?)',
        );
        args.addAll([
          '%$search%',
          '%$search%',
          '%$search%',
        ]);
      }

      if (activeOnly) {
        where.add("e.status = 'Active'");
      }

      return Db.db.rawQuery(
        '''
        SELECT
          e.*,
          (
            SELECT m.name
            FROM employees m
            WHERE m.id = e.manager_id
          ) AS manager_name
        FROM employees e
        ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
        ORDER BY e.name COLLATE NOCASE
        ''',
        args,
      );
    });
  }

  Future<List<Rec>> fetchEmployees({
    String q = '',
    bool activeOnly = false,
  }) {
    return employees(
      q: q,
      activeOnly: activeOnly,
    );
  }

  Future<String> nextCode() async {
    final count = await LocalDatasource.dbCount(
      'SELECT COUNT(*) FROM employees',
    );

    return 'EMP${(count + 1).toString().padLeft(3, '0')}';
  }


  Future<int> saveEmployee(Rec data, {int? id,}) async {
    final query = id == null
        ? <String, String>{}
        : {'id': id.toString()};

    return Repo.saveData(
      'employees',
      query,
      data,
    );
  }

  Future<List<Rec>> scopeEmployees() async {
    final ids = await scopeIds();

    final all = await employees(activeOnly: true);

    if (ids == null) return all;

    return all.where((employee) {
      final employeeId = int.tryParse(
        employee['id']?.toString() ?? '',
      );

      return employeeId != null && ids.contains(employeeId);
    }).toList();
  }
}
