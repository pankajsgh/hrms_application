
import 'package:flutter/material.dart';
import 'package:hrms/comman_widget/customer_dropdown.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import '../data/leave_repository.dart';
import 'leave_controller.dart';

class LeaveFeaturePage extends StatefulWidget {
  const LeaveFeaturePage({super.key});

  @override
  State<LeaveFeaturePage> createState() => LeaveFeaturePageState();
}

class LeaveFeaturePageState extends State<LeaveFeaturePage> {
  late final LeaveController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LeaveController()
      ..loadLeaveData(Session.empId, DateTime.now().year);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageBox(
      child: Column(
        children: [
          const Header('Leave Management'),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final titles = <String>[
                  if (Session.empId != null) 'My Leave',
                  if (Session.isLead) 'Approvals',
                  if (Session.isHr) 'Leave Setup',
                ];

                final tabs = <Widget>[
                  if (Session.empId != null)
                    _MyLeaveTab(controller: _controller),
                  if (Session.isLead)
                    _ApprovalsTab(controller: _controller),
                  if (Session.isHr)
                    _SetupTab(controller: _controller),
                ];

                if (tabs.isEmpty) {
                  return const Center(
                    child: Text(
                      'You do not have access to this section.',
                    ),
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

// =============================================================================
// MY LEAVE
// =============================================================================

class _MyLeaveTab extends StatelessWidget {
  const _MyLeaveTab({required this.controller});

  final LeaveController controller;

  Future<void> _apply(BuildContext context) async {
    final types = controller.leaveTypes.isNotEmpty
        ? controller.leaveTypes
        : await LeaveRepository().leaveTypes();

    if (!context.mounted) return;

    if (types.isEmpty) {
      toast(context, 'No leave types available');
      return;
    }

    final typeController = TextEditingController();
    final reasonController = TextEditingController();

    final typeNames = {
      for (final type in types)
        '${type['id']}': type.s('name'),
    };

    DateTime? fromDate;
    DateTime? toDate;
    String? error;

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          final cs = theme.colorScheme;

          return StatefulBuilder(
            builder: (context, setState) {
              Future<void> pickDate(bool isFrom) async {
                final initialDate = isFrom
                    ? fromDate ?? DateTime.now()
                    : toDate ?? fromDate ?? DateTime.now();

                final picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: isFrom
                      ? DateTime(2020)
                      : fromDate ?? DateTime(2020),
                  lastDate: DateTime(2100),
                );

                if (picked == null) return;

                setState(() {
                  if (isFrom) {
                    fromDate = picked;

                    if (toDate != null && toDate!.isBefore(picked)) {
                      toDate = picked;
                    }
                  } else {
                    toDate = picked;
                  }

                  error = null;
                });
              }

              InputDecoration inputDecoration(
                  String label,
                  IconData icon,
                  ) {
                return InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon, size: 19),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: cs.primary,
                      width: 1.4,
                    ),
                  ),
                );
              }

              Widget sectionTitle(String title) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              Widget dateField({
                required String label,
                required DateTime? date,
                required IconData icon,
                required VoidCallback onTap,
              }) {
                return InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: inputDecoration(label, icon),
                    child: Text(
                      date == null ? 'Select date' : fmtDate(ymd(date)),
                      style: TextStyle(
                        fontSize: 13,
                        color: date == null
                            ? cs.onSurfaceVariant
                            : cs.onSurface,
                        fontWeight: date == null
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }

              return AlertDialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
                contentPadding: const EdgeInsets.fromLTRB(22, 10, 22, 8),
                actionsPadding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.event_available_rounded,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apply for Leave',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Enter your leave details below',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
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
                        sectionTitle('Leave Information'),

                        CustomDropdown<String>(
                          label: 'Leave Type',
                          value: typeController.text.isEmpty
                              ? null
                              : typeController.text,
                          icon: Icons.beach_access_outlined,
                          hint: 'Select leave type',
                          searchText: (id) => typeNames[id] ?? id,
                          items: [
                            for (final type in types)
                              DropdownMenuItem<String>(
                                value: '${type['id']}',
                                child: Text(type.s('name')),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              typeController.text = value ?? '';
                              error = null;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        sectionTitle('Leave Duration'),

                        Row(
                          children: [
                            Expanded(
                              child: dateField(
                                label: 'From Date',
                                date: fromDate,
                                icon: Icons.calendar_today_outlined,
                                onTap: () => pickDate(true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: dateField(
                                label: 'To Date',
                                date: toDate,
                                icon: Icons.event_outlined,
                                onTap: () => pickDate(false),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        sectionTitle('Reason'),

                        TextField(
                          controller: reasonController,
                          minLines: 3,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: inputDecoration(
                            'Enter reason for leave',
                            Icons.notes_rounded,
                          ),
                        ),

                        if (error != null) ...[
                          const SizedBox(height: 13),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.errorContainer.withValues(
                                alpha: 0.45,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: cs.error,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    error!,
                                    style: TextStyle(
                                      color: cs.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      if (typeController.text.isEmpty) {
                        setState(() {
                          error = 'Please select a leave type';
                        });
                        return;
                      }

                      if (fromDate == null || toDate == null) {
                        setState(() {
                          error = 'Please select both dates';
                        });
                        return;
                      }

                      if (toDate!.isBefore(fromDate!)) {
                        setState(() {
                          error = 'To date cannot be before from date';
                        });
                        return;
                      }

                      Navigator.pop(dialogContext, {
                        'type': typeController.text,
                        'from': ymd(fromDate!),
                        'to': ymd(toDate!),
                        'reason': reasonController.text.trim(),
                      });
                    },
                    icon: const Icon(Icons.send_rounded, size: 17),
                    label: const Text('Submit Request'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == null) return;

      final err = await controller.applyLeave(
        Session.empId!,
        int.parse(result['type'] as String),
        DateTime.parse(result['from'] as String),
        DateTime.parse(result['to'] as String),
        result['reason'] as String,
      );

      if (!context.mounted) return;

      toast(context, err ?? 'Leave request submitted');
    } finally {
      typeController.dispose();
      reasonController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Leave Balance',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Track your available leave days',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _apply(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Apply Leave'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Balance cards
          SizedBox(
            height: 112,
            child: controller.balances.isEmpty
                ? _emptyMessage(
              context,
              'No leave balances available',
            )
                : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.balances.length,
              separatorBuilder: (_, __) =>
              const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _BalanceCard(
                  balance: controller.balances[index],
                );
              },
            ),
          ),

          const SizedBox(height: 22),

          // Requests heading
          Row(
            children: [
              Expanded(
                child: Text(
                  'My Leave Requests',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _CountBadge(count: controller.leaves.length),
            ],
          ),

          const SizedBox(height: 12),

          // Requests table
          Expanded(
            child: TableCard(
              columns: const [
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('From')),
                DataColumn(label: Text('To')),
                DataColumn(label: Text('Days'), numeric: true),
                DataColumn(label: Text('Reason')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Action')),
              ],
              rows: [
                for (final leave in controller.leaves)
                  DataRow(
                    cells: [
                      DataCell(Text(leave.s('type_name'))),
                      DataCell(Text(fmtDate(leave['start_date']))),
                      DataCell(Text(fmtDate(leave['end_date']))),
                      DataCell(Text(nf(leave.d('days')))),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            leave.s('reason'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(StatusChip(leave.s('status'))),
                      DataCell(
                        leave.s('status') == 'Pending'
                            ? IconButton(
                          tooltip: 'Cancel request',
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.red,
                          ),
                          onPressed: () => _cancel(context, leave),
                        )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
              ],
              empty: 'No leave requests yet.',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, Rec leave) async {
    final confirm = await _confirm(
      context,
      'Cancel Leave',
      'Are you sure you want to cancel this leave request?',
    );

    if (confirm != true) return;

    final id = leave.i('id');

    if (id == null || Session.empId == null) {
      if (!context.mounted) return;
      toast(context, 'Unable to cancel leave request');
      return;
    }

    final success = await controller.cancelLeave(
      id,
      Session.empId,
    );

    if (!context.mounted) return;

    toast(
      context,
      success
          ? 'Leave request cancelled successfully'
          : 'Failed to cancel leave request',
    );
  }
}

// =============================================================================
// LEAVE BALANCE CARD
// =============================================================================

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final Rec balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final paid = balance.i('paid') == 1;
    final total = balance.d('days_per_year');
    final used = balance.d('used');
    final pending = balance.d('pending');

    final remaining = (total - used - pending)
        .clamp(0.0, double.infinity)
        .toDouble();

    final progress = total > 0
        ? (remaining / total).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return SizedBox(
      width: 220,
      child: Panel(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      balance.s('name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    paid ? '${nf(remaining)} left' : 'Unpaid',
                    style: TextStyle(
                      color: paid ? cs.primary : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (paid)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
              const SizedBox(height: 9),
              Text(
                paid
                    ? 'Total ${nf(total)}  ·  Used ${nf(used)}  ·  Pending ${nf(pending)}'
                    : 'Used ${nf(used)}  ·  Pending ${nf(pending)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// APPROVALS
// =============================================================================

class _ApprovalsTab extends StatelessWidget {
  const _ApprovalsTab({required this.controller});

  final LeaveController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              ChoiceChip(
                label: const Text('Pending'),
                selected: controller.pendingOnlyApprovals,
                onSelected: (_) {
                  controller.setPendingOnlyApprovals(
                    true,
                    Session.empId,
                  );
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('All Requests'),
                selected: !controller.pendingOnlyApprovals,
                onSelected: (_) {
                  controller.setPendingOnlyApprovals(
                    false,
                    Session.empId,
                  );
                },
              ),
              const Spacer(),
              _CountBadge(
                count: controller.approvalLeaves.length,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: TableCard(
              columns: const [
                DataColumn(label: Text('Employee')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('From')),
                DataColumn(label: Text('To')),
                DataColumn(label: Text('Days'), numeric: true),
                DataColumn(label: Text('Reason')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Action')),
              ],
              rows: [
                for (final leave in controller.approvalLeaves)
                  DataRow(
                    cells: [
                      DataCell(Text(leave.s('emp_name'))),
                      DataCell(Text(leave.s('type_name'))),
                      DataCell(Text(fmtDate(leave['start_date']))),
                      DataCell(Text(fmtDate(leave['end_date']))),
                      DataCell(Text(nf(leave.d('days')))),
                      DataCell(
                        SizedBox(
                          width: 140,
                          child: Text(
                            leave.s('reason'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(StatusChip(leave.s('status'))),
                      DataCell(
                        leave.s('status') == 'Pending'
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Approve',
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                              onPressed: () {
                                _decide(context, leave, true);
                              },
                            ),
                            IconButton(
                              tooltip: 'Reject',
                              icon: const Icon(
                                Icons.cancel_outlined,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                _decide(context, leave, false);
                              },
                            ),
                          ],
                        )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
              ],
              empty: 'No leave requests.',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _decide(
      BuildContext context,
      Rec leave,
      bool approve,
      ) async {
    final action = approve ? 'Approve' : 'Reject';

    final confirm = await _confirm(
      context,
      '$action Leave',
      'Are you sure you want to $action the leave request from ${leave.s('emp_name')}?',
    );

    if (confirm != true) return;

    await controller.decideLeave(
      leave,
      approve,
      Session.empId,
    );

    if (!context.mounted) return;

    toast(
      context,
      approve ? 'Leave approved' : 'Leave rejected',
    );
  }
}

// =============================================================================
// LEAVE SETUP
// =============================================================================

class _SetupTab extends StatelessWidget {
  const _SetupTab({required this.controller});

  final LeaveController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 850;

        if (compact) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _leaveTypesPanel(context, compact: true),
                const SizedBox(height: 16),
                _holidaysPanel(context, compact: true),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _leaveTypesPanel(context),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _holidaysPanel(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _leaveTypesPanel(
      BuildContext context, {
        bool compact = false,
      }) {
    return SizedBox(
      height: compact ? 340 : null,
      child: Panel(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Leave Types',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _editType(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _leaveTypesTable(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leaveTypesTable(BuildContext context) {
    return TableCard(
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Days/Yr'), numeric: true),
        DataColumn(label: Text('Paid')),
        DataColumn(label: Text('Actions')),
      ],
      rows: [
        for (final type in controller.leaveTypes)
          DataRow(
            cells: [
              DataCell(Text(type.s('name'))),
              DataCell(Text(nf(type.d('days_per_year')))),
              DataCell(
                Text(type.i('paid') == 1 ? 'Paid' : 'Unpaid'),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editType(context, type),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteType(context, type),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
      empty: 'No leave types available.',
    );
  }

  Widget _holidaysPanel(
      BuildContext context, {
        bool compact = false,
      }) {
    return SizedBox(
      height: compact ? 340 : null,
      child: Panel(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Holidays',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Previous year',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      controller.setHolidayYear(
                        controller.holidayYear - 1,
                        Session.empId,
                      );
                    },
                  ),
                  Text(
                    '${controller.holidayYear}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next year',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      controller.setHolidayYear(
                        controller.holidayYear + 1,
                        Session.empId,
                      );
                    },
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _addHoliday(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _holidaysTable(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _holidaysTable(BuildContext context) {
    return TableCard(
      columns: const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Holiday')),
        DataColumn(label: Text('Action')),
      ],
      rows: [
        for (final holiday in controller.holidays)
          DataRow(
            cells: [
              DataCell(Text(fmtDate(holiday['date']))),
              DataCell(Text(holiday.s('name'))),
              DataCell(
                IconButton(
                  tooltip: 'Delete holiday',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  onPressed: () => _deleteHoliday(context, holiday),
                ),
              ),
            ],
          ),
      ],
      empty: 'No holidays for ${controller.holidayYear}.',
    );
  }

  Future<void> _editType(
      BuildContext context, [
        Rec? type,
      ]) async {
    final result = await formDialog(
      context,
      type == null ? 'Add Leave Type' : 'Edit Leave Type',
      [
        F(
          'name',
          'Name',
          required: true,
          initial: type?['name'],
        ),
        F(
          'days',
          'Days per year (0 = unlimited for unpaid)',
          type: 'number',
          required: true,
          initial: type?['days_per_year'] ?? 0,
        ),
        F(
          'paid',
          'Paid?',
          type: 'dropdown',
          required: true,
          options: const {
            '1': 'Paid',
            '0': 'Unpaid',
          },
          initial: '${type?['paid'] ?? 1}',
        ),
      ],
    );

    if (result == null) return;

    try {
      await controller.saveLeaveType(
        {
          'name': result['name'],
          'days_per_year': result['days'],
          'paid': int.parse(result['paid'] as String),
        },
        id: type?.i('id'),
      );

      if (context.mounted) {
        toast(
          context,
          type == null ? 'Leave type added' : 'Leave type updated',
        );
      }
    } catch (_) {
      if (context.mounted) {
        toast(
          context,
          'A leave type with that name already exists',
        );
      }
    }
  }

  Future<void> _deleteType(
      BuildContext context,
      Rec type,
      ) async {
    final confirm = await _confirm(
      context,
      'Delete Leave Type',
      'Delete "${type.s('name')}"?',
    );

    if (confirm != true) return;

    final error = await controller.deleteLeaveType(
      type.i('id')!,
    );

    if (!context.mounted) return;

    toast(context, error ?? 'Leave type deleted');
  }

  Future<void> _addHoliday(BuildContext context) async {
    final result = await formDialog(
      context,
      'Add Holiday',
      const [
        F('date', 'Date', type: 'date', required: true),
        F('name', 'Holiday Name', required: true),
      ],
    );

    if (result == null) return;

    final error = await controller.addHoliday(
      result['date'] as String,
      result['name'] as String,
    );

    if (!context.mounted) return;

    toast(context, error ?? 'Holiday added');
  }

  Future<void> _deleteHoliday(
      BuildContext context,
      Rec holiday,
      ) async {
    final confirm = await _confirm(
      context,
      'Delete Holiday',
      'Delete "${holiday.s('name')}"?',
    );

    if (confirm != true) return;

    await controller.deleteHoliday(
      holiday.i('id')!,
    );

    if (!context.mounted) return;

    toast(context, 'Holiday deleted');
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count requests',
        style: TextStyle(
          color: cs.onSecondaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Widget _emptyMessage(BuildContext context, String message) {
  return Center(
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

// =============================================================================
// CONFIRMATION DIALOG
// =============================================================================

Future<bool?> _confirm(
    BuildContext context,
    String title,
    String message,
    ) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );
}
