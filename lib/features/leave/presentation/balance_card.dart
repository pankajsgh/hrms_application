import 'package:flutter/material.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/domain/entities/leave_entity.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({required this.balance});

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
    total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: 155,
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showBalanceDetails(
            context,
            paid: paid,
            total: total,
            used: used,
            pending: pending,
            remaining: remaining,
            progress: progress,
          ),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      paid ? Icons.event_available : Icons.money_off,
                      size: 16,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 6),
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
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      paid ? nf(remaining) : '—',
                      style: TextStyle(
                        fontSize: 18,
                        height: 1,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        paid ? 'days left' : 'unpaid',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (paid) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${nf(used)} used',
                        style: TextStyle(
                          fontSize: 9,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${nf(pending)} pending',
                        style: TextStyle(
                          fontSize: 9,
                          color: cs.tertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBalanceDetails(
      BuildContext context, {
        required bool paid,
        required double total,
        required double used,
        required double pending,
        required double remaining,
        required double progress,
      }) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          paid
                              ? Icons.event_available
                              : Icons.money_off,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              balance.s('name'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              paid
                                  ? 'Leave balance details'
                                  : 'Unpaid leave details',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () =>
                            Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  if (paid) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available balance',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                nf(remaining),
                                style: TextStyle(
                                  fontSize: 30,
                                  height: 1.1,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(width: 7),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text('days remaining'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _balanceRow('Total allowance', total),
                    _balanceRow('Used leave', used),
                    _balanceRow('Pending requests', pending),
                    Divider(color: cs.outlineVariant),
                    _balanceRow('Remaining balance', remaining),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${nf(used)} days used',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${nf(total > 0 ? (used / total * 100) : 0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _balanceRow('Leave type', 0, valueText: 'Unpaid'),
                    _balanceRow('Used', used),
                    _balanceRow('Pending', pending),
                    const SizedBox(height: 8),
                    Text(
                      'This leave type does not have a paid leave allowance.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _balanceRow(
      String label,
      double value, {
        String? valueText,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            valueText ?? nf(value),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
