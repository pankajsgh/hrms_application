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
    toast(context, 'Reports refreshed');
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
  // COMPACT & INTERACTIVE KPI CARDS
  // ------------------------------------------------------------

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
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
                        fontSize: 10.5,
                        color: theme.hintColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int columns = width >= 1000 ? 4 : (width >= 600 ? 2 : 2);
        const spacing = 10.0;
        final cardWidth = (width - (spacing * (columns - 1))) / columns;

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
                onTap: () => toast(context, 'Total active employees'),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _kpiCard(
                title: 'Total Hours',
                value: '${_controller.totalHoursWorked.toStringAsFixed(1)} h',
                icon: Icons.schedule,
                color: Colors.purple,
                onTap: () => toast(context, 'Total hours worked'),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _kpiCard(
                title: 'Avg Daily Hours',
                value: '${_controller.overallAvgDailyHours.toStringAsFixed(1)} h/d',
                icon: Icons.access_time,
                color: Colors.teal,
                onTap: () => toast(context, 'Average daily work hours'),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _kpiCard(
                title: 'Avg Attendance',
                value: '${_controller.avgAttendanceRate.toStringAsFixed(1)}%',
                icon: Icons.check_circle_outline,
                color: Colors.green,
                onTap: () => toast(context, 'Overall attendance rate'),
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // TABLES & RESPONSIVE LISTS
  // ------------------------------------------------------------

  Widget _buildSummaryTable() {
    final rows = _controller.filteredSummaryRows;
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      if (rows.isEmpty) {
        return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No attendance records found for this month.')));
      }
      return ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final e = rows[index];
          return Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(e.key.s('code'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.key.s('name'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      Text('${e.value.attendanceRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: e.value.attendanceRate >= 85 ? Colors.green.shade700 : Colors.orange.shade800,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Dept: ${e.key.s('department')}  •  Working: ${nf(e.value.working)} days',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Present: ${nf(e.value.present)}', style: const TextStyle(fontSize: 11)),
                      Text('Leave: ${nf(e.value.leave)}', style: const TextStyle(fontSize: 11)),
                      Text('Absent: ${nf(e.value.absent)}', style: const TextStyle(fontSize: 11)),
                      Text('Hours: ${(e.value.hours.inMinutes / 60).toStringAsFixed(1)}h', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return TableCard(
      columns: const [
        DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Employee', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Working', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)), numeric: true),
        DataColumn(label: Text('Present', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)), numeric: true),
        DataColumn(label: Text('Half', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)), numeric: true),
        DataColumn(label: Text('Leave', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)), numeric: true),
        DataColumn(label: Text('Unpaid', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)), numeric: true),
        DataColumn(label: Text('Absent', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)), numeric: true),
        DataColumn(label: Text('Hours', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)), numeric: true),
        DataColumn(label: Text('Avg/D', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)), numeric: true),
        DataColumn(label: Text('Rate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)), numeric: true),
      ],
      rows: [
        for (final e in rows)
          DataRow(
            cells: [
              DataCell(Text(e.key.s('code'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5))),
              DataCell(Text(e.key.s('name'), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(e.key.s('department'), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(nf(e.value.working), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(nf(e.value.present), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(nf(e.value.half), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(nf(e.value.leave), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(nf(e.value.unpaid), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(nf(e.value.absent), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text((e.value.hours.inMinutes / 60).toStringAsFixed(1), style: const TextStyle(fontSize: 11.5))),
              DataCell(
                Text(
                  '${e.value.avgDailyHours.toStringAsFixed(1)}h',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
                ),
              ),
              DataCell(
                Text(
                  '${e.value.attendanceRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: e.value.attendanceRate >= 85
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
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
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      if (rows.isEmpty) {
        return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No attendance details found for this month.')));
      }
      return ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final r = rows[index];
          return Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(fmtDate(r.s('date')), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(r.s('name'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      StatusChip(r.s('status')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Dept: ${r.s('department')}  •  Code: ${r.s('code')}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('In: ${fmtTime(r['check_in'])}', style: const TextStyle(fontSize: 11)),
                      Text('Out: ${fmtTime(r['check_out'])}', style: const TextStyle(fontSize: 11)),
                      Text('Hours: ${((workedBetween(r['check_in'], r['check_out'])?.inMinutes ?? 0) / 60).toStringAsFixed(1)}h', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return TableCard(
      columns: const [
        DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Employee', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('In', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Hours', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)), numeric: true),
        DataColumn(label: Text('Note', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
      ],
      rows: [
        for (final r in rows)
          DataRow(
            cells: [
              DataCell(Text(fmtDate(r.s('date')), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(r.s('code'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5))),
              DataCell(Text(r.s('name'), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(r.s('department'), style: const TextStyle(fontSize: 11.5))),
              DataCell(StatusChip(r.s('status'))),
              DataCell(Text(fmtTime(r['check_in']), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(fmtTime(r['check_out']), style: const TextStyle(fontSize: 11.5))),
              DataCell(
                Text(
                  ((workedBetween(r['check_in'], r['check_out'])?.inMinutes ?? 0) / 60)
                      .toStringAsFixed(1),
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    r.s('note'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5),
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
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      if (rows.isEmpty) {
        return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No leave records found.')));
      }
      return ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final l = rows[index];
          return Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(l.s('emp_name'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      StatusChip(l.s('status')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Type: ${l.s('type_name')}  •  Days: ${nf(l.d('days'))}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text('From: ${fmtDate(l.s('start_date'))}  To: ${fmtDate(l.s('end_date'))}',
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          );
        },
      );
    }

    return TableCard(
      columns: const [
        DataColumn(label: Text('Employee', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('From', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('To', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Days', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)), numeric: true),
        DataColumn(label: Text('Reason', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Applied', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
      ],
      rows: [
        for (final l in rows)
          DataRow(
            cells: [
              DataCell(Text(l.s('emp_name'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5))),
              DataCell(Text(l.s('type_name'), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(fmtDate(l.s('start_date')), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(fmtDate(l.s('end_date')), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(nf(l.d('days')), style: const TextStyle(fontSize: 11.5))),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    l.s('reason'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ),
              ),
              DataCell(StatusChip(l.s('status'))),
              DataCell(Text(fmtDate(l.s('applied_on')), style: const TextStyle(fontSize: 11.5))),
            ],
          ),
      ],
      empty: 'No leave records found.',
    );
  }

  Widget _buildEmployeesTable() {
    final rows = _controller.filteredEmployeeRows;
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      if (rows.isEmpty) {
        return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No employees found.')));
      }
      return ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final e = rows[index];
          return Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(e.s('code'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.s('name'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                            StatusChip(e.s('status')),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Dept: ${e.s('department')}  •  Role: ${e.s('designation')}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return TableCard(
      columns: const [
        DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Designation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Manager', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Joined', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
      ],
      rows: [
        for (final e in rows)
          DataRow(
            cells: [
              DataCell(Text(e.s('code'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5))),
              DataCell(Text(e.s('name'), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(e.s('department'), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(e.s('designation'), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(e.s('manager_name'), style: const TextStyle(fontSize: 11.5))),
              DataCell(Text(fmtDate(e.s('join_date')), style: const TextStyle(fontSize: 11.5))),
              DataCell(StatusChip(e.s('status'))),
            ],
          ),
      ],
      empty: 'No employees found.',
    );
  }

  Widget _buildToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
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
              width: compact ? constraints.maxWidth - 90 : 250,
              height: 38,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search records...',
                  prefixIcon: const Icon(Icons.search, size: 17),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: _clearSearch,
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 1.2),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 38,
              child: OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: compact ? const SizedBox.shrink() : const Text('Refresh', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExportMenu() {
    return PopupMenuButton<String>(
      tooltip: 'Export reports',
      onSelected: _exportMenu,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'summary',
          child: Row(
            children: [
              Icon(Icons.table_chart_outlined, size: 17),
              SizedBox(width: 8),
              Text('Attendance Summary', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'detail',
          child: Row(
            children: [
              Icon(Icons.view_list_outlined, size: 17),
              SizedBox(width: 8),
              Text('Attendance Details', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'leaves',
          child: Row(
            children: [
              Icon(Icons.event_note_outlined, size: 17),
              SizedBox(width: 8),
              Text('Leave Requests', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'employees',
          child: Row(
            children: [
              Icon(Icons.people_outline, size: 17),
              SizedBox(width: 8),
              Text('Employee Directory', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_outlined, size: 16),
            SizedBox(width: 6),
            Text(
              'Export',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16),
          ],
        ),
      ),
    );
  }

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
          // const SizedBox(height: 12),
          _buildToolbar(),
          const SizedBox(height: 14),
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
                    const SizedBox(height: 14),
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
