import 'package:flutter/material.dart';
import 'package:hrms/features/employees/data/employees_repository.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import 'performance_controller.dart';

class PerformanceFeaturePage extends StatefulWidget {
  const PerformanceFeaturePage({super.key});

  @override
  State<PerformanceFeaturePage> createState() => PerformanceFeaturePageState();
}

class PerformanceFeaturePageState extends State<PerformanceFeaturePage> {
  late final PerformanceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PerformanceController()..loadPerformance();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageBox(
      child: Column(children: [
        const Header('Performance (MVVM)'),
        Expanded(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return TabsView(
                titles: const ['Goals', 'Reviews'],
                children: [
                  _GoalsTab(controller: _controller),
                  _ReviewsTab(controller: _controller),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _GoalsTab extends StatelessWidget {
  const _GoalsTab({required this.controller});
  final PerformanceController controller;

  Future<void> _edit(BuildContext context, [Rec? g]) async {
    final emps = await EmployeesRepository().scopeEmployees();
    if (!context.mounted) return;
    final r = await formDialog(
        context, g == null ? 'New goal' : 'Edit goal', [
      F('emp', 'Employee',
          type: 'dropdown',
          required: true,
          options: {for (final e in emps) '${e['id']}': e.s('name')},
          initial: g?['employee_id'] ?? Session.empId),
      F('title', 'Goal', required: true, initial: g?['title']),
      F('description', 'Details', type: 'multiline', initial: g?['description']),
      F('due', 'Due date', type: 'date', initial: g?['due_date']),
      F('progress', 'Progress %',
          type: 'number', required: true, initial: g?['progress'] ?? 0),
      F('status', 'Status',
          type: 'dropdown',
          required: true,
          options: const {
            'In Progress': 'In Progress',
            'Completed': 'Completed',
            'On Hold': 'On Hold',
          },
          initial: g?['status'] ?? 'In Progress'),
    ]);
    if (r == null) return;
    await controller.saveGoal({
      'employee_id': int.parse(r['emp'] as String),
      'title': r['title'],
      'description': r['description'],
      'due_date': r['due'],
      'progress': ((r['progress'] as num?) ?? 0).clamp(0, 100).toInt(),
      'status': r['status'],
    }, id: g?.i('id'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: const Text('New goal')),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: TableCard(
          columns: const [
            DataColumn(label: Text('Employee')),
            DataColumn(label: Text('Goal')),
            DataColumn(label: Text('Due')),
            DataColumn(label: Text('Progress')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('')),
          ],
          rows: [
            for (final g in controller.goals)
              DataRow(cells: [
                DataCell(Text(g.s('emp_name'))),
                DataCell(Text(g.s('title'))),
                DataCell(Text(fmtDate(g['due_date']))),
                DataCell(Row(children: [
                  SizedBox(
                      width: 90,
                      child: LinearProgressIndicator(
                          value: (g.i('progress') ?? 0) / 100)),
                  const SizedBox(width: 8),
                  Text('${g.i('progress')}%'),
                ])),
                DataCell(StatusChip(g.s('status'))),
                DataCell(Row(children: [
                  IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _edit(context, g)),
                  IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (await confirm(context, 'Delete goal?', g.s('title'))) {
                          await controller.deleteGoal(g.i('id')!);
                        }
                      }),
                ])),
              ]),
          ],
          empty: 'No goals yet.',
        ),
      ),
    ]);
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.controller});
  final PerformanceController controller;

  Future<void> _add(BuildContext context) async {
    final emps = (await EmployeesRepository().scopeEmployees())
        .where((e) => Session.isAdmin || e['id'] != Session.empId)
        .toList();
    if (!context.mounted) return;
    final r = await formDialog(context, 'New performance review', [
      F('emp', 'Employee',
          type: 'dropdown',
          required: true,
          options: {for (final e in emps) '${e['id']}': e.s('name')}),
      const F('period', 'Review period (e.g. Q3 2026)', required: true),
      F('rating', 'Rating',
          type: 'dropdown',
          required: true,
          options: const {
            '5': '5 - Outstanding',
            '4': '4 - Exceeds expectations',
            '3': '3 - Meets expectations',
            '2': '2 - Needs improvement',
            '1': '1 - Unsatisfactory',
          },
          initial: '3'),
      const F('strengths', 'Strengths', type: 'multiline'),
      const F('improvements', 'Areas to improve', type: 'multiline'),
      const F('comments', 'Overall comments', type: 'multiline'),
    ]);
    if (r == null) return;
    await controller.saveReview({
      'employee_id': int.parse(r['emp'] as String),
      'reviewer_id': Session.empId,
      'period': r['period'],
      'rating': int.parse(r['rating'] as String),
      'strengths': r['strengths'],
      'improvements': r['improvements'],
      'comments': r['comments'],
      'created_on': ymd(DateTime.now()),
    });
  }

  void _view(BuildContext context, Rec r) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${r.s('emp_name')} — ${r.s('period')}'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rating: ${r.i('rating')} / 5'),
                  const SizedBox(height: 8),
                  Text('Strengths',
                      style: Theme.of(ctx).textTheme.titleSmall),
                  Text(r.s('strengths')),
                  const SizedBox(height: 8),
                  Text('Areas to improve',
                      style: Theme.of(ctx).textTheme.titleSmall),
                  Text(r.s('improvements')),
                  const SizedBox(height: 8),
                  Text('Comments',
                      style: Theme.of(ctx).textTheme.titleSmall),
                  Text(r.s('comments')),
                  const SizedBox(height: 8),
                  Text(
                      'Reviewed by ${r.s('reviewer_name')} on ${fmtDate(r['created_on'])}'),
                ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (Session.isLead)
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add),
              label: const Text('New review')),
        ),
      const SizedBox(height: 8),
      Expanded(
        child: TableCard(
          columns: const [
            DataColumn(label: Text('Employee')),
            DataColumn(label: Text('Period')),
            DataColumn(label: Text('Rating')),
            DataColumn(label: Text('Reviewer')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('')),
          ],
          rows: [
            for (final r in controller.reviews)
              DataRow(cells: [
                DataCell(Text(r.s('emp_name'))),
                DataCell(Text(r.s('period'))),
                DataCell(Text('★' * (r.i('rating') ?? 0))),
                DataCell(Text(r.s('reviewer_name'))),
                DataCell(Text(fmtDate(r['created_on']))),
                DataCell(Row(children: [
                  IconButton(
                      tooltip: 'View',
                      icon: const Icon(Icons.visibility_outlined),
                      onPressed: () => _view(context, r)),
                  if (Session.isHr)
                    IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => controller.deleteReview(r.i('id')!)),
                ])),
              ]),
          ],
          empty: 'No reviews yet.',
        ),
      ),
    ]);
  }
}
