
import 'package:flutter/material.dart';
import 'package:hrms/core/ui.dart';

class LeaveBalanceSection extends StatelessWidget {
  const LeaveBalanceSection({
    super.key,
    required this.balances,
    required this.year,
  });

  final List<Map<String, Object?>> balances;
  final int year;

  // ------------------------------------------------------------
  // SAFE MAP HELPERS
  // ------------------------------------------------------------

  static String _string(Map<String, Object?> data, String key) {
    return data[key]?.toString() ?? '';
  }

  static double _number(Map<String, Object?> data, String key) {
    final value = data[key];

    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _isPaid(Map<String, Object?> data) {
    final value = data['paid'];

    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().toLowerCase().trim();
    return text == '1' || text == 'true' || text == 'yes';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          const SizedBox(height: 16),
          if (balances.isEmpty)
            _emptyState(context)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 420 ? 2 : 1;
                const spacing = 10.0;

                final itemWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: balances.map((balance) {
                    return SizedBox(
                      width: itemWidth,
                      child: _LeaveBalanceCard(
                        balance: balance,
                        onTap: () => _showDetails(context, balance),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            Icons.event_available_rounded,
            size: 20,
            color: cs.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leave Balance',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Your available leave overview',
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$year',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 30,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 9),
          Text(
            'No leave balance available',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(
      BuildContext context,
      Map<String, Object?> balance,
      ) {
    showDialog(
      context: context,
      builder: (_) => _LeaveBalanceDetailsDialog(
        balance: balance,
        year: year,
      ),
    );
  }
}

// ============================================================
// LEAVE BALANCE CARD
// ============================================================

class _LeaveBalanceCard extends StatelessWidget {
  const _LeaveBalanceCard({
    required this.balance,
    required this.onTap,
  });

  final Map<String, Object?> balance;
  final VoidCallback onTap;

  String get _name =>
      LeaveBalanceSection._string(balance, 'name').isEmpty
          ? 'Leave'
          : LeaveBalanceSection._string(balance, 'name');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final paid = LeaveBalanceSection._isPaid(balance);
    final total = LeaveBalanceSection._number(balance, 'days_per_year');
    final used = LeaveBalanceSection._number(balance, 'used');
    final pending = LeaveBalanceSection._number(balance, 'pending');
    final remaining = LeaveBalanceSection._number(balance, 'remaining');

    final progress = total > 0
        ? (used / total).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child:
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    paid
                        ? Icons.event_available_rounded
                        : Icons.money_off_csred_outlined,
                    size: 14,
                    color: paid ? cs.primary : cs.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 15,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    paid ? nf(remaining.clamp(0.0, double.infinity)) : '—',
                    style: TextStyle(
                      fontSize: 17,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    paid ? 'days left' : 'unpaid',
                    style: TextStyle(
                      fontSize: 9,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (pending > 0)
                    Text(
                      '${nf(pending)} pending',
                      style: TextStyle(
                        fontSize: 8,
                        color: cs.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${nf(used)} / ${nf(total)} days used',
                style: TextStyle(
                  fontSize: 8,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        )
        ,
      ),
    );
  }
}

// ============================================================
// DETAILS DIALOG
// ============================================================

class _LeaveBalanceDetailsDialog extends StatelessWidget {
  const _LeaveBalanceDetailsDialog({
    required this.balance,
    required this.year,
  });

  final Map<String, Object?> balance;
  final int year;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final paid = LeaveBalanceSection._isPaid(balance);
    final name = LeaveBalanceSection._string(balance, 'name');
    final total = LeaveBalanceSection._number(balance, 'days_per_year');
    final used = LeaveBalanceSection._number(balance, 'used');
    final pending = LeaveBalanceSection._number(balance, 'pending');
    final remaining = LeaveBalanceSection._number(balance, 'remaining');

    final progress = total > 0
        ? (used / total).clamp(0.0, 1.0)
        : 0.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        paid
                            ? Icons.event_available_rounded
                            : Icons.money_off_csred_outlined,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? 'Leave details' : name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Leave details • $year',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (paid) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available balance',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              nf(remaining.clamp(0.0, double.infinity)),
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 32,
                                height: 1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(
                                left: 7,
                                bottom: 3,
                              ),
                              child: Text('days remaining'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _detailRow(context, 'Total allowance', nf(total)),
                  _detailRow(context, 'Used leave', nf(used)),
                  _detailRow(context, 'Pending requests', nf(pending)),
                  Divider(color: cs.outlineVariant),
                  _detailRow(
                    context,
                    'Remaining balance',
                    '${nf(remaining.clamp(0.0, double.infinity))} days',
                    strong: true,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${nf(total > 0 ? (used / total) * 100 : 0)}% allowance used',
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  _detailRow(context, 'Leave type', 'Unpaid'),
                  _detailRow(context, 'Used', '${nf(used)} days'),
                  _detailRow(context, 'Pending', '${nf(pending)} days'),
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
                  height: 44,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
      BuildContext context,
      String label,
      String value, {
        bool strong = false,
      }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
