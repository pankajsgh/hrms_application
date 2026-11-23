import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/data/repositories/repository_impl.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import 'package:hrms/domain/entities/special_day_entity.dart';
import '../../employees/data/employees_repository.dart';

class SpecialDaysRepository {
  Future<List<SpecialDayEntity>> specialDays() async {
    final raw = await Repo.queryOrLocal('special_days', {}, () => Db.db.rawQuery(
        'SELECT s.*, e.name AS emp_name FROM special_days s '
        'JOIN employees e ON e.id = s.employee_id '
        'ORDER BY e.name COLLATE NOCASE, s.date'));
    return raw.map((r) => SpecialDayEntity.fromMap(r)).toList();
  }

  Future<List<SpecialDayEntity>> fetchSpecialDays() => specialDays();

  Future<void> saveSpecialDay(Object data, {int? id}) async {
    final map = data is SpecialDayEntity ? data.toMap() : (data as Map<String, Object?>);
    if (id == null) {
      await Repo.saveData('special_days', {}, {
        ...map,
        'created_by': Session.empId,
        'created_on': ymd(DateTime.now()),
      });
    } else {
      await Repo.saveData('special_days', {'id': '$id'}, map);
    }
  }

  Future<void> deleteSpecialDay(int id) => Repo.deleteData('special_days', {'id': '$id'});

  DateTime _occurrence(DateTime d, int year) {
    final last = DateTime(year, d.month + 1, 0).day;
    return DateTime(year, d.month, d.day > last ? last : d.day);
  }

  Future<List<SpecialDayEntity>> upcomingSpecialDays({int days = 30}) async {
    final rows = await Db.db.rawQuery(
        'SELECT s.*, e.name AS emp_name FROM special_days s '
        'JOIN employees e ON e.id = s.employee_id '
        "WHERE e.status = 'Active'");
    final t = today();
    final tUtc = DateTime.utc(t.year, t.month, t.day);
    final out = <SpecialDayEntity>[];
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
      final map = {
        ...r,
        'next': ymd(next),
        'away': away,
        'years': next.year - orig.year,
      };
      out.add(SpecialDayEntity.fromMap(map));
    }
    out.sort((a, b) => (a.away ?? 0).compareTo(b.away ?? 0));
    return out;
  }

  Future<List<SpecialDayEntity>> fetchUpcomingSpecialDays(int days) => upcomingSpecialDays(days: days);

  Future<List<EmployeeEntity>> activeEmployees() => EmployeesRepository().employees(activeOnly: true);

  Future<List<EmployeeEntity>> fetchActiveEmployees() => activeEmployees();
}
