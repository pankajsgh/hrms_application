import 'package:flutter/material.dart';

import 'package:hrms/core/ui.dart';
import '../../employees/data/employees_repository.dart';
import '../data/special_days_repository.dart';
import 'special_days_controller.dart';

Future<bool> showSpecialDayForm(BuildContext context,
    {Rec? existing, int? empId}) async {
  final emps = await EmployeesRepository().employees(activeOnly: true);
  if (!context.mounted) return false;
  final r = await formDialog(
      context, existing == null ? 'Add special day' : 'Edit special day', [
    F('emp', 'Employee',
        type: 'dropdown',
        required: true,
        options: {for (final e in emps) '${e['id']}': e.s('name')},
        initial: existing?['employee_id'] ?? empId),
    F('kind', 'Type',
        type: 'dropdown',
        required: true,
        options: opts(kSpecialKinds),
        initial: existing?['kind'] ?? 'Birthday'),
    F('title', 'Title (optional, e.g. 30th birthday)',
        initial: existing?['title']),
    F('date', 'Date (birth date, joining date or event date)',
        type: 'date', required: true, initial: existing?['date']),
    F('yearly', 'Repeats',
        type: 'dropdown',
        required: true,
        options: const {'1': 'Every year', '0': 'One time only'},
        initial: '${existing?['yearly'] ?? 1}'),
  ]);
  if (r == null) return false;
  await SpecialDaysRepository().saveSpecialDay({
    'employee_id': int.parse(r['emp'] as String),
    'kind': r['kind'],
    'title': r['title'],
    'date': r['date'],
    'yearly': int.parse(r['yearly'] as String),
  }, id: existing?.i('id'));
  return true;
}

IconData specialIcon(String kind) {
  switch (kind) {
    case 'Birthday':
      return Icons.cake_outlined;
    case 'Work Anniversary':
      return Icons.work_outline;
    case 'Wedding Anniversary':
      return Icons.favorite_border;
    default:
      return Icons.star_outline;
  }
}

class SpecialDaysFeaturePage extends StatefulWidget {
  const SpecialDaysFeaturePage({super.key});

  @override
  State<SpecialDaysFeaturePage> createState() => SpecialDaysFeaturePageState();
}

class SpecialDaysFeaturePageState extends State<SpecialDaysFeaturePage> {
  late final SpecialDaysController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SpecialDaysController()..loadSpecialDays();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _edit([Rec? s]) async {
    if (await showSpecialDayForm(context, existing: s)) {
      _controller.loadSpecialDays();
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 800;
    final add = FilledButton.icon(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: Text(narrow ? 'Add' : 'Add special day'));

    return PageBox(
      child: Column(children: [
        Header('Special days (MVVM)', actions: [add]),
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => Row(children: [
                for (final k in ['All', ...kSpecialKinds])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(k),
                      selected: _controller.selectedKind == k,
                      onSelected: (_) => _controller.setSelectedKind(k),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
            'Upcoming special days (next 30 days) appear on everyone’s dashboard, like holidays.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Expanded(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = _controller.specialDays
                  .where((r) =>
                      _controller.selectedKind == 'All' ||
                      r.s('kind') == _controller.selectedKind)
                  .toList();
              return TableCard(
                columns: const [
                  DataColumn(label: Text('Employee')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Repeats')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  for (final s in list)
                    DataRow(cells: [
                      DataCell(Text(s.s('emp_name'))),
                      DataCell(Row(children: [
                        Icon(specialIcon(s.s('kind')), size: 18),
                        const SizedBox(width: 6),
                        Text(s.s('kind')),
                      ])),
                      DataCell(Text(s.s('title'))),
                      DataCell(Text(fmtDate(s['date']))),
                      DataCell(
                          Text(s.i('yearly') == 1 ? 'Every year' : 'One time')),
                      DataCell(Row(children: [
                        IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _edit(s)),
                        IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              if (await confirm(
                                  context,
                                  'Delete special day?',
                                  '${s.s('emp_name')} — ${s.s('kind')}')) {
                                await _controller.deleteSpecialDay(s.i('id')!);
                              }
                            }),
                      ])),
                    ]),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}
