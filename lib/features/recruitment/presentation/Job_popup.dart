  import 'package:flutter/material.dart';
  import 'package:hrms/comman_widget/customer_dropdown.dart';
  import 'package:hrms/data/global_data.dart';

  import 'package:hrms/core/common.dart';

  /// Popup used to create / edit a job opening.
  ///
  /// Usage:
  /// ```dart
  /// final data = await JobFormDialog.show(context, job: existingJob);
  /// if (data == null) return; // cancelled
  /// ```
  /// Returns a map ready to be sent to the repository, or `null` if cancelled.
  /// All controllers are owned (and disposed) by this widget, so callers never
  /// have to manage them.
  class JobFormDialog extends StatefulWidget {
    const JobFormDialog({super.key, this.job});

    final Rec? job;

    static Future<Map<String, Object?>?> show(BuildContext context, {Rec? job}) {
      return showDialog<Map<String, Object?>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => JobFormDialog(job: job),
      );
    }

    @override
    State<JobFormDialog> createState() => _JobFormDialogState();
  }

  class _JobFormDialogState extends State<JobFormDialog> {
    final _formKey = GlobalKey<FormState>();

    late final TextEditingController _title;
    late final TextEditingController _department;
    late final TextEditingController _location;
    late final TextEditingController _openings;
    late final TextEditingController _experience;
    late final TextEditingController _salaryMin;
    late final TextEditingController _salaryMax;
    late final TextEditingController _skills;
    late final TextEditingController _description;

    late final Map<String, String> _jobTypes;
    late final List<String> _branches;

    late String _employmentType;
    late String _status;
    String? _branch;
    DateTime? _closingDate;

    Rec? get _job => widget.job;
    bool get _isNew => _job == null;
    bool get _approved => _job != null && _job!.s('approval') == 'Approved';

    @override
    void initState() {
      super.initState();
      final j = _job;

      _title = TextEditingController(text: j?.s('title') ?? '');
      _department = TextEditingController(text: j?.s('department') ?? '');
      _location = TextEditingController(text: j?.s('location') ?? '');
      _openings = TextEditingController(text: '${j?['openings'] ?? 1}');
      _experience = TextEditingController(text: j?.s('experience') ?? '');
      _salaryMin = TextEditingController(text: j?['salary_min']?.toString() ?? '');
      _salaryMax = TextEditingController(text: j?['salary_max']?.toString() ?? '');
      _skills = TextEditingController(text: j?.s('skills') ?? '');
      _description = TextEditingController(text: j?.s('description') ?? '');

      // Employment type (keep a legacy value even if it's no longer an option).
      _jobTypes = Map<String, String>.from(opts(kJobTypes));
      final type = j?.s('employment_type') ?? '';
      _employmentType = type.isNotEmpty ? type : 'Full-time';
      _jobTypes.putIfAbsent(_employmentType, () => _employmentType);

      // Branch (keep a legacy value even if it's no longer an option).
      _branches = List<String>.from(kBranchOffices);
      final currentBranch = j?.s('branch').trim() ?? '';
      if (currentBranch.isNotEmpty && !_branches.contains(currentBranch)) {
        _branches.insert(0, currentBranch);
      }
      _branch = currentBranch.isNotEmpty
          ? currentBranch
          : (_branches.isEmpty ? null : _branches.first);

      final status = j?.s('status') ?? '';
      _status = status.isNotEmpty ? status : 'Open';

      final d = j?.s('closing_date') ?? '';
      if (d.isNotEmpty) _closingDate = DateTime.tryParse(d);
    }

    @override
    void dispose() {
      for (final c in [
        _title,
        _department,
        _location,
        _openings,
        _experience,
        _salaryMin,
        _salaryMax,
        _skills,
        _description,
      ]) {
        c.dispose();
      }
      super.dispose();
    }

    // ----------------------------------------------------------------- actions

    Future<void> _pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: _closingDate ?? DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 3650)),
        lastDate: DateTime(2100),
      );
      if (picked != null) setState(() => _closingDate = picked);
    }

    void _submit() {
      if (!_formKey.currentState!.validate()) return;

      Navigator.pop<Map<String, Object?>>(context, {
        'title': _title.text.trim(),
        'department': _department.text.trim(),
        'location': _location.text.trim(),
        'branch': _branch ?? '',
        'employment_type': _employmentType,
        'openings': int.parse(_openings.text.trim()),
        'experience': _experience.text.trim(),
        'salary_min': double.tryParse(_salaryMin.text.trim()),
        'salary_max': double.tryParse(_salaryMax.text.trim()),
        'skills': _skills.text.trim(),
        'closing_date': _closingDate == null ? null : ymd(_closingDate!),
        'description': _description.text.trim(),
        if (_approved) 'status': _status,
      });
    }

    // ------------------------------------------------------------------ helpers

    InputDecoration _decoration(String label, {IconData? icon, String? hint}) {
      final cs = Theme.of(context).colorScheme;
      OutlineInputBorder border(Color color, [double width = 1]) =>
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color, width: width),
          );

      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, size: 18),
        isDense: true,
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: const TextStyle(fontSize: 12.5),
        hintStyle: TextStyle(fontSize: 12, color: cs.outline),
        border: border(cs.outlineVariant),
        enabledBorder: border(cs.outlineVariant),
        focusedBorder: border(cs.primary, 1.6),
        errorBorder: border(cs.error),
        focusedErrorBorder: border(cs.error, 1.6),
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

    /// Two fields side by side on wide screens, stacked on narrow ones.
    Widget _row(Widget a, Widget b) {
      return LayoutBuilder(builder: (context, box) {
        if (box.maxWidth < 480) {
          return Column(children: [a, const SizedBox(height: 12), b]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.end,

            children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ]);
      });
    }

    Widget _gap() => const SizedBox(height: 12);

    // -------------------------------------------------------------------- build

    @override
    Widget build(BuildContext context) {
      final cs = Theme.of(context).colorScheme;

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 760,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(isNew: _isNew, onClose: () => Navigator.pop(context)),
              Flexible(
                child: Container(
                  color: cs.surfaceContainerLow,
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        _Section(
                          title: 'Job information',
                          subtitle: 'Position and employment details',
                          icon: Icons.work_outline,
                          children: [
                            _input(
                              _title,
                              'Job title *',
                              icon: Icons.badge_outlined,
                              hint: 'e.g. Flutter Developer',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Job title is required'
                                  : null,
                            ),
                            _gap(),
                            _row(
                              CustomDropdown<String>(
                                label: 'Department',
                                value: _department.text.isEmpty
                                    ? departmentOptions.first
                                    : _department.text,
                                icon: Icons.apartment,
                                items: [
                                  for (final department
                                  in departmentOptions)
                                    DropdownMenuItem(
                                      value: department,
                                      child: Text(
                                        department,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _department.text = value ?? '';
                                  });
                                },
                              ),
                              CustomDropdown<String>(
                                label: 'Employment type *',
                                value: _employmentType,
                                icon: Icons.schedule_outlined,
                                hint: 'Select type',
                                items: [
                                  for (final e in _jobTypes.entries)
                                    DropdownMenuItem<String>(
                                      value: e.key,
                                      child: Text(e.value,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                ],
                                onChanged: (v) => setState(
                                        () => _employmentType = v ?? _employmentType),
                              ),
                            ),
                            _gap(),
                            _row(
                              _input(
                                _openings,
                                'Number of openings *',
                                icon: Icons.people_outline,
                                keyboard: TextInputType.number,
                                validator: (v) {
                                  final n = int.tryParse(v?.trim() ?? '');
                                  return (n == null || n <= 0)
                                      ? 'Enter a valid number'
                                      : null;
                                },
                              ),
                              _input(
                                _experience,
                                'Experience required',
                                icon: Icons.workspace_premium_outlined,
                                hint: 'e.g. 2-4 years',
                              ),
                            ),
                          ],
                        ),
                        _Section(
                          title: 'Location & branch',
                          subtitle: 'Where this position will be based',
                          icon: Icons.location_on_outlined,
                          children: [
                            _row(
                              _branches.isEmpty
                                  ? _input(
                                TextEditingController(),
                                'Branch office (not configured)',
                                icon: Icons.business_outlined,
                              )
                                  : CustomDropdown<String>(
                                label: 'Branch office',
                                value: _branch,
                                icon: Icons.business_outlined,
                                hint: 'Select branch',
                                items: [
                                  for (final b in _branches)
                                    DropdownMenuItem<String>(
                                      value: b,
                                      child: Text(b,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _branch = v ?? _branch),
                              ),
                              _input(
                                _location,
                                'Job location',
                                icon: Icons.location_on_outlined,
                                hint: 'e.g. Delhi / Remote',
                              ),
                            ),
                          ],
                        ),
                        _Section(
                          title: 'Salary',
                          subtitle: 'Monthly salary range in INR',
                          icon: Icons.currency_rupee,
                          children: [
                            _row(
                              _input(
                                _salaryMin,
                                'Minimum salary',
                                icon: Icons.currency_rupee,
                                hint: 'e.g. 25000',
                                keyboard: const TextInputType.numberWithOptions(
                                    decimal: true),
                              ),
                              _input(
                                _salaryMax,
                                'Maximum salary',
                                icon: Icons.currency_rupee,
                                hint: 'e.g. 50000',
                                keyboard: const TextInputType.numberWithOptions(
                                    decimal: true),
                                validator: (v) {
                                  final min =
                                  double.tryParse(_salaryMin.text.trim());
                                  final max = double.tryParse(v?.trim() ?? '');
                                  if (min != null && max != null && max < min) {
                                    return 'Must be ≥ minimum salary';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        _Section(
                          title: 'Requirements & deadline',
                          subtitle: 'Skills and application deadline',
                          icon: Icons.checklist_rounded,
                          children: [
                            _input(
                              _skills,
                              'Required skills',
                              icon: Icons.code_rounded,
                              hint: 'Flutter, Dart, REST API',
                            ),
                            _gap(),
                            _DateField(
                              decoration: _decoration('Apply before',
                                  icon: Icons.calendar_month_outlined),
                              date: _closingDate,
                              onTap: _pickDate,
                              onClear: _closingDate == null
                                  ? null
                                  : () => setState(() => _closingDate = null),
                            ),
                          ],
                        ),
                        _Section(
                          title: 'Job description',
                          subtitle: 'Responsibilities and qualifications',
                          icon: Icons.description_outlined,
                          children: [
                            _input(
                              _description,
                              'Description',
                              icon: Icons.notes_rounded,
                              hint: 'Enter job responsibilities, qualifications…',
                              maxLines: 5,
                            ),
                          ],
                        ),
                        if (_approved)
                          _Section(
                            title: 'Job status',
                            subtitle: 'Change the current job opening status',
                            icon: Icons.toggle_on_outlined,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _status,
                                isExpanded: true,
                                borderRadius: BorderRadius.circular(12),
                                decoration: _decoration('Status',
                                    icon: Icons.flag_outlined),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Open', child: Text('Open')),
                                  DropdownMenuItem(
                                      value: 'On hold', child: Text('On hold')),
                                  DropdownMenuItem(
                                      value: 'Closed', child: Text('Closed')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _status = v ?? _status),
                              ),
                            ],
                          ),
                      ]),
                    ),
                  ),
                ),
              ),
              _Footer(isNew: _isNew, onCancel: () => Navigator.pop(context), onSave: _submit),
            ],
          ),
        ),
      );
    }
  }

  // ============================================================ private parts

  class _Header extends StatelessWidget {
    const _Header({required this.isNew, required this.onClose});

    final bool isNew;
    final VoidCallback onClose;

    @override
    Widget build(BuildContext context) {
      final cs = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, Color.lerp(cs.primary, Colors.black, 0.25)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work_outline_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isNew ? 'New job opening' : 'Edit job opening',
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                isNew
                    ? 'Create a new recruitment opportunity'
                    : 'Update job opening information',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5),
              ),
            ]),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ]),
      );
    }
  }

  class _Footer extends StatelessWidget {
    const _Footer({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              isNew ? 'Fields marked * are required' : 'Review and update the job',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ),
          OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(isNew ? 'Save job' : 'Update job'),
          ),
        ]),
      );
    }
  }

  class _Section extends StatelessWidget {
    const _Section({
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
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: cs.onPrimaryContainer, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11, color: cs.onSurfaceVariant)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          ...children,
        ]),
      );
    }
  }

  class _DateField extends StatelessWidget {
    const _DateField({
      required this.decoration,
      required this.date,
      required this.onTap,
      this.onClear,
    });

    final InputDecoration decoration;
    final DateTime? date;
    final VoidCallback onTap;
    final VoidCallback? onClear;

    @override
    Widget build(BuildContext context) {
      final cs = Theme.of(context).colorScheme;
      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: InputDecorator(
          decoration: decoration,
          child: Row(children: [
            Expanded(
              child: Text(
                date == null ? 'Select closing date' : ymd(date!),
                style: TextStyle(
                  fontSize: 13,
                  color: date == null ? cs.onSurfaceVariant : cs.onSurface,
                ),
              ),
            ),
            if (onClear != null)
              InkWell(
                onTap: onClear,
                child: Icon(Icons.clear, size: 16, color: cs.outline),
              ),
            const SizedBox(width: 8),
            Icon(Icons.edit_calendar_outlined, size: 18, color: cs.primary),
          ]),
        ),
      );
    }
  }