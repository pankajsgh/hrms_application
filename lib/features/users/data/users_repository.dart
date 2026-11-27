import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/data/datasources/local_datasource.dart';
import 'package:hrms/data/repositories/repository_impl.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import 'package:hrms/domain/entities/user_entity.dart';
import '../../employees/data/employees_repository.dart';

class UsersRepository {
  // ============================================================
  // FETCH USERS
  // ============================================================

  Future<List<UserEntity>> users() async {
    final raw = await Repo.queryOrLocal(
      'users',
      {},
      () => Db.db.rawQuery(
        'SELECT u.*, e.name AS emp_name FROM users u '
        'LEFT JOIN employees e ON e.id = u.employee_id '
        'ORDER BY u.username',
      ),
    );
    return raw.map((r) => UserEntity.fromMap(r)).toList();
  }

  Future<List<UserEntity>> fetchUsers() => users();

  // ============================================================
  // CREATE USER
  // ============================================================

  Future<String?> createUser(
    String username,
    String password,
    String role,
    int? empId,
  ) async {
    final cleanUsername = username.trim();

    if (cleanUsername.isEmpty) return 'Username is required';
    if (password.length < 6) return 'Password must be at least 6 characters';

    final exists = await LocalDatasource.dbCount(
      'SELECT COUNT(*) FROM users WHERE username = ? COLLATE NOCASE',
      [cleanUsername],
    );

    if (exists > 0) return 'Username already exists';

    await Repo.saveData(
      'users',
      {},
      {
        'username': cleanUsername,
        'password': hashPassword(password),
        'role': role,
        'employee_id': empId,
        'must_change': 1,
        'active': 1,
      },
    );

    return null;
  }

  // ============================================================
  // UPDATE USER
  // ============================================================

  Future<void> updateUser(int id, Object values) async {
    final map = values is UserEntity
        ? values.toMap()
        : Map<String, Object?>.from(values as Map);

    // Remove virtual joined fields before saving
    map.remove('emp_name');

    await Repo.saveData('users', {'id': '$id'}, map);
  }

  // ============================================================
  // SET PASSWORD
  // ============================================================

  Future<void> setPassword(
    int userId,
    String pw, {
    bool mustChange = false,
  }) async {
    await Db.db.update(
      'users',
      {
        'password': hashPassword(pw),
        'must_change': mustChange ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ============================================================
  // ACTIVE EMPLOYEES
  // ============================================================

  Future<List<EmployeeEntity>> activeEmployees() =>
      EmployeesRepository().fetchEmployees(activeOnly: true);

  Future<List<EmployeeEntity>> fetchActiveEmployees() => activeEmployees();
}
