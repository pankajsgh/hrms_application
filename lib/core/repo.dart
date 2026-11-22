import 'package:hrms/core/dio_client.dart';
import 'package:hrms/core/repo.dart' as LocalDatasource;
import 'package:hrms/core/storage_config.dart';
import 'package:hrms/data/datasources/remote_datasource.dart';

import 'common.dart';
import 'db.dart';
import 'session.dart';


class MonthCalc {
  double working = 0,
      paid = 0,
      present = 0,
      half = 0,
      leave = 0,
      unpaid = 0,
      absent = 0,
      holidays = 0;
  Duration hours = Duration.zero;

  double get totalHours => hours.inMinutes / 60.0;
  double get daysAttended => present + half;
  double get daysWorked => present + (half * 0.5);
  double get avgDailyHours => daysAttended > 0 ? totalHours / daysAttended : 0.0;
  double get attendanceRate => working > 0 ? (daysWorked / working) * 100.0 : 0.0;
}

// ------------------------------------------------------------ Shared Data Helpers

String dbIn(List<int> ids) => '(${ids.isEmpty ? '-1' : ids.join(',')})';

Future<int> dbCount(String sql, [List<Object?>? args]) async {
  final rows = await Db.db.rawQuery(sql, args);
  if (rows.isEmpty) return 0;
  return (rows.first.values.first as num?)?.toInt() ?? 0;
}

Future<List<Rec>> fetchData(String tableOrEndpoint, Map<String, String> query) async {
  if (StorageConfig.mode == StorageMode.apiOnly) {
    return await RemoteDatasource(DioClient()).fetchData(tableOrEndpoint, query);
  }
  return await LocalDatasource.fetchData(tableOrEndpoint, query);
}

Future<int> saveData(String tableOrEndpoint, Map<String, String> query, Map<String, Object?> data) async {
  int id = 0;

  if (StorageConfig.mode != StorageMode.apiOnly) {

    try {
      id = await LocalDatasource.saveData(tableOrEndpoint, query, data);
    } catch (e) {
      print("this is good: Errro |||||||||||||||||||");
    }

  }
  if (StorageConfig.mode == StorageMode.apiOnly || StorageConfig.mode == StorageMode.localAndApi) {
    try {
      final remoteId = await RemoteDatasource(DioClient()).saveData(tableOrEndpoint, query, data);
      if (remoteId > 0) id = remoteId;
    } catch (e) {
      print("this is good: Errro |||||||||||||||||||");
    }
  }
  return id;
}

Future<int> deleteData(String tableOrEndpoint, Map<String, String> query) async {
  int count = 0;
  if (StorageConfig.mode != StorageMode.apiOnly) {
    count = await LocalDatasource.deleteData(tableOrEndpoint, query);
  }
  if (StorageConfig.mode == StorageMode.apiOnly || StorageConfig.mode == StorageMode.localAndApi) {
    try {
      await RemoteDatasource(DioClient()).deleteData(tableOrEndpoint, query);
    } catch (_) {}
  }
  return count;
}

Future<List<Rec>> queryOrLocal(
    String endpoint,
    Map<String, String> query,
    Future<List<Rec>> Function() localQueryFn) async {
  if (StorageConfig.mode == StorageMode.apiOnly) {
    try {
      return await fetchData(endpoint, query);
    } catch (_) {
      return [];
    }
  } else if (StorageConfig.mode == StorageMode.localAndApi) {
    try {
      final remote = await fetchData(endpoint, query);
      if (remote.isNotEmpty) return remote;
    } catch (_) {}
  }
  return await localQueryFn();
}

/// null = everyone (HR/admin). Otherwise the employee ids the user may see.
Future<List<int>?> scopeIds() async {
  if (Session.isHr) return null;
  final me = Session.empId;
  if (me == null) return [];
  if (Session.isManager) {
    final t = await Db.db.query('employees',
        columns: ['id'],
        where: "manager_id = ? AND status = 'Active'",
        whereArgs: [me]);
    return [me, ...t.map((r) => (r['id'] as num).toInt())];
  }
  return [me];
}

MonthCalc calc(
    Rec e, int y, int m, List<Rec> recs, Set<String> hs,
    {DateTime? upTo}) {
  final c = MonthCalc();
  final byDate = {for (final r in recs) r.s('date'): r};
  final join = e.s('join_date').isEmpty
      ? null
      : DateTime.tryParse(e.s('join_date'));
  final last = DateTime(y, m + 1, 0).day;
  for (var day = 1; day <= last; day++) {
    final d = DateTime(y, m, day);
    if (upTo != null && d.isAfter(upTo)) break;
    final key = ymd(d);
    final r = byDate[key];
    if (r != null) {
      final w = workedBetween(r['check_in'], r['check_out']);
      if (w != null) c.hours += w;
    }

    final isWeekday = d.weekday <= DateTime.friday;
    final isBeforeJoin = join != null && d.isBefore(join);
    if (isBeforeJoin) continue;

    if (isWeekday) {
      c.working++;
    }

    if (r == null) {
      if (!isWeekday) continue;
      if (hs.contains(key)) {
        c.holidays++;
        c.paid++;
      } else {
        c.absent++;
      }
      continue;
    }

    switch (r.s('status')) {
      case 'Present':
        c.present++;
        c.paid++;
        if (!isWeekday) c.working++;
        break;
      case 'Half Day':
        c.half++;
        c.paid += 0.5;
        if (!isWeekday) c.working += 0.5;
        break;
      case 'Leave':
        c.leave++;
        c.paid++;
        break;
      case 'Unpaid Leave':
        c.unpaid++;
        break;
      default:
        c.absent++;
    }
  }
  return c;
}

/// All database access live in individual feature repositories.
/// Feature controllers and pages call feature repositories directly.
abstract class Repo {}
