
import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/data/repositories/repository_impl.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import 'package:hrms/domain/entities/special_day_entity.dart';

import '../../employees/data/employees_repository.dart';

class SpecialDaysRepository {
  Future<List<SpecialDayEntity>> fetchSpecialDays() async {
    final rows = await Repo.queryOrLocal(
      'special_days',
      {},
          () => Db.db.rawQuery(
        'SELECT s.*, e.name AS emp_name '
            'FROM special_days s '
            'JOIN employees e ON e.id = s.employee_id '
            'ORDER BY e.name COLLATE NOCASE, s.date',
      ),
    );

    return rows.map((row) {
      return SpecialDayEntity.fromMap(
        Map<String, Object?>.from(row),
      );
    }).toList();
  }

  Future<void> saveSpecialDay(
      Object data, {
        int? id,
      }) async {
    final Map<String, Object?> map;

    if (data is SpecialDayEntity) {
      map = data.toMap();
    } else if (data is Map<String, Object?>) {
      map = Map<String, Object?>.from(data);
    } else {
      throw ArgumentError(
        'Unsupported special day data: ${data.runtimeType}',
      );
    }

    map.remove('emp_name');
    map.remove('next');
    map.remove('away');
    map.remove('years');

    if (id == null) {
      map.remove('id');
      map['created_by'] = Session.empId;
      map['created_on'] = ymd(DateTime.now());

      await Repo.saveData('special_days', {}, map);
    } else {
      map.remove('id');

      await Repo.saveData(
        'special_days',
        {'id': '$id'},
        map,
      );
    }
  }

  Future<void> deleteSpecialDay(int id) async {
    await Repo.deleteData(
      'special_days',
      {'id': '$id'},
    );
  }

  Future<List<EmployeeEntity>> fetchActiveEmployees() {
    return EmployeesRepository().fetchEmployees(activeOnly: true);
  }

  Future<List<SpecialDayEntity>> upcomingSpecialDays({
    int days = 30,
  }) async {
    final rows = await Db.db.rawQuery(
      'SELECT s.*, e.name AS emp_name '
          'FROM special_days s '
          'JOIN employees e ON e.id = s.employee_id',
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final result = <SpecialDayEntity>[];

    for (final row in rows) {
      final original = DateTime.tryParse(
        row['date']?.toString() ?? '',
      );

      if (original == null) continue;

      final yearly = (row['yearly'] as num?)?.toInt() ?? 1;

      DateTime next;

      if (yearly == 1) {
        next = _dateForYear(original, today.year);

        if (next.isBefore(today)) {
          next = _dateForYear(original, today.year + 1);
        }
      } else {
        next = DateTime(
          original.year,
          original.month,
          original.day,
        );

        if (next.isBefore(today)) continue;
      }

      final away = next.difference(today).inDays;

      if (away > days) continue;

      result.add(
        SpecialDayEntity.fromMap({
          ...Map<String, Object?>.from(row),
          'next': ymd(next),
          'away': away,
          'years': next.year - original.year,
        }),
      );
    }

    result.sort(
          (a, b) => (a.away ?? 0).compareTo(b.away ?? 0),
    );

    return result;
  }

  DateTime _dateForYear(DateTime date, int year) {
    final lastDay = DateTime(year, date.month + 1, 0).day;

    return DateTime(
      year,
      date.month,
      date.day > lastDay ? lastDay : date.day,
    );
  }
}
