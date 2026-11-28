import 'package:flutter/widgets.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/db.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/storage_config.dart';
import 'package:hrms/data/datasources/local_datasource.dart';
import 'package:hrms/data/repositories/repository_impl.dart';
import 'package:hrms/domain/entities/leave_entity.dart';

class LeaveRepository {
  bool get _isLocal => StorageConfig.mode != StorageMode.apiOnly;

  // ============================================================
  // HELPERS
  // ============================================================

  int _number(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _decimal(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _date(DateTime value) {
    return ymd(DateTime(value.year, value.month, value.day));
  }

  Future<int> _count(String sql, List<Object?> args) async {
    if (!_isLocal) return 0;
    return LocalDatasource.dbCount(sql, args);
  }

  // ============================================================
  // LEAVE TYPES
  // ============================================================

  Future<List<LeaveTypeEntity>> leaveTypes() async {
    final raw = await Repo.queryOrLocal(
      'leave_types',
      {},
      () => Db.db.query(
        'leave_types',
        orderBy: 'id ASC',
      ),
    );
    final types = raw.map((r) => LeaveTypeEntity.fromMap(r)).toList();

    // Auto-ensure WFH and Field Work leave types exist
    if (!types.any((t) =>
        t.name.toLowerCase().contains('home') ||
        t.name.toLowerCase().contains('wfh'))) {
      await saveLeaveType({
        'name': 'Work From Home',
        'days_per_year': 365,
        'paid': 1,
      });
      return leaveTypes();
    }
    if (!types.any((t) =>
        t.name.toLowerCase().contains('field') ||
        t.name.toLowerCase().contains('outside'))) {
      await saveLeaveType({
        'name': 'Work Outside (Field)',
        'days_per_year': 365,
        'paid': 1,
      });
      return leaveTypes();
    }

    return types;
  }

  Future<List<LeaveTypeEntity>> fetchLeaveTypes() => leaveTypes();

  Future<void> saveLeaveType(
    Map<String, Object?> data, {
    int? id,
  }) async {
    final name = (data['name'] ?? '').toString().trim();
    final days = _decimal(data['days_per_year']);

    if (name.isEmpty) {
      throw Exception('Please enter leave type name');
    }

    if (days < 0) {
      throw Exception('Days per year cannot be negative');
    }

    final paid = _number(data['paid']);

    await Repo.saveData(
      'leave_types',
      id != null ? {'id': '$id'} : {},
      {
        'name': name,
        'days_per_year': days,
        'paid': paid == 1 ? 1 : 0,
      },
    );
  }

  Future<String?> deleteLeaveType(int id) async {
    if (id <= 0) return 'Invalid leave type';

    if (_isLocal) {
      final used = await _count(
        'SELECT COUNT(*) FROM leaves WHERE type_id = ?',
        [id],
      );

      if (used > 0) {
        return 'This leave type is already used by leave requests';
      }
    }

    await Repo.deleteData(
      'leave_types',
      {'id': '$id'},
    );

    return null;
  }

  // ============================================================
  // HOLIDAYS
  // ============================================================

  Future<List<Rec>> holidays(int year) {
    return Repo.queryOrLocal(
      'holidays',
      {'year': '$year'},
      () => Db.db.query(
        'holidays',
        where: 'substr(date, 1, 4) = ?',
        whereArgs: ['$year'],
        orderBy: 'date ASC',
      ),
    );
  }

  Future<List<Rec>> fetchHolidays(int year) => holidays(year);

  Future<Set<String>> holidaySet() async {
    final rows = await Repo.queryOrLocal(
      'holidays',
      {},
      () => Db.db.query('holidays'),
    );

    return rows
        .map((row) => row.s('date'))
        .where((date) => date.isNotEmpty)
        .toSet();
  }

  Future<List<Rec>> upcomingHolidays(int limit) {
    return Repo.queryOrLocal(
      'upcoming_holidays',
      {
        'from': _date(DateTime.now()),
        'limit': '$limit',
      },
      () => Db.db.query(
        'holidays',
        where: 'date >= ?',
        whereArgs: [_date(DateTime.now())],
        orderBy: 'date ASC',
        limit: limit,
      ),
    );
  }

  Future<List<Rec>> fetchUpcomingHolidays(int limit) =>
      upcomingHolidays(limit);

  Future<String?> addHoliday(String date, String name) async {
    final cleanDate = date.trim();
    final cleanName = name.trim();

    if (cleanDate.isEmpty || cleanName.isEmpty) {
      return 'Please enter holiday date and name';
    }

    final parsed = DateTime.tryParse(cleanDate);
    if (parsed == null) {
      return 'Invalid holiday date';
    }

    if (_isLocal) {
      final exists = await _count(
        'SELECT COUNT(*) FROM holidays WHERE date = ?',
        [cleanDate],
      );

      if (exists > 0) {
        return 'A holiday already exists on that date';
      }
    } else {
      final existing = await holidays(parsed.year);
      if (existing.any((row) => row.s('date') == cleanDate)) {
        return 'A holiday already exists on that date';
      }
    }

    await Repo.saveData(
      'holidays',
      {},
      {
        'date': cleanDate,
        'name': cleanName,
      },
    );

    return null;
  }

  Future<void> deleteHoliday(int id) async {
    if (id <= 0) throw Exception('Invalid holiday');

    await Repo.deleteData(
      'holidays',
      {'id': '$id'},
    );
  }

  // ============================================================
  // LEAVE BALANCES
  // ============================================================

  Future<List<LeaveBalanceEntity>> balances(int emp, int year) async {
    final raw = await Db.db.rawQuery(
      '''
  SELECT
    t.id,
    t.name,
    t.days_per_year,
    t.paid,

    COALESCE((
      SELECT SUM(l.days)
      FROM leaves l
      WHERE l.type_id = t.id
        AND l.employee_id = ?
        AND l.status = 'Approved'
        AND substr(l.start_date, 1, 4) = ?
    ), 0) AS used,

    COALESCE((
      SELECT SUM(l.days)
      FROM leaves l
      WHERE l.type_id = t.id
        AND l.employee_id = ?
        AND l.status = 'Pending'
        AND substr(l.start_date, 1, 4) = ?
    ), 0) AS pending,

    COALESCE((
      SELECT json_group_array(
        json_object(
          'id', l.id,
          'startDate', l.start_date,
          'endDate', l.end_date,
          'days', l.days,
          'status', l.status,
          'reason', l.reason
        )
      )
      FROM leaves l
      WHERE l.type_id = t.id
        AND l.employee_id = ?
        AND substr(l.start_date, 1, 4) = ?
    ), '[]') AS applications

  FROM leave_types t
  ORDER BY t.id ASC
  ''',
      [emp, '$year', emp, '$year', emp, '$year'],
    );
    return raw.map((r) => LeaveBalanceEntity.fromMap(r)).toList();
  }

  Future<List<LeaveBalanceEntity>> fetchBalances(int emp, int year) =>
      balances(emp, year);

  // ============================================================
  // WORKING DAYS
  // ============================================================

  double _workingDays(
    DateTime start,
    DateTime end,
    Set<String> holidays,
  ) {
    var total = 0.0;

    for (var date = DateTime(start.year, start.month, start.day);
        !date.isAfter(DateTime(end.year, end.month, end.day));
        date = date.add(const Duration(days: 1))) {
      final weekday = date.weekday <= DateTime.friday;
      final holiday = holidays.contains(_date(date));

      if (weekday && !holiday) total++;
    }

    return total;
  }

  // ============================================================
  // APPLY LEAVE
  // ============================================================

  Future<String?> applyLeave(
    int emp,
    int typeId,
    DateTime start,
    DateTime end,
    String reason, {
    bool isHalfDay = false,
    String? halfDayType,
  }) async {
    try {
      if (emp <= 0) return 'Invalid employee';
      if (typeId <= 0) return 'Invalid leave type';

      final s = DateTime(start.year, start.month, start.day);
      final e = DateTime(end.year, end.month, end.day);

      if (e.isBefore(s)) {
        return 'End date is before start date';
      }

      if (isHalfDay && !s.isAtSameMomentAs(e)) {
        return 'Half day can only be applied for a single date';
      }

      if (reason.trim().isEmpty) {
        return 'Please enter leave reason';
      }

      final types = await fetchLeaveTypes();
      final typeIndex = types.indexWhere(
        (row) => row.id == typeId,
      );

      if (typeIndex < 0) return 'Invalid leave type';

      final leaveType = types[typeIndex];
      final paid = leaveType.paid == 1;

      final holidayDates = await holidaySet();
      final calculatedDays = _workingDays(s, e, holidayDates);

      if (calculatedDays <= 0) {
        return 'The selected dates have no working days';
      }

      final days = isHalfDay ? 0.5 : calculatedDays;
      final finalReason = isHalfDay && halfDayType != null
          ? '[$halfDayType] ${reason.trim()}'
          : reason.trim();

      final existingLeaves = await fetchLeaves(mine: true);

      for (final leave in existingLeaves) {
        final status = leave.status;

        if (status != 'Pending' && status != 'Approved') {
          continue;
        }

        final oldStart = DateTime.tryParse(leave.startDate);
        final oldEnd = DateTime.tryParse(leave.endDate);

        if (oldStart == null || oldEnd == null) continue;

        final overlaps = !s.isAfter(oldEnd) && !e.isBefore(oldStart);

        if (overlaps) {
          return 'You already have leave in this period';
        }
      }

      if (paid) {
        final balanceList = await fetchBalances(emp, s.year);

        final balanceIndex = balanceList.indexWhere(
          (row) => row.id == typeId,
        );

        if (balanceIndex < 0) {
          return 'Leave balance not found';
        }

        final balance = balanceList[balanceIndex];

        final total = balance.daysPerYear;
        final used = balance.used;
        final pending = balance.pending;

        final remaining = total - used - pending;

        if (days > remaining) {
          return 'Only ${nf(remaining < 0 ? 0 : remaining)} '
              'day(s) left for ${leaveType.name}';
        }
      }

      await Repo.saveData(
        'leaves',
        {},
        {
          'employee_id': emp,
          'type_id': typeId,
          'start_date': _date(s),
          'end_date': _date(e),
          'days': days,
          'reason': finalReason,
          'status': 'Pending',
          'applied_on': _date(DateTime.now()),
        },
      );

      return null;
    } catch (e) {
      return 'Unable to apply leave: $e';
    }
  }

  // ============================================================
  // LEAVE REQUESTS
  // ============================================================

  Future<List<LeaveEntity>> leaves({
    bool mine = false,
    bool approvals = false,
    bool pendingOnly = false,
  }) async {
    final queryMap = {
      'mine': mine.toString(),
      'approvals': approvals.toString(),
      'pendingOnly': pendingOnly.toString(),
    };

    final raw = await Repo.queryOrLocal(
      'leaves',
      queryMap,
      () async {
        final where = <String>[];
        final args = <Object?>[];

        if (mine) {
          final empId = Session.empId;
          if (empId == null) return [];

          where.add('l.employee_id = ?');
          args.add(empId);
        }

        if (approvals) {
          if (Session.isHr || Session.isAdmin) {
            // HR/admin can see all requests.
          } else if (Session.isLead || Session.isManager) {
            final empId = Session.empId;
            if (empId == null) return [];

            final employees = await Db.db.query(
              'employees',
              columns: ['id'],
              where: 'manager_id = ? AND status = ?',
              whereArgs: [empId, 'Active'],
            );

            final ids = <int>[
              empId,
              ...employees.map((row) => _number(row['id'])),
            ];

            where.add(
              'l.employee_id IN ${LocalDatasource.dbIn(ids)}',
            );
            where.add('l.employee_id != ?');
            args.add(empId);
          } else {
            return [];
          }
        }

        if (pendingOnly) {
          where.add("l.status = 'Pending'");
        }

        final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

        return Db.db.rawQuery(
          '''
        SELECT
          l.*,
          e.name AS emp_name,
          e.code AS emp_code,
          e.department AS department,
          t.name AS type_name,
          t.paid AS paid
        FROM leaves l
        INNER JOIN employees e
          ON e.id = l.employee_id
        INNER JOIN leave_types t
          ON t.id = l.type_id
        $whereSql
        ORDER BY l.id DESC
        ''',
          args,
        );
      },
    );

    return raw.map((r) => LeaveEntity.fromMap(r)).toList();
  }

  Future<List<LeaveEntity>> fetchLeaves({
    bool mine = false,
    bool approvals = false,
    bool pendingOnly = false,
  }) {
    return leaves(
      mine: mine,
      approvals: approvals,
      pendingOnly: pendingOnly,
    );
  }

  // ============================================================
  // CANCEL LEAVE
  // ============================================================

  Future<void> cancelLeave(int id) async {
    if (id <= 0) {
      throw Exception('Invalid leave request');
    }

    final rows = await fetchLeaves(mine: true);

    final index = rows.indexWhere(
      (row) => row.id == id,
    );

    if (index < 0) {
      throw Exception('Leave request not found');
    }

    if (rows[index].status != 'Pending') {
      throw Exception('Only pending leave requests can be cancelled');
    }

    await Repo.deleteData(
      'leaves',
      {'id': '$id'},
    );
  }

  // ============================================================
  // APPROVE / REJECT LEAVE
  // ============================================================

  Future<void> decideLeave(
    LeaveEntity leave,
    bool approve,
  ) async {
    final id = leave.id;

    if (id == null || id <= 0) {
      throw Exception('Invalid leave request');
    }

    final currentRows = await fetchLeaves(
      approvals: true,
      pendingOnly: true,
    );

    final index = currentRows.indexWhere(
      (row) => row.id == id,
    );

    if (index < 0) {
      throw Exception(
        'Leave request not found or already processed',
      );
    }

    final current = currentRows[index];

    final start = DateTime.tryParse(current.startDate);
    final end = DateTime.tryParse(current.endDate);

    if (start == null || end == null) {
      throw Exception('Invalid leave dates');
    }

    final decision = approve ? 'Approved' : 'Rejected';

    await Repo.saveData(
      'leaves',
      {'id': '$id'},
      {
        'status': decision,
        'decided_by': Session.empId,
        'decided_on': _date(DateTime.now()),
      },
    );

    if (!approve) return;

    final holidays = await holidaySet();

    final employeeId = current.employeeId;
    if (employeeId <= 0) {
      throw Exception('Invalid employee on leave request');
    }

    String attendanceStatus;
    final typeLower = (current.typeName ?? '').toLowerCase();
    if (typeLower.contains('home') || typeLower.contains('wfh')) {
      attendanceStatus = 'WFH';
    } else if (typeLower.contains('field') ||
        typeLower.contains('outside') ||
        typeLower.contains('duty')) {
      attendanceStatus = 'On Duty';
    } else {
      attendanceStatus = current.paid == 1 ? 'Leave' : 'Unpaid Leave';
    }

    for (var date = DateTime(start.year, start.month, start.day);
        !date.isAfter(DateTime(end.year, end.month, end.day));
        date = date.add(const Duration(days: 1))) {
      if (date.weekday > DateTime.friday) continue;
      if (holidays.contains(_date(date))) continue;

      if (_isLocal) {
        final existing = await Db.db.query(
          'attendance',
          where: 'employee_id = ? AND date = ?',
          whereArgs: [employeeId, _date(date)],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          final row = existing.first;
          final checkIn = row['check_in'];
          final checkOut = row['check_out'];

          if (checkIn != null || checkOut != null) {
            continue;
          }
        }
      }

      await Repo.saveData(
        'attendance',
        {
          'employee_id': '$employeeId',
          'date': _date(date),
        },
        {
          'employee_id': employeeId,
          'date': _date(date),
          'status': attendanceStatus,
          'check_in': null,
          'check_out': null,
          'note': current.typeName,
        },
      );
    }
  }
}
