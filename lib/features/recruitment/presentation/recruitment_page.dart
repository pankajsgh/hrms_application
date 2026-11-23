import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import 'package:hrms/domain/entities/recruitment_entity.dart';
import 'package:hrms/features/recruitment/presentation/Job_popup.dart';
import 'package:hrms/features/recruitment/presentation/candidate_dialog.dart';
import 'package:hrms/features/recruitment/presentation/candidate_popup.dart';
import 'package:intl/intl.dart';

import '../../employees/data/employees_repository.dart';
import '../../employees/presentation/employee_form.dart';
import '../data/recruitment_repository.dart';

class RecruitmentFeaturePage extends StatefulWidget {
  const RecruitmentFeaturePage({super.key});

  @override
  State<RecruitmentFeaturePage> createState() =>
      _RecruitmentFeaturePageState();
}

class _RecruitmentFeaturePageState extends State<RecruitmentFeaturePage> {
  final RecruitmentRepository _repo = RecruitmentRepository();

  Timer? _searchDebounce;

  int _tab = 0;
  List<JobEntity> _jobs = [];
  List<CandidateEntity> _cands = [];
  List<InterviewEntity> _ints = [];
  Map<String, int> _stats = {};

  String _jobFilter = 'All';
  int? _pipeJob;
  String _q = '';
  bool _board = true;
  String _intFilter = 'Upcoming';

  static const _stageColors = <String, Color>{
    'Applied': Colors.blueGrey,
    'Screening': Colors.orange,
    'Interview': Colors.blue,
    'Offered': Colors.purple,
    'Hired': Colors.green,
    'Rejected': Colors.red,
  };

  static const _jobStatusColors = <String, Color>{
    'Open': Colors.green,
    'On hold': Colors.orange,
    'Closed': Colors.blueGrey,
    'Pending approval': Colors.orange,
    'Rejected': Colors.red,
  };

  bool get _narrow => MediaQuery.of(context).size.width < 800;

  // ---------------------------------------------------------------- lifecycle

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final jobs = await _repo.jobs();

      if (_pipeJob != null && !jobs.any((j) => j.id == _pipeJob)) {
        _pipeJob = null;
      }

      final cands = await _repo.candidates(jobId: _pipeJob, q: _q);
      final ints = await _repo.interviews();
      final stats = await _repo.recruitmentStats();

      if (!mounted) return;

