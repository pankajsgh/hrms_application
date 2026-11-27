import 'package:flutter/material.dart';

class ExpandableJobDescription extends StatelessWidget {
  final String description;

  const ExpandableJobDescription({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (description.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      description,
      softWrap: true,
      style: TextStyle(
        fontSize: 10.5,
        height: 1.4,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}
