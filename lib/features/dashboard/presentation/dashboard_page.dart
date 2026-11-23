
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/domain/entities/special_day_entity.dart';

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
      padding: const EdgeInsets.all(18),
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
                    fontSize: 11.5,
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMMON SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
        ),
      ),
    );
  }

  // ============================================================
  // COMMON CARD
  // ============================================================

  Widget _surface({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
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
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_count(keyName)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STAT GRID
  // ============================================================

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

        const gap = 10.0;

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
    if (!_isManagement) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Today Overview'),

        _statGrid([
          _statCard(
            keyName: 'employees',
            label: Session.isLead &&
                !Session.isAdmin &&
                !Session.isHr
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
  // RECRUITMENT HIGHLIGHT
  // IMPORTANT: No Expanded inside this method.
  // The parent Row handles Expanded.
  // ============================================================

  Widget _recruitmentHighlight({
    required String title,
    required String subtitle,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // JOB STATUS ROW
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
      padding: const EdgeInsets.only(bottom: 12),
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
                    fontSize: 11.5,
                  ),
                ),
              ),
              Text(
                '$value',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
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

    return _RecruitmentReportSection(
      controller: _controller,
      widgetRef: this,
    );
  }

  // ============================================================
  // SPECIAL DAYS
  // ============================================================

  Widget _specialRow(SpecialDayEntity item) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final kind = _value(item.toMap(), 'kind');
    final title = item.title;
    final employee = item.empName ?? '';

    final date =
    (item.next ?? '').isNotEmpty ? item.next! : item.date;

    final years = item.years?.toString() ?? '';

    final details = [
      if (employee.isNotEmpty) employee,
      if (years.isNotEmpty) '$years years',
      if (date.isNotEmpty) _date(date),
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.tertiaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              specialIcon(kind),
              color: colors.tertiary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? kind : title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    details,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
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
          _sectionTitle('Upcoming Special Days'),

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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Icon(
            Icons.celebration_rounded,
            color: colors.tertiary,
            size: 18,
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
          _sectionTitle('Upcoming Holidays'),

          if (_controller.holidays.isEmpty)
            _emptyMessage('No upcoming holidays.')
          else
            ..._controller.holidays.map(_holidayRow),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY MESSAGE
  // ============================================================

  Widget _emptyMessage(String message) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD SECTIONS
  // ============================================================

  Widget _buildSections() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 850 ? 2 : 1;

        const gap = 12.0;

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
  // ERROR MESSAGE
  // ============================================================

  Widget _buildError() {
    if (_controller.error == null) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: colors.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
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
            onPressed:
            _controller.isLoading ? null : _controller.refresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _header(),

                  const SizedBox(height: 18),

                  if (firstLoad)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 50),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    _buildError(),

                    if (_controller.error != null)
                      const SizedBox(height: 12),

                    if (_isManagement) ...[
                      _buildEmployeeOverview(),
                      const SizedBox(height: 18),
                    ],

                    if (_isRecruitmentUser) ...[
                      _buildRecruitmentReport(),
                      const SizedBox(height: 18),
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

// ============================================================================
// RECRUITMENT REPORT SECTION
// ============================================================================

class _RecruitmentReportSection extends StatefulWidget {
  const _RecruitmentReportSection({
    required this.controller,
    required this.widgetRef,
  });

  final DashboardController controller;
  final _DashboardFeaturePageState widgetRef;

  @override
  State<_RecruitmentReportSection> createState() =>
      _RecruitmentReportSectionState();
}

class _RecruitmentReportSectionState
    extends State<_RecruitmentReportSection> {
  bool _jobsExpanded = false;
  bool _pipelineExpanded = false;

  static const int _maxCollapsed = 3;

  // ============================================================
  // REUSABLE BREAKDOWN CARD
  // ============================================================

  Widget _buildBreakdown({
    required String title,
    required String subtitle,
    required List<Map<String, Object>> items,
    required int total,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    final hasMore = items.length > _maxCollapsed;

    // Always show first three items.
    // Show all items when expanded.
    final visibleItems = expanded
        ? items
        : items.take(_maxCollapsed).toList();

    return widget.widgetRef._surface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Only show arrow when there are more than 3 items.
              if (hasMore)
                IconButton(
                  onPressed: onToggle,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 22,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          ...visibleItems.map((item) {
            return widget.widgetRef._jobStatusRow(
              label: item['label'] as String,
              value: item['value'] as int,
              color: item['color'] as Color,
              total: total,
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final openJobs = widget.controller.count('openJobs');
    final pendingJobs = widget.controller.count('pendingJobs');
    final closedJobs = widget.controller.count('closedJobs');
    final jobsListed = widget.controller.count('jobsListed');

    final applied = widget.controller.count('candidateApplied');
    final screening = widget.controller.count('candidateScreening');
    final interview = widget.controller.count('candidateInterview');
    final offered = widget.controller.count('candidateOffered');
    final hired = widget.controller.count('candidateHired');
    final rejected = widget.controller.count('candidateRejected');

    final cands = widget.controller.count('candidates');
    final interviews = widget.controller.count('interviews');

    final jobTotal = jobsListed > 0 ? jobsListed : 1;
    final candTotal = cands > 0 ? cands : 1;

    // ----------------------------------------------------------
    // JOB OPENINGS
    // ----------------------------------------------------------

    final jobItems = <Map<String, Object>>[
      {
        'label': 'Open & Approved',
        'value': openJobs,
        'color': Colors.green,
      },
      {
        'label': 'Pending Approval',
        'value': pendingJobs,
        'color': Colors.orange,
      },
      {
        'label': 'Closed',
        'value': closedJobs,
        'color': Colors.red,
      },
    ];

    // ----------------------------------------------------------
    // CANDIDATE PIPELINE
    // ----------------------------------------------------------

    final pipelineItems = <Map<String, Object>>[
      {
        'label': 'Applied',
        'value': applied,
        'color': Colors.blue,
      },
      {
        'label': 'Screening',
        'value': screening,
        'color': Colors.deepOrange,
      },
      {
        'label': 'Interview',
        'value': interview,
        'color': Colors.purple,
      },
      {
        'label': 'Offered',
        'value': offered,
        'color': Colors.amber.shade800,
      },
      {
        'label': 'Hired',
        'value': hired,
        'color': Colors.teal,
      },
      {
        'label': 'Rejected',
        'value': rejected,
        'color': Colors.red,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.widgetRef._sectionTitle(
          'Recruitment Highlights',
        ),

        // ------------------------------------------------------
        // HIGHLIGHT CARDS
        // ------------------------------------------------------

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: widget.widgetRef._recruitmentHighlight(
                title: 'Total Candidates',
                subtitle: 'In pipeline',
                value: cands,
                icon: Icons.person_search_rounded,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: widget.widgetRef._recruitmentHighlight(
                title: 'Interviews',
                subtitle: 'Scheduled',
                value: interviews,
                icon: Icons.event_available_rounded,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: widget.widgetRef._recruitmentHighlight(
                title: 'Hired',
                subtitle: 'This month',
                value: hired,
                icon: Icons.verified_rounded,
                color: Colors.teal,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ------------------------------------------------------
        // JOB OPENINGS + CANDIDATE PIPELINE
        // ------------------------------------------------------

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildBreakdown(
                title: 'Job Openings Breakdown',
                subtitle: 'Total Jobs: $jobsListed',
                items: jobItems,
                total: jobTotal,
                expanded: _jobsExpanded,
                onToggle: () {
                  setState(() {
                    _jobsExpanded = !_jobsExpanded;
                  });
                },
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildBreakdown(
                title: 'Candidate Pipeline',
                subtitle: 'Total Candidates: $cands',
                items: pipelineItems,
                total: candTotal,
                expanded: _pipelineExpanded,
                onToggle: () {
                  setState(() {
                    _pipelineExpanded = !_pipelineExpanded;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
