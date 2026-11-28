
import 'package:flutter/material.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/domain/entities/leave_entity.dart';
import 'package:hrms/features/leave/presentation/balance_card.dart';

class LeaveBalanceSection extends StatelessWidget {
  const LeaveBalanceSection({
    super.key,
    required this.balances,
    required this.year,
  });

  final List<LeaveBalanceEntity> balances;
  final int year;

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
                      child: BalanceCard(
                        balance: balance, year: year,
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
      LeaveBalanceEntity balance,
      ) {
    showDialog(
      context: context,
      builder: (_) => BalanceCard(
        balance: balance,
        year: year,
      ),
    );
  }
}
