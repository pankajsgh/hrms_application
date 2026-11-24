
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:doc_text_extractor/doc_text_extractor.dart';

import 'package:hrms/comman_widget/customer_dropdown.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/data/global_data.dart';
import 'package:hrms/domain/entities/recruitment_entity.dart';

class CandidateFormDialog extends StatefulWidget {
  const CandidateFormDialog({
    super.key,
    required this.jobs,
    this.candidate,
    this.initialJobId,
  });

  final List<JobEntity> jobs;
  final CandidateEntity? candidate;
  final dynamic initialJobId;

  static Future<Map<String, Object?>?> show(
      BuildContext context, {
        required List<JobEntity> jobs,
        CandidateEntity? candidate,
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

  late final List<JobEntity> _availableJobs;

  final TextExtractor _extractor = TextExtractor();

  String? _jobId;
  String _source = '';
  String _rating = '0';
  String _stage = 'Applied';

  String? _resumePath;
  String? _originalResumePath;

  PlatformFile? _resumeFile;

  bool _isParsingResume = false;
  bool _didSubmit = false;

  CandidateEntity? get _candidate => widget.candidate;

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

    _availableJobs = widget.jobs.where((job) {
      return job.id != null &&
          (job.approval == 'Approved' || job.id == c?.jobId);
    }).toList();

    final currentJob = c?.jobId.toString();
    final requestedJob = widget.initialJobId?.toString();

    if (_availableJobs.any(
          (job) => job.id.toString() == currentJob,
    )) {
      _jobId = currentJob;
    } else if (_availableJobs.any(
          (job) => job.id.toString() == requestedJob,
    )) {
      _jobId = requestedJob;
    } else if (_availableJobs.isNotEmpty) {
      _jobId = _availableJobs.first.id.toString();
    }

    _name = TextEditingController(text: c?.name ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');

    _experience = TextEditingController(
      text: c?.experienceYears.toString() ?? '',
    );

    _company = TextEditingController(
      text: c?.currentCompany ?? '',
    );

    _salary = TextEditingController(
      text: c?.expectedSalary.toString() ?? '',
    );

    _notes = TextEditingController(text: c?.notes ?? '');

    _source = c?.source ?? '';
    _rating = c?.rating.toString() ?? '0';

    _resumePath = c?.resumePath;
    _originalResumePath = c?.resumePath;

    _stage = c?.stage.isNotEmpty == true ? c!.stage : 'Applied';

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

    // If the dialog was cancelled, delete a newly copied resume.
    // Never delete the original candidate resume here.
    if (!_didSubmit &&
        _resumePath != null &&
        _resumePath != _originalResumePath) {
      unawaited(_deleteLocalFile(_resumePath!));
    }

    super.dispose();
  }

  // ------------------------------------------------------------
  // LOCAL FILE STORAGE
  // ------------------------------------------------------------

  Future<String> _saveResumeLocally(PlatformFile file) async {
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Unable to read selected resume');
    }

    final appDir = await getApplicationSupportDirectory();

    final resumeDir = Directory(
      p.join(appDir.path, 'resumes'),
    );

    if (!await resumeDir.exists()) {
      await resumeDir.create(recursive: true);
    }

    final extension = p.extension(file.name).toLowerCase();

    final fileName =
        'resume_${DateTime.now().microsecondsSinceEpoch}$extension';

    final savedFile = File(
      p.join(resumeDir.path, fileName),
    );

    await savedFile.writeAsBytes(bytes, flush: true);

    return savedFile.path;
  }

  Future<void> _deleteLocalFile(String path) async {
    try {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Resume delete error: $e');
    }
  }

  // ------------------------------------------------------------
  // RESUME PICKER
  // ------------------------------------------------------------

  Future<void> _pickResume() async {
    if (_isParsingResume) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      if (file.bytes == null || file.bytes!.isEmpty) {
        toast(context, 'Unable to read selected resume');
        return;
      }

      setState(() {
        _isParsingResume = true;
      });

      // Copy the selected file into permanent local app storage.
      final newPath = await _saveResumeLocally(file);

      if (!mounted) {
        await _deleteLocalFile(newPath);
        return;
      }

      // Keep the previous path temporarily so cancellation
      // does not remove the original candidate attachment.
      final previousPath = _resumePath;

      setState(() {
        _resumeFile = file;
        _resumePath = newPath;
      });

      // Extract text and fill form fields.
      await _parseResume(newPath);

      // If the previous path was another newly uploaded file,
      // it can now be deleted.
      if (previousPath != null &&
          previousPath != _originalResumePath &&
          previousPath != newPath) {
        await _deleteLocalFile(previousPath);
      }
    } catch (e) {
      if (!mounted) return;

      toast(context, 'Resume upload failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isParsingResume = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // EXTRACT RESUME TEXT LOCALLY
  // ------------------------------------------------------------

  Future<void> _parseResume(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('Resume file does not exist');
      }

      // This reads the local file. No backend API is called.
      final result = await _extractor.extractText(
        filePath,
        isUrl: false,
      );

      final resumeText = result.text?.toString() ?? '';

      if (resumeText.trim().isEmpty) {
        throw Exception(
          'No readable text found. The PDF may be scanned or image-based.',
        );
      }

      if (!mounted) return;

      _fillCandidateFromResume(resumeText);

      toast(context, 'Resume saved and candidate details filled');
    } catch (e) {
      if (!mounted) return;

      toast(context, 'Resume extraction failed: $e');
    }
  }

  // ------------------------------------------------------------
  // RESUME DATA EXTRACTION
  // ------------------------------------------------------------

  String _findFirst(
      String text,
      List<RegExp> patterns,
      ) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);

