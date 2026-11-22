
import 'package:flutter/foundation.dart';
import 'package:hrms/core/common.dart';

import '../data/dashboard_repository.dart';

class DashboardController extends ChangeNotifier {
  final DashboardRepository _repository = DashboardRepository();

  bool isLoading = false;
  String? error;

  Map<String, int> stats = {};

  List<Rec> holidays = [];
  List<Rec> specialDays = [];

  int count(String key) => stats[key] ?? 0;

  Future<void> loadDashboard() async {
    if (isLoading) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final dashboardStats =
      await _repository.fetchDashboardStats();

      final upcomingHolidays =
      await _repository.fetchUpcomingHolidays(6);

      final upcomingSpecialDays =
      await _repository.fetchUpcomingSpecialDays(30);

      stats = dashboardStats;
      holidays = upcomingHolidays;
      specialDays = upcomingSpecialDays;
    } catch (e, stackTrace) {
      error = 'Unable to load dashboard. Please try again.';

      debugPrint('Dashboard error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadDashboard();
  }
}
