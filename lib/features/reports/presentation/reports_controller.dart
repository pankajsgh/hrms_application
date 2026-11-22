import 'package:flutter/foundation.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/repo.dart';
import '../data/reports_repository.dart';

class ReportsController extends ChangeNotifier {
  final ReportsRepository _repository = ReportsRepository();

  bool isLoading = false;
  String? error;

  int year = DateTime.now().year;
  int month = DateTime.now().month;
  String searchQuery = '';

  List<MapEntry<Rec, MonthCalc>> summaryRows = [];
  List<Rec> detailRows = [];
  List<Rec> leaveRows = [];
  List<Rec> employeeRows = [];

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

      summaryRows = results[0] as List<MapEntry<Rec, MonthCalc>>;
      detailRows = results[1] as List<Rec>;
      leaveRows = results[2] as List<Rec>;
      employeeRows = results[3] as List<Rec>;
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

  List<MapEntry<Rec, MonthCalc>> get filteredSummaryRows {
    if (searchQuery.isEmpty) return summaryRows;
    final q = searchQuery.toLowerCase();
    return summaryRows.where((e) {
      final name = e.key.s('name').toLowerCase();
      final code = e.key.s('code').toLowerCase();
      final dept = e.key.s('department').toLowerCase();
      return name.contains(q) || code.contains(q) || dept.contains(q);
    }).toList();
  }

  List<Rec> get filteredDetailRows {
    if (searchQuery.isEmpty) return detailRows;
    final q = searchQuery.toLowerCase();
    return detailRows.where((r) {
      final name = r.s('name').toLowerCase();
      final code = r.s('code').toLowerCase();
      final dept = r.s('department').toLowerCase();
      final status = r.s('status').toLowerCase();
      return name.contains(q) ||
          code.contains(q) ||
          dept.contains(q) ||
          status.contains(q);
    }).toList();
  }

  List<Rec> get filteredLeaveRows {
    if (searchQuery.isEmpty) return leaveRows;
    final q = searchQuery.toLowerCase();
    return leaveRows.where((l) {
      final empName = l.s('emp_name').toLowerCase();
      final typeName = l.s('type_name').toLowerCase();
      final reason = l.s('reason').toLowerCase();
      final status = l.s('status').toLowerCase();
      return empName.contains(q) ||
          typeName.contains(q) ||
          reason.contains(q) ||
          status.contains(q);
    }).toList();
  }

  List<Rec> get filteredEmployeeRows {
    if (searchQuery.isEmpty) return employeeRows;
    final q = searchQuery.toLowerCase();
    return employeeRows.where((e) {
      final name = e.s('name').toLowerCase();
      final code = e.s('code').toLowerCase();
      final dept = e.s('department').toLowerCase();
      final email = e.s('email').toLowerCase();
      final desig = e.s('designation').toLowerCase();
      return name.contains(q) ||
          code.contains(q) ||
          dept.contains(q) ||
          email.contains(q) ||
          desig.contains(q);
    }).toList();
  }

  // Backward compatibility helpers
  Future<List<Rec>> fetchAttendanceDetail() async {
    if (detailRows.isNotEmpty) return detailRows;
    return await _repository.fetchAttendanceDetail(year, month);
  }

  Future<List<Rec>> fetchEmployees() async {
    if (employeeRows.isNotEmpty) return employeeRows;
    return await _repository.fetchEmployees();
  }

  Future<List<Rec>> fetchLeaves() async {
    if (leaveRows.isNotEmpty) return leaveRows;
    return await _repository.fetchLeaves();
  }
}
