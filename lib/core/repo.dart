
import 'package:hrms/core/dio_client.dart';
import 'package:hrms/core/storage_config.dart';
import 'package:hrms/data/datasources/remote_datasource.dart';

import 'common.dart';
import 'db.dart';
import 'session.dart';

// ============================================================
// MONTH CALCULATION
// ============================================================

class MonthCalc {
  double working = 0;
  double paid = 0;
  double present = 0;
  double half = 0;
  double leave = 0;
  double unpaid = 0;
  double absent = 0;
  double holidays = 0;

  Duration hours = Duration.zero;

  double get totalHours => hours.inMinutes / 60.0;

  double get daysAttended => present + half;

  double get daysWorked => present + (half * 0.5);

  double get avgDailyHours =>
      daysAttended > 0 ? totalHours / daysAttended : 0;

  double get attendanceRate =>
      working > 0 ? (daysWorked / working) * 100 : 0;
}

// ============================================================
// STORAGE HELPERS
// ============================================================

bool get _isLocal => StorageConfig.mode != StorageMode.apiOnly;

bool get _isRemote =>
    StorageConfig.mode == StorageMode.apiOnly ||
        StorageConfig.mode == StorageMode.localAndApi;

RemoteDatasource get _remote => RemoteDatasource(DioClient());

void _requireLocalDatabase() {
  if (!_isLocal) {
    throw UnsupportedError(
      'This operation requires SQLite and cannot run in API-only mode.',
    );
  }
}

// ============================================================
// SQL HELPERS
// ============================================================

String dbIn(List<int> ids) {
  return '(${ids.isEmpty ? '-1' : ids.join(',')})';
}

Future<int> dbCount(String sql, [List<Object?>? args]) async {
  _requireLocalDatabase();

  final rows = await Db.db.rawQuery(sql, args);

  if (rows.isEmpty || rows.first.isEmpty) return 0;

  final value = rows.first.values.first;

  return value is num ? value.toInt() : 0;
}

// ============================================================
// LOCAL FETCH
// ============================================================

Future<List<Rec>> _localFetchData(
    String table,
    Map<String, String> query,
    ) async {
  _requireLocalDatabase();

  final where = <String>[];
  final whereArgs = <Object?>[];

  for (final entry in query.entries) {
    where.add('${entry.key} = ?');
    whereArgs.add(entry.value);
  }

  final rows = await Db.db.query(
    table,
    where: where.isEmpty ? null : where.join(' AND '),
    whereArgs: where.isEmpty ? null : whereArgs,
  );

  return rows;
}

// ============================================================
// FETCH DATA
// ============================================================

Future<List<Rec>> fetchData(
    String tableOrEndpoint,
    Map<String, String> query,
    ) async {
  if (StorageConfig.mode == StorageMode.apiOnly) {
    return _remote.fetchData(tableOrEndpoint, query);
  }

  return _localFetchData(tableOrEndpoint, query);
}

// ============================================================
// SAVE DATA
// ADD + UPDATE
// ============================================================

Future<int> _localSaveData(
    String table,
    Map<String, String> query,
    Map<String, Object?> data,
    ) async {
  _requireLocalDatabase();

  if (data.isEmpty) {
    throw ArgumentError('Cannot save empty data.');
  }

  // ADD
  if (query.isEmpty) {
    return Db.db.insert(table, data);
  }

  // UPDATE
  final where = query.keys.map((key) => '$key = ?').join(' AND ');
  final whereArgs = query.values.toList();

  return Db.db.update(
    table,
    data,
    where: where,
    whereArgs: whereArgs,
  );
}

Future<int> saveData(
    String tableOrEndpoint,
    Map<String, String> query,
    Map<String, Object?> data,
    ) async {
  // LOCAL ONLY
  if (StorageConfig.mode == StorageMode.localOnly) {
    return _localSaveData(tableOrEndpoint, query, data);
  }

  // LOCAL + API
  if (StorageConfig.mode == StorageMode.localAndApi) {
    final localId = await _localSaveData(
      tableOrEndpoint,
      query,
      data,
    );

    final remoteId = await _remote.saveData(
      tableOrEndpoint,
      query,
      data,
    );

    return remoteId > 0 ? remoteId : localId;
  }

  // API ONLY
  return _remote.saveData(
    tableOrEndpoint,
    query,
    data,
  );
}

// ============================================================
// DELETE DATA
// ============================================================

