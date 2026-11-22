
import 'package:flutter/material.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/ui.dart';

import 'reports_controller.dart';

class ReportsFeaturePage extends StatefulWidget {
  const ReportsFeaturePage({super.key});

  @override
  State<ReportsFeaturePage> createState() => ReportsFeaturePageState();
}

class ReportsFeaturePageState extends State<ReportsFeaturePage> {
  late final ReportsController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ReportsController()..loadReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String get _key => monthKey(_controller.year, _controller.month);

  Future<void> _export(
      String fileName,
      List<String> headers,
      List<List<dynamic>> rows,
      ) async {
    if (!mounted) return;

    try {
      await exportCsv(context, fileName, headers, rows);
    } catch (e) {
      if (mounted) toast(context, 'Export failed: $e');
    }
  }

  Future<void> _summaryCsv() async {
    await _export(
      'attendance_summary_$_key.csv',
      [
        'Code',
        'Employee',
        'Department',
        'Working Days',
        'Present',
        'Half Day',
        'Leave',
        'Unpaid Leave',
        'Absent',
        'Total Hours',
        'Avg Daily Hours',
        'Attendance Rate (%)',
      ],
      [
        for (final e in _controller.summaryRows)
          [
            e.key.s('code'),
            e.key.s('name'),
            e.key.s('department'),
            e.value.working,
            e.value.present,
            e.value.half,
            e.value.leave,
            e.value.unpaid,
            e.value.absent,
            (e.value.hours.inMinutes / 60).toStringAsFixed(2),
            e.value.avgDailyHours.toStringAsFixed(2),
            '${e.value.attendanceRate.toStringAsFixed(1)}%',
          ],
      ],
    );
  }

  Future<void> _detailCsv() async {
    try {
      final rows = await _controller.fetchAttendanceDetail();
      if (!mounted) return;

      await _export(
        'attendance_detail_$_key.csv',
        [
          'Code',
          'Employee',
          'Department',
          'Date',
          'Status',
          'Check In',
          'Check Out',
          'Worked Hours',
          'Note',
        ],
        [
          for (final r in rows)
            [
              r.s('code'),
              r.s('name'),
              r.s('department'),
              r.s('date'),
              r.s('status'),
              fmtTime(r['check_in']),
              fmtTime(r['check_out']),
              ((workedBetween(r['check_in'], r['check_out'])?.inMinutes ?? 0) /
                  60)
                  .toStringAsFixed(2),
              r.s('note'),
            ],
        ],
      );
    } catch (e) {
      if (mounted) toast(context, 'Unable to export attendance: $e');
    }
  }

  Future<void> _employeesCsv() async {
    try {
      final rows = await _controller.fetchEmployees();
      if (!mounted) return;

      await _export(
        'employees.csv',
        [
          'Code',
          'Name',
          'Email',
          'Phone',
          'Department',
          'Designation',
          'Manager',
          'Joined',
          'Status',
          'Basic',
          'HRA',
          'Allowances',
        ],
        [
          for (final e in rows)
            [
              e.s('code'),
              e.s('name'),
              e.s('email'),
              e.s('phone'),
              e.s('department'),
              e.s('designation'),
              e.s('manager_name'),
              e.s('join_date'),
              e.s('status'),
              e.d('basic'),
              e.d('hra'),
              e.d('allowances'),
            ],
        ],
      );
    } catch (e) {
      if (mounted) toast(context, 'Unable to export employees: $e');
    }
  }

  Future<void> _leavesCsv() async {
    try {
      final rows = await _controller.fetchLeaves();
      if (!mounted) return;

      await _export(
        'leave_requests.csv',
        [
          'Employee',
          'Type',
          'From',
          'To',
          'Days',
          'Reason',
          'Status',
          'Applied On',
        ],
        [
          for (final l in rows)
            [
              l.s('emp_name'),
              l.s('type_name'),
              l.s('start_date'),
              l.s('end_date'),
              l.d('days'),
              l.s('reason'),
              l.s('status'),
              l.s('applied_on'),
            ],
        ],
      );
    } catch (e) {
      if (mounted) toast(context, 'Unable to export leaves: $e');
    }
  }

  Future<void> _refresh() async {
    await _controller.loadReports();
  }

