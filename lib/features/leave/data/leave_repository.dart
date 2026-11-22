import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/repo.dart';
import 'package:hrms/core/session.dart';

class LeaveRepository {
  Future<List<Rec>> leaveTypes() =>
      queryOrLocal('leave_types', {}, () => Db.db.query('leave_types', orderBy: 'id'));

  Future<List<Rec>> fetchLeaveTypes() => leaveTypes();

  Future<void> saveLeaveType(Rec data, {int? id}) async {
    await saveData('leave_types', id != null ? {'id': '$id'} : {}, data);
  }

  Future<String?> deleteLeaveType(int id) async {
    final used =
        await dbCount('SELECT COUNT(*) FROM leaves WHERE type_id = ?', [id]);
    if (used > 0) return 'This leave type is already used by leave requests';
    await deleteData('leave_types', {'id': '$id'});
    return null;
  }

  Future<Set<String>> holidaySet() async =>
      (await Db.db.query('holidays')).map((r) => r.s('date')).toSet();

  Future<List<Rec>> holidays(int year) => queryOrLocal('holidays', {'year': '$year'}, () => Db.db.query('holidays',
      where: 'substr(date, 1, 4) = ?', whereArgs: ['$year'], orderBy: 'date'));

  Future<List<Rec>> fetchHolidays(int year) => holidays(year);

  Future<List<Rec>> upcomingHolidays(int limit) => Db.db.query('holidays',
      where: 'date >= ?',
      whereArgs: [ymd(DateTime.now())],
      orderBy: 'date',
      limit: limit);

  Future<List<Rec>> fetchUpcomingHolidays(int limit) => upcomingHolidays(limit);

  Future<String?> addHoliday(String date, String name) async {
    final exists =
        await dbCount('SELECT COUNT(*) FROM holidays WHERE date = ?', [date]);
    if (exists > 0) return 'A holiday already exists on that date';
    await saveData('holidays', {}, {'date': date, 'name': name});
    return null;
  }

  Future<void> deleteHoliday(int id) async {
    await deleteData('holidays', {'id': '$id'});
  }

  Future<List<Rec>> balances(int emp, int year) => queryOrLocal('balances', {'employee_id': '$emp', 'year': '$year'}, () => Db.db.rawQuery(
      'SELECT t.id, t.name, t.days_per_year, t.paid, '
      "COALESCE((SELECT SUM(days) FROM leaves l WHERE l.type_id = t.id AND l.employee_id = ? AND l.status = 'Approved' AND substr(l.start_date, 1, 4) = ?), 0) AS used, "
      "COALESCE((SELECT SUM(days) FROM leaves l WHERE l.type_id = t.id AND l.employee_id = ? AND l.status = 'Pending' AND substr(l.start_date, 1, 4) = ?), 0) AS pending "
      'FROM leave_types t ORDER BY t.id',
      [emp, '$year', emp, '$year']));

  Future<List<Rec>> fetchBalances(int emp, int year) => balances(emp, year);

  double _workingDays(DateTime s, DateTime e, Set<String> hs) {
    var n = 0.0;
    for (var d = s; !d.isAfter(e); d = DateTime(d.year, d.month, d.day + 1)) {
      if (d.weekday <= DateTime.friday && !hs.contains(ymd(d))) n++;
    }
    return n;
  }

  Future<String?> applyLeave(
      int emp, int typeId, DateTime s, DateTime e, String reason) async {
    if (e.isBefore(s)) return 'End date is before start date';
    final hs = await holidaySet();
    final days = _workingDays(s, e, hs);
    if (days == 0) return 'The selected dates have no working days';
    final overlap = await dbCount(
        "SELECT COUNT(*) FROM leaves WHERE employee_id = ? AND status IN ('Pending','Approved') AND start_date <= ? AND end_date >= ?",
        [emp, ymd(e), ymd(s)]);
    if (overlap > 0) return 'You already have leave in this period';
    final t = await Db.db.query('leave_types', where: 'id = ?', whereArgs: [typeId]);
    if (t.isEmpty) return 'Invalid leave type';
    if (t.first.i('paid') == 1) {
      final b = (await balances(emp, s.year)).firstWhere((x) => x['id'] == typeId);
      final left = b.d('days_per_year') - b.d('used') - b.d('pending');
      if (days > left) {
        return 'Only ${nf(left)} day(s) left for ${t.first.s('name')}';
      }
    }
    await saveData('leaves', {}, {
      'employee_id': emp,
      'type_id': typeId,
      'start_date': ymd(s),
      'end_date': ymd(e),
      'days': days,
      'reason': reason,
      'status': 'Pending',
      'applied_on': ymd(DateTime.now()),
    });
    return null;
  }

  Future<List<Rec>> leaves(
      {bool mine = false,
      bool approvals = false,
      bool pendingOnly = false}) async {
    final queryMap = {
      'mine': mine.toString(),
      'approvals': approvals.toString(),
      'pendingOnly': pendingOnly.toString(),
    };
    return queryOrLocal('leaves', queryMap, () async {
      final w = <String>[];
      final a = <Object?>[];
      if (mine) {
        w.add('l.employee_id = ?');
        a.add(Session.empId);
      }
      if (approvals) {
        final ids = await scopeIds();
        if (ids != null) w.add('l.employee_id IN ${dbIn(ids)}');
        if (!Session.isAdmin && Session.empId != null) {
          w.add('l.employee_id != ?');
          a.add(Session.empId);
        }
      }
      if (pendingOnly) w.add("l.status = 'Pending'");
      return Db.db.rawQuery(
          'SELECT l.*, e.name AS emp_name, t.name AS type_name, t.paid AS paid '
          'FROM leaves l JOIN employees e ON e.id = l.employee_id '
          'JOIN leave_types t ON t.id = l.type_id '
          '${w.isEmpty ? '' : 'WHERE ${w.join(' AND ')}'} '
          'ORDER BY l.id DESC',
          a);
    });
  }

  Future<List<Rec>> fetchLeaves(
          {bool mine = false, bool approvals = false, bool pendingOnly = false}) =>
      leaves(mine: mine, approvals: approvals, pendingOnly: pendingOnly);

  Future<void> cancelLeave(int id) async {
    await Db.db.delete('leaves',
        where: "id = ? AND status = 'Pending'", whereArgs: [id]);
  }

  Future<void> decideLeave(Rec leave, bool approve) async {
    await Db.db.update(
        'leaves',
        {
          'status': approve ? 'Approved' : 'Rejected',
          'decided_by': Session.empId,
          'decided_on': ymd(DateTime.now()),
        },
        where: 'id = ?',
        whereArgs: [leave['id']]);
    if (!approve) return;
    final hs = await holidaySet();
    final status = leave.i('paid') == 1 ? 'Leave' : 'Unpaid Leave';
    final s = DateTime.parse(leave.s('start_date'));
    final e = DateTime.parse(leave.s('end_date'));
    for (var d = s; !d.isAfter(e); d = DateTime(d.year, d.month, d.day + 1)) {
      if (d.weekday > DateTime.friday || hs.contains(ymd(d))) continue;
      await Db.db.rawInsert(
          'INSERT INTO attendance(employee_id, date, status, note) '
          'VALUES(?, ?, ?, ?) ON CONFLICT(employee_id, date) DO UPDATE SET '
          'status = excluded.status, check_in = NULL, check_out = NULL, '
          'note = excluded.note',
          [leave['employee_id'], ymd(d), status, leave.s('type_name')]);
    }
  }
}
