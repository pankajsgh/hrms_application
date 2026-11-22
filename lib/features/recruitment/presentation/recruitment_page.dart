import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hrms/features/recruitment/presentation/Job_popup.dart';
import 'package:hrms/features/recruitment/presentation/candidate_dialog.dart';
import 'package:hrms/features/recruitment/presentation/candidate_popup.dart';
import 'package:intl/intl.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import '../../employees/data/employees_repository.dart';
import '../../employees/presentation/employee_form.dart';
import '../data/recruitment_repository.dart';
import 'recruitment_controller.dart';

class RecruitmentFeaturePage extends StatefulWidget {
  const RecruitmentFeaturePage({super.key});

  @override
  State<RecruitmentFeaturePage> createState() => _RecruitmentFeaturePageState();
}

class _RecruitmentFeaturePageState extends State<RecruitmentFeaturePage> {
  late final RecruitmentController _controller;
  final _repo = RecruitmentRepository();
  Timer? _searchDebounce;

  int _tab = 0; // 0 jobs, 1 pipeline, 2 interviews
  List<Rec> _jobs = [];
  List<Rec> _cands = [];
  List<Rec> _ints = [];
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
    _controller = RecruitmentController()..loadRecruitment();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final jobs = await _repo.jobs();
    if (_pipeJob != null && !jobs.any((j) => j['id'] == _pipeJob)) {
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
  }

  String _jobStatus(Rec j) {
    final a = j.s('approval');
    if (a == 'Pending') return 'Pending approval';
    if (a == 'Rejected') return 'Rejected';
    return j.s('status');
  }

  // --------------------------------------------------------------------- jobs

  Future<void> _editJob([Rec? j]) async {
    final data = await JobFormDialog.show(context, job: j);
    if (data == null) return;

    if (j == null) {
      await _repo.createJob(data);
      if (mounted) {
        toast(context,
            Session.isAdmin ? 'Job published' : 'Job sent to admin for approval');
      }
    } else {
      await _repo.updateJob(j.i('id')!, data, currentApproval: j.s('approval'));
      if (mounted && j.s('approval') == 'Rejected' && !Session.isAdmin) {
        toast(context, 'Job re-sent to admin for approval');
      }
    }
    if (mounted) _load();
  }

  Future<void> _approve(Rec j) async {
    await _repo.decideJob(j.i('id')!, true, '');
    if (mounted) toast(context, '"${j.s('title')}" approved and published');
    _load();
  }

  Future<void> _reject(Rec j) async {
    final r = await formDialog(
      context,
      'Reject "${j.s('title')}"',
      const [
        F('reason', 'Reason (shown to the person who created it)',
            type: 'multiline', required: true),
      ],
      saveLabel: 'Reject',
    );
    if (r == null) return;
    await _repo.decideJob(j.i('id')!, false, r['reason'] as String);
    _load();
  }

  Future<void> _deleteJob(Rec j) async {
    final ok = await confirm(context, 'Delete job?',
        'This also deletes its candidates and interviews.');
    if (!ok) return;
    await _repo.deleteJob(j.i('id')!);
    _load();
  }

  void _openCandidatesOf(Rec j) {
    setState(() {
      _pipeJob = j.i('id');
      _tab = 1;
    });
    _load();
  }

  // ----------------------------------------------------------- small widgets

  Widget _meta(IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: cs.outline),
      const SizedBox(width: 4),
      Text(text, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }

