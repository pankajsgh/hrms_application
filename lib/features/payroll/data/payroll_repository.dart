import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/month_calulator.dart';
import 'package:hrms/data/repositories/repository_impl.dart';
import 'package:hrms/domain/entities/payroll_entity.dart';
import '../../employees/data/employees_repository.dart';
import '../../leave/data/leave_repository.dart';

class PayrollRepository {
  Future<List<PayrollEntity>> payroll({String? month, int? empId}) async {
    final queryMap = <String, String>{
      if (month != null) 'month': month,
      if (empId != null) 'employee_id': '$empId',
    };
    final raw = await Repo.queryOrLocal('payroll', queryMap, () async {
      final w = <String>[];
      final a = <Object?>[];
      if (month != null) {
        w.add('p.month = ?');
        a.add(month);
      }
      if (empId != null) {
        w.add('p.employee_id = ?');
        a.add(empId);
      }
      return Db.db.rawQuery(
          'SELECT p.*, e.name, e.code, e.department, e.designation, '
          'e.bank_account FROM payroll p JOIN employees e ON e.id = p.employee_id '
          '${w.isEmpty ? '' : 'WHERE ${w.join(' AND ')}'} '
          'ORDER BY p.month DESC, e.name COLLATE NOCASE',
          a);
    });
    return raw.map((r) => PayrollEntity.fromMap(r)).toList();
  }

  Future<List<PayrollEntity>> fetchPayroll({String? month, int? empId}) =>
      payroll(month: month, empId: empId);

  Future<int> runPayroll(int y, int m) async {
    final month = monthKey(y, m);
    final hs = await LeaveRepository().holidaySet();
    final emps = await EmployeesRepository().fetchEmployees(activeOnly: true);
    var count = 0;
    for (final e in emps) {
      final total = e.basic + e.hra + e.allowances;
      if (total <= 0) continue;
      final recs = await Db.db.query('attendance',
          where: 'employee_id = ? AND substr(date, 1, 7) = ?',
          whereArgs: [e.id, month]);
      final c = calc(e.toMap(), y, m, recs, hs);
      final ratio = c.working == 0 ? 0.0 : c.paid / c.working;
      final basic = r2(e.basic * ratio);
      final hra = r2(e.hra * ratio);
      final allow = r2(e.allowances * ratio);
      final gross = r2(basic + hra + allow);
      final pf = r2(basic * e.pfPercent / 100);
      final other = gross == 0 ? 0.0 : e.otherDeduction;
      final net = r2((gross - pf - other).clamp(0.0, double.infinity).toDouble());
      await Repo.saveData('payroll', {}, {
        'employee_id': e.id,
        'month': month,
        'working_days': c.working,
        'paid_days': c.paid,
        'basic': basic,
        'hra': hra,
        'allowances': allow,
        'gross': gross,
        'pf': pf,
        'other_deduction': other,
        'net': net,
        'generated_on': ymd(DateTime.now()),
      });
      count++;
    }
    return count;
  }
}
