
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hrms/core/ui.dart';
import 'package:hrms/features/attendance/data/attendance_repository.dart';

class AllEmployeesAttendanceView extends StatefulWidget {
  const AllEmployeesAttendanceView({super.key});

  @override
  State<AllEmployeesAttendanceView> createState() =>
      AllEmployeesAttendanceViewState();
}

class AllEmployeesAttendanceViewState
    extends State<AllEmployeesAttendanceView> {
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final TextEditingController _searchController = TextEditingController();

  DateTime _date = today();

  List<Rec> _employees = [];

  bool _loading = true;
  bool _exporting = false;

  String _search = '';
  String _filter = 'All';

  final Set<int> _updatingEmployees = {};

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _load({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() => _loading = true);
    }

    try {
      final result = await _attendanceRepo.dayAttendance(ymd(_date));

      if (!mounted) return;

      setState(() {
        _employees = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      toast(context, 'Unable to load attendance: $e');
    }
  }

  Future<void> _refresh() => _load(showLoading: false);

  void _showMessage(String message) {
    if (!mounted) return;
    toast(context, message);
  }

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  String _status(Rec record) {
    final value = record.s('status');
    return value.isEmpty ? 'Absent' : value;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'half day':
      case 'half-day':
        return Colors.deepOrange;
      case 'leave':
      case 'unpaid leave':
        return Colors.purple;
      case 'absent':
        return Colors.red;
      case 'holiday':
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle_outline_rounded;
      case 'late':
        return Icons.access_time_rounded;
      case 'half day':
      case 'half-day':
        return Icons.timelapse_rounded;
      case 'leave':
      case 'unpaid leave':
        return Icons.event_busy_outlined;
      case 'absent':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  int _countStatus(String status) {
    return _employees.where((r) {
      final current = _status(r).toLowerCase();

      if (status == 'Leave') {
        return current == 'leave' || current == 'unpaid leave';
      }

      return current == status.toLowerCase();
    }).length;
  }

  int get _total => _employees.length;
  int get _present => _countStatus('Present');
  int get _late => _countStatus('Late');
  int get _half => _countStatus('Half Day');
  int get _leave => _countStatus('Leave');
  int get _absent => _countStatus('Absent');

  double get _attendanceRate {
    if (_total == 0) return 0;

    return ((_present + _late + (_half * 0.5)) / _total) * 100;
  }

  // ============================================================
  // FILTERING
  // ============================================================

  List<Rec> get _filteredEmployees {
    return _employees.where((record) {
      final status = _status(record);

      if (_filter != 'All') {
        final matchesStatus = _filter == 'Leave'
            ? status == 'Leave' || status == 'Unpaid Leave'
            : status == _filter;

        if (!matchesStatus) return false;
      }

      if (_search.isNotEmpty) {
        final query = _search.toLowerCase();

        final name = record.s('name').toLowerCase();
        final code = record.s('code').toLowerCase();
        final department = record.s('department').toLowerCase();

        if (!name.contains(query) &&
            !code.contains(query) &&
            !department.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _setFilter(String value) {
    setState(() => _filter = value);
  }

  // ============================================================
  // DATE NAVIGATION
  // ============================================================

  bool get _isToday => ymd(_date) == ymd(today());

  void _changeDate(int offset) {
    setState(() {
      _date = _date.add(Duration(days: offset));
    });

    _load();
  }

  void _goToToday() {
    setState(() => _date = today());
    _load();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select attendance date',
    );

    if (selected == null || !mounted) return;

    setState(() => _date = selected);
    _load();
  }

  // ============================================================
  // STATUS UPDATE
  // ============================================================

  Future<void> _updateStatus(Rec record, String newStatus) async {
    final empId = record.i('emp_id') ?? record.i('employee_id');
    if (empId == null || _updatingEmployees.contains(empId)) return;

    setState(() => _updatingEmployees.add(empId));

    try {
      await _attendanceRepo.setStatus(
        empId,
        ymd(_date),
        newStatus,
      );

      if (!mounted) return;

      await _load(showLoading: false);
      _showMessage('Attendance status updated.');
    } catch (e) {
      _showMessage('Unable to update attendance: $e');
    } finally {
      if (mounted) {
        setState(() => _updatingEmployees.remove(empId));
      }
    }
  }

  // ============================================================
  // TIME HELPERS
  // ============================================================

  TimeOfDay? _parseTime(String value) {
    if (value.isEmpty) return null;

    final parsedDate = DateTime.tryParse(value);

    if (parsedDate != null) {
      return TimeOfDay.fromDateTime(parsedDate);
    }

    final parsedTime = DateFormat('HH:mm').tryParse(value);

    if (parsedTime != null) {
      return TimeOfDay.fromDateTime(parsedTime);
    }

    return null;
  }

  DateTime? _dateTimeFromController(
      TextEditingController controller,
      ) {
    final value = controller.text.trim();
    if (value.isEmpty) return null;

    final time = _parseTime(value);
    if (time == null) return null;

    return DateTime(
      _date.year,
      _date.month,
      _date.day,
      time.hour,
      time.minute,
    );
  }

  // ============================================================
  // EDIT ATTENDANCE
  // ============================================================

  Future<void> _showModifyAttendanceDialog(Rec record) async {
    final empId = record.i('emp_id') ?? record.i('employee_id');
    if (empId == null) return;

    final name = record.s('name');
    final currentNote = record.s('note');

    String selectedStatus = kStatuses.contains(_status(record))
        ? _status(record)
        : 'Present';

    final checkInController = TextEditingController(
      text: fmtTime(record['check_in']) == '--'
          ? ''
          : fmtTime(record['check_in']),
    );

    final checkOutController = TextEditingController(
      text: fmtTime(record['check_out']) == '--'
          ? ''
          : fmtTime(record['check_out']),
    );

    final noteController = TextEditingController(text: currentNote);

    Future<void> pickTime(TextEditingController controller) async {
      final initial = _parseTime(controller.text) ??
          const TimeOfDay(hour: 9, minute: 0);

      final picked = await showTimePicker(
        context: context,
        initialTime: initial,
      );

      if (picked != null) {
        controller.text =
        '${picked.hour.toString().padLeft(2, '0')}:'
            '${picked.minute.toString().padLeft(2, '0')}';
      }
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final cs = Theme.of(ctx).colorScheme;

            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: cs.primary.withValues(alpha: 0.09),
                    child: Icon(
                      Icons.edit_calendar_rounded,
                      size: 19,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Attendance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dialogLabel('ATTENDANCE STATUS'),
                      const SizedBox(height: 7),

                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            _statusIcon(selectedStatus),
                            size: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                        ),
                        items: [
                          for (final status in kStatuses)
                            DropdownMenuItem(
                              value: status,
                              child: Text(
                                status,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedStatus = value);
                          }
                        },
                      ),

                      const SizedBox(height: 16),
                      _dialogLabel('WORKING HOURS'),
                      const SizedBox(height: 7),

                      Row(
                        children: [
                          Expanded(
                            child: _timeField(
                              controller: checkInController,
                              label: 'Check In',
                              icon: Icons.login_rounded,
                              color: Colors.green,
                              onTap: () => pickTime(checkInController),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _timeField(
                              controller: checkOutController,
                              label: 'Check Out',
                              icon: Icons.logout_rounded,
                              color: Colors.orange,
                              onTap: () => pickTime(checkOutController),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      _dialogLabel('NOTE'),
                      const SizedBox(height: 7),

                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add an attendance note...',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 35),
                            child: Icon(Icons.notes_rounded, size: 18),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy').format(_date),
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      try {
        final inTime = _dateTimeFromController(checkInController);
        final outTime = _dateTimeFromController(checkOutController);

        await _attendanceRepo.setStatus(
          empId,
          ymd(_date),
          selectedStatus,
        );

        if (inTime != null || outTime != null) {
          await _attendanceRepo.setTime(
            empId,
            ymd(_date),
            inTime: inTime,
            outTime: outTime,
          );
        }

        if (noteController.text.trim() != currentNote) {
          await _attendanceRepo.setNote(
            empId,
            ymd(_date),
            noteController.text.trim(),
          );
        }

        if (!mounted) return;

        await _load(showLoading: false);
        _showMessage('Attendance updated for $name.');
      } catch (e) {
        _showMessage('Unable to save attendance: $e');
      }
    }

    checkInController.dispose();
    checkOutController.dispose();
    noteController.dispose();
  }

  Widget _dialogLabel(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Colors.grey,
      ),
    );
  }

  Widget _timeField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        prefixIcon: Icon(icon, size: 16, color: color),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close_rounded, size: 15),
          onPressed: controller.clear,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        isDense: true,
      ),
    );
  }

  // ============================================================
  // CSV EXPORT
  // ============================================================

  Future<void> _exportDayAttendanceCsv() async {
    if (_exporting) return;

    setState(() => _exporting = true);

    try {
      await exportCsv(
        context,
        'attendance_${ymd(_date)}.csv',
        [
          'Code',
          'Employee',
          'Department',
          'Date',
          'Status',
          'Check In',
          'Check Out',
          'Note',
        ],
        [
          for (final record in _filteredEmployees)
            [
              record.s('code'),
              record.s('name'),
              record.s('department'),
              ymd(_date),
              _status(record),
              fmtTime(record['check_in']),
              fmtTime(record['check_out']),
              record.s('note'),
            ],
        ],
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String filter,
    String? subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    final selected = _filter == filter;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: selected
            ? color.withValues(alpha: 0.09)
            : cs.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _setFilter(filter),
          child: AnimatedContainer(
            width: 200,
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.65)
                    : cs.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 8,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: color,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DATE HEADER
  // ============================================================

  Widget _dateHeader() {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Previous day',
                onPressed: () => _changeDate(-1),
                icon: const Icon(Icons.chevron_left_rounded, size: 19),
              ),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 15,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        DateFormat('d MMM yyyy').format(_date),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Next day',
                onPressed: () => _changeDate(1),
                icon: const Icon(Icons.chevron_right_rounded, size: 19),
              ),
            ],
          ),
        ),
        if (!_isToday)
          OutlinedButton.icon(
            onPressed: _goToToday,
            icon: const Icon(Icons.today_rounded, size: 14),
            label: const Text('Today'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 10),
            ),
          ),
        OutlinedButton.icon(
          onPressed: _loading ? null : _refresh,
          icon: const Icon(Icons.refresh_rounded, size: 14),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            textStyle: const TextStyle(fontSize: 10),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _exporting || _filteredEmployees.isEmpty
              ? null
              : _exportDayAttendanceCsv,
          icon: _exporting
              ? const SizedBox(
            height: 13,
            width: 13,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.download_rounded, size: 14),
          label: const Text('Export'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            textStyle: const TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH AND FILTERS
  // ============================================================

  Widget _searchAndFilters() {
    final cs = Theme.of(context).colorScheme;

    const filters = [
      'All',
      'Present',
      'Late',
      'Half Day',
      'Leave',
      'Absent',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _search = value.trim()),
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search employee, code or department...',
            hintStyle: const TextStyle(fontSize: 11),
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            suffixIcon: _search.isEmpty
                ? null
                : IconButton(
              tooltip: 'Clear search',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                _searchController.clear();
                setState(() => _search = '');
              },
              icon: const Icon(Icons.close_rounded, size: 16),
            ),
            isDense: true,
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.25),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),],
    );
  }

  // ============================================================
  // EMPLOYEE ROW
  // ============================================================

  Widget _employeeRow(Rec record) {
    final cs = Theme.of(context).colorScheme;
    final name = record.s('name');
    final department = record.s('department');
    final status = _status(record);
    final color = _statusColor(status);

    final empId = record.i('emp_id') ?? record.i('employee_id');
    final updating = empId != null && _updatingEmployees.contains(empId);

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primary.withValues(alpha: 0.09),
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Unknown employee' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (record.s('code').isNotEmpty) record.s('code'),
                      if (department.isNotEmpty) department,
                    ].join(' • ').isEmpty
                        ? 'No employee details'
                        : [
                      if (record.s('code').isNotEmpty) record.s('code'),
                      if (department.isNotEmpty) department,
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 7),

            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _timeInfo(
                    Icons.login_rounded,
                    fmtTime(record['check_in']),
                    Colors.green,
                  ),
                  const SizedBox(height: 5),
                  _timeInfo(
                    Icons.logout_rounded,
                    fmtTime(record['check_out']),
                    Colors.orange,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 5),

            if (updating)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              PopupMenuButton<String>(
                tooltip: 'Change status',
                initialValue: null,
                onSelected: (value) => _updateStatus(record, value),
                itemBuilder: (context) => [
                  for (final value in kStatuses)
                    PopupMenuItem(
                      value: value,
                      child: Row(
                        children: [
                          Icon(
                            _statusIcon(value),
                            size: 16,
                            color: _statusColor(value),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            value,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Spacer(),
                          if (value == status)
                            Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: cs.primary,
                            ),
                        ],
                      ),
                    ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: color.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(status),
                        size: 12,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 13,
                        color: color,
                      ),
                    ],
                  ),
                ),
              ),

            IconButton(
              tooltip: 'Edit attendance',
              visualDensity: VisualDensity.compact,
              onPressed: () => _showModifyAttendanceDialog(record),
              icon: Icon(
                Icons.edit_outlined,
                size: 17,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeInfo(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            value.isEmpty ? '--' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPLOYEE LIST
  // ============================================================

  Widget _employeeList() {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filteredEmployees;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 38,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 10),
              Text(
                _employees.isEmpty
                    ? 'No attendance records for this date.'
                    : 'No matching employees found.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (_filter != 'All' || _search.isNotEmpty) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _search = '';
                      _filter = 'All';
                    });
                  },
                  child: const Text('Clear filters'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _employeeRow(filtered[index]),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1150
            ? 3
            : constraints.maxWidth >= 700
            ? 2
            : 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SUMMARY CARDS
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(

                children: [
                  _summaryCard(
                    title: 'Total Employees',
                    value: '$_total',
                    icon: Icons.people_outline_rounded,
                    color: Colors.blue,
                    filter: 'All',
                    subtitle: 'View everyone',
                  ),
                  _summaryCard(
                    title: 'Present',
                    value: '$_present',
                    icon: Icons.check_circle_outline_rounded,
                    color: Colors.green,
                    filter: 'Present',
                    subtitle: 'On duty',
                  ),
                  _summaryCard(
                    title: 'Late',
                    value: '$_late',
                    icon: Icons.access_time_rounded,
                    color: Colors.orange,
                    filter: 'Late',
                    subtitle: 'Late arrivals',
                  ),
                  _summaryCard(
                    title: 'Half Day',
                    value: '$_half',
                    icon: Icons.timelapse_rounded,
                    color: Colors.deepOrange,
                    filter: 'Half Day',
                    subtitle: 'Partial attendance',
                  ),
                  _summaryCard(
                    title: 'On Leave',
                    value: '$_leave',
                    icon: Icons.event_busy_outlined,
                    color: Colors.purple,
                    filter: 'Leave',
                    subtitle: 'Approved / unpaid',
                  ),
                  _summaryCard(
                    title: 'Absent',
                    value: '$_absent',
                    icon: Icons.cancel_outlined,
                    color: Colors.red,
                    filter: 'Absent',
                    subtitle: 'Not present',
                  ),
                ],
              ),
            ),

            // ATTENDANCE RATE
            Container(
              margin: const EdgeInsets.only(bottom: 11),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.045),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      color: cs.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attendance Rate',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: (_attendanceRate / 100).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor:
                            cs.outlineVariant.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_attendanceRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),

            // DATE AND EXPORT
            _dateHeader(),
            const SizedBox(height: 12),

            // SEARCH AND FILTERS
            _searchAndFilters(),
            const SizedBox(height: 10),

            // RESULT COUNT
            Row(
              children: [
                Text(
                  'Employees',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_filteredEmployees.length}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('d MMM yyyy').format(_date),
                  style: TextStyle(
                    fontSize: 9,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // EMPLOYEE LIST
            Expanded(child: _employeeList()),
          ],
        );
      },
    );
  }
}