  Widget _pill(String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11.5, color: cs.onSecondaryContainer)),
    );
  }

  Widget _emptyState(IconData icon, String message) {
    final cs = Theme.of(context).colorScheme;
    return Panel(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 44, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ]),
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
      child: ListView(scrollDirection: Axis.horizontal, children: [
        for (final v in values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label(v)),
              selected: selected == v,
              onSelected: (_) => onSelected(v),
            ),
          ),
      ]),
    );
  }

  // --------------------------------------------------------------- jobs: card

  Widget _jobCard(Rec j) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final approval = j.s('approval');
    final status = _jobStatus(j);
    final accent = _jobStatusColors[status] ?? cs.primary;
    final canDelete = Session.isAdmin ||
        (approval != 'Approved' && j['created_by'] == Session.empId);

    final salary = [
      if (j.d('salary_min') > 0) money(j.d('salary_min')),
      if (j.d('salary_max') > 0) money(j.d('salary_max')),
    ].join(' - ');

    final skills = j
        .s('skills')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(6)
        .toList();

    final where = [
      if (j.s('department').isNotEmpty) j.s('department'),
      if (j.s('branch').isNotEmpty) j.s('branch'),
      if (j.s('location').isNotEmpty) j.s('location'),
      if (j.s('employment_type').isNotEmpty) j.s('employment_type'),
    ].join('  •  ');

    return Panel(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 5, color: accent),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Text(j.s('title'),
                        style: const TextStyle(
                            fontSize: 16.5, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status),
                ]),
                if (where.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(where, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 12),
                Wrap(spacing: 14, runSpacing: 6, children: [
                  _meta(Icons.groups_outlined, '${j.i('openings') ?? 1} opening(s)'),
                  _meta(Icons.person_outline, '${j.i('cands') ?? 0} candidates'),
                  if (j.s('experience').isNotEmpty)
                    _meta(Icons.work_history_outlined, j.s('experience')),
                  if (salary.isNotEmpty) _meta(Icons.payments_outlined, salary),

                ]),
                SizedBox(height: 6,),
                if (j.s('closing_date').isNotEmpty)
                  _meta(Icons.event_outlined,
                      'Apply by ${fmtDate(j['closing_date'])}'),
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final s in skills) _pill(s),
                  ]),
                ],
                if (approval == 'Pending') ...[
                  const SizedBox(height: 12),
                  _notice(
                    Icons.hourglass_top,
                    Colors.orange,
                    'Waiting for admin approval'
                        '${j.s('creator_name').isEmpty ? '' : ' • by ${j.s('creator_name')}'}',
                  ),
                ],
                if (approval == 'Rejected') ...[
                  const SizedBox(height: 12),
                  _notice(
                    Icons.block,
                    cs.error,
                    'Rejected${j.s('reject_reason').isEmpty ? '' : ': ${j.s('reject_reason')}'}'
                        '${Session.isAdmin ? '' : '\nEdit the job to send it for approval again.'}',
                  ),
                ],
                const Divider(height: 24),
                Wrap(spacing: 8, runSpacing: 4,
                    children: [
                  if (Session.isAdmin && approval == 'Pending') ...[
                    FilledButton.icon(
                      onPressed: () => _approve(j),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _reject(j),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                    ),
                  ],
                  if (approval == 'Approved')
                    TextButton.icon(
                      onPressed: () => _openCandidatesOf(j),
                      icon: const Icon(Icons.people_alt_outlined, size: 18),
                      label: const Text('Candidates'),
                    ),
                  TextButton.icon(
                    onPressed: () => _editJob(j),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                  if (canDelete)
                    TextButton.icon(
                      onPressed: () => _deleteJob(j),
                      style: TextButton.styleFrom(foregroundColor: cs.error),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                    ),
                ]),
              ]),
            ),
          ),
        ]),
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
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 12.5))),
      ]),
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
    int count(String f) => f == 'All'
        ? _jobs.length
        : _jobs.where((j) => _jobStatus(j) == f).length;
    final list = _jobs
        .where((j) => _jobFilter == 'All' || _jobStatus(j) == _jobFilter)
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
            child: Row(children: [
              const Icon(Icons.approval_outlined, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(child: Text('$pending job(s) waiting for your approval')),
              TextButton(
                onPressed: () => setState(() => _jobFilter = 'Pending approval'),
                child: const Text('Review'),
              ),
            ]),
          ),
        ),
      _filterChips<String>(
        values: filters,
        selected: _jobFilter,
        label: (f) => '$f (${count(f)})',
        onSelected: (f) => setState(() => _jobFilter = f),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: list.isEmpty
            ? _emptyState(Icons.work_off_outlined,
            'No jobs here yet. Tap "New job" to create one.')
            : LayoutBuilder(builder: (context, box) {
          final cols = (box.maxWidth / 400).floor().clamp(1, 4).toInt();
          final w = (box.maxWidth - 16 * (cols - 1)) / cols;
          return SingleChildScrollView(
            child: Wrap(spacing: 16, runSpacing: 16,

                children: [
              for (final j in list) SizedBox(width: w, child: _jobCard(j)),
            ]),
          );
        }),
      ),
    ]);
  }

  // --------------------------------------------------------------- candidates


  Future<void> _editCandidate([Rec? c]) async {
    final approved = _jobs
        .where((j) => j.s('approval') == 'Approved')
        .toList();

    if (approved.isEmpty && c == null) {
      toast(
        context,
        'No approved job yet. Create a job and get it approved first.',
      );
      return;
    }

    final r = await CandidateFormDialog.show(
      context,
      jobs: _jobs,
      candidate: c,
      initialJobId: _pipeJob,
    );

    if (r == null) return;

    final now = ymd(DateTime.now());

    await _repo.saveCandidate({
      'job_id': int.parse(r['job'] as String),
      'name': r['name'],
      'email': r['email'],
      'phone': r['phone'],
      'source': r['source'],
      'experience_years': r['experience_years'],
      'current_company': r['current_company'],
      'expected_salary': r['expected_salary'],
      'rating': int.parse(r['rating'] as String),
      'stage': r['stage'],
      'notes': r['notes'],
      if (c == null) 'applied_on': now,
      if (c == null || c.s('stage') != r['stage'])
        'stage_changed_on': now,
    }, id: c?.i('id'));

    await _load();
  }

  Future<void> _deleteCandidate(Rec c) async {
    final ok = await confirm(context, 'Delete candidate?',
        '${c.s('name')} and their interviews will be removed.');
    if (!ok) return;
    await _repo.deleteCandidate(c.i('id')!);
    _load();
  }

  Future<void> _attachResume(Rec c) async {
    try {
      final pick = await FilePicker.platform.pickFiles();
      final path = pick?.files.single.path;
      if (path == null) return;
      await _repo.attachResume(c.i('id')!, path);
      if (mounted) toast(context, 'Resume attached');
      _load();
    } catch (e) {
      if (mounted) toast(context, 'Could not attach resume: $e');
    }
  }

  Future<void> _convert(Rec c) async {
    final id = await showEmployeeForm(context, existing: {
      'name': c['name'],
      'email': c['email'],
      'phone': c['phone'],
      'designation': c['job_title'],
      'department': c['job_department'],
    });
    if (id == null) return;
    await _repo.markConverted(c.i('id')!, id);
    if (mounted) toast(context, 'Employee created from ${c.s('name')}');
    _load();
  }

  Future<void> _details(Rec c) async {
    final ints = await _repo.candidateInterviews(c.i('id')!);
    if (!mounted) return;

    final action = await CandidateDetailsDialog.show(
      context,
      candidate: c,
      interviews: ints,
    );
    if (action == null) return;

    switch (action) {
      case CandidateAction.edit:
        await _editCandidate(c);
      case CandidateAction.openResume:
      // TODO: open the stored resume file (e.g. with open_filex).
        break;
      case CandidateAction.attachResume:
        await _attachResume(c);
      case CandidateAction.scheduleInterview:
        await _scheduleInterview(c.i('id')!, c.s('name'));
      case CandidateAction.convert:
        await _convert(c);
    }
  }

  Widget _candCard(Rec c) {
    final cs = Theme.of(context).colorScheme;
    final next = DateTime.tryParse(c.s('next_interview'));
    final rating = c.i('rating') ?? 0;

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
          onTap: () => _details(c),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    c.s('name').isEmpty ? '?' : c.s('name')[0].toUpperCase(),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c.s('name'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                _candMenu(c),
              ]),
              if (_pipeJob == null && c.s('job_title').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 2),
                  child: Text(c.s('job_title'),
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              if (rating > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('★' * rating + '☆' * (5 - rating),
                      style: TextStyle(color: Colors.amber.shade700)),
                ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Wrap(spacing: 6, runSpacing: 4, children: [
                  if (c.s('source').isNotEmpty) _pill(c.s('source')),
                  if (c.d('experience_years') > 0)
                    _pill('${nf(c.d('experience_years'))} yrs'),
                  if (c.d('expected_salary') > 0)
                    _pill(money(c.d('expected_salary'))),
                  if (c.i('converted_employee_id') != null) _pill('Employee'),
                ]),
              ),
              if (next != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Row(children: [
                    Icon(Icons.event, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(DateFormat('d MMM, hh:mm a').format(next),
                        style: TextStyle(color: cs.primary, fontSize: 12)),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _candMenu(Rec c) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      iconSize: 20,
      icon: const Icon(Icons.more_vert),
      tooltip: 'Actions',
      onSelected: (v) async {
        if (v.startsWith('stage:')) {
          await _repo.setStage(c.i('id')!, v.substring(6));
          _load();
        } else if (v == 'edit') {
          _editCandidate(c);
        } else if (v == 'interview') {
          _scheduleInterview(c.i('id')!, c.s('name'));
        } else if (v == 'delete') {
          _deleteCandidate(c);
        }
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        for (final s in kStages)
          if (s != c.s('stage'))
            PopupMenuItem(value: 'stage:$s', child: Text('Move to $s')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'interview', child: Text('Schedule interview')),
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  Widget _stageColumn(String stage) {
    final cs = Theme.of(context).colorScheme;
    final items = _cands.where((c) => c.s('stage') == stage).toList();
    final color = _stageColors[stage] ?? Colors.blueGrey;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 280,
        child: Panel(
          padding: EdgeInsets.zero,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                border: Border(bottom: BorderSide(color: color, width: 2.5)),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(stage,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${items.length}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                  child: Text('No candidates',
                      style: Theme.of(context).textTheme.bodySmall))
                  : ListView(
                padding: const EdgeInsets.all(10),
                children: [for (final c in items) _candCard(c)],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _boardView() => ListView(
    scrollDirection: Axis.horizontal,
    children: [for (final s in kStages) _stageColumn(s)],
  );

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
        for (final c in _cands)
          DataRow(
            onSelectChanged: (_) => _details(c),
            cells: [
              DataCell(Text(c.s('name'))),
              DataCell(Text(c.s('job_title'))),
              DataCell(DropdownButton<String>(
                value: c.s('stage'),
                underline: const SizedBox.shrink(),
                items: [
                  for (final s in kStages)
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  await _repo.setStage(c.i('id')!, v);
                  _load();
                },
              )),
              DataCell(Text('★' * (c.i('rating') ?? 0))),
              DataCell(Text(c.s('source'))),
              DataCell(Text(c.d('expected_salary') > 0
                  ? money(c.d('expected_salary'))
                  : '')),
              DataCell(_candMenu(c)),
            ],
          ),
      ],
      empty: 'No candidates found.',
    );
  }

  Widget _pipelineTab() {
    final approved = _jobs.where((j) => j.s('approval') == 'Approved').toList();
    final narrow = _narrow;

    return Column(children: [
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
                const DropdownMenuItem<int?>(value: null, child: Text('All jobs')),
                for (final j in approved)
                  DropdownMenuItem<int?>(
                    value: j.i('id'),
                    child: Text(j.s('title'), overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) {
                _pipeJob = v;
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
              onChanged: (v) {
                _q = v.trim();
                _searchDebounce?.cancel();
                _searchDebounce =
                    Timer(const Duration(milliseconds: 350), _load);
              },
            ),
          ),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                  value: true,
                  icon: Icon(Icons.view_kanban_outlined),
                  label: Text('Board')),
              ButtonSegment(
                  value: false, icon: Icon(Icons.list), label: Text('List')),
            ],
            selected: {_board},
            onSelectionChanged: (s) => setState(() => _board = s.first),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Expanded(child: _board ? _boardView() : _listView()),
    ]);
  }

  // --------------------------------------------------------------- interviews

  Future<void> _scheduleInterview(int candId, String candName,
      {Rec? existing}) async {
    final emps = await EmployeesRepository().employees(activeOnly: true);
    if (!mounted) return;
    final dt = DateTime.tryParse(existing?.s('scheduled_at') ?? '');

    final r = await formDialog(
      context,
      existing == null ? 'Schedule interview: $candName' : 'Edit interview',
      [
        F('round', 'Round',
            type: 'dropdown',
            required: true,
            options: opts(kRounds),
            initial: existing?['round'] ?? kRounds.first),
        F('date', 'Date',
            type: 'date', required: true, initial: dt == null ? null : ymd(dt)),
        F('time', 'Time',
            type: 'time',
            required: true,
            initial: dt == null ? '10:00' : DateFormat('HH:mm').format(dt)),
        F('mode', 'Mode',
            type: 'dropdown',
            required: true,
            options: opts(kModes),
            initial: existing?['mode'] ?? 'In person'),
        F('interviewer', 'Interviewer',
            type: 'dropdown',
            options: {for (final e in emps) '${e['id']}': e.s('name')},
            initial: existing?['interviewer_id']),
        F('location', 'Location / meeting link', initial: existing?['location']),
        F('notes', 'Notes', type: 'multiline', initial: existing?['notes']),
      ],
      saveLabel: existing == null ? 'Schedule' : 'Save',
    );
    if (r == null) return;

    await _repo.saveInterview({
      'candidate_id': candId,
      'round': r['round'],
      'scheduled_at': '${r['date']}T${r['time']}:00',
      'mode': r['mode'],
      'interviewer_id': int.tryParse('${r['interviewer'] ?? ''}'),
      'location': r['location'],
      'notes': r['notes'],
      if (existing == null) 'result': 'Scheduled',
    }, id: existing?.i('id'));
    if (mounted) toast(context, 'Interview saved');
    _load();
  }

  Future<void> _setResult(Rec i) async {
    final r = await formDialog(context, 'Interview result: ${i.s('cand_name')}', [
      F('result', 'Result',
          type: 'dropdown',
          required: true,
          options: opts(kInterviewResults),
          initial: i['result']),
      F('feedback', 'Feedback', type: 'multiline', initial: i['feedback']),
    ]);
    if (r == null) return;
    await _repo.setInterviewResult(
        i.i('id')!, r['result'] as String, r['feedback'] as String);
    _load();
  }

  Widget _intCard(Rec i) {
    final theme = Theme.of(context);
    final dt = DateTime.tryParse(i.s('scheduled_at'));
    final isToday = dt != null && ymd(dt) == ymd(today());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          DateBadge(dt, highlight: isToday),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(i.s('cand_name'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              Text(i.s('job_title'), style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text([
                i.s('round'),
                if (dt != null) DateFormat('hh:mm a').format(dt),
                i.s('mode'),
                if (i.s('interviewer_name').isNotEmpty)
                  'with ${i.s('interviewer_name')}',
              ].where((e) => e.isNotEmpty).join('  •  ')),
              if (i.s('location').isNotEmpty)
                Text(i.s('location'), style: theme.textTheme.bodySmall),
              if (i.s('feedback').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Feedback: ${i.s('feedback')}',
                      style: theme.textTheme.bodySmall),
                ),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusChip(i.s('result')),
            PopupMenuButton<String>(
              tooltip: 'Actions',
              onSelected: (v) async {
                if (v == 'result') {
                  _setResult(i);
                } else if (v == 'edit') {
                  _scheduleInterview(i.i('candidate_id')!, i.s('cand_name'),
                      existing: i);
                } else if (v == 'delete') {
                  await _repo.deleteInterview(i.i('id')!);
                  _load();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'result', child: Text('Update result')),
                PopupMenuItem(value: 'edit', child: Text('Reschedule / edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _interviewsTab() {
    final now = ymd(DateTime.now());
    final list = _ints.where((i) {
      final scheduled = i.s('result') == 'Scheduled';
      final upcoming = scheduled && i.s('scheduled_at').compareTo(now) >= 0;
      if (_intFilter == 'Upcoming') return upcoming;
      if (_intFilter == 'Completed') return !scheduled;
      return true;
    }).toList();

    if (_intFilter == 'Upcoming') {
      list.sort((a, b) => a.s('scheduled_at').compareTo(b.s('scheduled_at')));
    }

    return Column(children: [
      Align(
        alignment: Alignment.centerLeft,
        child: _filterChips<String>(
          values: const ['Upcoming', 'Completed', 'All'],
          selected: _intFilter,
          label: (f) => f,
          onSelected: (f) => setState(() => _intFilter = f),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: list.isEmpty
            ? _emptyState(Icons.event_busy_outlined,
            'No interviews here. Open a candidate and choose "Schedule interview".')
            : ListView(children: [for (final i in list) _intCard(i)]),
      ),
    ]);
  }

  // -------------------------------------------------------------------- build

  Widget _statsRow() {
    final items = [
      ('Open jobs', _stats['openJobs'] ?? 0, Icons.work_outline, Colors.teal),
      ('Awaiting approval', _stats['pendingJobs'] ?? 0, Icons.hourglass_top,
      Colors.orange),
      ('Active candidates', _stats['candidates'] ?? 0, Icons.people_outline,
      Colors.indigo),
      ('Interviews ahead', _stats['interviews'] ?? 0, Icons.event_available,
      Colors.blue),
      ('Hired this month', _stats['hired'] ?? 0, Icons.verified_outlined,
      Colors.green),
    ];
    return SizedBox(
      height: 84,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        for (final s in items)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StatCard(s.$1, '${s.$2}', s.$3, s.$4),
          ),
      ]),
    );
  }

  Widget _primaryAction() {
    final narrow = _narrow;
    Widget btn(IconData icon, String label, VoidCallback onTap) => narrow
        ? Tooltip(
      message: label,
      child: FilledButton(onPressed: onTap, child: Icon(icon)),
    )
        : FilledButton.icon(
        onPressed: onTap, icon: Icon(icon), label: Text(label));

    switch (_tab) {
      case 0:
        return btn(Icons.add, 'New job', () => _editJob());
      case 1:
        return btn(Icons.person_add_alt, 'Add candidate', () => _editCandidate());
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['Jobs', 'Pipeline', 'Interviews'];

    return PageBox(
      child: Column(children: [
        const Header('Recruitment'),
        _statsRow(),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _filterChips<int>(
              values: List.generate(tabs.length, (i) => i),
              selected: _tab,
              label: (i) => tabs[i],
              onSelected: (i) => setState(() => _tab = i),
            ),
          ),
          const SizedBox(width: 8),
          _primaryAction(),
        ]),
        const SizedBox(height: 8),
        Expanded(
          child: switch (_tab) {
            0 => _jobsTab(),
            1 => _pipelineTab(),
            _ => _interviewsTab(),
          },
        ),
      ]),
    );
  }
}
