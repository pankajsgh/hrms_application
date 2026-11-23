import 'package:flutter/foundation.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/month_calulator.dart';
import 'package:hrms/domain/entities/attendance_entity.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import 'package:hrms/domain/entities/leave_entity.dart';
import '../data/reports_repository.dart';

class ReportsController extends ChangeNotifier {
  final ReportsRepository _repository = ReportsRepository();

  bool isLoading = false;
  String? error;

  int year = DateTime.now().year;
  int month = DateTime.now().month;
  String searchQuery = '';

  List<MapEntry<EmployeeEntity, MonthCalc>> summaryRows = [];
  List<AttendanceEntity> detailRows = [];
  List<LeaveEntity> leaveRows = [];
  List<EmployeeEntity> employeeRows = [];

  Future<void> loadReports() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final summaryFuture = _repository.fetchMonthSummary(year, month);
      final detailFuture = _repository.fetchAttendanceDetail(year, month);
      final leaveFuture = _repository.fetchLeaves();
      final empFuture = _repository.fetchEmployees();

      final results = await Future.wait([
        summaryFuture,
        detailFuture,
        leaveFuture,
        empFuture,
      ]);

      summaryRows = results[0] as List<MapEntry<EmployeeEntity, MonthCalc>>;
      detailRows = results[1] as List<AttendanceEntity>;
      leaveRows = results[2] as List<LeaveEntity>;
      employeeRows = results[3] as List<EmployeeEntity>;
    } catch (e, stackTrace) {
      error = 'Unable to load report data';
      debugPrint('loadReports error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setYearMonth(int y, int m) {
    year = y;
    month = m;
    loadReports();
  }

  void setSearchQuery(String q) {
    searchQuery = q.trim();
    notifyListeners();
  }

  // --- Metrics ---

  int get totalEmployees => summaryRows.length;

  double get totalHoursWorked => summaryRows.fold<double>(
        0.0,
        (sum, entry) => sum + entry.value.totalHours,
      );

  double get overallAvgDailyHours {
    final totalDaysAttended = summaryRows.fold<double>(
      0.0,
      (sum, entry) => sum + entry.value.daysAttended,
    );
    if (totalDaysAttended <= 0) return 0.0;
    return totalHoursWorked / totalDaysAttended;
  }

  double get avgAttendanceRate {
    if (summaryRows.isEmpty) return 0.0;
    final sumRates = summaryRows.fold<double>(
      0.0,
      (sum, entry) => sum + entry.value.attendanceRate,
    );
    return sumRates / summaryRows.length;
  }

  // --- Filtered Data Getters ---

  List<MapEntry<EmployeeEntity, MonthCalc>> get filteredSummaryRows {
    if (searchQuery.isEmpty) return summaryRows;
    final q = searchQuery.toLowerCase();
    return summaryRows.where((e) {
      final name = e.key.name.toLowerCase();
      final code = e.key.code.toLowerCase();
      final dept = (e.key.department ?? '').toLowerCase();
      return name.contains(q) || code.contains(q) || dept.contains(q);
    }).toList();
  }

  List<AttendanceEntity> get filteredDetailRows {
    if (searchQuery.isEmpty) return detailRows;
    final q = searchQuery.toLowerCase();
    return detailRows.where((r) {
      final name = (r.empName ?? '').toLowerCase();
      final code = (r.code ?? '').toLowerCase();
      final dept = (r.department ?? '').toLowerCase();
      final status = r.status.toLowerCase();
      return name.contains(q) ||
          code.contains(q) ||
          dept.contains(q) ||
          status.contains(q);
    }).toList();
  }

  List<LeaveEntity> get filteredLeaveRows {
    if (searchQuery.isEmpty) return leaveRows;
    final q = searchQuery.toLowerCase();
    return leaveRows.where((l) {
      final empName = (l.empName ?? '').toLowerCase();
      final typeName = (l.typeName ?? '').toLowerCase();
      final reason = l.reason.toLowerCase();
      final status = l.status.toLowerCase();
      return empName.contains(q) ||
          typeName.contains(q) ||
          reason.contains(q) ||
          status.contains(q);
    }).toList();
  }

  List<EmployeeEntity> get filteredEmployeeRows {
    if (searchQuery.isEmpty) return employeeRows;
    final q = searchQuery.toLowerCase();
    return employeeRows.where((e) {
      final name = e.name.toLowerCase();
      final code = e.code.toLowerCase();
      final dept = (e.department ?? '').toLowerCase();
      final email = (e.email ?? '').toLowerCase();
      final desig = (e.designation ?? '').toLowerCase();
      return name.contains(q) ||
          code.contains(q) ||
          dept.contains(q) ||
          email.contains(q) ||
          desig.contains(q);
    }).toList();
  }

  // Backward compatibility helpers
  Future<List<AttendanceEntity>> fetchAttendanceDetail() async {
    if (detailRows.isNotEmpty) return detailRows;
    return await _repository.fetchAttendanceDetail(year, month);
  }

  Future<List<EmployeeEntity>> fetchEmployees() async {
    if (employeeRows.isNotEmpty) return employeeRows;
    return await _repository.fetchEmployees();
  }

  Future<List<LeaveEntity>> fetchLeaves() async {
    if (leaveRows.isNotEmpty) return leaveRows;
    return await _repository.fetchLeaves();
  }
}
