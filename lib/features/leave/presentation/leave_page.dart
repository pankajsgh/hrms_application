
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
  State<LeaveFeaturePage> createState() => _LeaveFeaturePageState();
}

class _LeaveFeaturePageState extends State<LeaveFeaturePage> {
  late final LeaveController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LeaveController();
    _controller.loadLeaveData(Session.empId, DateTime.now().year);
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
                    child: CircularProgressIndicator(strokeWidth: 2),
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
                    child: Text('You do not have access to this section.'),
                  );
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

// ============================================================================
// MY LEAVE
// ============================================================================

class _MyLeaveTab extends StatelessWidget {
  const _MyLeaveTab({required this.controller});

  final LeaveController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final pending =
        controller.leaves.where((e) => e.s('status') == 'Pending').length;
    final approved =
        controller.leaves.where((e) => e.s('status') == 'Approved').length;

    return RefreshIndicator(
      onRefresh: () => controller.loadLeaveData(
        Session.empId,
        DateTime.now().year,
      ),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Leave',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your leave and balances',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: controller.isSubmitting ? null : () => _apply(context),
                icon: const Icon(Icons.add, size: 17),
                label: Text(
                  controller.isSubmitting ? 'Wait...' : 'Apply Leave',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _SummaryCard(
                title: 'Requests',
                value: '${controller.leaves.length}',
                icon: Icons.event_note_outlined,
                color: cs.primary,
              ),
              _SummaryCard(
                title: 'Pending',
                value: '$pending',
                icon: Icons.hourglass_top_outlined,
                color: Colors.orange,
              ),
              _SummaryCard(
                title: 'Approved',
                value: '$approved',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 16),

          const _SectionHeader(
            title: 'Leave Balance',
            subtitle: 'Available leave days',
          ),

          const SizedBox(height: 8),

          if (controller.balances.isEmpty)
            const _EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No leave balance',
              subtitle: 'Your leave balances will appear here.',
            )
          else
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.balances.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return _BalanceCard(
                    balance: controller.balances[index],
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          _SectionHeader(
            title: 'My Requests',
            subtitle: 'Your leave applications',
            trailing: Text(
              '${controller.leaves.length} total',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.primary,
              ),
            ),
          ),

          const SizedBox(height: 8),

          if (controller.leaves.isEmpty)
            const _EmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'No leave requests',
              subtitle: 'Tap Apply Leave to submit a request.',
            )
          else
            ...controller.leaves.map(
                  (leave) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LeaveRequestCard(
                  leave: leave,
                  showEmployee: false,
                  onCancel: leave.s('status') == 'Pending'
                      ? () => _cancel(context, leave)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _apply(BuildContext context) async {
    final empId = Session.empId;

    if (empId == null) {
      toast(context, 'Employee session not found');
      return;
    }

    final types = controller.leaveTypes.isNotEmpty
        ? controller.leaveTypes
        : await LeaveRepository().leaveTypes();

    if (!context.mounted) return;

    if (types.isEmpty) {
      toast(context, 'No leave types available');
      return;
    }

    final reasonController = TextEditingController();

    String? selectedType;
    DateTime? fromDate;
    DateTime? toDate;

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final cs = Theme.of(context).colorScheme;

              Future<void> pickDate(bool isFrom) async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: isFrom
                      ? fromDate ?? DateTime.now()
                      : toDate ?? fromDate ?? DateTime.now(),
                  firstDate: isFrom
                      ? DateTime(2020)
                      : fromDate ?? DateTime(2020),
                  lastDate: DateTime(2100),
                );

                if (picked == null) return;

                setDialogState(() {
                  if (isFrom) {
                    fromDate = picked;
                    if (toDate != null && toDate!.isBefore(picked)) {
                      toDate = picked;
                    }
                  } else {
                    toDate = picked;
                  }
                });
              }

              Widget dateButton(
                  String label,
                  DateTime? date,
                  IconData icon,
                  VoidCallback onTap,
                  ) {
                return Expanded(
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 14, color: cs.primary),
                              const SizedBox(width: 5),
                              Text(
                                label,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            date == null
                                ? 'Select date'
                                : fmtDate(ymd(date)),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return AlertDialog(
                title: const Text(
                  'Apply for Leave',
                  style: TextStyle(fontSize: 17),
                ),
                content: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomDropdown<String>(
                          label: 'Leave Type',
                          value: selectedType,
                          icon: Icons.beach_access_outlined,
                          hint: 'Select leave type',
                          searchText: (id) {
                            final index = types.indexWhere(
                                  (e) => e.i('id').toString() == id,
                            );
                            return index == -1
                                ? id
                                : types[index].s('name');
                          },
                          items: [
                            for (final type in types)
                              if (type.i('id') != null)
                                DropdownMenuItem<String>(
                                  value: type.i('id').toString(),
                                  child: Text(
                                    type.s('name'),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                          ],
                          onChanged: (value) {
                            setDialogState(() => selectedType = value);
                          },
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          'Leave Duration',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 7),

                        Row(
                          children: [
                            dateButton(
                              'From',
                              fromDate,
                              Icons.calendar_today_outlined,
                                  () => pickDate(true),
                            ),
                            const SizedBox(width: 8),
                            dateButton(
                              'To',
                              toDate,
                              Icons.event_outlined,
                                  () => pickDate(false),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          'Reason',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 6),

                        TextField(
                          controller: reasonController,
                          minLines: 3,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Enter reason for leave',
                            hintStyle: TextStyle(fontSize: 12),
                            prefixIcon: Icon(Icons.notes_outlined, size: 18),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(10),
                          ),
                        ),
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
                      if (selectedType == null ||
                          fromDate == null ||
                          toDate == null ||
                          reasonController.text.trim().isEmpty) {
                        toast(context, 'Please complete all fields');
                        return;
                      }

                      if (toDate!.isBefore(fromDate!)) {
                        toast(context, 'Invalid leave dates');
                        return;
                      }

                      Navigator.pop(dialogContext, {
                        'type': selectedType,
                        'from': ymd(fromDate!),
                        'to': ymd(toDate!),
                        'reason': reasonController.text.trim(),
                      });
                    },
                    icon: const Icon(Icons.send_outlined, size: 16),
                    label: const Text('Submit'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == null || !context.mounted) return;

      final error = await controller.applyLeave(
        empId,
        int.parse(result['type'] as String),
        DateTime.parse(result['from'] as String),
        DateTime.parse(result['to'] as String),
        result['reason'] as String,
      );

      if (!context.mounted) return;

      toast(context, error ?? 'Leave request submitted successfully');
    } catch (e) {
      if (context.mounted) {
        toast(context, 'Unable to submit leave: $e');
      }
    } finally {
      reasonController.dispose();
    }
  }

  Future<void> _cancel(BuildContext context, Rec leave) async {
    final confirmed = await _confirm(
      context,
      'Cancel Leave',
      'Are you sure you want to cancel this leave request?',
    );

    if (confirmed != true || !context.mounted) return;

    final id = leave.i('id');
    final empId = Session.empId;

    if (id == null || empId == null) {
      toast(context, 'Invalid leave request');
      return;
    }

    final success = await controller.cancelLeave(id, empId);

    if (!context.mounted) return;

    toast(
      context,
      success ? 'Leave request cancelled' : 'Unable to cancel leave',
    );
  }
}

// ============================================================================
// APPROVALS
// ============================================================================

class _ApprovalsTab extends StatelessWidget {
  const _ApprovalsTab({required this.controller});

  final LeaveController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final pending =
        controller.approvalLeaves.where((e) => e.s('status') == 'Pending').length;

    return RefreshIndicator(
      onRefresh: () => controller.loadLeaveData(
        Session.empId,
        DateTime.now().year,
      ),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave Approvals',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'Review employee leave requests',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _SummaryCard(
                title: 'Pending',
                value: '$pending',
                icon: Icons.hourglass_top_outlined,
                color: Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 7,
            children: [
              ChoiceChip(
                label: const Text('Pending'),
                selected: controller.pendingOnlyApprovals,
                onSelected: (value) {
                  if (value) {
                    controller.setPendingOnlyApprovals(true, Session.empId);
                  }
                },
              ),
              ChoiceChip(
                label: const Text('All Requests'),
                selected: !controller.pendingOnlyApprovals,
                onSelected: (value) {
                  if (value) {
                    controller.setPendingOnlyApprovals(false, Session.empId);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (controller.approvalLeaves.isEmpty)
            const _EmptyState(
              icon: Icons.task_alt_outlined,
              title: 'No approval requests',
              subtitle: 'There are no requests to display.',
            )
          else
            ...controller.approvalLeaves.map(
                  (leave) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LeaveRequestCard(
                  leave: leave,
                  showEmployee: true,
                  onApprove: leave.s('status') == 'Pending'
                      ? () => _decide(context, leave, true)
                      : null,
                  onReject: leave.s('status') == 'Pending'
                      ? () => _decide(context, leave, false)
                      : null,
                ),
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

    final confirmed = await _confirm(
      context,
      '$action Leave',
      'Are you sure you want to $action this leave request?',
    );

    if (confirmed != true || !context.mounted) return;

    final success = await controller.decideLeave(
      leave,
      approve,
      Session.empId,
    );

    if (!context.mounted) return;

    toast(
      context,
      success
          ? (approve ? 'Leave approved' : 'Leave rejected')
          : 'Unable to process leave request',
    );
  }
}

// ============================================================================
// LEAVE SETUP
// ============================================================================

class _SetupTab extends StatelessWidget {
  const _SetupTab({required this.controller});

  final LeaveController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 850;

        if (!wide) {
          return ListView(
            padding: const EdgeInsets.all(10),
            children: [
              _leaveTypesPanel(context),
              const SizedBox(height: 10),
              _holidaysPanel(context),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _leaveTypesPanel(context)),
              const SizedBox(width: 10),
              Expanded(child: _holidaysPanel(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _leaveTypesPanel(BuildContext context) {
    return Panel(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _panelHeader(
              context,
              'Leave Types',
              'Employee leave categories',
              Icons.beach_access_outlined,
              onAdd: () => _editType(context),
            ),
            const Divider(height: 14),

            if (controller.leaveTypes.isEmpty)
              const _EmptyState(
                icon: Icons.category_outlined,
                title: 'No leave types',
                subtitle: 'Add a leave type to get started.',
              )
            else
              ...controller.leaveTypes.map(
                    (type) => ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 3),
                  leading: CircleAvatar(
                    radius: 15,
                    child: Icon(
                      type.i('paid') == 1
                          ? Icons.account_balance_wallet_outlined
                          : Icons.money_off_outlined,
                      size: 15,
                    ),
                  ),
                  title: Text(
                    type.s('name'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    '${nf(type.d('days_per_year'))} days/year · '
                        '${type.i('paid') == 1 ? 'Paid' : 'Unpaid'}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editType(context, type);
                      } else if (value == 'delete') {
                        _deleteType(context, type);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _holidaysPanel(BuildContext context) {
    return Panel(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _panelHeader(
                    context,
                    'Holidays',
                    'Company holidays',
                    Icons.calendar_month_outlined,
                    onAdd: () => _addHoliday(context),
                    showAdd: false,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Previous year',
                  onPressed: () {
                    controller.setHolidayYear(
                      controller.holidayYear - 1,
                      Session.empId,
                    );
                  },
                  icon: const Icon(Icons.chevron_left, size: 19),
                ),
                Text(
                  '${controller.holidayYear}',
                  style: const TextStyle(fontSize: 12),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Next year',
                  onPressed: () {
                    controller.setHolidayYear(
                      controller.holidayYear + 1,
                      Session.empId,
                    );
                  },
                  icon: const Icon(Icons.chevron_right, size: 19),
                ),
                IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Add holiday',
                  onPressed: () => _addHoliday(context),
                  icon: const Icon(Icons.add, size: 17),
                ),
              ],
            ),

            const Divider(height: 14),

            if (controller.holidays.isEmpty)
              const _EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No holidays',
                subtitle: 'No holidays configured for this year.',
              )
            else
              ...controller.holidays.map(
                    (holiday) => ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 3),
                  leading: const CircleAvatar(
                    radius: 15,
                    child: Icon(Icons.event_available_outlined, size: 15),
                  ),
                  title: Text(
                    holiday.s('name'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    fmtDate(holiday['date']),
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete holiday',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    onPressed: () => _deleteHoliday(context, holiday),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _panelHeader(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon, {
        required VoidCallback onAdd,
        bool showAdd = true,
      }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 19, color: theme.colorScheme.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (showAdd)
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 15),
            label: const Text(
              'Add',
              style: TextStyle(fontSize: 12),
            ),
          ),
      ],
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
          'Days per year',
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

    if (result == null || !context.mounted) return;

    try {
      final success = await controller.saveLeaveType(
        {
          'name': result['name'],
          'days_per_year': result['days'],
          'paid': int.parse(result['paid'].toString()),
        },
        id: type?.i('id'),
      );

      if (!context.mounted) return;

      toast(
        context,
        success
            ? (type == null ? 'Leave type added' : 'Leave type updated')
            : 'Unable to save leave type',
      );
    } catch (e) {
      if (context.mounted) {
        toast(context, 'Unable to save leave type: $e');
      }
    }
  }

  Future<void> _deleteType(BuildContext context, Rec type) async {
    final confirmed = await _confirm(
      context,
      'Delete Leave Type',
      'Delete "${type.s('name')}"?',
    );

    if (confirmed != true || !context.mounted) return;

    final id = type.i('id');

    if (id == null) {
      toast(context, 'Invalid leave type');
      return;
    }

    final error = await controller.deleteLeaveType(id);

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

    if (result == null || !context.mounted) return;

    final error = await controller.addHoliday(
      result['date'].toString(),
      result['name'].toString(),
    );

    if (!context.mounted) return;

    toast(context, error ?? 'Holiday added');
  }

  Future<void> _deleteHoliday(
      BuildContext context,
      Rec holiday,
      ) async {
    final confirmed = await _confirm(
      context,
      'Delete Holiday',
      'Delete "${holiday.s('name')}"?',
    );

    if (confirmed != true || !context.mounted) return;

    final id = holiday.i('id');

    if (id == null) {
      toast(context, 'Invalid holiday');
      return;
    }

    final success = await controller.deleteHoliday(id);

    if (!context.mounted) return;

    toast(
      context,
      success ? 'Holiday deleted' : 'Unable to delete holiday',
    );
  }
}

// ============================================================================
// LEAVE REQUEST CARD
// ============================================================================

class _LeaveRequestCard extends StatelessWidget {
  const _LeaveRequestCard({
    required this.leave,
    required this.showEmployee,
    this.onCancel,
    this.onApprove,
    this.onReject,
  });

  final Rec leave;
  final bool showEmployee;
  final VoidCallback? onCancel;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(
                    showEmployee
                        ? Icons.person_outline
                        : Icons.beach_access_outlined,
                    color: cs.onPrimaryContainer,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showEmployee
                            ? leave.s('emp_name')
                            : leave.s('type_name'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      if (showEmployee)
                        Text(
                          leave.s('type_name'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                StatusChip(leave.s('status')),
              ],
            ),

            const SizedBox(height: 9),

            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _InfoItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'From',
                  value: fmtDate(leave['start_date']),
                ),
                _InfoItem(
                  icon: Icons.event_outlined,
                  label: 'To',
                  value: fmtDate(leave['end_date']),
                ),
                _InfoItem(
                  icon: Icons.timelapse_outlined,
                  label: 'Duration',
                  value: '${nf(leave.d('days'))} days',
                ),
              ],
            ),

            if (leave.s('reason').isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  leave.s('reason'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],

            if (onCancel != null ||
                onApprove != null ||
                onReject != null) ...[
              const SizedBox(height: 7),
              const Divider(height: 1),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 5,
                runSpacing: 3,
                children: [
                  if (onCancel != null)
                    TextButton.icon(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.close, size: 15),
                      label: const Text('Cancel'),
                    ),
                  if (onReject != null)
                    TextButton.icon(
                      onPressed: onReject,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.close, size: 15),
                      label: const Text('Reject'),
                    ),
                  if (onApprove != null)
                    FilledButton.tonalIcon(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.check, size: 15),
                      label: const Text('Approve'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BALANCE CARD
// ============================================================================

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
      width: 195,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                balance.s('name'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    paid ? nf(remaining) : '—',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      paid ? 'days left' : 'unpaid',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (paid)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
              const SizedBox(height: 5),
              Text(
                paid
                    ? 'Used ${nf(used)} · Pending ${nf(pending)} · Total ${nf(total)}'
                    : 'Used ${nf(used)} · Pending ${nf(pending)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SUMMARY CARD
// ============================================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      width: 145,
      height: 62,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
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
}

// ============================================================================
// COMMON WIDGETS
// ============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: cs.primary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: style?.copyWith(color: cs.onSurfaceVariant),
        ),
        Text(
          value,
          style: style,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 25, color: cs.onSurfaceVariant),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CONFIRMATION DIALOG
// ============================================================================

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
          borderRadius: BorderRadius.circular(13),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13),
        ),
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
