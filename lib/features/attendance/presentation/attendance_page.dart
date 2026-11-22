
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/features/attendance/data/attendance_repository.dart';
import 'package:hrms/features/leave/data/leave_repository.dart';

import 'all_employees_attendance_view.dart';

class AttendanceFeaturePage extends StatefulWidget {
  const AttendanceFeaturePage({super.key});

  @override
  State<AttendanceFeaturePage> createState() =>
      _AttendanceFeaturePageState();
}

class _AttendanceFeaturePageState extends State<AttendanceFeaturePage> {
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final LeaveRepository _leaveRepo = LeaveRepository();

  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  List<Rec> _records = [];
  List<Rec> _balances = [];
  Set<String> _holidays = {};

  Rec? _todayRecord;
  DateTime _selectedDate = today();

  bool _loading = true;
  bool _saving = false;

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _load({bool showLoading = true}) async {
    final empId = Session.empId;
    if (empId == null) return;

    if (showLoading && mounted) {
      setState(() => _loading = true);
    }

    try {
      final results = await Future.wait<dynamic>([
        _attendanceRepo.monthRecords(empId, _year, _month),
        AttendanceRepository.holidaySet(),
        _leaveRepo.balances(empId, _year),
        _attendanceRepo.attendanceOf(empId, ymd(today())),
      ]);

      if (!mounted) return;

      setState(() {
        _records = results[0] as List<Rec>;
        _holidays = results[1] as Set<String>;
        _balances = results[2] as List<Rec>;
        _todayRecord = results[3] as Rec?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Unable to load attendance: $e');
    }
  }

  Future<void> _refresh() => _load(showLoading: false);

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // CHECK IN / CHECK OUT
  // ============================================================

  Future<void> _markAttendance(bool checkIn) async {
    final empId = Session.empId;
    if (empId == null || _saving) return;

    setState(() => _saving = true);

    try {
      if (checkIn) {
        await _attendanceRepo.checkIn(empId);
      } else {
        await _attendanceRepo.checkOut(empId);
      }

      await _load(showLoading: false);

      if (!mounted) return;

      _showMessage(
        checkIn
            ? 'Check-in successful.'
            : 'Check-out successful.',
      );
    } catch (e) {
      _showMessage('Attendance update failed: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Map<String, Rec> get _recordsByDate => {
    for (final record in _records) record.s('date'): record,
  };

  Rec? _recordFor(DateTime date) => _recordsByDate[ymd(date)];

  String _statusFor(DateTime date) {
    final record = _recordFor(date);
    final key = ymd(date);

    if (record != null) return record.s('status');
    if (_holidays.contains(key)) return 'Holiday';

    if (date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday) {
      return 'Weekend';
    }

    if (DateUtils.dateOnly(date).isAfter(
      DateUtils.dateOnly(today()),
    )) {
      return 'Upcoming';
    }

    return 'Absent';
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'half day':
      case 'half-day':
        return Colors.deepOrange;
      case 'absent':
        return Colors.red;
      case 'leave':
      case 'unpaid leave':
        return Colors.purple;
      case 'holiday':
        return Colors.blue;
      case 'weekend':
        return Colors.blueGrey;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  String get _todayStatus {
    final status = _todayRecord?.s('status') ?? '';
    return status.isEmpty ? 'Not marked' : status;
  }

  String get _checkIn => _todayRecord?.s('check_in') ?? '';

  String get _checkOut => _todayRecord?.s('check_out') ?? '';

  bool get _hasCheckedIn => _checkIn.isNotEmpty;

  bool get _hasCheckedOut => _checkOut.isNotEmpty;

  String get _workedTime {
    final duration = workedBetween(
      _todayRecord?['check_in'],
      _todayRecord?['check_out'],
    );

    return duration == null ? '--' : fmtDuration(duration);
  }

  String _workedTimeFor(Rec? record) {
    if (record == null) return '--';

    final duration = workedBetween(
      record['check_in'],
      record['check_out'],
    );

    return duration == null ? '--' : fmtDuration(duration);
  }

  // ============================================================
  // MONTH NAVIGATION
  // ============================================================

  bool get _isCurrentMonth {
    final now = today();
    return _year == now.year && _month == now.month;
  }

  void _changeMonth(int offset) {
    final date = DateTime(_year, _month + offset, 1);

    setState(() {
      _year = date.year;
      _month = date.month;
      _selectedDate = date;
    });

    _load();
  }

  void _goToToday() {
    final now = today();

    setState(() {
      _year = now.year;
      _month = now.month;
      _selectedDate = now;
    });

    _load();
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  // ============================================================
  // COMMON WIDGETS
  // ============================================================

  Widget _card(Widget child) {
    return Panel(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }

  Widget _heading(
      String title,
      IconData icon, {
        Widget? trailing,
      }) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          height: 27,
          width: 27,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: cs.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _header() {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.access_time_rounded,
              color: cs.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  DateFormat('EEEE, d MMM yyyy').format(today()),
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh attendance',
            visualDensity: VisualDensity.compact,
            onPressed: _loading ? null : _refresh,
            icon: AnimatedRotation(
              turns: _loading ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TODAY ATTENDANCE
  // ============================================================

  Widget _todayCard() {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColor(_todayStatus);

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _heading(
                  "Today's Attendance",
                  Icons.today_rounded,
                ),
              ),
              _badge(_todayStatus, statusColor),
            ],
          ),
          const SizedBox(height: 13),

          Row(
            children: [
              _metric(
                'Check In',
                _hasCheckedIn
                    ? fmtTime(_todayRecord?['check_in'])
                    : '--:--',
                Icons.login_rounded,
                Colors.green,
              ),
              const SizedBox(width: 7),
              _metric(
                'Check Out',
                _hasCheckedOut
                    ? fmtTime(_todayRecord?['check_out'])
                    : '--:--',
                Icons.logout_rounded,
                Colors.orange,
              ),
              const SizedBox(width: 7),
              _metric(
                'Worked',
                _workedTime,
                Icons.timelapse_rounded,
                cs.primary,
              ),
            ],
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: FilledButton.icon(
                    onPressed: !_hasCheckedIn && !_saving
                        ? () => _markAttendance(true)
                        : null,
                    icon: _saving && !_hasCheckedIn
                        ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.login_rounded, size: 15),
                    label: Text(
                      _hasCheckedIn ? 'Checked In' : 'Check In',
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: _hasCheckedIn &&
                        !_hasCheckedOut &&
                        !_saving
                        ? () => _markAttendance(false)
                        : null,
                    icon: const Icon(Icons.logout_rounded, size: 15),
                    label: Text(
                      _hasCheckedOut ? 'Completed' : 'Check Out',
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_saving) ...[
            const SizedBox(height: 9),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }

  Widget _metric(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
             children: [
               Icon(icon, color: color, size: 15),
               const SizedBox(width: 12),
               Text(
                 label,
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
                 style: const TextStyle(
                   fontSize: 9,
                   color: Colors.grey,
                   fontWeight: FontWeight.w500,
                 ),
               ),
             ],
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LEAVE BALANCE
  // ============================================================

  Widget _leaveBalances() {
    final cs = Theme.of(context).colorScheme;

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            'Leave Balance',
            Icons.event_available_rounded,
            trailing: Text(
              '$_year',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 11),

          if (_balances.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No leave balance available.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 340 ? 2 : 1;
                final itemWidth =
                    (constraints.maxWidth - (columns - 1) * 7) /
                        columns;

                return Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: _balances.map((balance) {
                    final remaining = balance.d('remaining');
                    final used = balance.d('used');
                    final total = balance.d('days_per_year');

                    final progress = total > 0
                        ? (used / total).clamp(0.0, 1.0)
                        : 0.0;

                    return SizedBox(
                      width: itemWidth,
                      child: Material(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            _showMessage(
                              '${balance.s('name')}: '
                                  '${nf(remaining)} days remaining.',
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        balance.s('name'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 15,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${nf(remaining)} days',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: cs.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${nf(used)} used of ${nf(total)}',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 4,
                                    backgroundColor: cs.outlineVariant
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SELECTED DATE DETAILS
  // ============================================================

  Widget _selectedDayDetails() {
    final record = _recordFor(_selectedDate);
    final status = _statusFor(_selectedDate);
    final color = _statusColor(status);
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    DateFormat('EEE, d MMM yyyy').format(_selectedDate),
                    key: ValueKey(ymd(_selectedDate)),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _badge(status, color),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              _detail(
                'CHECK IN',
                fmtTime(record?['check_in']),
                Icons.login_rounded,
                Colors.green,
              ),
              _detail(
                'CHECK OUT',
                fmtTime(record?['check_out']),
                Icons.logout_rounded,
                Colors.orange,
              ),
              _detail(
                'WORKED',
                _workedTimeFor(record),
                Icons.timelapse_rounded,
                Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          if (record != null && record.s('note').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Note: ${record.s('note')}',
              style: TextStyle(
                fontSize: 9,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detail(String title, String value,
      IconData icon,
      Color color,) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color,),
          const SizedBox(width: 12),
          Text(
            value.isEmpty ? '--' : value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CALENDAR
  // ============================================================

  Widget _calendar() {
    final firstDay = DateTime(_year, _month, 1);
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final offset = firstDay.weekday % 7;

    final cs = Theme.of(context).colorScheme;

    const weekdays = [
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
    ];

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _heading(
                  DateFormat('MMMM yyyy').format(firstDay),
                  Icons.calendar_month_rounded,
                ),
              ),
              if (!_isCurrentMonth)
                TextButton(
                  onPressed: _goToToday,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              IconButton(
                tooltip: 'Previous month',
                visualDensity: VisualDensity.compact,
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
              ),
              IconButton(
                tooltip: 'Next month',
                visualDensity: VisualDensity.compact,
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 6),
          _selectedDayDetails(),
          const SizedBox(height: 13),

          Row(
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          LayoutBuilder(
            builder: (context, constraints) {
              final cellHeight =
              constraints.maxWidth >= 500 ? 48.0 : 39.0;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: offset + daysInMonth,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: cellHeight,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  if (index < offset) {
                    return const SizedBox.shrink();
                  }

                  final day = index - offset + 1;
                  final date = DateTime(_year, _month, day);

                  final status = _statusFor(date);
                  final color = _statusColor(status);

                  final selected = ymd(date) == ymd(_selectedDate);
                  final isToday = ymd(date) == ymd(today());

                  return Tooltip(
                    message: '$day - $status',
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      child: InkWell(
                        onTap: () => _selectDate(date),
                        borderRadius: BorderRadius.circular(9),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 170),
                          decoration: BoxDecoration(
                            color: selected
                                ? cs.primary.withValues(alpha: 0.12)
                                : color.withValues(alpha: 0.055),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: selected
                                  ? cs.primary
                                  : isToday
                                  ? cs.primary.withValues(alpha: 0.55)
                                  : Colors.transparent,
                              width: selected || isToday ? 1.2 : 0.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected || isToday
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? cs.primary
                                      : cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 170),
                                height: selected ? 6 : 5,
                                width: selected ? 6 : 5,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 13),

          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _legend('Present', Colors.green),
              _legend('Absent', Colors.red),
              _legend('Late', Colors.orange),
              _legend('Leave', Colors.purple),
              _legend('Holiday', Colors.blue),
              _legend('Weekend', Colors.blueGrey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 7,
          width: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          title,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RESPONSIVE CONTENT
  // ============================================================

  Widget _responsiveContent(double width) {
    final todayCard = _todayCard();
    final leaveCard = _leaveBalances();
    final calendarCard = _calendar();

    // Desktop: Today + Leave on the left, Calendar on the right.
    if (width >= 1000) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                todayCard,
                const SizedBox(height: 10),
                leaveCard,
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                calendarCard,
              ],
            ),
          ),
        ],
      );
    }

    // Tablet: Today + Leave side by side, Calendar below.
    if (width >= 620) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: todayCard),
              const SizedBox(width: 10),
              Expanded(child: leaveCard),
            ],
          ),
          const SizedBox(height: 10),
          calendarCard,
        ],
      );
    }

    // Mobile: All components stacked vertically.
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        todayCard,
        const SizedBox(height: 9),
        leaveCard,
        const SizedBox(height: 9),
        calendarCard,
      ],
    );
  }

  Widget _myAttendance() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: _refresh,
          child: _responsiveContent(constraints.maxWidth),
        );
      },
    );
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (Session.empId == null) {
      return const Center(
        child: Text('Employee account is not linked.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          Expanded(
            child: _loading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : Session.isHr
                ? TabsView(
              titles: const [
                'My Attendance',
                'All Employees',
              ],
              children: [
                _myAttendance(),
                const AllEmployeesAttendanceView(),
              ],
            )
                : _myAttendance(),
          ),
        ],
      ),
    );
  }
}
