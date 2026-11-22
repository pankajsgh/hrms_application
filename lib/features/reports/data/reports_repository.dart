import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/repo.dart';
import '../../employees/data/employees_repository.dart';
import '../../leave/data/leave_repository.dart';

class ReportsRepository {
  Future<List<MapEntry<Rec, MonthCalc>>> monthSummary(int y, int m) async {
    final emps = await EmployeesRepository().scopeEmployees();
    final hs = await LeaveRepository().holidaySet();
    final month = monthKey(y, m);
    final all = await queryOrLocal(
      'attendance_summary',
      {'month': month},
      () => Db.db.query('attendance',
          where: 'substr(date, 1, 7) = ?', whereArgs: [month]),
    );

    final now = DateTime.now();
    final isCurrentMonth = (y == now.year && m == now.month);
    final upToDate = isCurrentMonth ? today() : null;

    final out = <MapEntry<Rec, MonthCalc>>[];
    for (final e in emps) {
      final empId = e.i('id');
      final recs = all
          .where((r) =>
              r.i('employee_id') == empId ||
              (r['employee_id'] != null &&
                  r['employee_id'].toString() == empId?.toString()))
          .toList();
      out.add(MapEntry(e, calc(e, y, m, recs, hs, upTo: upToDate)));
    }
    return out;
  }

  Future<List<MapEntry<Rec, MonthCalc>>> fetchMonthSummary(int y, int m) =>
      monthSummary(y, m);

  Future<List<Rec>> attendanceDetail(int y, int m) {
    return queryOrLocal(
      'attendance_detail',
      {'month': monthKey(y, m)},
      () => Db.db.rawQuery(
        'SELECT a.*, e.name, e.code, e.department FROM attendance a '
        'JOIN employees e ON e.id = a.employee_id '
        'WHERE substr(a.date, 1, 7) = ? ORDER BY a.date, e.name',
        [monthKey(y, m)],
      ),
    );
  }

  Future<List<Rec>> fetchAttendanceDetail(int y, int m) => attendanceDetail(y, m);

  Future<List<Rec>> employees() => EmployeesRepository().employees();

  Future<List<Rec>> fetchEmployees() => employees();

  Future<List<Rec>> leaves() => LeaveRepository().leaves();

  Future<List<Rec>> fetchLeaves() => leaves();
}
