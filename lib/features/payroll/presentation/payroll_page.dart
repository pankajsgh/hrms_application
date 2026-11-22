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
      if (Session.isHr) 'Run payroll',
      if (Session.empId != null) 'My payslips',
    ];
    final tabs = <Widget>[
      if (Session.isHr) _RunTab(controller: _controller),
      if (Session.empId != null) _MineTab(controller: _controller),
    ];
    return PageBox(
      child: Column(children: [
        const Header('Payroll'),
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
      ]),
    );
  }
}

class _RunTab extends StatelessWidget {
  const _RunTab({required this.controller});
  final PayrollController controller;

  Future<void> _generate(BuildContext context) async {
    final ok = await confirm(
        context,
        'Generate payroll',
        'Generate payroll for ${monthLabel(monthKey(controller.year, controller.month))}? '
            'Existing payroll for this month will be recalculated.\n\n'
            'Tip: run it after the month ends and attendance is complete. '
            'Weekdays without a record count as unpaid.');
    if (!ok) return;
    final n = await controller.runPayroll(controller.year, controller.month);
    if (!context.mounted) return;
    toast(
        context,
        n == 0
            ? 'No active employees with a salary set'
            : 'Payroll generated for $n employees');
  }

  @override
  Widget build(BuildContext context) {
    final totalNet = controller.payrollRows.fold<double>(0, (a, r) => a + r.d('net'));
    return Column(children: [
      Row(children: [
        MonthBar(
            year: controller.year,
            month: controller.month,
            onChanged: (y, m) => controller.setYearMonth(y, m)),
        const Spacer(),
        if (controller.payrollRows.isNotEmpty)
          Text('Total net pay: ${money(totalNet)}   '),
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
          icon: const Icon(Icons.download),
          label: const Text('Export CSV'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
            onPressed: () => _generate(context),
            icon: const Icon(Icons.calculate),
            label: const Text('Generate payroll')),
      ]),
      const SizedBox(height: 8),
      Expanded(
        child: TableCard(
          columns: const [
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Employee')),
            DataColumn(label: Text('Working'), numeric: true),
            DataColumn(label: Text('Paid'), numeric: true),
            DataColumn(label: Text('Gross'), numeric: true),
            DataColumn(label: Text('PF'), numeric: true),
            DataColumn(label: Text('Other'), numeric: true),
            DataColumn(label: Text('Net pay'), numeric: true),
            DataColumn(label: Text('')),
          ],
          rows: [
            for (final r in controller.payrollRows)
              DataRow(cells: [
                DataCell(Text(r.s('code'))),
                DataCell(Text(r.s('name'))),
                DataCell(Text('${nf(r.d('working_days'))}')),
                DataCell(Text('${nf(r.d('paid_days'))}')),
                DataCell(Text(money(r.d('gross')))),
                DataCell(Text(money(r.d('pf')))),
                DataCell(Text(money(r.d('other_deduction')))),
                DataCell(Text(money(r.d('net')))),
                DataCell(IconButton(
                    tooltip: 'Download payslip PDF',
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    onPressed: () => savePayslip(context, r))),
              ]),
          ],
          empty: 'No payroll for this month. Set salaries on the Employees '
              'page, then press Generate payroll.',
        ),
      ),
    ]);
  }
}

class _MineTab extends StatelessWidget {
  const _MineTab({required this.controller});
  final PayrollController controller;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        MonthBar(
            year: controller.year,
            month: controller.month,
            onChanged: (y, m) => controller.setYearMonth(y, m, empId: Session.empId)),
      ]),
      const SizedBox(height: 8),
      Expanded(
        child: TableCard(
          columns: const [
            DataColumn(label: Text('Month')),
            DataColumn(label: Text('Gross'), numeric: true),
            DataColumn(label: Text('Deductions'), numeric: true),
            DataColumn(label: Text('Net pay'), numeric: true),
            DataColumn(label: Text('')),
          ],
          rows: [
            for (final r in controller.payrollRows)
              if (r.i('employee_id') == Session.empId)
                DataRow(cells: [
                  DataCell(Text(monthLabel(r.s('month')))),
                  DataCell(Text(money(r.d('gross')))),
                  DataCell(Text(money(r.d('pf') + r.d('other_deduction')))),
                  DataCell(Text(money(r.d('net')))),
                  DataCell(IconButton(
                      tooltip: 'Download payslip PDF',
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      onPressed: () => savePayslip(context, r))),
                ]),
          ],
          empty: 'No payslips for this month.',
        ),
      ),
    ]);
  }
}
