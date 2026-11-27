
import 'package:flutter/material.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/payslip.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/domain/entities/payroll_entity.dart';

import 'payroll_controller.dart';

class PayrollFeaturePage extends StatefulWidget {
  const PayrollFeaturePage({super.key});

  @override
  State<PayrollFeaturePage> createState() => PayrollFeaturePageState();
}

class PayrollFeaturePageState extends State<PayrollFeaturePage> {
  late final PayrollController _controller;

  @override
  void initState() {
    super.initState();

    _controller = PayrollController()
      ..loadPayroll(
        empId: Session.isHr ? null : Session.empId,
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = <String>[
      if (Session.isHr) 'Overview',
      if (Session.isHr) 'Run Payroll',
      if (Session.empId != null) 'My Payslips',
    ];

    final tabs = <Widget>[
      if (Session.isHr) _OverviewTab(controller: _controller),
      if (Session.isHr) _RunTab(controller: _controller),
      if (Session.empId != null) _MineTab(controller: _controller),
    ];

    return PageBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Header('Payroll & Payslips'),
          const SizedBox(height: 12),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (titles.isEmpty) {
                  return const Center(
                    child: Text('You do not have access to payroll.'),
                  );
                }

                return TabsView(
                  titles: titles,
                  children: tabs,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PAYROLL OVERVIEW
// ============================================================

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.controller});

  final PayrollController controller;

  @override
  Widget build(BuildContext context) {
    final rows = controller.payrollRows;
    final cs = Theme.of(context).colorScheme;

    final gross = rows.fold<double>(
      0,
          (sum, r) => sum + r.d('gross'),
    );

    final net = rows.fold<double>(
      0,
          (sum, r) => sum + r.d('net'),
    );

    final basic = rows.fold<double>(
      0,
          (sum, r) => sum + r.d('basic'),
    );

    final hra = rows.fold<double>(
      0,
          (sum, r) => sum + r.d('hra'),
    );

    final allowances = rows.fold<double>(
      0,
          (sum, r) => sum + r.d('allowances'),
    );

    final pf = rows.fold<double>(
      0,
          (sum, r) => sum + r.d('pf'),
    );

    final other = rows.fold<double>(
      0,
          (sum, r) => sum + r.d('other_deduction'),
    );

    final deductions = pf + other;
    final count = rows.length;
    final average = count == 0 ? 0.0 : net / count;

    return Column(
      children: [
        Row(
          children: [
            MonthBar(
              year: controller.year,
              month: controller.month,
              onChanged: (y, m) {
                controller.setYearMonth(y, m);
              },
            ),
            const Spacer(),
            if (rows.isNotEmpty)
              Text(
                '$count employees',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        Expanded(
          child: rows.isEmpty
              ? _PayrollEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No payroll data available',
            message:
            'Generate payroll for this month to see your payroll overview and reports.',
          )
              : ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              // SUMMARY CARDS
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  final columns = width >= 1100
                      ? 4
                      : width >= 600
                      ? 2
                      : 1;

                  const spacing = 10.0;

                  final cardWidth =
                      (width - spacing * (columns - 1)) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      _PayrollStatCard(
                        width: cardWidth,
                        title: 'Gross Payroll',
                        value: money(gross),
                        subtitle: 'Total earnings',
                        icon: Icons.account_balance_wallet_outlined,
                        color: Colors.blue,
                      ),
                      _PayrollStatCard(
                        width: cardWidth,
                        title: 'Net Payroll',
                        value: money(net),
                        subtitle: 'Take-home salary',
                        icon: Icons.payments_outlined,
                        color: Colors.green,
                      ),
                      _PayrollStatCard(
                        width: cardWidth,
                        title: 'Total Deductions',
                        value: money(deductions),
                        subtitle: 'PF + other deductions',
                        icon: Icons.remove_circle_outline,
                        color: Colors.deepOrange,
                      ),
                      _PayrollStatCard(
                        width: cardWidth,
                        title: 'Employees',
                        value: '$count',
                        subtitle: 'Payroll processed',
                        icon: Icons.people_outline,
                        color: Colors.purple,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // SALARY BREAKDOWN AND SUMMARY
              LayoutBuilder(
                builder: (context, constraints) {
                  final breakdown = _PayrollReportCard(
                    title: 'Salary Breakdown',
                    subtitle: 'Monthly earnings and deductions',
                    icon: Icons.bar_chart_rounded,
                    children: [
                      _PayrollBreakdownRow(
                        label: 'Basic Salary',
                        amount: basic,
                        total: gross,
                        color: Colors.blue,
                      ),
                      _PayrollBreakdownRow(
                        label: 'HRA',
                        amount: hra,
                        total: gross,
                        color: Colors.teal,
                      ),
                      _PayrollBreakdownRow(
                        label: 'Allowances',
                        amount: allowances,
                        total: gross,
                        color: Colors.purple,
                      ),
                      const Divider(height: 20),
                      _PayrollBreakdownRow(
                        label: 'PF Deduction',
                        amount: pf,
                        total: gross,
                        color: Colors.orange,
                      ),
                      _PayrollBreakdownRow(
                        label: 'Other Deductions',
                        amount: other,
                        total: gross,
                        color: Colors.red,
                      ),
                    ],
                  );

                  final summary = _PayrollReportCard(
                    title: 'Payroll Summary',
                    subtitle: 'Monthly payroll statistics',
                    icon: Icons.analytics_outlined,
                    children: [
                      _PayrollSummaryRow(
                        label: 'Total employees',
                        value: '$count',
                      ),
                      _PayrollSummaryRow(
                        label: 'Average net salary',
                        value: money(average),
                      ),
                      _PayrollSummaryRow(
                        label: 'Total gross salary',
                        value: money(gross),
                      ),
                      _PayrollSummaryRow(
                        label: 'Total deductions',
                        value: money(deductions),
                      ),
                      const Divider(height: 20),
                      _PayrollSummaryRow(
                        label: 'Total net payable',
                        value: money(net),
                        highlight: true,
                      ),
                    ],
                  );

                  if (constraints.maxWidth < 850) {
                    return Column(
                      children: [
                        breakdown,
                        const SizedBox(height: 12),
                        summary,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: breakdown),
                      const SizedBox(width: 12),
                      Expanded(child: summary),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // EMPLOYEE PAYROLL REPORT
              _PayrollReportCard(
                title: 'Employee Payroll Report',
                subtitle:
                'Employee-wise salary details for this month',
                icon: Icons.groups_outlined,
                trailing: Text(
                  '$count records',
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                children: [
                  for (int i = 0; i < rows.length; i++) ...[
                    _EmployeePayrollRow(record: rows[i]),
                    if (i != rows.length - 1)
                      Divider(
                        height: 1,
                        color: cs.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// RUN PAYROLL
// ============================================================

class _RunTab extends StatelessWidget {
  const _RunTab({required this.controller});

  final PayrollController controller;

  Future<void> _generate(BuildContext context) async {
    final ok = await confirm(
      context,
      'Generate Payroll',
      'Generate payroll for '
          '${monthLabel(monthKey(controller.year, controller.month))}?\n\n'
          'Existing payroll for this month will be recalculated.\n\n'
          'Run it after the month ends and attendance is complete.',
    );

    if (!ok) return;

    final n = await controller.runPayroll(
      controller.year,
      controller.month,
    );

    if (!context.mounted) return;

    toast(
      context,
      n == 0
          ? 'No active employees with a salary set'
          : 'Payroll generated successfully for $n employees',
    );
  }

  void _export(BuildContext context) {
    final rows = controller.payrollRows;

    if (rows.isEmpty) return;

    exportCsv(
      context,
      'payroll_${monthKey(controller.year, controller.month)}.csv',
      [
        'Code',
        'Employee',
        'Department',
        'Working days',
        'Paid days',
        'Basic',
        'HRA',
        'Allowances',
        'Gross',
        'PF',
        'Other deductions',
        'Net pay',
      ],
      [
        for (final r in rows)
          [
            r.s('code'),
            r.s('name'),
            r.s('department'),
            r.d('working_days'),
            r.d('paid_days'),
            r.d('basic'),
            r.d('hra'),
            r.d('allowances'),
            r.d('gross'),
            r.d('pf'),
            r.d('other_deduction'),
            r.d('net'),
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = controller.payrollRows;
    final cs = Theme.of(context).colorScheme;

    final totalGross = rows.fold<double>(
      0,
          (sum, r) => sum + r.d('gross'),
    );

    final totalNet = rows.fold<double>(
      0,
          (sum, r) => sum + r.d('net'),
    );

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MonthBar(
              year: controller.year,
              month: controller.month,
              onChanged: (y, m) {
                controller.setYearMonth(y, m);
              },
            ),
            if (rows.isNotEmpty)
              _SmallAmountBadge(
                label: 'Net: ${money(totalNet)}',
                color: Colors.green,
              ),
            if (rows.isNotEmpty)
              _SmallAmountBadge(
                label: 'Gross: ${money(totalGross)}',
                color: Colors.blue,
              ),
            OutlinedButton.icon(
              onPressed: rows.isEmpty ? null : () => _export(context),
              icon: const Icon(Icons.download_rounded, size: 15),
              label: const Text('Export CSV'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _generate(context),
              icon: const Icon(Icons.calculate_rounded, size: 15),
              label: const Text('Generate Payroll'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Expanded(
          child: rows.isEmpty
              ? _PayrollEmptyState(
            icon: Icons.calculate_outlined,
            title: 'No payroll records',
            message:
            'Set employee salaries and complete attendance, then press Generate Payroll.',
          )
              : ListView.separated(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: rows.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final r = rows[index];

              return _RunPayrollEmployeeCard(
                record: r,
                color: cs.primary,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EMPLOYEE PAYSLIPS
// ============================================================

class _MineTab extends StatelessWidget {
  const _MineTab({required this.controller});

  final PayrollController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final mine = controller.payrollRows
        .where((r) => r.i('employee_id') == Session.empId)
        .toList();

    final total = mine.fold<double>(
      0,
          (sum, r) => sum + r.d('net'),
    );

    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MonthBar(
              year: controller.year,
              month: controller.month,
              onChanged: (y, m) {
                controller.setYearMonth(
                  y,
                  m,
                  empId: Session.empId,
                );
              },
            ),
            if (mine.isNotEmpty)
              _SmallAmountBadge(
                label: 'Net Salary: ${money(total)}',
                color: Colors.green,
              ),
          ],
        ),

        const SizedBox(height: 12),

        Expanded(
          child: mine.isEmpty
              ? _PayrollEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No payslips available',
            message: 'Your payslips will appear here after payroll is generated.',
          )
              : ListView.separated(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: mine.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final r = mine[index];

              return Material(
                color: cs.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 21,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              monthLabel(r.s('month')),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gross: ${money(r.d('gross'))}',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Deductions: ${money(r.d('pf') + r.d('other_deduction'))}',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            money(r.d('net')),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FilledButton.tonalIcon(
                            onPressed: () => savePayslip(context, r),
                            icon: const Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 14,
                            ),
                            label: const Text(
                              'PDF',
                              style: TextStyle(fontSize: 10),
                            ),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// REUSABLE PAYROLL STAT CARD
// ============================================================

class _PayrollStatCard extends StatelessWidget {
  const _PayrollStatCard({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
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
        ],
      ),
    );
  }
}
// ============================================================
// REPORT CARD
// ============================================================

class _PayrollReportCard extends StatelessWidget {
  const _PayrollReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: .55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 23),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 9.5,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
// ============================================================
// SALARY BREAKDOWN ROW
// ============================================================

class _PayrollBreakdownRow extends StatelessWidget {
  const _PayrollBreakdownRow({
    required this.label,
    required this.amount,
    required this.total,
    required this.color,
  });

  final String label;
  final double amount;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final progress = total > 0
        ? (amount / total).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10.5),
                ),
              ),
              Text(
                money(amount),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: cs.surfaceContainerHighest,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
// ============================================================
// PAYROLL SUMMARY ROW
// ============================================================

class _PayrollSummaryRow extends StatelessWidget {
  const _PayrollSummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontWeight:
                highlight ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: highlight ? cs.primary : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPLOYEE PAYROLL REPORT ROW
// ============================================================

class _EmployeePayrollRow extends StatelessWidget {
  const _EmployeePayrollRow({required this.record});

  final PayrollEntity record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = record.s('name');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${record.s('code')} • ${record.s('department')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(record.d('net')),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Gross: ${money(record.d('gross'))}',
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RUN PAYROLL EMPLOYEE CARD
// ============================================================

class _RunPayrollEmployeeCard extends StatelessWidget {
  const _RunPayrollEmployeeCard({
    required this.record,
    required this.color,
  });

  final PayrollEntity record;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                record.s('code'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.s('name'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${record.s('department')} • '
                        'Days: ${nf(record.d('paid_days'))}/'
                        '${nf(record.d('working_days'))}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(record.d('net')),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Gross: ${money(record.d('gross'))}',
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            IconButton(
              tooltip: 'Download Payslip PDF',
              visualDensity: VisualDensity.compact,
              onPressed: () => savePayslip(context, record),
              icon: const Icon(
                Icons.picture_as_pdf_outlined,
                size: 19,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SMALL AMOUNT BADGE
// ============================================================

class _SmallAmountBadge extends StatelessWidget {
  const _SmallAmountBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class _PayrollEmptyState extends StatelessWidget {
  const _PayrollEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 27,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
