import 'package:flutter/material.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/domain/entities/leave_entity.dart';
import 'package:hrms/features/leave/presentation/comman_widget/status_widget.dart';

class LeaveRequestCard extends StatelessWidget {
  const LeaveRequestCard({
    super.key,
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
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final status = leave.s('status');
    final normalizedStatus = status.trim().toLowerCase();

    final employeeName = (leave.empName ?? '').trim();
    final employeeCode = (leave.empCode ?? '').trim();
    final department = (leave.department ?? '').trim();
    final leaveType = (leave.typeName ?? '').trim();
    final reason = leave.s('reason');

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

    // ==========================================================
    // DESKTOP: SQL-Like Data-Dense Enterprise Row
    // ==========================================================
    if (isDesktop) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showEmployee
                        ? (employeeName.isEmpty ? 'Employee' : employeeName)
                        : (leaveType.isEmpty ? 'Leave' : leaveType),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    [
                      if (employeeCode.isNotEmpty) employeeCode,
                      if (department.isNotEmpty) department,
                      if (leaveType.isNotEmpty && showEmployee) leaveType,
                    ].join(' • '),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                '${fmtDate(leave['start_date'])} → ${fmtDate(leave['end_date'])}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 55,
              child: Text(
                '${nf(leave.d('days'))} days',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                reason.isEmpty ? '—' : reason,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            StatusBadge(
              status: status,
              color: color,
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: actions,
              ),
            ],
          ],
        ),
      );
    }

    // ==========================================================
    // MOBILE: Touch-Friendly Interactive Card
    // ==========================================================
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
    final isField = leaveTypeLower.contains('field') ||
        leaveTypeLower.contains('outside') ||
        leaveTypeLower.contains('duty');

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
                      if (showEmployee &&
                          [
                            if (employeeCode.isNotEmpty) employeeCode,
                            if (department.isNotEmpty) department,
                            if (leaveType.isNotEmpty) leaveType,
                          ].join(' · ').isNotEmpty) ...[
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
                StatusBadge(
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

class _CompactInfo extends StatelessWidget {
  const _CompactInfo({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