  void _onSearch(String value) {
    _controller.setSearchQuery(value);
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    _controller.setSearchQuery('');
    setState(() {});
  }

  void _exportMenu(String value) {
    switch (value) {
      case 'summary':
        _summaryCsv();
        break;
      case 'detail':
        _detailCsv();
        break;
      case 'leaves':
        _leavesCsv();
        break;
      case 'employees':
        _employeesCsv();
        break;
    }
  }

  // ------------------------------------------------------------
  // KPI CARDS
  // ------------------------------------------------------------

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Responsive columns
        final int columns = width >= 1000
            ? 4 // Windows / Large desktop
            : width >= 600
            ? 2 // Tablet / Small window
            : 2; // Mobile

        const spacing = 12.0;

        final cardWidth =
            (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _kpiCard(
                title: 'Total Employees',
                value: '${_controller.totalEmployees}',
                icon: Icons.people_outline,
                color: Colors.blue,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _kpiCard(
                title: 'Total Hours',
                value:
                '${_controller.totalHoursWorked.toStringAsFixed(1)} h',
                icon: Icons.schedule,
                color: Colors.purple,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _kpiCard(
                title: 'Avg Daily Hours',
                value:
                '${_controller.overallAvgDailyHours.toStringAsFixed(1)} h/d',
                icon: Icons.access_time,
                color: Colors.teal,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _kpiCard(
                title: 'Avg Attendance',
                value:
                '${_controller.avgAttendanceRate.toStringAsFixed(1)}%',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }
  // ------------------------------------------------------------
  // TABLES
  // ------------------------------------------------------------

  Widget _buildSummaryTable() {
    final rows = _controller.filteredSummaryRows;

    return TableCard(
      columns: const [
        DataColumn(label: Text('Code')),
        DataColumn(label: Text('Employee')),
        DataColumn(label: Text('Department')),
        DataColumn(label: Text('Working Days'), numeric: true),
        DataColumn(label: Text('Present'), numeric: true),
        DataColumn(label: Text('Half Day'), numeric: true),
        DataColumn(label: Text('Leave'), numeric: true),
        DataColumn(label: Text('Unpaid'), numeric: true),
        DataColumn(label: Text('Absent'), numeric: true),
        DataColumn(label: Text('Total Hours'), numeric: true),
        DataColumn(label: Text('Avg Daily Hours'), numeric: true),
        DataColumn(label: Text('Attendance Rate'), numeric: true),
      ],
      rows: [
        for (final e in rows)
          DataRow(
            cells: [
              DataCell(Text(e.key.s('code'))),
              DataCell(Text(e.key.s('name'))),
              DataCell(Text(e.key.s('department'))),
              DataCell(Text(nf(e.value.working))),
              DataCell(Text(nf(e.value.present))),
              DataCell(Text(nf(e.value.half))),
              DataCell(Text(nf(e.value.leave))),
              DataCell(Text(nf(e.value.unpaid))),
              DataCell(Text(nf(e.value.absent))),
              DataCell(
                Text((e.value.hours.inMinutes / 60).toStringAsFixed(1)),
              ),
              DataCell(
                Text(
                  '${e.value.avgDailyHours.toStringAsFixed(1)} h/d',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(
                Text(
                  '${e.value.attendanceRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: e.value.attendanceRate >= 85
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
      ],
      empty: 'No attendance records found for this month.',
    );
  }

  Widget _buildDetailTable() {
    final rows = _controller.filteredDetailRows;

    return TableCard(
      columns: const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Code')),
        DataColumn(label: Text('Employee')),
        DataColumn(label: Text('Department')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Check In')),
        DataColumn(label: Text('Check Out')),
        DataColumn(label: Text('Worked Hours'), numeric: true),
        DataColumn(label: Text('Note')),
      ],
      rows: [
        for (final r in rows)
          DataRow(
            cells: [
              DataCell(Text(fmtDate(r.s('date')))),
              DataCell(Text(r.s('code'))),
              DataCell(Text(r.s('name'))),
              DataCell(Text(r.s('department'))),
              DataCell(StatusChip(r.s('status'))),
              DataCell(Text(fmtTime(r['check_in']))),
              DataCell(Text(fmtTime(r['check_out']))),
              DataCell(
                Text(
                  ((workedBetween(r['check_in'], r['check_out'])?.inMinutes ??
                      0) /
                      60)
                      .toStringAsFixed(1),
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    r.s('note'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
      ],
      empty: 'No attendance details found for this month.',
    );
  }

  Widget _buildLeavesTable() {
    final rows = _controller.filteredLeaveRows;

    return TableCard(
      columns: const [
        DataColumn(label: Text('Employee')),
        DataColumn(label: Text('Leave Type')),
        DataColumn(label: Text('From')),
        DataColumn(label: Text('To')),
        DataColumn(label: Text('Days'), numeric: true),
        DataColumn(label: Text('Reason')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Applied On')),
      ],
      rows: [
        for (final l in rows)
          DataRow(
            cells: [
              DataCell(Text(l.s('emp_name'))),
              DataCell(Text(l.s('type_name'))),
              DataCell(Text(fmtDate(l.s('start_date')))),
              DataCell(Text(fmtDate(l.s('end_date')))),
              DataCell(Text(nf(l.d('days')))),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    l.s('reason'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(StatusChip(l.s('status'))),
              DataCell(Text(fmtDate(l.s('applied_on')))),
            ],
          ),
      ],
      empty: 'No leave records found.',
    );
  }

  Widget _buildEmployeesTable() {
    final rows = _controller.filteredEmployeeRows;

    return TableCard(
      columns: const [
        DataColumn(label: Text('Code')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Department')),
        DataColumn(label: Text('Designation')),
        DataColumn(label: Text('Manager')),
        DataColumn(label: Text('Joined')),
        DataColumn(label: Text('Status')),
      ],
      rows: [
        for (final e in rows)
          DataRow(
            cells: [
              DataCell(Text(e.s('code'))),
              DataCell(Text(e.s('name'))),
              DataCell(Text(e.s('department'))),
              DataCell(Text(e.s('designation'))),
              DataCell(Text(e.s('manager_name'))),
              DataCell(Text(fmtDate(e.s('join_date')))),
              DataCell(StatusChip(e.s('status'))),
            ],
          ),
      ],
      empty: 'No employees found.',
    );
  }

  // ------------------------------------------------------------
  // TOP FILTER BAR
  // ------------------------------------------------------------

  Widget _buildToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return MonthBar(
                  year: _controller.year,
                  month: _controller.month,
                  onChanged: (year, month) {
                    _controller.setYearMonth(year, month);
                  },
                );
              },
            ),
            SizedBox(
              width: compact ? constraints.maxWidth-100 : 270,
              child:TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search employee or department...',
                  prefixIcon: const Icon(Icons.search, size: 19),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _clearSearch,
                  )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade600, width: 1.5),
                  ),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: compact ? const SizedBox.shrink():const Text('Refresh')
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // EXPORT MENU
  // ------------------------------------------------------------

  Widget _buildExportMenu() {
    return PopupMenuButton<String>(
      tooltip: 'Export reports',
      onSelected: _exportMenu,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'summary',
          child: Row(
            children: [
              Icon(Icons.table_chart_outlined, size: 19),
              SizedBox(width: 10),
              Text('Attendance Summary'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'detail',
          child: Row(
            children: [
              Icon(Icons.view_list_outlined, size: 19),
              SizedBox(width: 10),
              Text('Attendance Details'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'leaves',
          child: Row(
            children: [
              Icon(Icons.event_note_outlined, size: 19),
              SizedBox(width: 10),
              Text('Leave Requests'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'employees',
          child: Row(
            children: [
              Icon(Icons.people_outline, size: 19),
              SizedBox(width: 10),
              Text('Employee Directory'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_outlined, size: 18),
            SizedBox(width: 7),
            Text(
              'Export',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // MAIN BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PageBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Header(
            'Reports & Analytics',
            actions: [_buildExportMenu()],
          ),
          // const SizedBox(height: 10),

          _buildToolbar(),
          const SizedBox(height: 16),

          // Expanded must be outside ListenableBuilder.
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_controller.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 44,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Unable to load reports',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _controller.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKpiRow(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabsView(
                        titles: const [
                          'Attendance Summary',
                          'Daily Details',
                          'Leave Requests',
                          'Employees Directory',
                        ],
                        children: [
                          _buildSummaryTable(),
                          _buildDetailTable(),
                          _buildLeavesTable(),
                          _buildEmployeesTable(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