      setState(() {
        _jobs = jobs;
        _cands = cands;
        _ints = ints;
        _stats = stats;
      });
    } catch (e) {
      if (mounted) {
        toast(context, 'Could not load recruitment data: $e');
      }
    }
  }

  String _jobStatus(JobEntity job) {
    if (job.approval == 'Pending') return 'Pending approval';
    if (job.approval == 'Rejected') return 'Rejected';
    return job.status;
  }

  int _toInt(Object? value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _toDouble(Object? value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _toString(Object? value, [String fallback = '']) {
    return value?.toString() ?? fallback;
  }

  // --------------------------------------------------------------------- jobs

  Future<void> _editJob([JobEntity? job]) async {
    // The popup receives a map so it remains compatible with the existing
    // JobFormDialog implementation.
    final data = await JobFormDialog.show(
      context,
      job: job?.toMap(),
    );

    if (data == null) return;

    final map = Map<String, Object?>.from(data as Map);

    final entity = JobEntity(
      id: job?.id,
      title: _toString(map['title']),
      department: _toString(map['department']),
      description: _toString(map['description']),
      status: _toString(map['status'], job?.status ?? 'Open'),
      approval: job?.approval ?? 'Pending',
      createdBy: job?.createdBy,
      createdOn: job?.createdOn,
      approvedBy: job?.approvedBy,
      approvedOn: job?.approvedOn,
      rejectReason: job?.rejectReason,
      cands: job?.cands,
      creatorName: job?.creatorName,
    );

    if (entity.title.trim().isEmpty) {
      toast(context, 'Job title is required');
      return;
    }

    try {
      if (job == null) {
        await _repo.createJob(entity);

        if (mounted) {
          toast(
            context,
            Session.isAdmin
                ? 'Job published'
                : 'Job sent to admin for approval',
          );
        }
      } else {
        await _repo.updateJob(
          job.id!,
          entity,
          currentApproval: job.approval,
        );

        if (mounted &&
            job.approval == 'Rejected' &&
            !Session.isAdmin) {
          toast(context, 'Job re-sent to admin for approval');
        }
      }

      await _load();
    } catch (e) {
      if (mounted) toast(context, 'Could not save job: $e');
    }
  }

  Future<void> _approve(JobEntity job) async {
    if (job.id == null) return;

    await _repo.decideJob(job.id!, true, '');

    if (mounted) {
      toast(context, '"${job.title}" approved and published');
    }

    await _load();
  }

  Future<void> _reject(JobEntity job) async {
    if (job.id == null) return;

    final result = await formDialog(
      context,
      'Reject "${job.title}"',
      const [
        F(
          'reason',
          'Reason (shown to the person who created it)',
          type: 'multiline',
          required: true,
        ),
      ],
      saveLabel: 'Reject',
    );

    if (result == null) return;

    await _repo.decideJob(
      job.id!,
      false,
      result['reason'] as String,
    );

    await _load();
  }

  Future<void> _deleteJob(JobEntity job) async {
    if (job.id == null) return;

    final ok = await confirm(
      context,
      'Delete job?',
      'This also deletes its candidates and interviews.',
    );

    if (!ok) return;

    await _repo.deleteJob(job.id!);
    await _load();
  }

  void _openCandidatesOf(JobEntity job) {
    setState(() {
      _pipeJob = job.id;
      _tab = 1;
    });

    _load();
  }

  // ----------------------------------------------------------- small widgets

  Widget _meta(IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: cs.outline),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _pill(String text) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          color: cs.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String message) {
    final cs = Theme.of(context).colorScheme;

    return Panel(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 44,
                color: cs.outlineVariant,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChips<T>({
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onSelected,
  }) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final value in values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label(value)),
                selected: selected == value,
                onSelected: (_) => onSelected(value),
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- jobs: card

  Widget _jobCard(JobEntity job) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final approval = job.approval;
    final status = _jobStatus(job);
    final accent = _jobStatusColors[status] ?? cs.primary;

    final canDelete = Session.isAdmin ||
        (approval != 'Approved' && job.createdBy == Session.empId);

    final where = job.department;

    return Panel(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(status),
                      ],
                    ),
                    if (where.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        where,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        _meta(
                          Icons.person_outline,
                          '${job.cands ?? 0} candidates',
                        ),
                        _meta(
                          Icons.approval_outlined,
                          job.approval,
                        ),
                      ],
                    ),
                    if (job.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        job.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (approval == 'Pending') ...[
                      const SizedBox(height: 12),
                      _notice(
                        Icons.hourglass_top,
                        Colors.orange,
                        'Waiting for admin approval'
                            '${(job.creatorName ?? '').isEmpty ? '' : ' • by ${job.creatorName}'}',
                      ),
                    ],
                    if (approval == 'Rejected') ...[
                      const SizedBox(height: 12),
                      _notice(
                        Icons.block,
                        cs.error,
                        'Rejected'
                            '${(job.rejectReason ?? '').isEmpty ? '' : ': ${job.rejectReason}'}'
                            '${Session.isAdmin ? '' : '\nEdit the job to send it for approval again.'}',
                      ),
                    ],
                    const Divider(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (Session.isAdmin && approval == 'Pending') ...[
                          FilledButton.icon(
                            onPressed: () => _approve(job),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Approve'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _reject(job),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Reject'),
                          ),
                        ],
                        if (approval == 'Approved')
                          TextButton.icon(
                            onPressed: () => _openCandidatesOf(job),
                            icon: const Icon(
                              Icons.people_alt_outlined,
                              size: 18,
                            ),
                            label: const Text('Candidates'),
                          ),
                        TextButton.icon(
                          onPressed: () => _editJob(job),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                          ),
                          label: const Text('Edit'),
                        ),
                        if (canDelete)
                          TextButton.icon(
                            onPressed: () => _deleteJob(job),
                            style: TextButton.styleFrom(
                              foregroundColor: cs.error,
                            ),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                            ),
                            label: const Text('Delete'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notice(IconData icon, Color color, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _jobsTab() {
    const filters = [
      'All',
      'Pending approval',
      'Open',
      'On hold',
      'Closed',
      'Rejected',
    ];

    int count(String filter) {
      if (filter == 'All') return _jobs.length;

      return _jobs
          .where((job) => _jobStatus(job) == filter)
          .length;
    }

    final list = _jobs
        .where(
          (job) =>
      _jobFilter == 'All' || _jobStatus(job) == _jobFilter,
    )
        .toList();

    final pending = _stats['pendingJobs'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (Session.isAdmin && pending > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(
                    Icons.approval_outlined,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$pending job(s) waiting for your approval',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _jobFilter = 'Pending approval';
                      });
                    },
                    child: const Text('Review'),
                  ),
                ],
              ),
            ),
          ),
        _filterChips<String>(
          values: filters,
          selected: _jobFilter,
          label: (filter) => '$filter (${count(filter)})',
          onSelected: (filter) {
            setState(() {
              _jobFilter = filter;
            });
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: list.isEmpty
              ? _emptyState(
            Icons.work_off_outlined,
            'No jobs here yet. Tap "New job" to create one.',
          )
              : LayoutBuilder(
            builder: (context, constraints) {
              final cols = (constraints.maxWidth / 400)
                  .floor()
                  .clamp(1, 4)
                  .toInt();

              final width = (constraints.maxWidth -
                  16 * (cols - 1)) /
                  cols;

              return SingleChildScrollView(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final job in list)
                      SizedBox(
                        width: width,
                        child: _jobCard(job),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- candidates

  Map<String, Object?> _candidateDialogMap(CandidateEntity candidate) {
    return {
      ...candidate.toMap(),
      'job_title': candidate.jobTitle,
      'job_department': candidate.jobDepartment,
      'next_interview': candidate.nextInterview,
    };
  }

  Future<void> _editCandidate([CandidateEntity? candidate]) async {
    final approvedJobs = _jobs
        .where((job) => job.approval == 'Approved')
        .toList();

    if (approvedJobs.isEmpty && candidate == null) {
      toast(
        context,
        'No approved job yet. Create a job and get it approved first.',
      );
      return;
    }

    final result = await CandidateFormDialog.show(
      context,
      jobs: _jobs,
      candidate: candidate,
      initialJobId: candidate?.jobId ?? _pipeJob,
    );

    if (result == null) return;

    final now = ymd(DateTime.now());

    final entity = CandidateEntity(
      id: candidate?.id,
      jobId: _toInt(result['job']),
      name: _toString(result['name']),
      email: _toString(result['email']),
      phone: _toString(result['phone']),
      source: _toString(result['source']),
      experienceYears: _toDouble(result['experience_years']),
      currentCompany: _toString(result['current_company']),
      expectedSalary: _toDouble(result['expected_salary']),
      rating: _toInt(result['rating']),
      stage: _toString(result['stage'], 'Applied'),
      notes: _toString(result['notes']),
      appliedOn: candidate?.appliedOn ?? now,
      resumePath: candidate?.resumePath,
      convertedEmployeeId: candidate?.convertedEmployeeId,
      jobTitle: candidate?.jobTitle,
      jobDepartment: candidate?.jobDepartment,
      nextInterview: candidate?.nextInterview,
    );

    if (entity.jobId == 0 || entity.name.trim().isEmpty) {
      toast(context, 'Please select a job and enter candidate name');
      return;
    }

    try {
      await _repo.saveCandidate(entity, id: candidate?.id);
      await _load();
    } catch (e) {
      if (mounted) {
        toast(context, 'Could not save candidate: $e');
      }
    }
  }
  Future<void> _deleteCandidate(CandidateEntity candidate) async {
    if (candidate.id == null) return;

    final ok = await confirm(
      context,
      'Delete candidate?',
      '${candidate.name} and their interviews will be removed.',
    );

    if (!ok) return;

    await _repo.deleteCandidate(candidate.id!);
    await _load();
  }

  Future<void> _attachResume(CandidateEntity candidate) async {
    if (candidate.id == null) return;

    try {
      final pick = await FilePicker.platform.pickFiles();
      final path = pick?.files.single.path;

      if (path == null) return;

      await _repo.attachResume(candidate.id!, path);

      if (mounted) {
        toast(context, 'Resume attached');
      }

      await _load();
    } catch (e) {
      if (mounted) {
        toast(context, 'Could not attach resume: $e');
      }
    }
  }

  Future<void> _convert(CandidateEntity candidate) async {
    if (candidate.id == null) return;

    final employee = EmployeeEntity(
      code: '',
      name: candidate.name,
      email: candidate.email,
      phone: candidate.phone,
      designation: candidate.jobTitle ?? '',
      department: candidate.jobDepartment ?? '',
    );

    final id = await showEmployeeForm(
      context,
      existing: employee,
    );

    if (id == null) return;

    await _repo.markConverted(candidate.id!, id);

    if (!mounted) return;

    toast(context, 'Employee created from ${candidate.name}');

    await _load();
  }
  Future<void> _details(CandidateEntity candidate) async {
    if (candidate.id == null) return;

    final interviews =
    await _repo.candidateInterviews(candidate.id!);

    if (!mounted) return;

    final action = await CandidateDetailsDialog.show(
      context,
      candidate: candidate,
      interviews: interviews,
    );

    if (action == null) return;

    switch (action) {
      case CandidateAction.edit:
        await _editCandidate(candidate);
        break;

      case CandidateAction.openResume:
      // Open the stored resume file here if you add a file-opening package.
        break;

      case CandidateAction.attachResume:
        await _attachResume(candidate);
        break;

      case CandidateAction.scheduleInterview:
        await _scheduleInterview(
          candidate.id!,
          candidate.name,
        );
        break;

      case CandidateAction.convert:
        await _convert(candidate);
        break;
    }
  }

  Widget _candCard(CandidateEntity candidate) {
    final cs = Theme.of(context).colorScheme;
    final next = DateTime.tryParse(candidate.nextInterview ?? '');
    final rating = candidate.rating.clamp(0, 5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _details(candidate),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        candidate.name.isEmpty
                            ? '?'
                            : candidate.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        candidate.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _candMenu(candidate),
                  ],
                ),
                if (_pipeJob == null &&
                    (candidate.jobTitle ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                      top: 2,
                    ),
                    child: Text(
                      candidate.jobTitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (rating > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '★' * rating + '☆' * (5 - rating),
                      style: TextStyle(
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (candidate.source.isNotEmpty)
                        _pill(candidate.source),
                      if (candidate.experienceYears > 0)
                        _pill('${nf(candidate.experienceYears)} yrs'),
                      if (candidate.expectedSalary > 0)
                        _pill(money(candidate.expectedSalary)),
                      if (candidate.convertedEmployeeId != null)
                        _pill('Employee'),
                    ],
                  ),
                ),
                if (next != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 6,
                      right: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 14,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM, hh:mm a').format(next),
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _candMenu(CandidateEntity candidate) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      iconSize: 20,
      icon: const Icon(Icons.more_vert),
      tooltip: 'Actions',
      onSelected: (value) async {
        if (candidate.id == null) return;

        if (value.startsWith('stage:')) {
          await _repo.setStage(
            candidate.id!,
            value.substring(6),
          );
          await _load();
        } else if (value == 'edit') {
          await _editCandidate(candidate);
        } else if (value == 'interview') {
          await _scheduleInterview(
            candidate.id!,
            candidate.name,
          );
        } else if (value == 'delete') {
          await _deleteCandidate(candidate);
        }
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        for (final stage in kStages)
          if (stage != candidate.stage)
            PopupMenuItem(
              value: 'stage:$stage',
              child: Text('Move to $stage'),
            ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'interview',
          child: Text('Schedule interview'),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Text('Edit'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
    );
  }

  Widget _stageColumn(String stage) {
    final cs = Theme.of(context).colorScheme;

    final items = _cands
        .where((candidate) => candidate.stage == stage)
        .toList();

    final color = _stageColors[stage] ?? Colors.blueGrey;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 280,
        child: Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  border: Border(
                    bottom: BorderSide(
                      color: color,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stage,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                  child: Text(
                    'No candidates',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
                    : ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    for (final candidate in items)
                      _candCard(candidate),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _boardView() {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (final stage in kStages) _stageColumn(stage),
      ],
    );
  }

  Widget _listView() {
    return TableCard(
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Applying for')),
        DataColumn(label: Text('Stage')),
        DataColumn(label: Text('Rating')),
        DataColumn(label: Text('Source')),
        DataColumn(label: Text('Expected'), numeric: true),
        DataColumn(label: Text('')),
      ],
      rows: [
        for (final candidate in _cands)
          DataRow(
            selected: false,
            onSelectChanged: (_) => _details(candidate),
            cells: [
              DataCell(Text(candidate.name)),
              DataCell(Text(candidate.jobTitle ?? '')),
              DataCell(
                DropdownButton<String>(
                  value: candidate.stage,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final stage in kStages)
                      DropdownMenuItem(
                        value: stage,
                        child: Text(stage),
                      ),
                  ],
                  onChanged: (value) async {
                    if (value == null || candidate.id == null) return;

                    await _repo.setStage(candidate.id!, value);
                    await _load();
                  },
                ),
              ),
              DataCell(
                Text('★' * candidate.rating.clamp(0, 5)),
              ),
              DataCell(Text(candidate.source)),
              DataCell(
                Text(
                  candidate.expectedSalary > 0
                      ? money(candidate.expectedSalary)
                      : '',
                ),
              ),
              DataCell(_candMenu(candidate)),
            ],
          ),
      ],
      empty: 'No candidates found.',
    );
  }

  Widget _pipelineTab() {
    final approvedJobs =
    _jobs.where((job) => job.approval == 'Approved').toList();

    final narrow = _narrow;

    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: narrow ? double.infinity : 260,
              child: DropdownButtonFormField<int?>(
                value: _pipeJob,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Job',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All jobs'),
                  ),
                  for (final job in approvedJobs)
                    DropdownMenuItem<int?>(
                      value: job.id,
                      child: Text(
                        job.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _pipeJob = value;
                  });
                  _load();
                },
              ),
            ),
            SizedBox(
              width: narrow ? double.infinity : 240,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search candidates',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _q = value.trim();
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 350),
                    _load,
                  );
                },
              ),
            ),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.view_kanban_outlined),
                  label: Text('Board'),
                ),
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.list),
                  label: Text('List'),
                ),
              ],
              selected: {_board},
              onSelectionChanged: (selection) {
                setState(() {
                  _board = selection.first;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _board ? _boardView() : _listView(),
        ),
      ],
    );
  }

  // --------------------------------------------------------------- interviews

  Future<void> _scheduleInterview(
      int candidateId,
      String candidateName, {
        InterviewEntity? existing,
      }) async {
    final employees =
    await EmployeesRepository().employees(activeOnly: true);

    if (!mounted) return;

    final dt = DateTime.tryParse(existing?.scheduledAt ?? '');

    final result = await formDialog(
      context,
      existing == null
          ? 'Schedule interview: $candidateName'
          : 'Edit interview',
      [
        F(
          'round',
          'Round',
          type: 'dropdown',
          required: true,
          options: opts(kRounds),
          initial: existing?.round ?? kRounds.first,
        ),
        F(
          'date',
          'Date',
          type: 'date',
          required: true,
          initial: dt == null ? null : ymd(dt),
        ),
        F(
          'time',
          'Time',
          type: 'time',
          required: true,
          initial: dt == null
              ? '10:00'
              : DateFormat('HH:mm').format(dt),
        ),
        F(
          'interviewer',
          'Interviewer',
          type: 'dropdown',
          required: true,
          options: {
            for (final employee in employees)
              '${employee.id}': employee.name,
          },
          initial: existing?.interviewerId.toString(),
        ),
        F(
          'feedback',
          'Feedback',
          type: 'multiline',
          initial: existing?.feedback,
        ),
      ],
      saveLabel: existing == null ? 'Schedule' : 'Save',
    );

    if (result == null) return;

    final interviewerId = int.tryParse(
      '${result['interviewer'] ?? ''}',
    );

    if (interviewerId == null) {
      toast(context, 'Please select an interviewer');
      return;
    }

    final entity = InterviewEntity(
      id: existing?.id,
      candidateId: candidateId,
      interviewerId: interviewerId,
      round: _toString(result['round']),
      scheduledAt: '${result['date']}T${result['time']}:00',
      result: existing?.result ?? 'Scheduled',
      feedback: _toString(result['feedback']),
      candName: existing?.candName ?? candidateName,
      jobTitle: existing?.jobTitle,
      interviewerName: existing?.interviewerName,
    );

    await _repo.saveInterview(
      entity,
      id: existing?.id,
    );

    if (mounted) {
      toast(context, 'Interview saved');
    }

    await _load();
  }

  Future<void> _setResult(InterviewEntity interview) async {
    if (interview.id == null) return;

    final result = await formDialog(
      context,
      'Interview result: ${interview.candName ?? ''}',
      [
        F(
          'result',
          'Result',
          type: 'dropdown',
          required: true,
          options: opts(kInterviewResults),
          initial: interview.result,
        ),
        F(
          'feedback',
          'Feedback',
          type: 'multiline',
          initial: interview.feedback,
        ),
      ],
    );

    if (result == null) return;

    await _repo.setInterviewResult(
      interview.id!,
      result['result'] as String,
      result['feedback'] as String,
    );

    await _load();
  }

  Widget _intCard(InterviewEntity interview) {
    final theme = Theme.of(context);

    final dt = DateTime.tryParse(interview.scheduledAt);
    final isToday = dt != null && ymd(dt) == ymd(today());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DateBadge(dt, highlight: isToday),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    interview.candName ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    interview.jobTitle ?? '',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text([
                    interview.round,
                    if (dt != null)
                      DateFormat('hh:mm a').format(dt),
                    if ((interview.interviewerName ?? '').isNotEmpty)
                      'with ${interview.interviewerName}',
                  ].where((value) => value.isNotEmpty).join('  •  ')),
                  if (interview.feedback.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Feedback: ${interview.feedback}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(interview.result),
                PopupMenuButton<String>(
                  tooltip: 'Actions',
                  onSelected: (value) async {
                    if (value == 'result') {
                      await _setResult(interview);
                    } else if (value == 'edit') {
                      await _scheduleInterview(
                        interview.candidateId,
                        interview.candName ?? '',
                        existing: interview,
                      );
                    } else if (value == 'delete') {
                      if (interview.id == null) return;

                      await _repo.deleteInterview(interview.id!);
                      await _load();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'result',
                      child: Text('Update result'),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Reschedule / edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _interviewsTab() {
    final now = ymd(DateTime.now());

    final list = _ints.where((interview) {
      final scheduled = interview.result == 'Scheduled';
      final upcoming = scheduled &&
          interview.scheduledAt.compareTo(now) >= 0;

      if (_intFilter == 'Upcoming') return upcoming;
      if (_intFilter == 'Completed') return !scheduled;

      return true;
    }).toList();

    if (_intFilter == 'Upcoming') {
      list.sort(
            (a, b) => a.scheduledAt.compareTo(b.scheduledAt),
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _filterChips<String>(
            values: const ['Upcoming', 'Completed', 'All'],
            selected: _intFilter,
            label: (filter) => filter,
            onSelected: (filter) {
              setState(() {
                _intFilter = filter;
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: list.isEmpty
              ? _emptyState(
            Icons.event_busy_outlined,
            'No interviews here. Open a candidate and choose "Schedule interview".',
          )
              : ListView(
            children: [
              for (final interview in list)
                _intCard(interview),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------- build

  Widget _statsRow() {
    final items = [
      (
      'Open jobs',
      _stats['openJobs'] ?? 0,
      Icons.work_outline,
      Colors.teal,
      ),
      (
      'Awaiting approval',
      _stats['pendingJobs'] ?? 0,
      Icons.hourglass_top,
      Colors.orange,
      ),
      (
      'Active candidates',
      _stats['candidates'] ?? 0,
      Icons.people_outline,
      Colors.indigo,
      ),
      (
      'Interviews ahead',
      _stats['interviews'] ?? 0,
      Icons.event_available,
      Colors.blue,
      ),
      (
      'Hired this month',
      _stats['hired'] ?? 0,
      Icons.verified_outlined,
      Colors.green,
      ),
    ];

    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: StatCard(
                item.$1,
                '${item.$2}',
                item.$3,
                item.$4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _primaryAction() {
    final narrow = _narrow;

    Widget button(
        IconData icon,
        String label,
        VoidCallback onTap,
        ) {
      return narrow
          ? Tooltip(
        message: label,
        child: FilledButton(
          onPressed: onTap,
          child: Icon(icon),
        ),
      )
          : FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    switch (_tab) {
      case 0:
        return button(
          Icons.add,
          'New job',
              () => _editJob(),
        );

      case 1:
        return button(
          Icons.person_add_alt,
          'Add candidate',
              () => _editCandidate(),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    const tabs = [
      'Jobs',
      'Pipeline',
      'Interviews',
    ];

    return PageBox(
      child: Column(
        children: [
          const Header('Recruitment'),
          _statsRow(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _filterChips<int>(
                  values: List.generate(tabs.length, (index) => index),
                  selected: _tab,
                  label: (index) => tabs[index],
                  onSelected: (index) {
                    setState(() {
                      _tab = index;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              _primaryAction(),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: switch (_tab) {
              0 => _jobsTab(),
              1 => _pipelineTab(),
              _ => _interviewsTab(),
            },
          ),
        ],
      ),
    );
  }
}