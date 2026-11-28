import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/storage_config.dart';
import 'package:hrms/data/datasources/local_datasource.dart';
import 'package:hrms/data/repositories/repository_impl.dart';
import 'package:hrms/domain/entities/employee_entity.dart';

class EmployeesRepository {
  // ============================================================
  // FETCH EMPLOYEES
  // ============================================================

  Future<List<EmployeeEntity>> fetchEmployees({
    String q = '',
    bool activeOnly = false,
  }) async {
    final search = q.trim();

    final queryMap = {
      'q': search,
      'activeOnly': activeOnly.toString(),
    };

    final raw = await Repo.queryOrLocal(
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
      },
    );

    return raw.map((r) => EmployeeEntity.fromMap(r)).toList();
  }

  // ============================================================
  // NEXT EMPLOYEE CODE
  // ============================================================

  Future<String> nextCode() async {
    if (StorageConfig.mode == StorageMode.apiOnly) {
      return 'EMP${(0 + 1).toString().padLeft(3, '0')}';
    }

    final count = await LocalDatasource.dbCount(
      'SELECT COUNT(*) FROM employees',
    );

    return 'EMP${(count + 1).toString().padLeft(3, '0')}';
  }

  // ============================================================
  // SAVE EMPLOYEE
  // ============================================================

  Future<int> saveEmployee(Map<String, Object?> data, {int? id}) async {
    final query = id == null ? <String, String>{} : {'id': id.toString()};

    return Repo.saveData(
      'employees',
      query,
      data,
    );
  }

  // ============================================================
  // SCOPED EMPLOYEES
  // ============================================================

  Future<List<EmployeeEntity>> scopeEmployees() async {
    final ids = await scopeIds();
    final all = await fetchEmployees(activeOnly: true);

    if (ids == null) return all;

    return all.where((employee) {
      final employeeId = employee.id;
      return employeeId != null && ids.contains(employeeId);
    }).toList();
  }
}
