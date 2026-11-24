
import 'package:flutter/material.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/data/global_data.dart';
import 'package:hrms/domain/entities/special_day_entity.dart';
import 'special_days_controller.dart';

Future<bool> showSpecialDayForm(
    BuildContext context,
    SpecialDaysController controller, {
      Rec? existing,
      int? empId,
    }) async {
  final r = await formDialog(
    context,
    existing == null ? 'Add special day' : 'Edit special day',
    [
      F(
        'emp',
        'Employee',
        type: 'dropdown',
        required: true,
        options: {
          for (final e in controller.activeEmployees)
            '${e.id}': e.name,
        },
        initial: existing?['employee_id']?.toString() ??
            (empId != null ? '$empId' : null),
      ),
      F(
        'kind',
        'Type',
        type: 'dropdown',
        required: true,
        options: opts(kSpecialKinds),
        initial: existing?['kind'] ?? 'Birthday',
      ),
      F(
        'title',
        'Title (optional, e.g. 30th birthday)',
        initial: existing?['title'],
      ),
      F(
        'date',
        'Date (birth date, joining date or event date)',
        type: 'date',
        required: true,
        initial: existing?['date'],
      ),
      F(
        'yearly',
        'Repeats',
        type: 'dropdown',
        required: true,
        options: const {
          '1': 'Every year',
          '0': 'One time only',
        },
        initial: '${existing?['yearly'] ?? 1}',
      ),
    ],
  );

  if (r == null) return false;

  await controller.saveSpecialDay(
    {
      'employee_id': int.parse(r['emp'] as String),
      'kind': r['kind'],
      'title': r['title'],
      'date': r['date'],
      'yearly': int.parse(r['yearly'] as String),
    },
    id: existing?.i('id'),
  );

  return true;
}

IconData specialIcon(String kind) {
  switch (kind.trim().toLowerCase()) {
    case 'birthday':
      return Icons.cake_outlined;
    case 'work anniversary':
      return Icons.work_outline;
    case 'wedding anniversary':
      return Icons.favorite_border;
    default:
      return Icons.star_outline;
  }
}

class SpecialDaysFeaturePage extends StatefulWidget {
  const SpecialDaysFeaturePage({super.key});

  @override
  State<SpecialDaysFeaturePage> createState() =>
      SpecialDaysFeaturePageState();
}

class SpecialDaysFeaturePageState extends State<SpecialDaysFeaturePage> {
  late final SpecialDaysController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SpecialDaysController();
    _controller.loadSpecialDays();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _edit([SpecialDayEntity? specialDay]) async {
    final result = await showSpecialDayForm(
      context,
      _controller,
      existing: specialDay?.toMap(),
    );

    if (!mounted) return;

    if (result) {
      await _controller.loadSpecialDays();
    }
  }
  Future<void> _delete(dynamic specialDay) async {
    final confirmed = await confirm(
      context,
      'Delete special day?',
      '${specialDay.s('emp_name')} — ${specialDay.s('kind')}',
    );

    if (!confirmed || !mounted) return;

    await _controller.deleteSpecialDay(
      specialDay.i('id')!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 800;

    final addButton = FilledButton.icon(
      onPressed: () => _edit(),
      icon: const Icon(Icons.add),
      label: Text(narrow ? 'Add' : 'Add special day'),
    );

    return PageBox(
      child: Column(
        children: [
          Header(
            'Special days',
            actions: [addButton],
          ),

          // Category filters
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return Row(
                    children: [
                      for (final kind in [
                        'All',
                        ...kSpecialKinds,
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(kind),
                            selected:
                            _controller.selectedKind == kind,
                            onSelected: (_) =>
                                _controller.setSelectedKind(kind),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Upcoming special days (next 30 days) appear on everyone’s dashboard, like holidays.',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: 8),

          // Special days table
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_controller.error!),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _controller.loadSpecialDays,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final list = _controller.filteredSpecialDays;

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          size: 42,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No special days found',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

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
                      DataRow(
                        cells: [
                          DataCell(
                            Text(s.s('emp_name')),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  specialIcon(s.s('kind')),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(s.s('kind')),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(s.s('title')),
                          ),
                          DataCell(
                            Text(fmtDate(s['date'])),
                          ),
                          DataCell(
                            Text(
                              s.i('yearly') == 1
                                  ? 'Every year'
                                  : 'One time',
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                  ),
                                  onPressed: () => _edit(s),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                  ),
                                  onPressed: () => _delete(s),
                                ),
                              ],
                            ),
                          ),
                        ],
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
