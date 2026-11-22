import 'package:flutter/foundation.dart';
import 'package:hrms/core/common.dart';
import '../data/payroll_repository.dart';

class PayrollController extends ChangeNotifier {
  final PayrollRepository _repository = PayrollRepository();

  bool isLoading = false;
  int year = DateTime.now().year;
  int month = DateTime.now().month;
  List<Rec> payrollRows = [];

  Future<void> loadPayroll({int? empId}) async {
    isLoading = true;
    notifyListeners();

    payrollRows = await _repository.fetchPayroll(month: monthKey(year, month), empId: empId);

    isLoading = false;
    notifyListeners();
  }

  void setYearMonth(int y, int m, {int? empId}) {
    year = y;
    month = m;
    loadPayroll(empId: empId);
  }

  Future<int> runPayroll(int y, int m) async {
    final count = await _repository.runPayroll(y, m);
    await loadPayroll();
    return count;
  }
}