Future<int> _localDeleteData(
    String table,
    Map<String, String> query,
    ) async {
  _requireLocalDatabase();

  if (query.isEmpty) {
    throw ArgumentError(
      'Delete requires a condition. Empty query is not allowed.',
    );
  }

  final where = query.keys.map((key) => '$key = ?').join(' AND ');
  final whereArgs = query.values.toList();

  return Db.db.delete(
    table,
    where: where,
    whereArgs: whereArgs,
  );
}

Future<int> deleteData(
    String tableOrEndpoint,
    Map<String, String> query,
    ) async {
  // LOCAL ONLY
  if (StorageConfig.mode == StorageMode.localOnly) {
    return _localDeleteData(tableOrEndpoint, query);
  }

  // LOCAL + API
  if (StorageConfig.mode == StorageMode.localAndApi) {
    final localCount = await _localDeleteData(
      tableOrEndpoint,
      query,
    );

    await _remote.deleteData(tableOrEndpoint, query);

    return localCount;
  }

  // API ONLY
  await _remote.deleteData(tableOrEndpoint, query);

  return 0;
}

// ============================================================
// QUERY WITH LOCAL FALLBACK
// ============================================================

Future<List<Rec>> queryOrLocal(
    String endpoint,
    Map<String, String> query,
    Future<List<Rec>> Function() localQueryFn,
    ) async {
  // LOCAL ONLY
  if (StorageConfig.mode == StorageMode.localOnly) {
    return localQueryFn();
  }

  // API ONLY
  if (StorageConfig.mode == StorageMode.apiOnly) {
    return _remote.fetchData(endpoint, query);
  }

  // LOCAL + API
  try {
    return await _remote.fetchData(endpoint, query);
  } catch (e) {
    return localQueryFn();
  }
}

// ============================================================
// EMPLOYEE ACCESS SCOPE
// null = everyone (HR/admin)
// [] = no employees
// ============================================================

Future<List<int>?> scopeIds() async {
  if (Session.isHr) return null;

  final me = Session.empId;

  if (me == null) return [];

  if (StorageConfig.mode == StorageMode.apiOnly) {
    throw UnsupportedError(
      'Manager employee scope must be provided by the API '
          'when running in API-only mode.',
    );
  }

  if (Session.isManager) {
    final employees = await Db.db.query(
      'employees',
      columns: ['id'],
      where: "manager_id = ? AND status = 'Active'",
      whereArgs: [me],
    );

    return [
      me,
      ...employees.map((r) => (r['id'] as num).toInt()),
    ];
  }

  return [me];
}

// ============================================================
// ATTENDANCE / PAYROLL CALCULATION
// ============================================================

MonthCalc calc(
    Rec employee,
    int year,
    int month,
    List<Rec> records,
    Set<String> holidayDates, {
      DateTime? upTo,
    }) {
  final result = MonthCalc();

  final byDate = {
    for (final record in records) record.s('date'): record,
  };

  final joinDate = employee.s('join_date').isEmpty
      ? null
      : DateTime.tryParse(employee.s('join_date'));

  final lastDay = DateTime(year, month + 1, 0).day;

  for (var day = 1; day <= lastDay; day++) {
    final date = DateTime(year, month, day);

    if (upTo != null &&
        date.isAfter(DateTime(upTo.year, upTo.month, upTo.day))) {
      break;
    }

    final key = ymd(date);
    final record = byDate[key];

    final isWeekday = date.weekday <= DateTime.friday;
    final isHoliday = holidayDates.contains(key);

    final isBeforeJoining = joinDate != null &&
        date.isBefore(
          DateTime(joinDate.year, joinDate.month, joinDate.day),
        );

    if (isBeforeJoining) continue;

    if (record != null) {
      final duration = workedBetween(
        record['check_in'],
        record['check_out'],
      );

      if (duration != null) {
        result.hours += duration;
      }
    }

    if (isWeekday && !isHoliday) {
      result.working++;
    }

    if (record == null) {
      if (!isWeekday) continue;

      if (isHoliday) {
        result.holidays++;
        result.paid++;
      } else {
        result.absent++;
      }

      continue;
    }

    switch (record.s('status')) {
      case 'Present':
        result.present++;
        result.paid++;

        if (!isWeekday && !isHoliday) {
          result.working++;
        }
        break;

      case 'Half Day':
        result.half++;
        result.paid += 0.5;

        if (!isWeekday && !isHoliday) {
          result.working += 0.5;
        }
        break;

      case 'Leave':
        result.leave++;
        result.paid++;
        break;

      case 'Unpaid Leave':
        result.unpaid++;
        break;

      default:
        result.absent++;
    }
  }

  return result;
}

// ============================================================
// REPOSITORY BASE
// ============================================================

abstract class Repo {}
