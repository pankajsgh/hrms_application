
import 'package:flutter/foundation.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/storage_config.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import 'package:hrms/features/auth/data/login_request.dart';


class AuthRepository {
  // ============================================================
  // LOGIN
  // ============================================================

  Future<bool> login(LoginRequest request) async {
    final username = request.username.trim();
    final password = request.password;

    if (username.isEmpty || password.isEmpty) {
      return false;
    }

    try {
      switch (StorageConfig.mode) {
        case StorageMode.localOnly:
          return await _loginLocal(request);

        case StorageMode.apiOnly:
          return await _loginApi(request);

        case StorageMode.localAndApi:
          return await _loginApi(request);
      }
    } catch (error, stackTrace) {
      debugPrint('AUTH ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  // ============================================================
  // LOCAL AUTHENTICATION
  // ============================================================

  Future<bool> _loginLocal(LoginRequest request) async {

    final user = await _findUser(request.username.trim());

    print("this is good 44");
    print(user);

    if (user == null) return false;

    if (!_verifyPassword(request.password, user)) {
      return false;
    }

    EmployeeEntity? employee = await _findEmployee(user);

    if (!_isEmployeeActive(employee)) {
      return false;
    }

    print("this is good 44");
    print(employee);

    Session.set(user, employee);

    return true;
  }

  // ============================================================
  // FIND USER
  // ============================================================

  Future<Map<String, Object?>?> _findUser(
      String username,
      ) async {
    final rows = await Db.db.query(
      'users',
      where: 'username = ? COLLATE NOCASE AND active = 1',
      whereArgs: [username],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return Map<String, Object?>.from(rows.first);
  }

  // ============================================================
  // FIND EMPLOYEE
  // ============================================================

  Future<EmployeeEntity?> _findEmployee(
      Map<String, Object?> user,
      ) async {
    final employeeId = user.i('employee_id');

    if (employeeId == null) return null;

    final rows = await Db.db.query(
      'employees',
      where: 'id = ?',
      whereArgs: [employeeId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return EmployeeEntity.fromMap(rows.first);
  }

  // ============================================================
  // PASSWORD VALIDATION
  // ============================================================

  bool _verifyPassword(
      String password,
      Map<String, Object?> user,
      ) {
    final storedPassword = user.s('password');

    if (storedPassword.isEmpty) return false;
    return checkPassword(password, storedPassword);
  }

  // ============================================================
  // EMPLOYEE VALIDATION
  // ============================================================

  bool _isEmployeeActive(EmployeeEntity? employee) {
    if (employee == null) return false;

    return employee.status.toLowerCase() != 'inactive';
  }


  // ============================================================
  // API AUTHENTICATION
  // ============================================================

  Future<bool> _loginApi(LoginRequest request) async {


    debugPrint('API LOGIN: Not implemented yet');

    return false;
  }
}
