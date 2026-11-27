import 'package:flutter/foundation.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import 'package:hrms/domain/entities/user_entity.dart';
import '../data/users_repository.dart';

class UsersController extends ChangeNotifier {
  final UsersRepository _repository = UsersRepository();

  bool isLoading = false;
  List<UserEntity> users = [];
  List<EmployeeEntity> activeEmployees = [];

  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ============================================================
  // LOAD USERS
  // ============================================================

  Future<void> loadUsers() async {
    isLoading = true;
    _notify();

    try {
      users = await _repository.fetchUsers();
      activeEmployees = await _repository.fetchActiveEmployees();
    } catch (e, stackTrace) {
      debugPrint('UsersController.loadUsers: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading = false;
      _notify();
    }
  }

  // ============================================================
  // CREATE USER
  // ============================================================

  Future<String?> createUser(
    String username,
    String password,
    String role,
    int employeeId,
  ) async {
    try {
      final err = await _repository.createUser(
        username,
        password,
        role,
        employeeId,
      );
      await loadUsers();
      return err;
    } catch (e, stackTrace) {
      debugPrint('UsersController.createUser: $e');
      debugPrintStack(stackTrace: stackTrace);
      return 'Unable to create user: $e';
    }
  }

  // ============================================================
  // UPDATE USER
  // ============================================================

  Future<void> updateUser(int id, Map<String, Object?> values) async {
    try {
      await _repository.updateUser(id, values);
      await loadUsers();
    } catch (e, stackTrace) {
      debugPrint('UsersController.updateUser: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // SET PASSWORD
  // ============================================================

  Future<void> setPassword(
    int userId,
    String pw, {
    bool mustChange = false,
  }) async {
    try {
      await _repository.setPassword(userId, pw, mustChange: mustChange);
      await loadUsers();
    } catch (e, stackTrace) {
      debugPrint('UsersController.setPassword: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
