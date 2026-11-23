import 'employee_entity.dart';
import 'leave_entity.dart';
import 'recruitment_entity.dart';
import 'performance_entity.dart';
import 'document_entity.dart';
import 'payroll_entity.dart';
import 'special_day_entity.dart';
import 'user_entity.dart';
import 'attendance_entity.dart';

extension _MapUtils on Map<String, Object?> {
  Object? getVal(String key) => this[key];
  String getString(String key, [String defaultValue = '']) =>
      this[key]?.toString() ?? defaultValue;
  int? getInt(String key) {
    final val = this[key];
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val?.toString() ?? '');
  }
  double getDouble(String key, [double defaultValue = 0.0]) {
    final val = this[key];
    if (val is double) return val;
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '') ?? defaultValue;
  }
}

extension EmployeeEntityExt on EmployeeEntity {
  Map<String, Object?> get _m => toMap();
  Object? operator [](String key) => _m.getVal(key);
  String s(String key, [String def = '']) => _m.getString(key, def);
  int? i(String key) => _m.getInt(key);
  double d(String key, [double def = 0.0]) => _m.getDouble(key, def);
}

extension LeaveEntityExt on LeaveEntity {
  Map<String, Object?> get _m => toMap();
  Object? operator [](String key) => _m.getVal(key);
  String s(String key, [String def = '']) => _m.getString(key, def);
  int? i(String key) => _m.getInt(key);
  double d(String key, [double def = 0.0]) => _m.getDouble(key, def);
}

extension LeaveTypeEntityExt on LeaveTypeEntity {
  Map<String, Object?> get _m => toMap();
  Object? operator [](String key) => _m.getVal(key);
  String s(String key, [String def = '']) => _m.getString(key, def);
  int? i(String key) => _m.getInt(key);
  double d(String key, [double def = 0.0]) => _m.getDouble(key, def);
}

extension LeaveBalanceEntityExt on LeaveBalanceEntity {
  Map<String, Object?> get _m => toMap();
  Object? operator [](String key) => _m.getVal(key);
  String s(String key, [String def = '']) => _m.getString(key, def);
  int? i(String key) => _m.getInt(key);
  double d(String key, [double def = 0.0]) => _m.getDouble(key, def);
}

extension JobEntityExt on JobEntity {
  Map<String, Object?> get _m => toMap();
  Object? operator [](String key) => _m.getVal(key);
  String s(String key, [String def = '']) => _m.getString(key, def);
  int? i(String key) => _m.getInt(key);
  double d(String key, [double def = 0.0]) => _m.getDouble(key, def);
}

extension CandidateEntityExt on CandidateEntity {
  Map<String, Object?> get _m => toMap();
  Object? operator [](String key) => _m.getVal(key);
  String s(String key, [String def = '']) => _m.getString(key, def);
  int? i(String key) => _m.getInt(key);
  double d(String key, [double def = 0.0]) => _m.getDouble(key, def);
}

extension InterviewEntityExt on InterviewEntity {
  Map<String, Object?> get _m => toMap();
  Object? operator [](String key) => _m.getVal(key);
  String s(String key, [String def = '']) => _m.getString(key, def);
  int? i(String key) => _m.getInt(key);
  double d(String key, [double def = 0.0]) => _m.getDouble(key, def);
}

extension PayrollEntityExt on PayrollEntity {
  Map<String, Object?> get _m => toMap();
  Object? operator [](String key) => _m.getVal(key);
  String s(String key, [String def = '']) => _m.getString(key, def);
  int? i(String key) => _m.getInt(key);
  double d(String key, [double def = 0.0]) => _m.getDouble(key, def);
}

extension GoalEntityExt on GoalEntity {
  Map<String, Object?> get _m => toMap();
  Object? operator [](String key) => _m.getVal(key);
  String s(String key, [String def = '']) => _m.getString(key, def);
  int? i(String key) => _m.getInt(key);
  double d(String key, [double def = 0.0]) => _m.getDouble(key, def);
}

extension ReviewEntityExt on ReviewEntity {
  Map<String, Object?> get _m => toMap();
  Object? operator [](String key) => _m.getVal(key);
  String s(String key, [String def = '']) => _m.getString(key, def);
  int? i(String key) => _m.getInt(key);
  double d(String key, [double def = 0.0]) => _m.getDouble(key, def);
}

extension DocumentEntityExt on DocumentEntity {
  Map<String, Object?> get _m => toMap();
  Object? operator [](String key) => _m.getVal(key);
  String s(String key, [String def = '']) => _m.getString(key, def);
  int? i(String key) => _m.getInt(key);
  double d(String key, [double def = 0.0]) => _m.getDouble(key, def);
}

extension SpecialDayEntityExt on SpecialDayEntity {
  Map<String, Object?> get _m => toMap();
  Object? operator [](String key) => _m.getVal(key);
  String s(String key, [String def = '']) => _m.getString(key, def);
  int? i(String key) => _m.getInt(key);
  double d(String key, [double def = 0.0]) => _m.getDouble(key, def);
}

extension UserEntityExt on UserEntity {
  Map<String, Object?> get _m => toMap();
  Object? operator [](String key) => _m.getVal(key);
  String s(String key, [String def = '']) => _m.getString(key, def);
  int? i(String key) => _m.getInt(key);
  double d(String key, [double def = 0.0]) => _m.getDouble(key, def);
}

extension AttendanceEntityExt on AttendanceEntity {
  Map<String, Object?> get _m => toMap();
  Object? operator [](String key) => _m.getVal(key);
  String s(String key, [String def = '']) => _m.getString(key, def);
  int? i(String key) => _m.getInt(key);
  double d(String key, [double def = 0.0]) => _m.getDouble(key, def);
}
