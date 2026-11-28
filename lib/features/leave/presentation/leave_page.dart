import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/domain/entities/leave_entity.dart';
import 'package:hrms/features/leave/presentation/balance_card.dart';
import 'package:hrms/features/leave/presentation/leave_approval_widget.dart';
import 'package:hrms/features/leave/presentation/leave_request_card.dart';
import 'package:hrms/features/leave/presentation/comman_widget/leave_widgets.dart';
import 'package:hrms/features/leave/presentation/dialogs/apply_leave_dialog.dart';

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
                    ApprovalsTab(controller: _controller),
                  if (Session.isHr)
                    _SetupTab(controller: _controller),
                ];

                if (tabs.isEmpty) {
                  return const EmptyState(
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
// MY LEAVE TAB
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
          WelcomeCard(
            title: 'My Requests',
            subtitle: 'Apply for leaves, work from home, or field work',
            icon: Icons.event_available_rounded,
            trailing: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: controller.isSubmitting
                        ? null
                        : () => showApplyLeaveDialog(context, controller, defaultTypeName: 'home'),
                    icon: const Icon(Icons.home_work_outlined, size: 16),
                    label: const Text('Apply WFH'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: controller.isSubmitting
                        ? null
                        : () => showApplyLeaveDialog(context, controller, defaultTypeName: 'field'),
                    icon: const Icon(Icons.near_me_outlined, size: 16),
                    label: const Text('Work Outside'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: FilledButton.icon(
                    onPressed: controller.isSubmitting
                        ? null
                        : () => showApplyLeaveDialog(context, controller),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      controller.isSubmitting ? 'Please wait' : 'Apply Leave',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(
            title: 'Leave Overview',
            subtitle: 'Your leave request summary',
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final itemWidth = width < 500
                  ? (width - 10) / 2
                  :width < 1000? (width - 20) / 3: (width - 20) / 5;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: SummaryCard(
                      title: 'Total Requests',
                      value: '${controller.leaves.length}',
                      icon: Icons.calendar_month_rounded,
                      color: cs.primary,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: SummaryCard(
                      title: 'Pending',
                      value: '$pending',
                      icon: Icons.hourglass_top_rounded,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: SummaryCard(
                      title: 'Approved',
                      value: '$approved',
                      icon: Icons.check_circle_outline_rounded,
                      color: Colors.green,
                    ),
                  ),
                  if (rejected > 0)
                    SizedBox(
                      width: itemWidth,
                      child: SummaryCard(
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
          const SectionHeader(
            title: 'Leave Balance',
            subtitle: 'Check your available leave days',
          ),
          const SizedBox(height: 10),
          if (controller.balances.isEmpty)
            const EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No leave balance',
              subtitle: 'Your leave balances will appear here.',
            )
          else
            SizedBox(
              height: 120,
              width: double.infinity,
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  itemCount: controller.balances.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return BalanceCard(
                      balance: controller.balances[index],
                      year: 2026,
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 10),
          SectionHeader(
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
            const EmptyState(
              icon: Icons.event_note_outlined,
              title: 'No leave requests yet',
              subtitle: 'Your leave applications will appear here.',
            )
          else
            ...controller.leaves.map(
                  (leave) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LeaveRequestCard(
                  leave: leave,
                  showEmployee: false,
                  onCancel: leave.s('status') == 'Pending'
                      ? () => _cancel(context, controller, leave)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, LeaveController controller, LeaveEntity leave) async {
    final confirmed = await confirm(
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
      success
          ? 'Leave request cancelled successfully'
          : 'Unable to cancel leave request',
    );
  }
}

// ============================================================================
// SETUP TAB
// ============================================================================

class _SetupTab extends StatelessWidget {
  const _SetupTab({required this.controller});

  final LeaveController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 850;

        if (wide) {
          return ListView(
            padding: const EdgeInsets.all(10),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _leaveTypesPanel(context)),
                  const SizedBox(width: 14),
                  Expanded(child: _holidaysPanel(context)),
                ],
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(10),
          children: [
            _leaveTypesPanel(context),
            const SizedBox(height: 16),
            _holidaysPanel(context),
          ],
        );
      },
    );
  }

  Widget _leaveTypesPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PanelHeader(
            title: 'Leave Types',
            subtitle: 'Employee leave categories',
            icon: Icons.beach_access_rounded,
            onAdd: () => _editType(context),
          ),
          const Divider(height: 22),
          if (controller.leaveTypes.isEmpty)
            const EmptyState(
              icon: Icons.category_outlined,
              title: 'No leave types',
              subtitle: 'Add a leave type to get started.',
            )
          else
            ...controller.leaveTypes.map(
              (type) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.6),
                    child: Icon(
                      type.i('paid') == 1
                          ? Icons.account_balance_wallet_outlined
                          : Icons.money_off_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 17,
                    ),
                  ),
                  title: Text(
                    type.s('name'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${nf(type.d('days_per_year'))} days/year · '
                      '${type.i('paid') == 1 ? 'Paid' : 'Unpaid'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
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
    );
  }

  Widget _holidaysPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: PanelHeader(
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
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
              ),
              Text(
                '${controller.holidayYear}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
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
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
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
            const EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No holidays',
              subtitle: 'No holidays configured for this year.',
            )
          else
            ...controller.holidays.map(
              (holiday) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    fmtDate(holiday['date']),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
    final confirmed = await confirm(
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
    final confirmed = await confirm(
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