      if (match == null) continue;

      final value = (match.groupCount >= 1
          ? match.group(1)
          : match.group(0))
          ?.trim();

      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  void _fillCandidateFromResume(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // NAME
    String name = _findFirst(text, [
      RegExp(
        r'(?:full\s*name|candidate\s*name|name)\s*[:\-]\s*([^\r\n]+)',
        caseSensitive: false,
      ),
    ]);

    // Fallback: first suitable line in the resume.
    if (name.isEmpty) {
      for (final line in lines.take(8)) {
        final lower = line.toLowerCase();

        final ignored = [
          'resume',
          'curriculum vitae',
          'curriculum',
          'profile',
          'contact',
          'personal details',
          'professional summary',
        ];

        if (line.length < 3 || line.length > 60) continue;
        if (line.contains('@')) continue;
        if (RegExp(r'\d{6,}').hasMatch(line)) continue;
        if (ignored.contains(lower)) continue;

        name = line;
        break;
      }
    }

    // EMAIL
    final email = _findFirst(text, [
      RegExp(
        r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
        caseSensitive: false,
      ),
    ]);

    // PHONE
    final phone = _findFirst(text, [
      RegExp(
        r'(?<!\d)(?:\+91[\s-]?)?[6-9]\d{9}(?!\d)',
      ),
    ]);

    // EXPERIENCE
    final experience = _findFirst(text, [
      RegExp(
        r'(\d+(?:\.\d+)?)\s*\+?\s*(?:years?|yrs?)\s*(?:of\s*)?(?:experience|exp)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:total\s*)?experience\s*[:\-]\s*(\d+(?:\.\d+)?)',
        caseSensitive: false,
      ),
    ]);

    // CURRENT COMPANY
    final company = _findFirst(text, [
      RegExp(
        r'(?:current\s*company|present\s*company|company)\s*[:\-]\s*([^\r\n]+)',
        caseSensitive: false,
      ),
    ]);

    // EXPECTED SALARY
    final salary = _findFirst(text, [
      RegExp(
        r'(?:expected\s*salary|salary\s*expectation|expected\s*ctc)\s*[:\-]\s*(?:₹|rs\.?\s*)?([0-9,]+(?:\.\d+)?\s*(?:lpa|lakhs?|k)?)',
        caseSensitive: false,
      ),
    ]);

    setState(() {
      // Only overwrite fields for which a value was extracted.
      if (name.isNotEmpty) {
        _name.text = name;
      }

      if (email.isNotEmpty) {
        _email.text = email;
      }

      if (phone.isNotEmpty) {
        _phone.text = phone;
      }

      if (experience.isNotEmpty) {
        _experience.text = experience;
      }

      if (company.isNotEmpty) {
        _company.text = company;
      }

      if (salary.isNotEmpty) {
        _salary.text = salary;
      }
    });
  }

  // ------------------------------------------------------------
  // REMOVE RESUME
  // ------------------------------------------------------------

  Future<void> _removeResume() async {
    final path = _resumePath;

    setState(() {
      _resumePath = null;
      _resumeFile = null;
    });

    // Delete only a newly selected file.
    // The original file remains untouched until the candidate
    // update is saved by the parent repository.
    if (path != null && path != _originalResumePath) {
      await _deleteLocalFile(path);
    }
  }

