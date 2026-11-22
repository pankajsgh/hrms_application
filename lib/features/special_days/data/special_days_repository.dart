import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/data/repositories/repository_impl.dart';
import '../../employees/data/employees_repository.dart';

class SpecialDaysRepository {
  Future<List<Rec>> specialDays() => Repo.queryOrLocal('special_days', {}, () => Db.db.rawQuery(
      'SELECT s.*, e.name AS emp_name FROM special_days s '
      'JOIN employees e ON e.id = s.employee_id '
      'ORDER BY e.name COLLATE NOCASE, s.date'));

  Future<List<Rec>> fetchSpecialDays() => specialDays();

  Future<void> saveSpecialDay(Rec data, {int? id}) async {
    if (id == null) {
      await Repo.saveData('special_days', {}, {
        ...data,
        'created_by': Session.empId,
        'created_on': ymd(DateTime.now()),
      });
    } else {
      await Repo.saveData('special_days', {'id': '$id'}, data);
    }
  }

  Future<void> deleteSpecialDay(int id) => Repo.deleteData('special_days', {'id': '$id'});

  DateTime _occurrence(DateTime d, int year) {
    final last = DateTime(year, d.month + 1, 0).day;
    return DateTime(year, d.month, d.day > last ? last : d.day);
  }

  Future<List<Rec>> upcomingSpecialDays({int days = 30}) async {
    final rows = await Db.db.rawQuery(
        'SELECT s.*, e.name AS emp_name FROM special_days s '
        'JOIN employees e ON e.id = s.employee_id '
        "WHERE e.status = 'Active'");
    final t = today();
    final tUtc = DateTime.utc(t.year, t.month, t.day);
    final out = <Rec>[];
    for (final r in rows) {
      final orig = DateTime.tryParse(r.s('date'));
      if (orig == null) continue;
      DateTime next;
      if (r.i('yearly') == 1) {
        next = _occurrence(orig, t.year);
        if (next.isBefore(t)) next = _occurrence(orig, t.year + 1);
      } else {
        next = DateTime(orig.year, orig.month, orig.day);
        if (next.isBefore(t)) continue;
      }
      final away =
          DateTime.utc(next.year, next.month, next.day).difference(tUtc).inDays;
      if (away > days) continue;
      out.add({
        ...r,
        'next': ymd(next),
        'away': away,
        'years': next.year - orig.year,
      });
    }
    out.sort((a, b) => (a['away'] as int).compareTo(b['away'] as int));
    return out;
  }

  Future<List<Rec>> fetchUpcomingSpecialDays(int days) => upcomingSpecialDays(days: days);

  Future<List<Rec>> activeEmployees() => EmployeesRepository().employees(activeOnly: true);

  Future<List<Rec>> fetchActiveEmployees() => activeEmployees();
}
