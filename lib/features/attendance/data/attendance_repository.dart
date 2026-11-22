import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/repo.dart';

class AttendanceRepository {
  Future<List<Rec>> dayAttendance(String date) async {
    final ids = await scopeIds();
    return Db.db.rawQuery(
        'SELECT e.id AS emp_id, e.name, e.department, a.status, a.check_in, '
        'a.check_out, a.note FROM employees e '
        'LEFT JOIN attendance a ON a.employee_id = e.id AND a.date = ? '
        "WHERE e.status = 'Active'"
        "${ids == null ? '' : ' AND e.id IN ${dbIn(ids)}'} "
        'ORDER BY e.name COLLATE NOCASE',
        [date]);
  }

  Future<List<Rec>> fetchDayAttendance(String date) => dayAttendance(date);

  Future<Rec?> attendanceOf(int emp, String date) async {
    final list = await Db.db.query('attendance',
        where: 'employee_id = ? AND date = ?', whereArgs: [emp, date]);
    return list.isEmpty ? null : list.first;
  }

  Future<Rec?> fetchAttendanceOf(int emp, String date) => attendanceOf(emp, date);

  Future<List<Rec>> monthRecords(int emp, int y, int m) async {
    return Db.db.query('attendance',
        where: 'employee_id = ? AND substr(date, 1, 7) = ?',
        whereArgs: [emp, monthKey(y, m)],
        orderBy: 'date');
  }

  Future<List<Rec>> fetchMonthRecords(int emp, int y, int m) => monthRecords(emp, y, m);

  Future<void> _ensure(int emp, String date) => Db.db.insert(
      'attendance', {'employee_id': emp, 'date': date, 'status': 'Present'},
      conflictAlgorithm: ConflictAlgorithm.ignore);

  Future<void> checkIn(int emp, [DateTime? at]) async {
    final now = at ?? DateTime.now();
    final d = ymd(now);
    await _ensure(emp, d);
    await Db.db.rawUpdate(
        'UPDATE attendance SET check_in = COALESCE(check_in, ?), '
        "status = CASE WHEN status IN ('Absent','Leave','Unpaid Leave') "
        "THEN 'Present' ELSE status END "
        'WHERE employee_id = ? AND date = ?',
        [now.toIso8601String(), emp, d]);
  }

  Future<void> checkOut(int emp, [DateTime? at]) async {
    final now = at ?? DateTime.now();
    final d = ymd(now);
    await _ensure(emp, d);
    await Db.db.rawUpdate(
        'UPDATE attendance SET check_in = COALESCE(check_in, ?), check_out = ? '
        'WHERE employee_id = ? AND date = ?',
        [now.toIso8601String(), now.toIso8601String(), emp, d]);
  }

  Future<void> setStatus(int emp, String date, String status) async {
    await _ensure(emp, date);
    final clear = status == 'Leave' ||
        status == 'Unpaid Leave' ||
        status == 'Absent';
    await Db.db.update(
        'attendance',
        {
          'status': status,
          if (clear) 'check_in': null,
          if (clear) 'check_out': null,
        },
        where: 'employee_id = ? AND date = ?',
        whereArgs: [emp, date]);
  }

  Future<void> setTime(int emp, String date,
      {DateTime? inTime, DateTime? outTime}) async {
    await _ensure(emp, date);
    await Db.db.update(
        'attendance',
        {
          if (inTime != null) 'check_in': inTime.toIso8601String(),
          if (outTime != null) 'check_out': outTime.toIso8601String(),
        },
        where: 'employee_id = ? AND date = ?',
        whereArgs: [emp, date]);
    if (inTime != null) {
      await Db.db.rawUpdate(
          "UPDATE attendance SET status = 'Present' WHERE employee_id = ? "
          "AND date = ? AND status IN ('Absent','Leave','Unpaid Leave')",
          [emp, date]);
    }
  }

  Future<void> setNote(int emp, String date, String note) async {
    await _ensure(emp, date);
    await Db.db.update('attendance', {'note': note},
        where: 'employee_id = ? AND date = ?', whereArgs: [emp, date]);
  }

  static Future<Set<String>> holidaySet() async =>
      (await Db.db.query('holidays')).map((r) => r.s('date')).toSet();

  Future<Set<String>> fetchHolidaySet() => holidaySet();
}
