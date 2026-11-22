import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/data/datasources/local_datasource.dart';
import 'package:hrms/data/repositories/repository_impl.dart';
import '../../employees/data/employees_repository.dart';

class UsersRepository {
  Future<List<Rec>> users() => Repo.queryOrLocal('users', {}, () => Db.db.rawQuery(
      'SELECT u.*, e.name AS emp_name FROM users u '
      'LEFT JOIN employees e ON e.id = u.employee_id ORDER BY u.username'));

  Future<List<Rec>> fetchUsers() => users();

  Future<String?> createUser(
      String username, String password, String role, int? empId) async {
    if (username.trim().isEmpty) return 'Username is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    final exists = await LocalDatasource.dbCount(
        'SELECT COUNT(*) FROM users WHERE username = ? COLLATE NOCASE',
        [username.trim()]);
    if (exists > 0) return 'Username already exists';
    await Repo.saveData('users', {}, {
      'username': username.trim(),
      'password': hashPassword(password),
      'role': role,
      'employee_id': empId,
      'must_change': 1,
      'active': 1,
    });
    return null;
  }

  Future<void> updateUser(int id, Rec values) =>
      Repo.saveData('users', {'id': '$id'}, values);

  Future<void> setPassword(int userId, String pw,
      {bool mustChange = false}) async {
    await Db.db.update(
        'users', {'password': hashPassword(pw), 'must_change': mustChange ? 1 : 0},
        where: 'id = ?', whereArgs: [userId]);
  }

  Future<List<Rec>> activeEmployees() => EmployeesRepository().employees(activeOnly: true);

  Future<List<Rec>> fetchActiveEmployees() => activeEmployees();
}