  // ------------------------------------------------------------
  // SUBMIT CANDIDATE
  // ------------------------------------------------------------

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_jobId == null) {
      toast(context, 'Please select a job opening');
      return;
    }

    _didSubmit = true;

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
      'resume_path': _resumePath,
    });
  }

  // ------------------------------------------------------------
  // INPUT DECORATION
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // RESUME BUTTON
  // ------------------------------------------------------------

  Widget _resumeUploadButton() {
    return OutlinedButton.icon(
      onPressed: _isParsingResume ? null : _pickResume,
      icon: _isParsingResume
          ? const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : const Icon(Icons.upload_file, size: 18),
      label: Text(
        _isParsingResume ? 'Reading...' : 'Upload Resume',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _resumeFileInfo() {
    if (_resumePath == null || _resumePath!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              p.basename(_resumePath!),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          IconButton(
            tooltip: 'Remove resume',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
            onPressed: _isParsingResume ? null : _removeResume,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // MAIN UI
  // ------------------------------------------------------------

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
                        // PERSONAL INFORMATION
                        _CandidateSection(
                          title: 'Personal information',
                          subtitle: 'Candidate contact details',
                          icon: Icons.person_outline_rounded,
                          trailing: Row(
                            children: [
                              Text("Auto fill", style: TextStyle(fontSize: 11, color: Colors.green),),
                              SizedBox(width: 12,),
                              _resumeUploadButton(),
                            ],
                          ),
                          children: [
                            _row(
                              CustomDropdown<String>(
                                label: 'Applying for',
                                value: _jobId,
                                icon: Icons.work_outline,
                                hint: 'Select job opening',
                                items: [
                                  for (final job in _availableJobs)
                                    DropdownMenuItem<String>(
                                      value: job.id.toString(),
                                      child: Text(
                                        job.title,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                                onChanged: (value) {
                                  setState(() => _jobId = value);
                                },
                              ),
                              CustomDropdown<String>(
                                label: 'Source',
                                value: opts(kSources).containsKey(_source)
                                    ? _source
                                    : null,
                                icon: Icons.source_outlined,
                                hint: 'Select Source',
                                items: [
                                  for (final e in opts(kSources).entries)
                                    DropdownMenuItem<String>(
                                      value: e.key,
                                      child: Text(e.value),
                                    ),
                                ],
                                onChanged: (value) {
                                  setState(() => _source = value ?? '');
                                },
                              ),
                            ),
                            _gap(),
                            _row(
                              _input(
                                _name,
                                'Full name *',
                                icon: Icons.badge_outlined,
                                hint: 'Enter candidate name',
                                validator: (value) =>
                                value == null || value.trim().isEmpty
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
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isNotEmpty &&
                                    !RegExp(
                                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                    ).hasMatch(email)) {
                                  return 'Enter a valid email';
                                }

                                return null;
                              },
                            ),
                            _resumeFileInfo(),
                          ],
                        ),

                        // PROFESSIONAL INFORMATION
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
                                keyboard:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';

                                  if (text.isNotEmpty &&
                                      double.tryParse(text) == null) {
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
                              keyboard:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              hint: 'Enter expected monthly salary',
                              validator: (value) {
                                final text = value?.trim() ?? '';

                                if (text.isNotEmpty &&
                                    double.tryParse(text) == null) {
                                  return 'Enter a valid salary';
                                }

                                return null;
                              },
                            ),
                          ],
                        ),

                        // EVALUATION AND PIPELINE
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
                                    DropdownMenuItem<String>(
                                      value: e.key,
                                      child: Text(e.value),
                                    ),
                                ],
                                onChanged: (value) {
                                  setState(() => _rating = value ?? '0');
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
                                    DropdownMenuItem<String>(
                                      value: e.key,
                                      child: Text(e.value),
                                    ),
                                ],
                                onChanged: (value) {
                                  setState(
                                        () => _stage = value ?? 'Applied',
                                  );
                                },
                              ),
                            ),
                            _gap(),
                            _input(
                              _notes,
                              'Notes',
                              icon: Icons.notes_rounded,
                              hint:
                              'Add remarks or interview observations...',
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
              onSave: _isParsingResume ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CANDIDATE HEADER
// ============================================================

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

// ============================================================
// CANDIDATE FOOTER
// ============================================================

class _CandidateFooter extends StatelessWidget {
  const _CandidateFooter({
    required this.isNew,
    required this.onCancel,
    required this.onSave,
  });

  final bool isNew;
  final VoidCallback onCancel;
  final VoidCallback? onSave;

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
            label: Text(
              isNew ? 'Save candidate' : 'Update candidate',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CANDIDATE SECTION
// ============================================================

class _CandidateSection extends StatelessWidget {
  const _CandidateSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

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
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
