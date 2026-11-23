import 'package:flutter/foundation.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import 'package:hrms/domain/entities/user_entity.dart';
import '../data/users_repository.dart';

class UsersController extends ChangeNotifier {
  final UsersRepository _repository = UsersRepository();

  bool isLoading = false;
  List<UserEntity> users = [];
  List<EmployeeEntity> activeEmployees = [];

  Future<void> loadUsers() async {
    isLoading = true;
    notifyListeners();

    users = await _repository.fetchUsers();
    activeEmployees = await _repository.fetchActiveEmployees();

    isLoading = false;
    notifyListeners();
  }

  Future<String?> createUser(String username, String password, String role, int employeeId) async {
    final err = await _repository.createUser(username, password, role, employeeId);
    await loadUsers();
    return err;
  }

  Future<void> updateUser(int id, Map<String, Object?> values) async {
    await _repository.updateUser(id, values);
    await loadUsers();
  }

  Future<void> setPassword(int userId, String pw, {bool mustChange = false}) async {
    await _repository.setPassword(userId, pw, mustChange: mustChange);
    await loadUsers();
  }
}
