import 'package:hrms/domain/entities/employee_entity.dart';

import 'common.dart';

/// The logged-in user and their employee profile.
class Session {
  static Rec? user;
  static EmployeeEntity? employee;

  static void set(Rec u, EmployeeEntity? e) {
    user = u;
    employee = e;
  }

  static void clear() {
    user = null;
    employee = null;
  }

  static String get role => (user?['role'] as String?) ?? 'employee';
  static int? get empId => (employee?.id as num?)?.toInt();
  static bool get isAdmin => role == 'admin';
  static bool get isHr => role == 'admin' || role == 'hr';
  static bool get isManager => role == 'manager';
  static bool get isLead => isHr || isManager;
  static bool get isRecruiter => role == 'recruiter';
  static bool get canRecruit => isHr || isRecruiter;
  static bool get canEditEmployees => isHr || isRecruiter;
  static String get name =>
      (employee?['name'] ?? user?['username'] ?? '').toString();
}
