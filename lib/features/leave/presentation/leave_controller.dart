
import 'package:flutter/foundation.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';

import '../data/leave_repository.dart';

class LeaveController extends ChangeNotifier {
  final LeaveRepository _repository = LeaveRepository();

  bool isLoading = false;
  bool isSubmitting = false;

  List<Rec> balances = [];
  List<Rec> leaves = [];
  List<Rec> approvalLeaves = [];
  List<Rec> leaveTypes = [];
  List<Rec> holidays = [];

  int holidayYear = DateTime.now().year;
  bool pendingOnlyApprovals = true;

  bool _disposed = false;
  Future<bool>? _loadFuture;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<bool> loadLeaveData(int? empId, int year) async {
    // Avoid running multiple identical loads simultaneously.
    if (_loadFuture != null) {
      return _loadFuture!;
    }

    final future = _loadLeaveDataInternal(empId, year);
    _loadFuture = future;

    try {
      return await future;
    } finally {
      if (identical(_loadFuture, future)) {
        _loadFuture = null;
      }
    }
  }

  Future<bool> _loadLeaveDataInternal(int? empId, int year) async {
    isLoading = true;
    _notify();

    try {
      if (empId != null && empId > 0) {
        balances = await _repository.fetchBalances(empId, year);
        leaves = await _repository.fetchLeaves(mine: true);
      } else {
        balances = [];
        leaves = [];
      }

      if (Session.isLead) {
        approvalLeaves = await _repository.fetchLeaves(
          approvals: true,
          pendingOnly: pendingOnlyApprovals,
        );
      } else {
        approvalLeaves = [];
      }

      leaveTypes = await _repository.fetchLeaveTypes();

      if (Session.isHr) {
        holidays = await _repository.fetchHolidays(holidayYear);
      } else {
        holidays = [];
      }

      return true;
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
  // RELOAD AFTER SAVE / UPDATE / DELETE
  // ============================================================

  Future<bool> _refresh() async {
    final empId = Session.empId;

    // Wait for an existing load to finish before refreshing.
    final currentLoad = _loadFuture;
    if (currentLoad != null) {
      await currentLoad;
    }

    return loadLeaveData(empId, DateTime.now().year);
  }

  // ============================================================
  // APPROVAL FILTER
  // ============================================================

  Future<void> setPendingOnlyApprovals(
      bool pending,
      int? empId,
      ) async {
    if (!Session.isLead) return;

    pendingOnlyApprovals = pending;
    _notify();

    try {
      approvalLeaves = await _repository.fetchLeaves(
        approvals: true,
        pendingOnly: pending,
      );
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
    if (holidayYear == year) return;

    holidayYear = year;
    _notify();

    if (!Session.isHr) return;

    try {
      holidays = await _repository.fetchHolidays(year);
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
      String reason,
      ) async {
    if (isSubmitting) {
      return 'Please wait. Your request is being submitted.';
    }

    if (empId <= 0) return 'Invalid employee.';
    if (typeId <= 0) return 'Please select a leave type.';
    if (reason.trim().isEmpty) return 'Please enter leave reason.';

    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);

    if (end.isBefore(start)) {
      return 'End date cannot be before start date.';
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
      );

      if (error != null) return error;

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
      Rec leave,
      bool approve,
      int? empId,
      ) async {
    try {
      await _repository.decideLeave(leave, approve);
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
      Rec data, {
        int? id,
      }) async {
    try {
      await _repository.saveLeaveType(data, id: id);
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
    try {
      final error = await _repository.addHoliday(date, name);

      if (error != null) return error;

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
    try {
      await _repository.deleteHoliday(id);

      holidays = await _repository.fetchHolidays(holidayYear);
      _notify();

      return true;
    } catch (e, stackTrace) {
      debugPrint('deleteHoliday: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
