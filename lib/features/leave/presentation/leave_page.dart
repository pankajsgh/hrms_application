import 'package:flutter/material.dart';
import 'package:hrms/comman_widget/customer_dropdown.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/domain/entities/leave_entity.dart';

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
                  return const _EmptyState(
                    icon: Icons.lock_outline,
                    title: 'Access unavailable',
                    subtitle: 'You do not have access to this section.',
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
    final rejected =
        controller.leaves.where((e) => e.s('status') == 'Rejected').length;

    return RefreshIndicator(
      onRefresh: () => controller.loadLeaveData(
        Session.empId,
        DateTime.now().year,
      ),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(10),
        children: [
          _WelcomeCard(
            title: 'My Requests',
            subtitle: 'Apply for leaves, work from home, or field work',
            icon: Icons.event_available_rounded,
            trailing: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: controller.isSubmitting
                      ? null
                      : () => _apply(context, defaultTypeName: 'home'),
                  icon: const Icon(Icons.home_work_outlined, size: 16),
                  label: const Text('Apply WFH'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: controller.isSubmitting
                      ? null
                      : () => _apply(context, defaultTypeName: 'field'),
                  icon: const Icon(Icons.near_me_outlined, size: 16),
                  label: const Text('Work Outside'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: controller.isSubmitting
                      ? null
                      : () => _apply(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    controller.isSubmitting ? 'Please wait' : 'Apply Leave',
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(
            title: 'Leave Overview',
            subtitle: 'Your leave request summary',
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final itemWidth = width < 420
                  ? (width - 10) / 2
                  : (width - 20) / 3;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _SummaryCard(
                      title: 'Total Requests',
                      value: '${controller.leaves.length}',
                      icon: Icons.calendar_month_rounded,
                      color: cs.primary,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _SummaryCard(
                      title: 'Pending',
                      value: '$pending',
                      icon: Icons.hourglass_top_rounded,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _SummaryCard(
                      title: 'Approved',
                      value: '$approved',
                      icon: Icons.check_circle_outline_rounded,
                      color: Colors.green,
                    ),
                  ),
                  if (rejected > 0)
                    SizedBox(
                      width: itemWidth,
                      child: _SummaryCard(
                        title: 'Rejected',
                        value: '$rejected',
                        icon: Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          const _SectionHeader(
            title: 'Leave Balance',
            subtitle: 'Check your available leave days',
          ),
          const SizedBox(height: 10),
          if (controller.balances.isEmpty)
            const _EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No leave balance',
              subtitle: 'Your leave balances will appear here.',
            )
          else
            SizedBox(
              height: 145,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.balances.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return _BalanceCard(
                    balance: controller.balances[index],
                  );
                },
              ),
            ),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'My Requests',
            subtitle: 'Track your leave applications',
            trailing: Text(
              '${controller.leaves.length} total',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (controller.leaves.isEmpty)
            const _EmptyState(
              icon: Icons.event_note_outlined,
              title: 'No leave requests yet',
              subtitle: 'Your leave applications will appear here.',
            )
          else
            ...controller.leaves.map(
                  (leave) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
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

  Future<void> _apply(BuildContext context, {String? defaultTypeName}) async {
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

    // Deduplicate leave types by lowercased name
    final seenNames = <String>{};
    final uniqueTypes = <LeaveTypeEntity>[];
    for (final t in types) {
      final nameKey = t.name.trim().toLowerCase();
      if (seenNames.add(nameKey)) {
        uniqueTypes.add(t);
      }
    }

    List<LeaveTypeEntity> availableTypes;
    bool dropdownEnabled = true;

    if (defaultTypeName == 'home') {
      availableTypes = uniqueTypes
          .where((t) =>
              t.name.toLowerCase().contains('home') ||
              t.name.toLowerCase().contains('wfh'))
          .toList();
      dropdownEnabled = false;
    } else if (defaultTypeName == 'field') {
      availableTypes = uniqueTypes
          .where((t) =>
              t.name.toLowerCase().contains('field') ||
              t.name.toLowerCase().contains('outside'))
          .toList();
      dropdownEnabled = false;
    } else {
      availableTypes = uniqueTypes
          .where((t) =>
              !t.name.toLowerCase().contains('home') &&
              !t.name.toLowerCase().contains('wfh') &&
              !t.name.toLowerCase().contains('field') &&
              !t.name.toLowerCase().contains('outside'))
          .toList();
      dropdownEnabled = true;
    }

    if (availableTypes.isEmpty) {
      availableTypes = uniqueTypes;
    }

    final reasonController = TextEditingController();
    String? selectedType = availableTypes.first.id?.toString();

    DateTime? fromDate;
    DateTime? toDate;
    bool isHalfDay = false;
    String halfDayType = 'First Half';

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

              final dialogTitle = defaultTypeName == 'home'
                  ? 'Apply Work From Home'
                  : defaultTypeName == 'field'
                      ? 'Apply Work Outside (Field)'
                      : 'Apply Leave Request';
              final dialogIcon = defaultTypeName == 'home'
                  ? Icons.home_work_outlined
                  : defaultTypeName == 'field'
                      ? Icons.near_me_outlined
                      : Icons.beach_access_rounded;

              final fieldLabel = defaultTypeName != null
                  ? 'Request Type'
                  : 'Leave Type';

              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        dialogIcon,
                        color: cs.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dialogTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // _FieldLabel(fieldLabel),
                        const SizedBox(height: 7),
                        CustomDropdown<String>(
                          label: fieldLabel,
                          value: selectedType,
                          enabled: dropdownEnabled,
                          icon: Icons.category_outlined,
                          hint: 'Select type',
                          searchText: (id) {
                            final index = availableTypes.indexWhere(
                              (e) => e.id.toString() == id,
                            );
                            return index == -1
                                ? id
                                : availableTypes[index].name;
                          },
                          items: [
                            for (final type in availableTypes)
                              if (type.id != null)
                                DropdownMenuItem<String>(
                                  value: type.id.toString(),
                                  child: Text(
                                    type.name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                          ],
                          onChanged: (value) {
                            if (dropdownEnabled) {
                              setDialogState(() => selectedType = value);
                            }
                          },
                        ),
                        const SizedBox(height: 18),
                        const _FieldLabel('Leave Duration'),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Expanded(
                              child: _DateSelector(
                                label: 'From Date',
                                date: fromDate,
                                icon: Icons.calendar_today_rounded,
                                onTap: () => pickDate(true),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _DateSelector(
                                label: 'To Date',
                                date: toDate,
                                icon: Icons.event_rounded,
                                onTap: () => pickDate(false),
                              ),
                            ),
                          ],
                        ),
                        if (fromDate != null && toDate != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(
                                alpha: 0.35,
                              ),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: cs.primary,
                                  size: 17,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  '${toDate!.difference(fromDate!).inDays + 1} calendar days selected',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (fromDate!.year == toDate!.year &&
                              fromDate!.month == toDate!.month &&
                              fromDate!.day == toDate!.day) ...[
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                children: [
                                  CheckboxListTile(
                                    title: const Text('Half Day Request',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    value: isHalfDay,
                                    onChanged: (val) {
                                      setDialogState(() {
                                        isHalfDay = val ?? false;
                                      });
                                    },
                                    dense: true,
                                    controlAffinity:
                                    ListTileControlAffinity.leading,
                                  ),
                                  if (isHalfDay) ...[
                                    const Divider(height: 1),
                                    RadioListTile<String>(
                                      title: const Text('First Half',
                                          style: TextStyle(fontSize: 12.5)),
                                      value: 'First Half',
                                      groupValue: halfDayType,
                                      dense: true,
                                      onChanged: (val) {
                                        if (val != null) {
                                          setDialogState(
                                                  () => halfDayType = val);
                                        }
                                      },
                                    ),
                                    RadioListTile<String>(
                                      title: const Text('Second Half',
                                          style: TextStyle(fontSize: 12.5)),
                                      value: 'Second Half',
                                      groupValue: halfDayType,
                                      dense: true,
                                      onChanged: (val) {
                                        if (val != null) {
                                          setDialogState(
                                                  () => halfDayType = val);
                                        }
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 18),
                        const _FieldLabel('Reason for Leave'),
                        const SizedBox(height: 7),
                        TextField(
                          controller: reasonController,
                          minLines: 3,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Enter reason for leave...',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 45),
                              child: Icon(Icons.notes_rounded, size: 18),
                            ),
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withValues(
                              alpha: 0.3,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: cs.outlineVariant,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: cs.outlineVariant,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: cs.primary,
                                width: 1.4,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
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
                        'isHalfDay': isHalfDay,
                        'halfDayType': halfDayType,
                      });
                    },
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Submit Request'),
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
        isHalfDay: result['isHalfDay'] == true,
        halfDayType: result['halfDayType'] as String?,
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

  Future<void> _cancel(BuildContext context, LeaveEntity leave) async {
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
    final pending = controller.approvalLeaves
        .where((e) => e.s('status') == 'Pending')
        .length;

    return RefreshIndicator(
      onRefresh: () => controller.loadLeaveData(
        Session.empId,
        DateTime.now().year,
      ),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        children: [
          _WelcomeCard(
            title: 'Leave Approvals',
            subtitle: 'Review and manage employee leave requests',
            icon: Icons.fact_check_outlined,
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '$pending',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionHeader(
            title: 'Requests',
            subtitle: 'Filter employee applications',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                avatar: const Icon(Icons.hourglass_top_rounded, size: 15),
                label: const Text('Pending'),
                selected: controller.pendingOnlyApprovals,
                onSelected: (value) {
                  if (value) {
                    controller.setPendingOnlyApprovals(
                      true,
                      Session.empId,
                    );
                  }
                },
              ),
              ChoiceChip(
                avatar: const Icon(Icons.list_alt_rounded, size: 15),
                label: const Text('All Requests'),
                selected: !controller.pendingOnlyApprovals,
                onSelected: (value) {
                  if (value) {
                    controller.setPendingOnlyApprovals(
                      false,
                      Session.empId,
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (controller.approvalLeaves.isEmpty)
            const _EmptyState(
              icon: Icons.task_alt_rounded,
              title: 'No approval requests',
              subtitle: 'There are no requests to display.',
            )
          else
            ...controller.approvalLeaves.map(
                  (leave) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
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
      LeaveEntity leave,
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
            padding: const EdgeInsets.all(12),
            children: [
              _leaveTypesPanel(context),
              const SizedBox(height: 14),
              _holidaysPanel(context),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _leaveTypesPanel(context)),
              const SizedBox(width: 14),
              Expanded(child: _holidaysPanel(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _leaveTypesPanel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Panel(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PanelHeader(
              title: 'Leave Types',
              subtitle: 'Employee leave categories',
              icon: Icons.beach_access_rounded,
              onAdd: () => _editType(context),
            ),
            const Divider(height: 22),
            if (controller.leaveTypes.isEmpty)
              const _EmptyState(
                icon: Icons.category_outlined,
                title: 'No leave types',
                subtitle: 'Add a leave type to get started.',
              )
            else
              ...controller.leaveTypes.map(
                    (type) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(
                      alpha: 0.25,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: cs.primaryContainer,
                      child: Icon(
                        type.i('paid') == 1
                            ? Icons.account_balance_wallet_outlined
                            : Icons.money_off_rounded,
                        color: cs.primary,
                        size: 17,
                      ),
                    ),
                    title: Text(
                      type.s('name'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        '${nf(type.d('days_per_year'))} days/year · '
                            '${type.i('paid') == 1 ? 'Paid' : 'Unpaid'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Options',
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
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.edit_outlined, size: 18),
                            title: Text('Edit'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            title: Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _holidaysPanel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Panel(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _PanelHeader(
                    title: 'Holidays',
                    subtitle: 'Company holidays',
                    icon: Icons.calendar_month_rounded,
                    showAdd: false,
                    onAdd: () {},
                  ),
                ),
                IconButton(
                  tooltip: 'Previous year',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    controller.setHolidayYear(
                      controller.holidayYear - 1,
                      Session.empId,
                    );
                  },
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(
                  '${controller.holidayYear}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  tooltip: 'Next year',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    controller.setHolidayYear(
                      controller.holidayYear + 1,
                      Session.empId,
                    );
                  },
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
                IconButton.filledTonal(
                  tooltip: 'Add holiday',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _addHoliday(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                ),
              ],
            ),
            const Divider(height: 22),
            if (controller.holidays.isEmpty)
              const _EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No holidays',
                subtitle: 'No holidays configured for this year.',
              )
            else
              ...controller.holidays.map(
                    (holiday) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(
                      alpha: 0.25,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    leading: CircleAvatar(
                      radius: 17,
                      backgroundColor: Colors.green.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: Colors.green,
                        size: 17,
                      ),
                    ),
                    title: Text(
                      holiday.s('name'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      fmtDate(holiday['date']),
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete holiday',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 19,
                      ),
                      onPressed: () => _deleteHoliday(context, holiday),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editType(
      BuildContext context, [
        LeaveTypeEntity? type,
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

  Future<void> _deleteType(
      BuildContext context,
      LeaveTypeEntity type,
      ) async {
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

  final LeaveEntity leave;
  final bool showEmployee;
  final VoidCallback? onCancel;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final status = leave.s('status');
    final normalizedStatus = status.trim().toLowerCase();

    final employeeName = (leave.empName ?? '').trim();
    final employeeCode = (leave.empCode ?? '').trim();
    final department = (leave.department ?? '').trim();
    final leaveType = (leave.typeName ?? '').trim();

    final employeeTitle = [
      if (employeeName.isNotEmpty) employeeName,
      if (employeeCode.isNotEmpty) employeeCode,
      if (department.isNotEmpty) department,
      if (leaveType.isNotEmpty) leaveType,
    ].join(' · ');

    final color = switch (normalizedStatus) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      'pending' => Colors.orange,
      _ => cs.primary,
    };

    final actions = <Widget>[
      if (onReject != null)
        _SmallActionButton(
          label: 'Reject',
          icon: Icons.close,
          color: Colors.red,
          onPressed: onReject!,
        ),
      if (onApprove != null)
        _SmallActionButton(
          label: 'Approve',
          icon: Icons.check,
          color: Colors.green,
          onPressed: onApprove!,
        ),
      if (onCancel != null)
        _SmallActionButton(
          label: 'Cancel',
          icon: Icons.close,
          color: Colors.red,
          onPressed: onCancel!,
        ),
    ];

    final info = Row(
      children: [
        Expanded(
          child: _CompactInfo(
            label: 'From',
            value: fmtDate(leave['start_date']),
          ),
        ),
        Expanded(
          child: _CompactInfo(
            label: 'To',
            value: fmtDate(leave['end_date']),
          ),
        ),
        Expanded(
          child: _CompactInfo(
            label: 'Days',
            value: nf(leave.d('days')),
          ),
        ),
      ],
    );

    final leaveTypeLower = leaveType.toLowerCase();
    final isWFH = leaveTypeLower.contains('home') || leaveTypeLower.contains('wfh');
    final isField = leaveTypeLower.contains('field') || leaveTypeLower.contains('outside') || leaveTypeLower.contains('duty');

    final categoryIcon = isWFH
        ? Icons.home_work_outlined
        : isField
            ? Icons.near_me_outlined
            : showEmployee
                ? Icons.person_outline
                : Icons.beach_access_outlined;

    final categoryColor = isWFH
        ? Colors.blue
        : isField
            ? Colors.deepPurple
            : cs.primary;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        children: [
          // Main employee and status section.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showEmployee
                            ? (employeeName.isEmpty
                            ? 'Employee details unavailable'
                            : employeeName)
                            : (leaveType.isEmpty ? 'Leave' : leaveType),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (showEmployee && employeeTitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (employeeCode.isNotEmpty) employeeCode,
                            if (department.isNotEmpty) department,
                            if (leaveType.isNotEmpty) leaveType,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                  status: status,
                  color: color,
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.4),
          ),

          // Date and duration section.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 440 && actions.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      info,
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: actions,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: info),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 6,
                        runSpacing: 6,
                        children: actions,
                      ),
                    ],
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

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.045),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ============================================================================
// BALANCE CARD
// ============================================================================

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final LeaveBalanceEntity balance;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final paid = balance.i('paid') == 1;
    final total = balance.d('days_per_year');
    final used = balance.d('used');
    final pending = balance.d('pending');

    final remaining =
    (total - used - pending).clamp(0.0, double.infinity);

    final progress =
    total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: 175,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.75),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      paid ? Icons.wallet_outlined : Icons.money_off,
                      size: 15,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      balance.s('name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    paid ? nf(remaining) : '—',
                    style: TextStyle(
                      fontSize: 19,
                      height: 1,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    paid ? 'days left' : 'unpaid',
                    style: TextStyle(
                      fontSize: 9,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (paid)
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
              const SizedBox(height: 6),
              _balanceRow('Used', used),
              _balanceRow('Pending', pending),
              if (paid) _balanceRow('Total', total),
              if (paid) _balanceRow('Remaining', remaining),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 9)),
          Text(
            nf(value),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        child: Row(
          children: [
            Container(
              width: 37,
              height: 37,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
    );
  }
}

// ============================================================================
// COMMON WIDGETS
// ============================================================================

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withValues(alpha: 0.75),
            cs.primaryContainer.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.15),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: cs.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 2,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (trailing != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: trailing!,
                  ),
                ],
              ],
            )
          : Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: cs.primary, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
    );
  }
}

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
    final cs = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 25,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 25,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.color,
  });

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        status.isEmpty ? 'Unknown' : status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              date == null ? 'Select date' : fmtDate(ymd(date!)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onAdd,
    this.showAdd = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onAdd;
  final bool showAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add'),
          ),
      ],
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
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
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

class _CompactInfo extends StatelessWidget {
  const _CompactInfo({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '-' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}