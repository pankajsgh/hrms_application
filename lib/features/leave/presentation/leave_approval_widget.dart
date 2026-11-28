import 'package:flutter/material.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/domain/entities/leave_entity.dart';
import 'package:hrms/features/leave/presentation/leave_controller.dart';
import 'package:hrms/features/leave/presentation/leave_request_card.dart';
import 'package:hrms/features/leave/presentation/comman_widget/leave_widgets.dart';

class ApprovalsTab extends StatefulWidget {
  const ApprovalsTab({super.key, required this.controller});

  final LeaveController controller;

  @override
  State<ApprovalsTab> createState() => _ApprovalsTabState();
}

class _ApprovalsTabState extends State<ApprovalsTab> {
  String _filterStatus = 'Pending';

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final allLeaves = controller.approvalLeaves;

    final pendingCount = allLeaves
        .where((e) => e.s('status').trim().toLowerCase() == 'pending')
        .length;
    final approvedCount = allLeaves
        .where((e) => e.s('status').trim().toLowerCase() == 'approved')
        .length;
    final rejectedCount = allLeaves
        .where((e) => e.s('status').trim().toLowerCase() == 'rejected')
        .length;

    final filteredLeaves = allLeaves.where((e) {
      if (_filterStatus == 'All') return true;
      return e.s('status').trim().toLowerCase() ==
          _filterStatus.toLowerCase();
    }).toList();

    return RefreshIndicator(
      onRefresh: () => controller.loadLeaveData(
        Session.empId,
        DateTime.now().year,
      ),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        children: [
          WelcomeCard(
            title: 'Leave Approvals',
            subtitle: 'Review and manage employee leave & attendance requests',
            icon: Icons.fact_check_outlined,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _statBadge('$pendingCount', 'Pending', Colors.orange),
                const SizedBox(width: 8),
                _statBadge('$approvedCount', 'Approved', Colors.green),
                const SizedBox(width: 8),
                _statBadge('$rejectedCount', 'Rejected', Colors.red),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(
            title: 'Filter Requests',
            subtitle: 'Quick filter by request status',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in ['Pending', 'Approved', 'Rejected', 'All'])
                ChoiceChip(
                  label: Text(status),
                  selected: _filterStatus == status,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() => _filterStatus = status);
                    if (status == 'Pending') {
                      controller.setPendingOnlyApprovals(true, Session.empId);
                    } else {
                      controller.setPendingOnlyApprovals(false, Session.empId);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (filteredLeaves.isEmpty)
            EmptyState(
              icon: Icons.task_alt_rounded,
              title: 'No requests found',
              subtitle: 'There are no $_filterStatus requests to display.',
            )
          else
            ...filteredLeaves.map(
              (leave) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LeaveRequestCard(
                  leave: leave,
                  showEmployee: true,
                  onApprove: leave.s('status') == 'Pending'
                      ? () => _decide(context, controller, leave, true)
                      : null,
                  onReject: leave.s('status') == 'Pending'
                      ? () => _decide(context, controller, leave, false)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statBadge(String count, String label, Color color) {
    final isSelected = _filterStatus.toLowerCase() == label.toLowerCase();

    return Material(
      color: isSelected ? color.withValues(alpha: 0.18) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? color : color.withValues(alpha: 0.25),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() => _filterStatus = label);
          if (label == 'Pending') {
            widget.controller.setPendingOnlyApprovals(true, Session.empId);
          } else {
            widget.controller.setPendingOnlyApprovals(false, Session.empId);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    LeaveController controller,
    LeaveEntity leave,
    bool approve,
  ) async {
    final action = approve ? 'Approve' : 'Reject';

    final confirmed = await confirm(
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
