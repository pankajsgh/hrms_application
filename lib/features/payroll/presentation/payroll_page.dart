import 'package:flutter/material.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/payslip.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
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
      ..loadPayroll(empId: Session.isHr ? null : Session.empId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = <String>[
      if (Session.isHr) 'Run Payroll',
      if (Session.empId != null) 'My Payslips',
    ];
    final tabs = <Widget>[
      if (Session.isHr) _RunTab(controller: _controller),
      if (Session.empId != null) _MineTab(controller: _controller),
    ];
    return PageBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Header('Payroll & Payslips'),
          const SizedBox(height: 16),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return TabsView(titles: titles, children: tabs);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RunTab extends StatelessWidget {
  const _RunTab({required this.controller});
  final PayrollController controller;

  Future<void> _generate(BuildContext context) async {
    final ok = await confirm(
      context,
      'Generate Payroll',
      'Generate payroll for ${monthLabel(monthKey(controller.year, controller.month))}? '
          'Existing payroll for this month will be recalculated.\n\n'
          'Tip: Run it after the month ends and attendance is complete.',
    );
    if (!ok) return;
    final n = await controller.runPayroll(controller.year, controller.month);
    if (!context.mounted) return;
    toast(
      context,
      n == 0
          ? 'No active employees with a salary set'
          : 'Payroll generated successfully for $n employees',
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalNet =
    controller.payrollRows.fold<double>(0, (a, r) => a + r.d('net'));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        Row(
          children: [
            MonthBar(
              year: controller.year,
              month: controller.month,
              onChanged: (y, m) => controller.setYearMonth(y, m),
            ),
            const Spacer(),
            if (controller.payrollRows.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total Net: ${money(totalNet)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            OutlinedButton.icon(
              onPressed: controller.payrollRows.isEmpty
                  ? null
                  : () => exportCsv(
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
                  'Net pay'
                ],
                [
                  for (final r in controller.payrollRows)
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
                    ]
                ],
              ),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Export CSV'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _generate(context),
              icon: const Icon(Icons.calculate_rounded, size: 16),
              label: const Text('Generate Payroll'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: controller.payrollRows.isEmpty
              ? const Center(
            child: Text(
              'No payroll records for this month.\nSet salaries on the Employees page, then press Generate Payroll.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          )
              : ListView.separated(
            itemCount: controller.payrollRows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final r = controller.payrollRows[index];
              return Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          r.s('code'),
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.s('name'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${r.s('department')}  •  Days: ${nf(r.d('paid_days'))}/${nf(r.d('working_days'))}',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
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
                            const SizedBox(height: 2),
                            Text(
                              'Gross: ${money(r.d('gross'))}',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Download Payslip PDF',
                        icon: const Icon(Icons.picture_as_pdf_outlined,
                            size: 20, color: Colors.redAccent),
                        onPressed: () => savePayslip(context, r),
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

class _MineTab extends StatelessWidget {
  const _MineTab({required this.controller});
  final PayrollController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mine = controller.payrollRows
        .where((r) => r.i('employee_id') == Session.empId)
        .toList();

    return Column(
      children: [
        Row(
          children: [
            MonthBar(
              year: controller.year,
              month: controller.month,
              onChanged: (y, m) =>
                  controller.setYearMonth(y, m, empId: Session.empId),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: mine.isEmpty
              ? const Center(child: Text('No payslips available for this month.'))
              : ListView.separated(
            itemCount: mine.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final r = mine[index];
              return Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.receipt_long_outlined,
                            size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monthLabel(r.s('month')),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Gross: ${money(r.d('gross'))}  •  Deductions: ${money(r.d('pf') + r.d('other_deduction'))}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            money(r.d('net')),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FilledButton.tonalIcon(
                            onPressed: () => savePayslip(context, r),
                            icon: const Icon(Icons.picture_as_pdf_outlined,
                                size: 14),
                            label: const Text('PDF',
                                style: TextStyle(fontSize: 11)),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 0),
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
