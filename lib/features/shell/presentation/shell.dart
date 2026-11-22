import 'package:flutter/material.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/features/leave/presentation/leave_page.dart';
import '../../../core/storage_config.dart';
import '../../users/data/users_repository.dart';
import '../../attendance/presentation/attendance_page.dart';
import '../../dashboard/presentation/dashboard_page.dart';
import '../../documents/presentation/documents_page.dart';
import '../../employees/presentation/employees_page.dart';
import '../../auth/presentation/login_page.dart';
import '../../payroll/presentation/payroll_page.dart';
import '../../performance/presentation/performance_page.dart';
import '../../recruitment/presentation/recruitment_page.dart';
import '../../reports/presentation/reports_page.dart';
import '../../special_days/presentation/special_days_page.dart';
import '../../users/presentation/users_page.dart';

class _Nav {
  _Nav(this.label, this.icon, this.build);
  final String label;
  final IconData icon;
  final Widget Function() build;
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;
  late final List<_Nav> _navs = [
    _Nav('Dashboard', Icons.dashboard_outlined, () => const DashboardFeaturePage()),
    if (Session.canEditEmployees)
      _Nav('Employees', Icons.people_outline, () => const EmployeesFeaturePage()),
    _Nav('Attendance', Icons.access_time, () => const AttendanceFeaturePage()),
    _Nav('Leave', Icons.beach_access_outlined, () => const LeaveFeaturePage()),
    _Nav('Payroll', Icons.payments_outlined, () => const PayrollFeaturePage()),
    if (Session.canRecruit)
      _Nav('Recruitment', Icons.person_search_outlined,
          () => const RecruitmentFeaturePage()),
    _Nav('Performance', Icons.trending_up, () => const PerformanceFeaturePage()),
    _Nav('Documents', Icons.folder_open, () => const DocumentsFeaturePage()),
    if (Session.isHr)
      _Nav('Special days', Icons.cake_outlined, () => const SpecialDaysFeaturePage()),
    if (Session.isHr)
      _Nav('Reports', Icons.assessment_outlined, () => const ReportsFeaturePage()),
    if (Session.isAdmin)
      _Nav('Users & Access', Icons.admin_panel_settings_outlined,
          () => const UsersFeaturePage()),
  ];

  @override
  void initState() {
    super.initState();
    if (Session.user?['must_change'] == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _changePassword(forced: true));
    }
  }

  Future<void> _changePassword({bool forced = false}) async {
    while (true) {
      if (!mounted) return;
      final r = await formDialog(
        context,
        forced ? 'Set a new password to continue' : 'Change password',
        const [
          F('pw', 'New password', type: 'password', required: true),
          F('pw2', 'Confirm password', type: 'password', required: true),
        ],
        cancelable: !forced,
      );
      if (r == null) return;
      if (!mounted) return;
      final pw = r['pw'] as String;
      if (pw.length < 6) {
        toast(context, 'Password must be at least 6 characters');
        continue;
      }
      if (pw != r['pw2']) {
        toast(context, 'Passwords do not match');
        continue;
      }
      await UsersRepository().setPassword((Session.user!['id'] as num).toInt(), pw);
      Session.user!['must_change'] = 0;
      if (mounted) toast(context, 'Password updated');
      return;
    }
  }

  void _logout() {
    Session.clear();
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const AuthFeaturePage()));
  }

  Widget _onlineOfflineToggle(ColorScheme cs) {
    final isOnline = StorageConfig.mode != StorageMode.localOnly;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          if (StorageConfig.mode == StorageMode.localOnly) {
            StorageConfig.setMode(StorageMode.apiOnly);
            toast(context, 'Switched to Online (Dio API Mode)');
          } else {
            StorageConfig.setMode(StorageMode.localOnly);
            toast(context, 'Switched to Offline (Local SQLite Mode)');
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isOnline ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOnline ? Icons.cloud_done : Icons.cloud_off,
              size: 16,
              color: isOnline ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOnline ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStorageSettings() async {
    StorageMode selectedMode = StorageConfig.mode;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Storage Mode Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<StorageMode>(
                title: const Text('Local Only (SQLite)'),
                subtitle: const Text('Save and fetch data locally on device'),
                value: StorageMode.localOnly,
                groupValue: selectedMode,
                onChanged: (v) => setStateDialog(() => selectedMode = v!),
              ),
              RadioListTile<StorageMode>(
                title: const Text('Dio API Only'),
                subtitle: const Text('Save and fetch data via remote Dio API'),
                value: StorageMode.apiOnly,
                groupValue: selectedMode,
                onChanged: (v) => setStateDialog(() => selectedMode = v!),
              ),
              RadioListTile<StorageMode>(
                title: const Text('Local & API (Sync)'),
                subtitle: const Text('Save locally and sync with Dio API'),
                value: StorageMode.localAndApi,
                groupValue: selectedMode,
                onChanged: (v) => setStateDialog(() => selectedMode = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                StorageConfig.setMode(selectedMode);
                Navigator.of(context).pop();
                toast(context, 'Storage mode updated to ${selectedMode.name}');
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navTile(ColorScheme cs, int i, {bool drawer = false}) {
    final sel = i == _index;
    final fg = sel ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: sel ? cs.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _index = i);
            if (drawer) Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(children: [
              Icon(_navs[i].icon, size: 20, color: fg),
              const SizedBox(width: 12),
              Text(_navs[i].label,
                  style: TextStyle(
                      color: fg,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sidebar(ColorScheme cs, {bool drawer = false}) {
    return Container(
      width: drawer ? null : 250,
      decoration: BoxDecoration(
        color: cs.surface,
        border: drawer
            ? null
            : Border(
                right: BorderSide(color: cs.outlineVariant.withOpacity(0.6))),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.badge_outlined, color: cs.onPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HRMS',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(kCompany,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (var i = 0; i < _navs.length; i++)
                _navTile(cs, i, drawer: drawer)
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    child: Text(
                        Session.name.isEmpty ? '?' : Session.name[0].toUpperCase()),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Session.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(kRoles[Session.role] ?? Session.role,
                              style: Theme.of(context).textTheme.bodySmall),
                        ]),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Account & Settings',
                    icon: const Icon(Icons.more_vert),
                    onSelected: (v) {
                      if (v == 'pw') _changePassword();
                      else if (v == 'storage') _showStorageSettings();
                      else _logout();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'pw', child: Text('Change password')),
                      PopupMenuItem(value: 'storage', child: Text('Storage Settings')),
                      PopupMenuItem(value: 'out', child: Text('Sign out')),
                    ],
                  ),
                ]),
                const SizedBox(height: 8),
                Center(child: _onlineOfflineToggle(cs)),
              ],
            ),
          ),
        ),
      ]),
    );
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Force white background for all feature pages.
    final whiteTheme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: Colors.white,
      canvasColor: Colors.white,
    );

    final page = Theme(
      data: whiteTheme,
      child: _navs[_index].build(),
    );

    final wide = MediaQuery.of(context).size.width >= 800;

    if (wide) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          children: [
            _sidebar(cs),
            Expanded(child: page),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _navs[_index].label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: _onlineOfflineToggle(cs)),
          ),
        ],
        shape: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: _sidebar(cs, drawer: true),
        ),
      ),
      body: page,
    );
  }

}
