import 'package:flutter/foundation.dart';
import 'package:hrms/core/common.dart';
import '../data/attendance_repository.dart';

class AttendanceController extends ChangeNotifier {
  final AttendanceRepository _repository = AttendanceRepository();

  bool isLoading = false;
  Rec? todayRecord;
  List<Rec> monthRecordsList = [];
  Set<String> holidays = {};
  List<Rec> dayAttendanceList = [];

  Future<void> loadTodayAttendance(int empId, String dateStr) async {
    isLoading = true;
    notifyListeners();

    todayRecord = await _repository.fetchAttendanceOf(empId, dateStr);

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMonthRecords(int empId, int y, int m) async {
    isLoading = true;
    notifyListeners();

    monthRecordsList = await _repository.fetchMonthRecords(empId, y, m);
    holidays = await _repository.fetchHolidaySet();

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadDayAttendance(String dateStr) async {
    isLoading = true;
    notifyListeners();

    dayAttendanceList = await _repository.fetchDayAttendance(dateStr);

    isLoading = false;
    notifyListeners();
  }

  Future<void> checkIn(int empId, [DateTime? at]) async {
    await _repository.checkIn(empId, at);
    await loadTodayAttendance(empId, ymd(DateTime.now()));
  }

  Future<void> checkOut(int empId, [DateTime? at]) async {
    await _repository.checkOut(empId, at);
    await loadTodayAttendance(empId, ymd(DateTime.now()));
  }

  Future<void> setStatus(int empId, String date, String status) async {
    await _repository.setStatus(empId, date, status);
    await loadDayAttendance(date);
  }

  Future<void> setTime(int empId, String date, {DateTime? inTime, DateTime? outTime}) async {
    await _repository.setTime(empId, date, inTime: inTime, outTime: outTime);
    await loadDayAttendance(date);
  }

  Future<void> setNote(int empId, String date, String note) async {
    await _repository.setNote(empId, date, note);
    await loadDayAttendance(date);
  }
}
