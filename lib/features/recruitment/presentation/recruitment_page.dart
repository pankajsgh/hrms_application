import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/data/global_data.dart';
import 'package:hrms/domain/entities/employee_entity.dart';
import 'package:hrms/domain/entities/recruitment_entity.dart';
import 'package:hrms/features/recruitment/presentation/Job_popup.dart';
import 'package:hrms/features/recruitment/presentation/candidate_dialog.dart';
import 'package:hrms/features/recruitment/presentation/candidate_popup.dart';
import 'package:hrms/features/recruitment/presentation/expendable_widget.dart';
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
  int _loadRequest = 0;

  List<JobEntity> _jobs = [];
  List<CandidateEntity> _cands = [];
  List<InterviewEntity> _ints = [];

  Map<String, int> _stats = {};

  String _jobFilter = 'All';
  int? _pipeJob;
  String _q = '';

  bool _board = true;
  bool _isLoading = false;

  String _intFilter = 'Upcoming';

  static const Map<String, Color> _stageColors = {
    'Applied': Colors.blueGrey,
    'Screening': Colors.orange,
    'Interview': Colors.blue,
    'Offered': Colors.purple,
    'Hired': Colors.green,
    'Rejected': Colors.red,
  };

  static const Map<String, Color> _jobStatusColors = {
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

  // ---------------------------------------------------------------- utilities

  String _string(Object? value, [String fallback = '']) {
    return value?.toString() ?? fallback;
  }

  int _int(Object? value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _double(Object? value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Color _statusColor(String status) {
    final cs = Theme.of(context).colorScheme;

    return _jobStatusColors[status] ??
        _stageColors[status] ??
        cs.primary;
  }

  // ---------------------------------------------------------------- data load

  Future<void> _load() async {
    final request = ++_loadRequest;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final jobs = await _repo.jobs();

      if (!mounted || request != _loadRequest) return;

      final selectedJob = _pipeJob != null &&
          jobs.any((job) => job.id == _pipeJob)
          ? _pipeJob
          : null;

      if (_pipeJob != selectedJob) {
        _pipeJob = selectedJob;
      }

      final results = await Future.wait([
        _repo.candidates(jobId: selectedJob, q: _q),
        _repo.interviews(),
        _repo.recruitmentStats(),
      ]);

      if (!mounted || request != _loadRequest) return;

      setState(() {
        _jobs = jobs;
        _cands = results[0] as List<CandidateEntity>;
        _ints = results[1] as List<InterviewEntity>;
        _stats = results[2] as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || request != _loadRequest) return;

      setState(() => _isLoading = false);
      toast(context, 'Could not load recruitment data: $e');
    }
  }

  String _jobStatus(JobEntity job) {
    if (job.approval == 'Pending') return 'Pending approval';
    if (job.approval == 'Rejected') return 'Rejected';
    return job.status;
  }

  // -------------------------------------------------------------------- jobs

  Future<void> _editJob([JobEntity? job]) async {
    final data = await JobFormDialog.show(
      context,
      job: job?.toMap(),
    );

    if (!mounted || data == null) return;

    if (data is! Map) {
      toast(context, 'Invalid job details');
      return;
    }

    final map = Map<String, Object?>.from(data);

    final entity = JobEntity(
      id: job?.id,
      title: _string(map['title']),
      department: _string(map['department']),
      description: _string(map['description']),
      status: _string(map['status'], job?.status ?? 'Open'),
      approval: job?.approval ?? 'Pending',
      openings: _int(map['openings'], job?.openings ?? 1),
      branch: _string(map['branch'], job?.branch ?? ''),
      location: _string(map['location'], job?.location ?? ''),
      employmentType: _string(map['employment_type'], job?.employmentType ?? ''),
      experience: _string(map['experience'], job?.experience ?? ''),
      salaryMin: _double(map['salary_min'], job?.salaryMin ?? 0),
      salaryMax: _double(map['salary_max'], job?.salaryMax ?? 0),
      skills: _string(map['skills'], job?.skills ?? ''),
      closingDate: _string(map['closing_date'], job?.closingDate ?? ''),
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

        if (!mounted) return;

        toast(
          context,
          Session.isAdmin
              ? 'Job published'
              : 'Job sent to admin for approval',
        );
      } else {
        await _repo.updateJob(
          job.id!,
          entity,
          currentApproval: job.approval,
        );

        if (!mounted) return;

        if (job.approval == 'Rejected' && !Session.isAdmin) {
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

    try {
      await _repo.decideJob(job.id!, true, '');

      if (!mounted) return;

      toast(context, '"${job.title}" approved and published');
      await _load();
    } catch (e) {
      if (mounted) toast(context, 'Could not approve job: $e');
    }
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

    if (!mounted || result == null) return;

    try {
      await _repo.decideJob(
        job.id!,
        false,
        _string(result['reason']),
      );

      await _load();
    } catch (e) {
      if (mounted) toast(context, 'Could not reject job: $e');
    }
  }

  Future<void> _deleteJob(JobEntity job) async {
    if (job.id == null) return;

    final ok = await confirm(
      context,
      'Delete job?',
      'This also deletes its candidates and interviews.',
    );

    if (!mounted || !ok) return;

    try {
      await _repo.deleteJob(job.id!);
      await _load();
    } catch (e) {
      if (mounted) toast(context, 'Could not delete job: $e');
    }
  }

  void _openCandidatesOf(JobEntity job) {
    setState(() {
      _pipeJob = job.id;
      _tab = 1;
      _q = '';
    });

    _load();
  }

  // --------------------------------------------------------------- UI helpers

  Widget _meta(IconData icon, String text) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: cs.primary),
        const SizedBox(width: 5),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _pill(String text) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String message) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Panel(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
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
    final cs = Theme.of(context).colorScheme;

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
                showCheckmark: false,
                backgroundColor: cs.surface,
                selectedColor: cs.primaryContainer,
                side: BorderSide(
                  color: selected == value
                      ? cs.primary.withValues(alpha: 0.35)
                      : cs.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: TextStyle(
                  color: selected == value
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                  fontWeight: selected == value
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {Widget? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _notice(IconData icon, Color color, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
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
                fontWeight: FontWeight.w500,
              ),
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
    final accent = _statusColor(status);

    final canDelete = Session.isAdmin ||
        (approval != 'Approved' && job.createdBy == Session.empId);

    final department = job.department;

    return Panel(
      padding: EdgeInsets.zero,
      child:

      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: accent,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(11, 6, 9, 7),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              job.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          StatusChip(status),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            iconSize: 19,
                            tooltip: 'Job options',
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _editJob(job);
                                  break;
                                case 'delete':
                                  _deleteJob(job);
                                  break;
                                case 'candidates':
                                  _openCandidatesOf(job);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              if (approval == 'Approved')
                                const PopupMenuItem(
                                  value: 'candidates',
                                  child: Row(
                                    children: [
                                      Icon(Icons.people_outline, size: 17),
                                      SizedBox(width: 9),
                                      Text('Candidates'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 17),
                                    SizedBox(width: 9),
                                    Text('Edit job'),
                                  ],
                                ),
                              ),
                              if (canDelete)
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 17,
                                        color: cs.error,
                                      ),
                                      const SizedBox(width: 9),
                                      Text(
                                        'Delete job',
                                        style: TextStyle(color: cs.error),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      if (department.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          department,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],

                      const SizedBox(height: 7),

                      // Interactive metadata

                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _meta(
                            Icons.approval_outlined,
                            job.approval,
                          ),

                          ElevatedButton(
                            onPressed: approval == 'Approved'
                                ? () => _openCandidatesOf(job)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade600,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people_outline, size: 13),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${job.cands ?? 0} Candidates',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward, size: 13),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),


                      // Expandable description
                      if (job.description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        ExpandableJobDescription(
                          description: job.description,
                        ),
                      ],

                      // Approval messages
                      if (approval == 'Pending') ...[
                        const SizedBox(height: 7),
                        _notice(
                          Icons.hourglass_top,
                          Colors.orange,
                          'Waiting for admin approval'
                              '${(job.creatorName ?? '').isEmpty ? '' : ' • ${job.creatorName}'}',
                        ),
                      ],

                      if (approval == 'Rejected') ...[
                        const SizedBox(height: 7),
                        _notice(
                          Icons.block,
                          cs.error,
                          'Rejected'
                              '${(job.rejectReason ?? '').isEmpty ? '' : ': ${job.rejectReason}'}'
                              '${Session.isAdmin ? '' : '\nEdit the job to send it for approval again.'}',
                        ),
                      ],

                      // Admin actions
                      if (Session.isAdmin && approval == 'Pending') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _approve(job),
                                icon: const Icon(Icons.check, size: 15),
                                label: const Text('Approve'),
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  minimumSize: const Size(0, 32),
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _reject(job),
                                icon: const Icon(Icons.close, size: 15),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  minimumSize: const Size(0, 32),
                                  foregroundColor: cs.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )

      ,
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

      return _jobs.where((job) => _jobStatus(job) == filter).length;
    }

    final list = _jobs
        .where(
          (job) => _jobFilter == 'All' || _jobStatus(job) == _jobFilter,
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.approval_outlined,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$pending job(s) waiting for your approval',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _jobFilter = 'Pending approval');
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
            setState(() => _jobFilter = filter);
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

              final width = (constraints.maxWidth - 16 * (cols - 1)) /
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

    if (!mounted || result == null) return;

    final now = ymd(DateTime.now());

    final entity = CandidateEntity(
      id: candidate?.id,
      jobId: _int(result['job']),
      name: _string(result['name']),
      email: _string(result['email']),
      phone: _string(result['phone']),
      source: _string(result['source']),
      experienceYears: _double(result['experience_years']),
      currentCompany: _string(result['current_company']),
      expectedSalary: _double(result['expected_salary']),
      rating: _int(result['rating']),
      stage: _string(result['stage'], 'Applied'),
      notes: _string(result['notes']),
      appliedOn: candidate?.appliedOn ?? now,
      resumePath: (result['resume_path'] as String?)?.trim().isNotEmpty == true
          ? result['resume_path'] as String
          : (candidate?.resumePath ?? ''),
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
      if (mounted) toast(context, 'Could not save candidate: $e');
    }
  }

  Future<void> _deleteCandidate(CandidateEntity candidate) async {
    if (candidate.id == null) return;

    final ok = await confirm(
      context,
      'Delete candidate?',
      '${candidate.name} and their interviews will be removed.',
    );

    if (!mounted || !ok) return;

    try {
      await _repo.deleteCandidate(candidate.id!);
      await _load();
    } catch (e) {
      if (mounted) toast(context, 'Could not delete candidate: $e');
    }
  }

  Future<void> _attachResume(CandidateEntity candidate) async {
    if (candidate.id == null) return;

    try {
      final pick = await FilePicker.platform.pickFiles();

      if (!mounted || pick == null || pick.files.isEmpty) return;

      final path = pick.files.single.path;

      if (path == null || path.isEmpty) {
        toast(context, 'Could not access the selected file');
        return;
      }

      await _repo.attachResume(candidate.id!, path);

      if (!mounted) return;

      toast(context, 'Resume attached');
      await _load();
    } catch (e) {
      if (mounted) toast(context, 'Could not attach resume: $e');
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

    if (!mounted || id == null) return;

    try {
      await _repo.markConverted(candidate.id!, id);

      if (!mounted) return;

      toast(context, 'Employee created from ${candidate.name}');
      await _load();
    } catch (e) {
      if (mounted) toast(context, 'Could not convert candidate: $e');
    }
  }

  Future<void> _details(CandidateEntity candidate) async {
    if (candidate.id == null) return;

    try {
      final interviews = await _repo.candidateInterviews(candidate.id!);

      if (!mounted) return;

      final action = await CandidateDetailsDialog.show(
        context,
        candidate: candidate,
        interviews: interviews,
      );

      if (!mounted || action == null) return;

      switch (action) {
        case CandidateAction.edit:
          await _editCandidate(candidate);
          break;

        case CandidateAction.openResume:
          if (candidate.resumePath != null &&
              candidate.resumePath!.isNotEmpty) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            try {
              final file = File(candidate.resumePath!);

              if (await file.exists()) {
                await openFile(candidate.resumePath!);
              } else {
                if (mounted) {
                  toast(context, 'File not found on disk');
                }
              }
            } catch (e) {
              if (mounted) {
                toast(context, 'Unable to open resume: $e');
              }
            } finally {
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            }
          }
        // Add a file-opening package here when resume preview is required.
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
    } catch (e) {
      if (mounted) toast(context, 'Could not open candidate details: $e');
    }
  }

  Widget _candCard(CandidateEntity candidate) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final next = DateTime.tryParse(candidate.nextInterview ?? '');
    final rating = candidate.rating.clamp(0, 5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.75),
          ),
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
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

        try {
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
        } catch (e) {
          if (mounted) toast(context, 'Could not update candidate: $e');
        }
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        for (final stage in kStages)
          if (!(stage == candidate.stage || stage == 'Interview'))
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

  // ------------------------------------------------------------ pipeline board

  Widget _stageColumn(String stage) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    border: Border(
                      bottom: BorderSide(
                        color: color.withValues(alpha: 0.75),
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          border: Border.all(
                            color: cs.outlineVariant,
                          ),
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
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

  // ---------------------------------------------------------------- list view

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
                  value: kStages.contains(candidate.stage)
                      ? candidate.stage
                      : null,
                  hint: Text(candidate.stage),
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final stage in kStages)
                      DropdownMenuItem(
                        value: stage,
                        child: Text(stage),
                      ),
                  ],
                  onChanged: (value) async {
                    if (value == null ||
                        candidate.id == null ||
                        value == candidate.stage) {
                      return;
                    }

                    try {
                      await _repo.setStage(candidate.id!, value);
                      await _load();
                    } catch (e) {
                      if (mounted) {
                        toast(context, 'Could not update stage: $e');
                      }
                    }
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

  // ------------------------------------------------------------- pipeline tab

  Widget _pipelineTab() {
    final approvedJobs = _jobs
        .where((job) => job.approval == 'Approved')
        .toList();

    final narrow = _narrow;
    final cs = Theme.of(context).colorScheme;

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
                decoration: InputDecoration(
                  labelText: 'Job',
                  isDense: true,
                  filled: true,
                  fillColor: cs.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: cs.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: cs.primary,
                      width: 1.3,
                    ),
                  ),
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
                  setState(() => _pipeJob = value);
                  _load();
                },
              ),
            ),
            SizedBox(
              width: narrow ? double.infinity : 240,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search candidates',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  fillColor: cs.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: cs.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: cs.primary,
                      width: 1.3,
                    ),
                  ),
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
                setState(() => _board = selection.first);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _cands.isEmpty
              ? _emptyState(
            Icons.people_outline,
            'No candidates found.',
          )
              : _board
              ? _boardView()
              : _listView(),
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
    try {
      final employees =
      await EmployeesRepository().fetchEmployees(activeOnly: true);

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

      if (!mounted || result == null) return;

      final interviewerId = int.tryParse(
        '${result['interviewer'] ?? ''}',
      );

      if (interviewerId == null) {
        toast(context, 'Please select an interviewer');
        return;
      }

      final date = _string(result['date']);
      final time = _string(result['time']);

      if (date.isEmpty || time.isEmpty) {
        toast(context, 'Please select interview date and time');
        return;
      }

      final entity = InterviewEntity(
        id: existing?.id,
        candidateId: candidateId,
        interviewerId: interviewerId,
        round: _string(result['round']),
        scheduledAt: '${date}T$time:00',
        result: existing?.result ?? 'Scheduled',
        feedback: _string(result['feedback']),
        candName: existing?.candName ?? candidateName,
        jobTitle: existing?.jobTitle,
        interviewerName: existing?.interviewerName,
      );

      await _repo.saveInterview(
        entity,
        id: existing?.id,
      );

      if (!mounted) return;

      toast(context, 'Interview saved');
      await _load();
    } catch (e) {
      if (mounted) toast(context, 'Could not save interview: $e');
    }
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

    if (!mounted || result == null) return;

    try {
      await _repo.setInterviewResult(
        interview.id!,
        _string(result['result']),
        _string(result['feedback']),
      );

      await _load();
    } catch (e) {
      if (mounted) toast(context, 'Could not update interview: $e');
    }
  }

  Future<void> _deleteInterview(InterviewEntity interview) async {
    if (interview.id == null) return;

    final ok = await confirm(
      context,
      'Delete interview?',
      'This interview will be permanently removed.',
    );

    if (!mounted || !ok) return;

    try {
      await _repo.deleteInterview(interview.id!);
      await _load();
    } catch (e) {
      if (mounted) toast(context, 'Could not delete interview: $e');
    }
  }

  Widget _intCard(InterviewEntity interview) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      interview.round,
                      if (dt != null)
                        DateFormat('hh:mm a').format(dt),
                      if ((interview.interviewerName ?? '').isNotEmpty)
                        'with ${interview.interviewerName}',
                    ].where((value) => value.isNotEmpty).join('  •  '),
                  ),
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
                      await _deleteInterview(interview);
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
              setState(() => _intFilter = filter);
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

  // ---------------------------------------------------------------- dashboard

  Widget _statsRow() {
    final items = [
      (
      'Open Jobs',
      _stats['openJobs'] ?? 0,
      Icons.work_outline_rounded,
      Colors.teal,
      ),
      (
      'Awaiting Approval',
      _stats['pendingJobs'] ?? 0,
      Icons.hourglass_top_rounded,
      Colors.orange,
      ),
      (
      'Active Candidates',
      _stats['candidates'] ?? 0,
      Icons.people_outline_rounded,
      Colors.indigo,
      ),
      (
      'Interviews Ahead',
      _stats['interviews'] ?? 0,
      Icons.event_available_rounded,
      Colors.blue,
      ),
      (
      'Hired This Month',
      _stats['hired'] ?? 0,
      Icons.verified_outlined,
      Colors.green,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 1100
            ? 6
            : width >= 750
            ? 4
            : width >= 500
            ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 50,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return StatCard(
              item.$1,
              '${item.$2}',
              item.$3,
              item.$4,
            );
          },
        );
      },
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

  // -------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    const tabs = [
      'Jobs',
      'Pipeline',
      'Interviews',
    ];

    final cs = Theme.of(context).colorScheme;

    return PageBox(
      child: Column(
        children: [
          const Header('Recruitment'),
          _statsRow(),
          Row(
            children: [
              Expanded(
                child: _filterChips<int>(
                  values: List.generate(tabs.length, (index) => index),
                  selected: _tab,
                  label: (index) => tabs[index],
                  onSelected: (index) {
                    setState(() => _tab = index);
                  },
                ),
              ),
              const SizedBox(width: 8),
              _primaryAction(),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: switch (_tab) {
                    0 => _jobsTab(),
                    1 => _pipelineTab(),
                    _ => _interviewsTab(),
                  },
                ),
                if (_isLoading)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: cs.primary,
                      backgroundColor:
                      cs.primary.withValues(alpha: 0.08),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}