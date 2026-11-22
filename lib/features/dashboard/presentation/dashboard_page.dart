
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';

import '../../special_days/presentation/special_days_page.dart'
    show specialIcon;

import 'dashboard_controller.dart';

class DashboardFeaturePage extends StatefulWidget {
  const DashboardFeaturePage({super.key});

  @override
  State<DashboardFeaturePage> createState() =>
      _DashboardFeaturePageState();
}

class _DashboardFeaturePageState extends State<DashboardFeaturePage> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController()..loadDashboard();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get _isManagement =>
      Session.isAdmin || Session.isHr || Session.isLead;

  bool get _isRecruitmentUser =>
      Session.isAdmin || Session.isHr;

  String get _role {
    if (Session.isAdmin) return 'Administrator';
    if (Session.isHr) return 'Human Resources';
    if (Session.isLead) return 'Team Lead';
    return 'Employee';
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _overviewText {
    if (Session.isAdmin) return 'Here is your company overview.';
    if (Session.isHr) return 'Here is your HR overview.';
    if (Session.isLead) return 'Here is your team overview.';
    return 'Here is your personal overview.';
  }

  int _count(String key) => _controller.count(key);

  String _value(Rec item, String key) {
    return item[key]?.toString() ?? '';
  }

  String _date(String? value) {
    if (value == null || value.isEmpty) return '-';

    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.tertiary, 0.4)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting, ${Session.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$_role  •  ${DateFormat('EEEE, dd MMM yyyy').format(DateTime.now())}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _overviewText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
      String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMMON SURFACE
  // ============================================================

  Widget _surface({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.14),
        ),
      ),
      child: child,
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required String keyName,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return _surface(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_count(keyName)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width >= 1200
            ? 5
            : width >= 850
            ? 4
            : width >= 560
            ? 3
            : 2;

        const gap = 9.0;
        final itemWidth =
            (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }

  // ============================================================
  // EMPLOYEE OVERVIEW
  // ============================================================

  Widget _buildEmployeeOverview() {
    if (!_isManagement) return const SizedBox.shrink();



    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          "Today Overview",
        ),
        _statGrid([
          _statCard(
            keyName: 'employees',
            label: Session.isLead && !Session.isAdmin && !Session.isHr
                ? 'My Team'
                : 'Active Employees',
            icon: Icons.people_alt_rounded,
            color: Colors.blue,
          ),
          _statCard(
            keyName: 'present',
            label: 'Present Today',
            icon: Icons.how_to_reg_rounded,
            color: Colors.green,
          ),
          _statCard(
            keyName: 'onLeave',
            label: 'On Leave',
            icon: Icons.event_busy_rounded,
            color: Colors.orange,
          ),
          _statCard(
            keyName: 'absent',
            label: 'Absent Today',
            icon: Icons.person_off_rounded,
            color: Colors.red,
          ),
          _statCard(
            keyName: 'pending',
            label: 'Pending Leaves',
            icon: Icons.pending_actions_rounded,
            color: Colors.deepOrange,
          ),
        ]),
      ],
    );
  }

  // ============================================================
  // RECRUITMENT HIGHLIGHTS
  // ============================================================

  Widget _recruitmentHighlight({
    required String title,
    required String subtitle,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // JOB STATUS
  // ============================================================

  Widget _jobStatusRow({
    required String label,
    required int value,
    required Color color,
    required int total,
  }) {
    final theme = Theme.of(context);

    final progress = total > 0
        ? (value / total).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                '$value',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor:
              theme.colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CANDIDATE PIPELINE
  // ============================================================

  Widget _candidatePipelineRow({
    required String label,
    required String keyName,
    required Color color,
    required int total,
  }) {
    final theme = Theme.of(context);
    final value = _count(keyName);

    final progress = total > 0
        ? (value / total).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                '$value',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor:
              theme.colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECRUITMENT REPORT
  // ============================================================

  Widget _buildRecruitmentReport() {
    if (!_isRecruitmentUser) {
      return const SizedBox.shrink();
    }

    final jobsListed = _count('jobsListed');
    final openJobs = _count('openJobs');
    final closedJobs = _count('closedJobs');
    final pendingJobs = _count('pendingJobs');
    final candidates = _count('candidates');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Recruitment overview',
        ),

        Row(
          children: [
            _recruitmentHighlight(
              title: 'Jobs Listed',
              subtitle: 'All job records',
              value: jobsListed,
              icon: Icons.work_outline_rounded,
              color: const Color(0xFF3157B7),
            ),
            const SizedBox(width: 10),
            _recruitmentHighlight(
              title: 'Candidates',
              subtitle: 'Registered candidates',
              value: candidates,
              icon: Icons.groups_rounded,
              color: const Color(0xFF087E72),
            ),
          ],
        ),

        const SizedBox(height: 10),

        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;

            final jobCard = _surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(
                    'Current Job status',
                  ),
                  _jobStatusRow(
                    label: 'Open Jobs',
                    value: openJobs,
                    color: Colors.green,
                    total: jobsListed,
                  ),
                  _jobStatusRow(
                    label: 'Closed Jobs',
                    value: closedJobs,
                    color: Colors.orange,
                    total: jobsListed,
                  ),
                  _jobStatusRow(
                    label: 'Pending Approval',
                    value: pendingJobs,
                    color: Colors.deepOrange,
                    total: jobsListed,
                  ),
                ],
              ),
            );

            final pipelineCard = _surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(
                    'Candidate Pipeline',
                  ),
                  _candidatePipelineRow(
                    label: 'Applied',
                    keyName: 'candidateApplied',
                    color: Colors.blue,
                    total: candidates,
                  ),
                  _candidatePipelineRow(
                    label: 'Screening',
                    keyName: 'candidateScreening',
                    color: Colors.purple,
                    total: candidates,
                  ),
                  _candidatePipelineRow(
                    label: 'Interview',
                    keyName: 'candidateInterview',
                    color: Colors.orange,
                    total: candidates,
                  ),
                  _candidatePipelineRow(
                    label: 'Offered',
                    keyName: 'candidateOffered',
                    color: Colors.teal,
                    total: candidates,
                  ),
                  _candidatePipelineRow(
                    label: 'Hired',
                    keyName: 'candidateHired',
                    color: Colors.green,
                    total: candidates,
                  ),
                  _candidatePipelineRow(
                    label: 'Rejected',
                    keyName: 'candidateRejected',
                    color: Colors.red,
                    total: candidates,
                  ),
                ],
              ),
            );

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: jobCard),
                  const SizedBox(width: 10),
                  Expanded(child: pipelineCard),
                ],
              );
            }

            return Column(
              children: [
                jobCard,
                const SizedBox(height: 10),
                pipelineCard,
              ],
            );
          },
        ),

        const SizedBox(height: 10),

        _surface(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 11,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Interviews",
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Interviews scheduled for today',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_count('interviewsToday')}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 23,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SPECIAL DAYS
  // ============================================================

  Widget _specialRow(Rec item) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final kind = _value(item, 'kind');
    final title = _value(item, 'title');
    final employee = _value(item, 'emp_name');

    final date = _value(item, 'next').isNotEmpty
        ? _value(item, 'next')
        : _value(item, 'date');

    final years = _value(item, 'years');

    final details = [
      if (employee.isNotEmpty) employee,
      if (years.isNotEmpty) '$years years',
      if (date.isNotEmpty) _date(date),
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.tertiaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              specialIcon(kind),
              color: colors.tertiary,
              size: 17,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? kind : title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    details,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialDays() {
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Upcoming Special Days',
          ),
          if (_controller.specialDays.isEmpty)
            _emptyMessage('No upcoming special days.')
          else
            ..._controller.specialDays.map(_specialRow),
        ],
      ),
    );
  }

  // ============================================================
  // HOLIDAYS
  // ============================================================

  Widget _holidayRow(Rec item) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final date = _value(item, 'date');
    final name = _value(item, 'name');

    String day = '-';
    String month = '';

    try {
      final parsed = DateTime.parse(date);
      day = DateFormat('dd').format(parsed);
      month = DateFormat('MMM').format(parsed);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  month,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          Icon(
            Icons.celebration_rounded,
            color: colors.tertiary,
            size: 17,
          ),
        ],
      ),
    );
  }

  Widget _buildHolidays() {
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Upcoming Holidays',
          ),
          if (_controller.holidays.isEmpty)
            _emptyMessage('No upcoming holidays.')
          else
            ..._controller.holidays.map(_holidayRow),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyMessage(String message) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM SECTIONS
  // ============================================================

  Widget _buildSections() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 850 ? 2 : 1;

        const gap = 10.0;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        final sections = <Widget>[
          _buildSpecialDays(),
          _buildHolidays(),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: sections.map((section) {
            return SizedBox(
              width: itemWidth,
              child: section,
            );
          }).toList(),
        );
      },
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    if (_controller.error == null) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: colors.onErrorContainer,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _controller.error!,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: _controller.isLoading
                ? null
                : _controller.refresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final firstLoad = _controller.isLoading &&
            _controller.stats.isEmpty &&
            _controller.holidays.isEmpty &&
            _controller.specialDays.isEmpty;

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _controller.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                children: [
                  _header(),
                  const SizedBox(height: 17),

                  if (firstLoad)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 45),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    _buildError(),

                    if (_controller.error != null)
                      const SizedBox(height: 10),

                    if (_isManagement) ...[
                      _buildEmployeeOverview(),
                      const SizedBox(height: 17),
                    ],

                    if (_isRecruitmentUser) ...[
                      _buildRecruitmentReport(),
                      const SizedBox(height: 17),
                    ],

                    _buildSections(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
