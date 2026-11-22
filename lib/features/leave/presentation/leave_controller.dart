import 'package:flutter/foundation.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import '../data/leave_repository.dart';

class LeaveController extends ChangeNotifier {
  final LeaveRepository _repository = LeaveRepository();

  bool isLoading = false;
  List<Rec> balances = [];
  List<Rec> leaves = [];
  List<Rec> approvalLeaves = [];
  List<Rec> leaveTypes = [];
  List<Rec> holidays = [];
  int holidayYear = DateTime.now().year;
  bool pendingOnlyApprovals = true;

  Future<bool> loadLeaveData(int? empId, int year) async {
    isLoading = true;
    notifyListeners();

    try {
      if (empId != null) {
        balances = await _repository.fetchBalances(empId, year);
      }

      leaves = await _repository.fetchLeaves(mine: true);

      if (Session.isLead) {
        approvalLeaves = await _repository.fetchLeaves(
          approvals: true,
          pendingOnly: pendingOnlyApprovals,
        );
      }

      if (Session.isHr) {
        leaveTypes = await _repository.fetchLeaveTypes();
        holidays = await _repository.fetchHolidays(holidayYear);
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('loadLeaveData error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPendingOnlyApprovals(bool pending, int? empId) async {
    pendingOnlyApprovals = pending;
    if (Session.isLead) {
      approvalLeaves = await _repository.fetchLeaves(approvals: true, pendingOnly: pendingOnlyApprovals);
      notifyListeners();
    }
  }

  Future<void> setHolidayYear(int year, int? empId) async {
    holidayYear = year;
    if (Session.isHr) {
      holidays = await _repository.fetchHolidays(holidayYear);
      notifyListeners();
    }
  }

  Future<String?> applyLeave(int empId, int typeId, DateTime from, DateTime to, String reason) async {
    final err = await _repository.applyLeave(empId, typeId, from, to, reason);
    await loadLeaveData(empId, DateTime.now().year);
    return err;
  }

  Future<bool> cancelLeave(int id, int? empId) async {
    await _repository.cancelLeave(id);
    return await loadLeaveData(empId, DateTime.now().year);
  }

  Future<void> decideLeave(Rec leave, bool approve, int? empId) async {
    await _repository.decideLeave(leave, approve);
    await loadLeaveData(empId, DateTime.now().year);
  }

  Future<void> saveLeaveType(Rec data, {int? id}) async {
    await _repository.saveLeaveType(data, id: id);
    await loadLeaveData(Session.empId, DateTime.now().year);
  }

  Future<String?> deleteLeaveType(int id) async {
    final err = await _repository.deleteLeaveType(id);
    await loadLeaveData(Session.empId, DateTime.now().year);
    return err;
  }

  Future<String?> addHoliday(String date, String name) async {
    final err = await _repository.addHoliday(date, name);
    await loadLeaveData(Session.empId, DateTime.now().year);
    return err;
  }

  Future<void> deleteHoliday(int id) async {
    await _repository.deleteHoliday(id);
    await loadLeaveData(Session.empId, DateTime.now().year);
  }
}
