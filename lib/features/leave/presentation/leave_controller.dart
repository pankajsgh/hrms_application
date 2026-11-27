
import 'package:flutter/foundation.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/domain/entities/leave_entity.dart';

import '../data/leave_repository.dart';

class LeaveController extends ChangeNotifier {
  final LeaveRepository _repository = LeaveRepository();

  bool isLoading = false;
  bool isSubmitting = false;

  List<LeaveBalanceEntity> balances = [];
  List<LeaveEntity> leaves = [];
  List<LeaveEntity> approvalLeaves = [];
  List<LeaveTypeEntity> leaveTypes = [];
  List<Rec> holidays = [];

  int holidayYear = DateTime.now().year;
  bool pendingOnlyApprovals = true;

  bool _disposed = false;

  Future<bool>? _loadFuture;
  int? _loadingEmpId;
  int? _loadingYear;

  int _approvalRequestId = 0;
  int _holidayRequestId = 0;

  // ============================================================
  // SAFE NOTIFICATION
  // ============================================================

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<bool> loadLeaveData(int? empId, int year) async {
    if (_disposed) return false;

    // Reuse the current request if it is loading the same data.
    final activeLoad = _loadFuture;

    if (activeLoad != null) {
      if (_loadingEmpId == empId && _loadingYear == year) {
        return activeLoad;
      }

      // Wait for the previous request before starting another one.
      await activeLoad;

      if (_disposed) return false;

      return loadLeaveData(empId, year);
    }

    _loadingEmpId = empId;
    _loadingYear = year;

    final future = _loadLeaveDataInternal(empId, year);
    _loadFuture = future;

    try {
      return await future;
    } finally {
      if (identical(_loadFuture, future)) {
        _loadFuture = null;
        _loadingEmpId = null;
        _loadingYear = null;
      }
    }
  }

