import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/data/datasources/local_datasource.dart';
import 'package:hrms/domain/entities/leave_entity.dart';
import 'package:hrms/domain/entities/special_day_entity.dart';

import '../../leave/data/leave_repository.dart';
import '../../special_days/data/special_days_repository.dart';

class DashboardRepository {
  // ------------------------------------------------------------
  // DASHBOARD STATISTICS
  // ------------------------------------------------------------

  Future<Map<String, int>> dashboard() async {
    if (!Session.isAdmin && !Session.isHr && !Session.isLead) {
      return {};
    }

    final today = ymd(DateTime.now());

    final ids = (!Session.isAdmin && !Session.isHr && Session.isLead)
        ? await scopeIds()
        : null;

    if (ids != null && ids.isEmpty) {
      return {
        'employees': 0,
        'present': 0,
        'onLeave': 0,
        'absent': 0,
        'pending': 0,
      };
    }

    final employeeFilter =
    ids == null ? '' : ' AND employee_id IN ${LocalDatasource.dbIn(ids)}';

    final employees = ids == null
        ? await LocalDatasource.dbCount(
      "SELECT COUNT(*) FROM employees WHERE status = 'Active'",
    )
        : await LocalDatasource.dbCount(
      "SELECT COUNT(*) FROM employees "
          "WHERE status = 'Active' AND id IN ${LocalDatasource.dbIn(ids)}",
    );

    final attendanceEmployeeFilter = ids == null
        ? ''
        : ' AND a.employee_id IN ${LocalDatasource.dbIn(ids)}';

    final present = await LocalDatasource.dbCount(
      "SELECT COUNT(DISTINCT a.employee_id) "
          "FROM attendance a "
          "INNER JOIN employees e ON e.id = a.employee_id "
          "WHERE a.date = ? "
          "AND e.status = 'Active' "
          "AND LOWER(TRIM(a.status)) IN ('present', 'half day')"
          "$attendanceEmployeeFilter",
      [today],
    );

    final onLeave = await LocalDatasource.dbCount(
      "SELECT COUNT(DISTINCT a.employee_id) "
          "FROM attendance a "
          "INNER JOIN employees e ON e.id = a.employee_id "
          "WHERE a.date = ? "
          "AND e.status = 'Active' "
          "AND LOWER(TRIM(a.status)) IN ('leave', 'unpaid leave')"
          "$attendanceEmployeeFilter",
      [today],
    );

    final absent = await LocalDatasource.dbCount(
      "SELECT COUNT(DISTINCT a.employee_id) "
          "FROM attendance a "
          "INNER JOIN employees e ON e.id = a.employee_id "
          "WHERE a.date = ? "
          "AND e.status = 'Active' "
          "AND LOWER(TRIM(a.status)) = 'absent'"
          "$attendanceEmployeeFilter",
      [today],
    );

    final ownLeaveFilter =
    (!Session.isAdmin && Session.empId != null)
        ? ' AND employee_id != ${Session.empId}'
        : '';

    final pending = await LocalDatasource.dbCount(
      "SELECT COUNT(*) FROM leaves "
          "WHERE status = 'Pending'"
          "$employeeFilter"
          "$ownLeaveFilter",
    );

    final result = <String, int>{
      'employees': employees,
      'present': present,
      'onLeave': onLeave,
      'absent': absent,
      'pending': pending,
    };

    if (Session.isAdmin || Session.isHr) {
      final jobsListed = await LocalDatasource.dbCount(
        'SELECT COUNT(*) FROM jobs',
      );

      final openJobs = await LocalDatasource.dbCount(
        "SELECT COUNT(*) FROM jobs "
            "WHERE approval = 'Approved' AND status = 'Open'",
      );

      final closedJobs = await LocalDatasource.dbCount(
        "SELECT COUNT(*) FROM jobs WHERE status = 'Closed'",
      );

      final pendingJobs = await LocalDatasource.dbCount(
        "SELECT COUNT(*) FROM jobs WHERE approval = 'Pending'",
      );

      final candidates = await LocalDatasource.dbCount(
        'SELECT COUNT(*) FROM candidates',
      );

      final interviewsToday = await LocalDatasource.dbCount(
        "SELECT COUNT(*) FROM interviews "
            "WHERE date(scheduled_at) = ?",
        [today],
      );

      final interviews = await LocalDatasource.dbCount(
        "SELECT COUNT(*) FROM interviews WHERE result = 'Scheduled' AND scheduled_at >= ?",
        [today],
      );

      result.addAll({
        'jobsListed': jobsListed,
        'openJobs': openJobs,
        'closedJobs': closedJobs,
        'pendingJobs': pendingJobs,
        'candidates': candidates,
        'interviewsToday': interviewsToday,
        'interviews': interviews,
      });

      const stages = [
        'Applied',
        'Screening',
        'Interview',
        'Offered',
        'Hired',
        'Rejected',
      ];

      for (final stage in stages) {
        final count = await LocalDatasource.dbCount(
          'SELECT COUNT(*) FROM candidates WHERE stage = ?',
          [stage],
        );

        final key = switch (stage) {
          'Applied' => 'candidateApplied',
          'Screening' => 'candidateScreening',
          'Interview' => 'candidateInterview',
          'Offered' => 'candidateOffered',
          'Hired' => 'candidateHired',
          'Rejected' => 'candidateRejected',
          _ => '',
        };

        if (key.isNotEmpty) {
          result[key] = count;
        }
      }
    }

    return result;
  }

  Future<Map<String, int>> fetchDashboardStats() => dashboard();

  // ------------------------------------------------------------
  // OTHER DASHBOARD DATA
  // ------------------------------------------------------------

  Future<List<LeaveBalanceEntity>> balances(int empId, int year) {
    return LeaveRepository().balances(empId, year);
  }

  Future<List<LeaveBalanceEntity>> fetchBalances(int empId, int year) {
    return balances(empId, year);
  }

  Future<List<Rec>> upcomingHolidays(int limit) {
    return LeaveRepository().upcomingHolidays(limit);
  }

  Future<List<Rec>> fetchUpcomingHolidays(int limit) {
    return upcomingHolidays(limit);
  }

  Future<List<SpecialDayEntity>> upcomingSpecialDays([int days = 30]) {
    return SpecialDaysRepository().upcomingSpecialDays(days: days);
  }

  Future<List<SpecialDayEntity>> fetchUpcomingSpecialDays(int days) {
    return upcomingSpecialDays(days);
  }
}
