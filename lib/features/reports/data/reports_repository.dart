import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/month_calulator.dart';
import 'package:hrms/data/repositories/repository_impl.dart';
import 'package:hrms/domain/entities/attendance_entity.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import 'package:hrms/domain/entities/leave_entity.dart';
import '../../employees/data/employees_repository.dart';
import '../../leave/data/leave_repository.dart';

class ReportsRepository {
  Future<List<MapEntry<EmployeeEntity, MonthCalc>>> monthSummary(int y, int m) async {
    final emps = await EmployeesRepository().scopeEmployees();
    final hs = await LeaveRepository().holidaySet();
    final month = monthKey(y, m);
    final all = await Repo.queryOrLocal(
      'attendance_summary',
      {'month': month},
      () => Db.db.query('attendance',
          where: 'substr(date, 1, 7) = ?', whereArgs: [month]),
    );

    final now = DateTime.now();
    final isCurrentMonth = (y == now.year && m == now.month);
    final upToDate = isCurrentMonth ? today() : null;

    final out = <MapEntry<EmployeeEntity, MonthCalc>>[];
    for (final e in emps) {
      final empId = e.id;
      final recs = all
          .where((r) =>
              r['employee_id'] == empId ||
              (r['employee_id'] != null &&
                  r['employee_id'].toString() == empId?.toString()))
          .toList();
      out.add(MapEntry(e, calc(e.toMap(), y, m, recs, hs, upTo: upToDate)));
    }
    return out;
  }

  Future<List<MapEntry<EmployeeEntity, MonthCalc>>> fetchMonthSummary(int y, int m) =>
      monthSummary(y, m);

  Future<List<AttendanceEntity>> attendanceDetail(int y, int m) async {
    final raw = await Repo.queryOrLocal(
      'attendance_detail',
      {'month': monthKey(y, m)},
      () => Db.db.rawQuery(
        'SELECT a.*, e.name, e.code, e.department FROM attendance a '
        'JOIN employees e ON e.id = a.employee_id '
        'WHERE substr(a.date, 1, 7) = ? ORDER BY a.date, e.name',
        [monthKey(y, m)],
      ),
    );
    return raw.map((r) => AttendanceEntity.fromMap(r)).toList();
  }

  Future<List<AttendanceEntity>> fetchAttendanceDetail(int y, int m) => attendanceDetail(y, m);

  Future<List<EmployeeEntity>> employees() => EmployeesRepository().employees();

  Future<List<EmployeeEntity>> fetchEmployees() => employees();

  Future<List<LeaveEntity>> leaves() => LeaveRepository().leaves();

  Future<List<LeaveEntity>> fetchLeaves() => leaves();
}
