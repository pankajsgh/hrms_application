import 'package:flutter/foundation.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/domain/entities/attendance_entity.dart';

import '../data/attendance_repository.dart';

class AttendanceController extends ChangeNotifier {
  final AttendanceRepository _repository = AttendanceRepository();

  bool isLoading = false;

  AttendanceEntity? todayRecord;

  List<AttendanceEntity> monthRecordsList = [];

  Set<String> holidays = {};

  List<AttendanceEntity> dayAttendanceList = [];

  // ============================================================
  // LOADING HELPER
  // ============================================================

  Future<void> _loadData(
      Future<void> Function() operation,
      ) async {
    isLoading = true;
    notifyListeners();

    try {
      await operation();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // TODAY ATTENDANCE
  // ============================================================

  Future<void> loadTodayAttendance(
      int empId,
      String dateStr,
      ) async {
    await _loadData(() async {
      todayRecord = await _repository.fetchAttendanceOf(
        empId,
        dateStr,
      );
    });
  }

  // ============================================================
  // MONTH ATTENDANCE
  // ============================================================

  Future<void> loadMonthRecords(
      int empId,
      int year,
      int month,
      ) async {
    await _loadData(() async {
      final results = await Future.wait<dynamic>([
        _repository.fetchMonthRecords(empId, year, month),
        _repository.fetchHolidaySet(),
      ]);

      monthRecordsList = results[0] as List<AttendanceEntity>;
      holidays = results[1] as Set<String>;
    });
  }

  // ============================================================
  // DAY ATTENDANCE
  // ============================================================

  Future<void> loadDayAttendance(String dateStr) async {
    await _loadData(() async {
      dayAttendanceList =
      await _repository.fetchDayAttendance(dateStr);
    });
  }

  // ============================================================
  // CHECK IN
  // ============================================================

  Future<void> checkIn(
      int empId, [
        DateTime? at,
      ]) async {
    final time = at ?? DateTime.now();

    await _repository.checkIn(empId, time);

    await loadTodayAttendance(
      empId,
      ymd(time),
    );
  }

  // ============================================================
  // CHECK OUT
  // ============================================================

  Future<void> checkOut(
      int empId, [
        DateTime? at,
      ]) async {
    final time = at ?? DateTime.now();

    await _repository.checkOut(empId, time);

    await loadTodayAttendance(
      empId,
      ymd(time),
    );
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> setStatus(
      int empId,
      String date,
      String status,
      ) async {
    await _repository.setStatus(
      empId,
      date,
      status,
    );

    await loadDayAttendance(date);
  }

  // ============================================================
  // UPDATE TIME
  // ============================================================

  Future<void> setTime(
      int empId,
      String date, {
        DateTime? inTime,
        DateTime? outTime,
      }) async {
    await _repository.setTime(
      empId,
      date,
      inTime: inTime,
      outTime: outTime,
    );

    await loadDayAttendance(date);
  }

  // ============================================================
  // UPDATE NOTE
  // ============================================================

  Future<void> setNote(
      int empId,
      String date,
      String note,
      ) async {
    await _repository.setNote(
      empId,
      date,
      note,
    );

    await loadDayAttendance(date);
  }
}