import 'common.dart';

/// The logged-in user and their employee profile.
class Session {
  static Rec? user;
  static Rec? emp;

  static void set(Rec u, Rec? e) {
    user = u;
    emp = e;
  }

  static void clear() {
    user = null;
    emp = null;
  }

  static String get role => (user?['role'] as String?) ?? 'employee';
  static int? get empId => (emp?['id'] as num?)?.toInt();
  static bool get isAdmin => role == 'admin';
  static bool get isHr => role == 'admin' || role == 'hr';
  static bool get isManager => role == 'manager';
  static bool get isLead => isHr || isManager;
  static bool get isRecruiter => role == 'recruiter';
  static bool get canRecruit => isHr || isRecruiter;
  static bool get canEditEmployees => isHr || isRecruiter;
  static String get name =>
      (emp?['name'] ?? user?['username'] ?? '').toString();
}
