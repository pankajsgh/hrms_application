import 'package:hrms/data/datasources/local_datasource.dart';
import 'package:hrms/domain/entities/attendance_entity.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';

class AttendanceRepository {
  // ============================================================
  // ALL EMPLOYEES ATTENDANCE FOR A DATE
  // ============================================================

  Future<List<AttendanceEntity>> dayAttendance(String date) async {
    final ids = await scopeIds();

    final raw = await Db.db.rawQuery(
      'SELECT '
          'a.id, '
          'e.id AS employee_id, '
          '? AS date, '
          'e.name, '
          'e.code, '
          'e.department, '
          "COALESCE(a.status, '') AS status, "
          'a.check_in, '
          'a.check_out, '
          'a.note '
          'FROM employees e '
          'LEFT JOIN attendance a '
          'ON a.employee_id = e.id AND a.date = ? '
          "WHERE e.status = 'Active' "
          "${ids == null ? '' : 'AND e.id IN ${LocalDatasource.dbIn(ids)}'} "
          'ORDER BY e.name COLLATE NOCASE',
      [date, date],
    );

    return raw
        .map((row) => AttendanceEntity.fromMap(row))
        .toList();
  }

  Future<List<AttendanceEntity>> fetchDayAttendance(String date) {
    return dayAttendance(date);
  }

  // ============================================================
  // SINGLE EMPLOYEE ATTENDANCE
  // ============================================================

  Future<AttendanceEntity?> attendanceOf(
      int emp,
      String date,
      ) async {
    final list = await Db.db.query(
      'attendance',
      where: 'employee_id = ? AND date = ?',
      whereArgs: [emp, date],
    );

    if (list.isEmpty) return null;

    return AttendanceEntity.fromMap(list.first);
  }

  Future<AttendanceEntity?> fetchAttendanceOf(
      int emp,
      String date,
      ) {
    return attendanceOf(emp, date);
  }

  // ============================================================
  // MONTH ATTENDANCE
  // ============================================================

  Future<List<AttendanceEntity>> monthRecords(
      int emp,
      int year,
      int month,
      ) async {
    final raw = await Db.db.query(
      'attendance',
      where: 'employee_id = ? AND substr(date, 1, 7) = ?',
      whereArgs: [
        emp,
        monthKey(year, month),
      ],
      orderBy: 'date',
    );

    return raw
        .map((row) => AttendanceEntity.fromMap(row))
        .toList();
  }

  Future<List<AttendanceEntity>> fetchMonthRecords(
      int emp,
      int year,
      int month,
      ) {
    return monthRecords(emp, year, month);
  }

  // ============================================================
  // ENSURE ATTENDANCE ROW
  // ============================================================

  Future<void> _ensure(int emp, String date) async {
    await Db.db.insert(
      'attendance',
      {
        'employee_id': emp,
        'date': date,
        'status': 'Present',
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // ============================================================
  // CHECK IN
  // ============================================================

  Future<void> checkIn(int emp, [DateTime? at]) async {
    final now = at ?? DateTime.now();
    final date = ymd(now);

    await _ensure(emp, date);

    await Db.db.rawUpdate(
      'UPDATE attendance '
          'SET check_in = COALESCE(check_in, ?), '
          "status = CASE "
          "WHEN status IN ('Absent', 'Leave', 'Unpaid Leave') "
          "THEN 'Present' "
          'ELSE status END '
          'WHERE employee_id = ? AND date = ?',
      [
        now.toIso8601String(),
        emp,
        date,
      ],
    );
  }

  // ============================================================
  // CHECK OUT
  // ============================================================

  Future<void> checkOut(int emp, [DateTime? at]) async {
    final now = at ?? DateTime.now();
    final date = ymd(now);

    final record = await attendanceOf(emp, date);

    if (record == null || record.checkIn == null) {
      throw StateError('Please check in before checking out.');
    }

    if (record.checkIn!.isEmpty) {
      throw StateError('Please check in before checking out.');
    }

    await Db.db.rawUpdate(
      'UPDATE attendance '
          'SET check_out = COALESCE(check_out, ?) '
          'WHERE employee_id = ? AND date = ?',
      [
        now.toIso8601String(),
        emp,
        date,
      ],
    );
  }

  // ============================================================
  // SET ATTENDANCE STATUS
  // ============================================================

  Future<void> setStatus(
      int emp,
      String date,
      String status,
      ) async {
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
      whereArgs: [emp, date],
    );
  }

  // ============================================================
  // SET ATTENDANCE TIME
  // ============================================================

  Future<void> setTime(
      int emp,
      String date, {
        DateTime? inTime,
        DateTime? outTime,
      }) async {
    await _ensure(emp, date);

    await Db.db.update(
      'attendance',
      {
        if (inTime != null) 'check_in': inTime.toIso8601String(),
        if (outTime != null) 'check_out': outTime.toIso8601String(),
      },
      where: 'employee_id = ? AND date = ?',
      whereArgs: [emp, date],
    );

    if (inTime != null) {
      await Db.db.rawUpdate(
        "UPDATE attendance "
            "SET status = 'Present' "
            "WHERE employee_id = ? "
            "AND date = ? "
            "AND status IN ('Absent', 'Leave', 'Unpaid Leave')",
        [emp, date],
      );
    }
  }

  // ============================================================
  // SET ATTENDANCE NOTE
  // ============================================================

  Future<void> setNote(
      int emp,
      String date,
      String note,
      ) async {
    await _ensure(emp, date);

    await Db.db.update(
      'attendance',
      {'note': note},
      where: 'employee_id = ? AND date = ?',
      whereArgs: [emp, date],
    );
  }

  // ============================================================
  // HOLIDAYS
  // ============================================================

  static Future<Set<String>> holidaySet() async {
    final rows = await Db.db.query('holidays');

    return rows
        .map((row) => row['date']?.toString() ?? '')
        .where((date) => date.isNotEmpty)
        .toSet();
  }

  Future<Set<String>> fetchHolidaySet() {
    return holidaySet();
  }
}