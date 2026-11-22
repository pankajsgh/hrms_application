
import 'package:flutter/material.dart';
import 'package:hrms/comman_widget/customer_dropdown.dart';

import 'package:hrms/core/common.dart';

class CandidateFormDialog extends StatefulWidget {
  const CandidateFormDialog({
    super.key,
    required this.jobs,
    this.candidate,
    this.initialJobId,
  });

  final List<Rec> jobs;
  final Rec? candidate;
  final dynamic initialJobId;

  static Future<Map<String, Object?>?> show(
      BuildContext context, {
        required List<Rec> jobs,
        Rec? candidate,
        dynamic initialJobId,
      }) {
    return showDialog<Map<String, Object?>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CandidateFormDialog(
        jobs: jobs,
        candidate: candidate,
        initialJobId: initialJobId,
      ),
    );
  }

  @override
  State<CandidateFormDialog> createState() =>
      _CandidateFormDialogState();
}

class _CandidateFormDialogState extends State<CandidateFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _experience;
  late final TextEditingController _company;
  late final TextEditingController _salary;
  late final TextEditingController _notes;

  late final List<Rec> _availableJobs;

  String? _jobId;
  String _source = '';
  String _rating = '0';
  String _stage = 'Applied';

  Rec? get _candidate => widget.candidate;
  bool get _isNew => _candidate == null;

  static const Map<String, String> _ratings = {
    '0': 'Not rated',
    '1': '1 star',
    '2': '2 stars',
    '3': '3 stars',
    '4': '4 stars',
    '5': '5 stars',
  };

  @override
  void initState() {
    super.initState();

    final c = _candidate;

    _availableJobs = widget.jobs.where((j) {
      return j.s('approval') == 'Approved' ||
          j['id'].toString() == c?['job_id']?.toString();
    }).toList();

    final currentJob = c?['job_id']?.toString();
    final requestedJob = widget.initialJobId?.toString();

    _jobId = _availableJobs.any(
          (j) => j['id'].toString() == currentJob,
    )
        ? currentJob
        : _availableJobs.any(
          (j) => j['id'].toString() == requestedJob,
    )
        ? requestedJob
        : _availableJobs.isNotEmpty
        ? _availableJobs.first['id'].toString()
        : null;

    _name = TextEditingController(text: c?.s('name') ?? '');
    _email = TextEditingController(text: c?.s('email') ?? '');
    _phone = TextEditingController(text: c?.s('phone') ?? '');
    _experience = TextEditingController(
      text: c?['experience_years']?.toString() ?? '',
    );
    _company = TextEditingController(
      text: c?.s('current_company') ?? '',
    );
    _salary = TextEditingController(
      text: c?['expected_salary']?.toString() ?? '',
    );
    _notes = TextEditingController(text: c?.s('notes') ?? '');

    _source = c?.s('source') ?? '';
    _rating = c?['rating']?.toString() ?? '0';
    _stage = c?.s('stage').isNotEmpty == true
        ? c!.s('stage')
        : 'Applied';

    if (!_ratings.containsKey(_rating)) {
      _rating = '0';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _experience.dispose();
    _company.dispose();
    _salary.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_jobId == null) return;

    Navigator.pop<Map<String, Object?>>(context, {
      'job': _jobId!,
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'source': _source,
      'experience_years': _experience.text.trim(),
      'current_company': _company.text.trim(),
      'expected_salary': _salary.text.trim(),
      'rating': _rating,
      'stage': _stage,
      'notes': _notes.text.trim(),
    });
  }

  InputDecoration _decoration(
      String label, {
        IconData? icon,
        String? hint,
      }) {
    final cs = Theme.of(context).colorScheme;

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 18),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      labelStyle: const TextStyle(fontSize: 12.5),
      hintStyle: TextStyle(fontSize: 12, color: cs.outline),
      border: border(Colors.grey.shade300),
      enabledBorder: border(Colors.grey.shade300),
      focusedBorder: border(cs.primary, 1.2),
      errorBorder: border(cs.error),
      focusedErrorBorder: border(cs.error, 1.2),
    );
  }

  Widget _input(
      TextEditingController controller,
      String label, {
        IconData? icon,
        String? hint,
        TextInputType keyboard = TextInputType.text,
        String? Function(String?)? validator,
        int maxLines = 1,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 13),
      decoration: _decoration(label, icon: icon, hint: hint),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    IconData? icon,
  }) {
    return CustomDropdown<String>(
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
      icon: icon,
    );
  }

  Widget _row(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            children: [
              first,
              const SizedBox(height: 12),
              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _gap() => const SizedBox(height: 12);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CandidateHeader(
              isNew: _isNew,
              onClose: () => Navigator.pop(context),
            ),
            Flexible(
              child: Container(
                color: cs.surfaceContainerLow,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [

                        _CandidateSection(
                          title: 'Personal information',
                          subtitle: 'Candidate contact details',
                          icon: Icons.person_outline_rounded,
                          children: [
                            _row(
                            CustomDropdown<String>(
                              label: 'Applying for',
                              value: _jobId,
                              icon: Icons.work_outline,
                              hint: 'Select job opening',
                              items: [
                                for (final j in _availableJobs)
                                  DropdownMenuItem<String>(
                                    value: j['id'].toString(),
                                    child: Text(
                                      j.s('title'),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (v) {
                                setState(() => _jobId = v);
                              },
                            ),

                              CustomDropdown<String>(
                                label: 'Source',
                                value: _source,
                                icon: Icons.source_outlined,
                                hint: 'Select Source',
                                items:  [
                                  for (final e in opts(kSources).entries)
                                    DropdownMenuItem(
                                      value: e.key,
                                      child: Text(e.value),
                                    ),
                                ],
                                onChanged: (v) {
                                  setState(() => _source = v ?? '');
                                },
                              ),
                              // _dropdown(
                              //   label: 'Source',
                              //   value: opts(kSources).containsKey(_source)
                              //       ? _source
                              //       : null,
                              //   icon: Icons.source_outlined,
                              //   items: [
                              //     for (final e in opts(kSources).entries)
                              //       DropdownMenuItem(
                              //         value: e.key,
                              //         child: Text(e.value),
                              //       ),
                              //   ],
                              //   onChanged: (v) {
                              //     setState(() => _source = v ?? '');
                              //   },
                              // ),
                           ),
                            _gap(),
                            _row(
                              _input(
                                _name,
                                'Full name *',
                                icon: Icons.badge_outlined,
                                hint: 'Enter candidate name',
                                validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Name is required'
                                    : null,
                              ),

                              _input(
                                _phone,
                                'Phone number',
                                icon: Icons.phone_outlined,
                                keyboard: TextInputType.phone,
                              ),
                            ),
                            _gap(),

                            _input(
                              _email,
                              'Email address',
                              icon: Icons.email_outlined,
                              keyboard: TextInputType.emailAddress,
                              validator: (v) {
                                final email = v?.trim() ?? '';
                                if (email.isNotEmpty &&
                                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                        .hasMatch(email)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),

                          ],
                        ),

                        _CandidateSection(
                          title: 'Professional information',
                          subtitle: 'Experience and salary expectations',
                          icon: Icons.workspace_premium_outlined,
                          children: [
                            _row(
                              _input(
                                _experience,
                                'Experience (years)',
                                icon: Icons.timeline_rounded,
                                keyboard: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isNotEmpty &&
                                      double.tryParse(value) == null) {
                                    return 'Enter valid experience';
                                  }
                                  return null;
                                },
                              ),
                              _input(
                                _company,
                                'Current company',
                                icon: Icons.business_outlined,
                                hint: 'Company name',
                              ),
                            ),
                            _gap(),
                            _input(
                              _salary,
                              'Expected salary / month',
                              icon: Icons.currency_rupee_rounded,
                              keyboard: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              hint: 'Enter expected monthly salary',
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isNotEmpty &&
                                    double.tryParse(value) == null) {
                                  return 'Enter a valid salary';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),

                        _CandidateSection(
                          title: 'Evaluation & pipeline',
                          subtitle: 'Candidate rating and recruitment stage',
                          icon: Icons.assessment_outlined,
                          children: [
                            _row(
                              _dropdown(
                                label: 'Candidate rating',
                                value: _rating,
                                icon: Icons.star_outline_rounded,
                                items: [
                                  for (final e in _ratings.entries)
                                    DropdownMenuItem(
                                      value: e.key,
                                      child: Text(e.value),
                                    ),
                                ],
                                onChanged: (v) {
                                  setState(() => _rating = v ?? '0');
                                },
                              ),
                              _dropdown(
                                label: 'Recruitment stage',
                                value: opts(kStages).containsKey(_stage)
                                    ? _stage
                                    : null,
                                icon: Icons.flag_outlined,
                                items: [
                                  for (final e in opts(kStages).entries)
                                    DropdownMenuItem(
                                      value: e.key,
                                      child: Text(e.value),
                                    ),
                                ],
                                onChanged: (v) {
                                  setState(() => _stage = v ?? 'Applied');
                                },
                              ),
                            ),
                            _gap(),
                            _input(
                              _notes,
                              'Notes',
                              icon: Icons.notes_rounded,
                              hint: 'Add remarks or interview observations...',
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _CandidateFooter(
              isNew: _isNew,
              onCancel: () => Navigator.pop(context),
              onSave: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateHeader extends StatelessWidget {
  const _CandidateHeader({
    required this.isNew,
    required this.onClose,
  });

  final bool isNew;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Color.lerp(
              Theme.of(context).colorScheme.primary,
              Colors.black,
              0.25,
            )!,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNew ? 'Add candidate' : 'Edit candidate',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isNew
                      ? 'Add a candidate to your recruitment pipeline'
                      : 'Update candidate information and evaluation',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _CandidateFooter extends StatelessWidget {
  const _CandidateFooter({
    required this.isNew,
    required this.onCancel,
    required this.onSave,
  });

  final bool isNew;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Fields marked * are required',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(isNew ? 'Save candidate' : 'Update candidate'),
          ),
        ],
      ),
    );
  }
}

class _CandidateSection extends StatelessWidget {
  const _CandidateSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: cs.onPrimaryContainer,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
