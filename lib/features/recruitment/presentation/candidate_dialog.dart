import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/ui.dart';

/// Action chosen by the user in [CandidateDetailsDialog].
enum CandidateAction { edit, openResume, attachResume, scheduleInterview, convert }

/// Popup showing a candidate's profile and interview history.
/// Returns the [CandidateAction] the user picked, or `null` when closed.
class CandidateDetailsDialog extends StatelessWidget {
  const CandidateDetailsDialog({
    super.key,
    required this.candidate,
    required this.interviews,
  });

  final Rec candidate;
  final List<Rec> interviews;

  static Future<CandidateAction?> show(
      BuildContext context, {
        required Rec candidate,
        required List<Rec> interviews,
      }) {
    return showDialog<CandidateAction>(
      context: context,
      builder: (_) =>
          CandidateDetailsDialog(candidate: candidate, interviews: interviews),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final c = candidate;
    final converted = c.i('converted_employee_id') != null;
    final hasResume = c.s('resume_path').isNotEmpty;
    final rating = c.i('rating') ?? 0;
    final fmt = DateFormat('d MMM yyyy, hh:mm a');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ---------------------------------------------------------- header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
            color: cs.primaryContainer,
            child: Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.primary,
                child: Text(
                  c.s('name').isEmpty ? '?' : c.s('name')[0].toUpperCase(),
                  style: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.s('name'),
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimaryContainer)),
                  if (c.s('job_title').isNotEmpty)
                    Text(c.s('job_title'),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onPrimaryContainer)),
                ]),
              ),
              StatusChip(c.s('stage')),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ]),
          ),

          // ------------------------------------------------------------ body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (rating > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('★' * rating + '☆' * (5 - rating),
                        style: TextStyle(
                            color: Colors.amber.shade700, fontSize: 18)),
                  ),
                _Row(Icons.mail_outline, 'Email', c.s('email')),
                _Row(Icons.phone_outlined, 'Phone', c.s('phone')),
                _Row(Icons.campaign_outlined, 'Source', c.s('source')),
                _Row(
                    Icons.work_history_outlined,
                    'Experience',
                    c.d('experience_years') > 0
                        ? '${nf(c.d('experience_years'))} years'
                        : ''),
                _Row(Icons.business_outlined, 'Company', c.s('current_company')),
                _Row(
                    Icons.payments_outlined,
                    'Expected salary',
                    c.d('expected_salary') > 0
                        ? money(c.d('expected_salary'))
                        : ''),
                _Row(Icons.event_outlined, 'Applied on', fmtDate(c['applied_on'])),
                _Row(Icons.notes_outlined, 'Notes', c.s('notes')),
                if (converted)
                  _Row(Icons.verified_outlined, 'Employee',
                      'Already converted to an employee'),
                if (interviews.isNotEmpty) ...[
                  const Divider(height: 28),
                  Text('Interviews',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  for (final i in interviews) _InterviewTile(i, fmt),
                ],
              ]),
            ),
          ),

          // --------------------------------------------------------- actions
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: cs.outlineVariant)),
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, CandidateAction.edit),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                if (hasResume)
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, CandidateAction.openResume),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Open resume'),
                  ),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, CandidateAction.attachResume),
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: Text(hasResume ? 'Replace resume' : 'Attach resume'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, CandidateAction.scheduleInterview),
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: const Text('Schedule interview'),
                ),
                if (c.s('stage') == 'Hired' && !converted)
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, CandidateAction.convert),
                    icon: const Icon(Icons.badge_outlined, size: 18),
                    label: const Text('Convert to employee'),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 17, color: cs.outline),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ),
        Expanded(child: Text(value)),
      ]),
    );
  }
}

class _InterviewTile extends StatelessWidget {
  const _InterviewTile(this.interview, this.fmt);

  final Rec interview;
  final DateFormat fmt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dt = DateTime.tryParse(interview.s('scheduled_at'));
    final feedback = interview.s('feedback');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              [interview.s('round'), if (dt != null) fmt.format(dt)]
                  .where((e) => e.isNotEmpty)
                  .join('  •  '),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (feedback.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(feedback,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ]),
        ),
        StatusChip(interview.s('result')),
      ]),
    );
  }
}