  Future<bool> _loadLeaveDataInternal(
      int? empId,
      int year,
      ) async {
    isLoading = true;
    _notify();

    bool success = true;

    try {
      // --------------------------------------------------------
      // EMPLOYEE LEAVES AND BALANCES
      // --------------------------------------------------------

      if (empId != null && empId > 0) {
        try {
          final results = await Future.wait([
            _repository.fetchBalances(empId, year),
            _repository.fetchLeaves(mine: true),
          ]);

          balances = results[0] as List<LeaveBalanceEntity>;
          leaves = results[1] as List<LeaveEntity>;
        } catch (e, stackTrace) {
          success = false;

          debugPrint('Loading employee leave data: $e');
          debugPrintStack(stackTrace: stackTrace);
        }
      } else {
        balances = [];
        leaves = [];
      }

      if (_disposed) return false;

      // --------------------------------------------------------
      // APPROVAL REQUESTS
      // --------------------------------------------------------

      if (Session.isLead) {
        try {
          approvalLeaves = await _repository.fetchLeaves(
            approvals: true,
            pendingOnly: pendingOnlyApprovals,
          );
        } catch (e, stackTrace) {
          success = false;

          debugPrint('Loading approval leaves: $e');
          debugPrintStack(stackTrace: stackTrace);
        }
      } else {
        approvalLeaves = [];
      }

      if (_disposed) return false;

      // --------------------------------------------------------
      // LEAVE TYPES
      // --------------------------------------------------------

      try {
        leaveTypes = await _repository.fetchLeaveTypes();
      } catch (e, stackTrace) {
        success = false;

        debugPrint('Loading leave types: $e');
        debugPrintStack(stackTrace: stackTrace);
      }

      if (_disposed) return false;

      // --------------------------------------------------------
      // HOLIDAYS
      // --------------------------------------------------------

      if (Session.isHr) {
        try {
          holidays = await _repository.fetchHolidays(holidayYear);
        } catch (e, stackTrace) {
          success = false;

          debugPrint('Loading holidays: $e');
          debugPrintStack(stackTrace: stackTrace);
        }
      } else {
        holidays = [];
      }

      return success;
    } catch (e, stackTrace) {
      debugPrint('LeaveController.loadLeaveData: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      isLoading = false;
      _notify();
    }
  }

  // ============================================================
  // REFRESH DATA AFTER MUTATIONS
  // ============================================================

  Future<bool> _refresh() async {
    if (_disposed) return false;

    final activeLoad = _loadFuture;

    if (activeLoad != null) {
      await activeLoad;
    }

    if (_disposed) return false;

    return loadLeaveData(
      Session.empId,
      DateTime.now().year,
    );
  }

  // ============================================================
  // APPROVAL FILTER
  // ============================================================

  Future<void> setPendingOnlyApprovals(
      bool pending,
      int? empId,
      ) async {
    if (!Session.isLead || _disposed) return;

    if (pendingOnlyApprovals == pending) return;

    pendingOnlyApprovals = pending;

    final requestId = ++_approvalRequestId;

    _notify();

    try {
      final result = await _repository.fetchLeaves(
        approvals: true,
        pendingOnly: pending,
      );

      // Ignore outdated responses.
      if (_disposed || requestId != _approvalRequestId) return;

      approvalLeaves = result;
    } catch (e, stackTrace) {
      debugPrint('setPendingOnlyApprovals: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    _notify();
  }

  // ============================================================
  // HOLIDAY YEAR
  // ============================================================

  Future<void> setHolidayYear(
      int year,
      int? empId,
      ) async {
    if (_disposed || !Session.isHr) return;

    if (holidayYear == year) return;

    holidayYear = year;

    final requestId = ++_holidayRequestId;

    _notify();

    try {
      final result = await _repository.fetchHolidays(year);

      // Ignore outdated year responses.
      if (_disposed || requestId != _holidayRequestId) return;

      holidays = result;
    } catch (e, stackTrace) {
      debugPrint('setHolidayYear: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    _notify();
  }

  // ============================================================
  // APPLY LEAVE
  // ============================================================

  Future<String?> applyLeave(
      int empId,
      int typeId,
      DateTime from,
      DateTime to,
      String reason, {
        bool isHalfDay = false,
        String? halfDayType,
      }) async {
    if (_disposed) return 'Leave controller is unavailable.';

    if (isSubmitting) {
      return 'Please wait. Your request is being submitted.';
    }

    if (empId <= 0) {
      return 'Invalid employee.';
    }

    if (typeId <= 0) {
      return 'Please select a leave type.';
    }

    if (reason.trim().isEmpty) {
      return 'Please enter leave reason.';
    }

    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);

    if (end.isBefore(start)) {
      return 'End date cannot be before start date.';
    }

    if (isHalfDay && start != end) {
      return 'Half day can only be applied for a single date.';
    }

    if (isHalfDay &&
        halfDayType != 'First Half' &&
        halfDayType != 'Second Half') {
      return 'Please select the half-day duration.';
    }

    isSubmitting = true;
    _notify();

    try {
      final error = await _repository.applyLeave(
        empId,
        typeId,
        start,
        end,
        reason.trim(),
        isHalfDay: isHalfDay,
        halfDayType: isHalfDay ? halfDayType : null,
      );

      if (error != null) {
        return error;
      }

      await _refresh();

      return null;
    } catch (e, stackTrace) {
      debugPrint('applyLeave: $e');
      debugPrintStack(stackTrace: stackTrace);

      return 'Unable to submit leave request: $e';
    } finally {
      isSubmitting = false;
      _notify();
    }
  }

  // ============================================================
  // CANCEL LEAVE
  // ============================================================

  Future<bool> cancelLeave(
      int id,
      int? empId,
      ) async {
    if (_disposed || id <= 0) return false;

    try {
      await _repository.cancelLeave(id);

      return await _refresh();
    } catch (e, stackTrace) {
      debugPrint('cancelLeave: $e');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ============================================================
  // APPROVE / REJECT LEAVE
  // ============================================================

  Future<bool> decideLeave(
      LeaveEntity leave,
      bool approve,
      int? empId,
      ) async {
    if (_disposed) return false;

    try {
      await _repository.decideLeave(
        leave,
        approve,
      );

      return await _refresh();
    } catch (e, stackTrace) {
      debugPrint('decideLeave: $e');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ============================================================
  // SAVE LEAVE TYPE
  // ============================================================

  Future<bool> saveLeaveType(
      Map<String, Object?> data, {
        int? id,
      }) async {
    if (_disposed) return false;

    try {
      final name = data['name']?.toString().trim() ?? '';

      if (name.isEmpty) return false;

      final days = double.tryParse(
        data['days_per_year']?.toString() ?? '',
      );

      if (days == null || days < 0) return false;

      final paid = int.tryParse(
        data['paid']?.toString() ?? '1',
      );

      if (paid != 0 && paid != 1) return false;

      final cleanedData = <String, Object?>{
        ...data,
        'name': name,
        'days_per_year': days,
        'paid': paid,
      };

      await _repository.saveLeaveType(
        cleanedData,
        id: id,
      );

      return await _refresh();
    } catch (e, stackTrace) {
      debugPrint('saveLeaveType: $e');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ============================================================
  // DELETE LEAVE TYPE
  // ============================================================

  Future<String?> deleteLeaveType(int id) async {
    if (_disposed) return 'Controller unavailable.';

    if (id <= 0) return 'Invalid leave type.';

    try {
      final error = await _repository.deleteLeaveType(id);

      if (error != null) return error;

      await _refresh();

      return null;
    } catch (e, stackTrace) {
      debugPrint('deleteLeaveType: $e');
      debugPrintStack(stackTrace: stackTrace);

      return 'Unable to delete leave type: $e';
    }
  }

  // ============================================================
  // ADD HOLIDAY
  // ============================================================

  Future<String?> addHoliday(
      String date,
      String name,
      ) async {
    if (_disposed) return 'Controller unavailable.';

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return 'Please enter holiday name.';
    }

    try {
      await _repository.addHoliday(
        date,
        cleanName,
      );

      if (_disposed) return null;

      holidays = await _repository.fetchHolidays(holidayYear);

      _notify();

      return null;
    } catch (e, stackTrace) {
      debugPrint('addHoliday: $e');
      debugPrintStack(stackTrace: stackTrace);

      return 'Unable to add holiday: $e';
    }
  }

  // ============================================================
  // DELETE HOLIDAY
  // ============================================================

  Future<bool> deleteHoliday(int id) async {
    if (_disposed || id <= 0) return false;

    try {
      await _repository.deleteHoliday(id);

      if (_disposed) return false;

      holidays = await _repository.fetchHolidays(holidayYear);

      _notify();

      return true;
    } catch (e, stackTrace) {
      debugPrint('deleteHoliday: $e');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;

    // Invalidate pending filter requests.
    _approvalRequestId++;
    _holidayRequestId++;

    super.dispose();
  }
}
