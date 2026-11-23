import 'package:flutter/material.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
import 'package:hrms/domain/entities/user_entity.dart';
import 'users_controller.dart';

class UsersFeaturePage extends StatefulWidget {
  const UsersFeaturePage({super.key});

  @override
  State<UsersFeaturePage> createState() => UsersFeaturePageState();
}

class UsersFeaturePageState extends State<UsersFeaturePage> {
  late final UsersController _controller;

  @override
  void initState() {
    super.initState();
    _controller = UsersController()..loadUsers();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final emps = _controller.activeEmployees;
    final haveLogin = _controller.users.map((u) => u.employeeId).toSet();
    final free = {
      for (final e in emps)
        if (!haveLogin.contains(e.id))
          '${e.id}': '${e.code} - ${e.name}',
    };
    if (!mounted) return;
    final r = await formDialog(context, 'Create login', [
      F('emp', 'Employee', type: 'dropdown', required: true, options: free),
      const F('username', 'Username', required: true),
      const F('password', 'Initial password (min 6)',
          type: 'password', required: true),
      const F('role', 'Role',
          type: 'dropdown',
          required: true,
          options: kRoles,
          initial: 'employee'),
    ]);
    if (r == null) return;
    final err = await _controller.createUser(
        r['username'] as String,
        r['password'] as String,
        r['role'] as String,
        int.parse(r['emp'] as String));
    if (!mounted) return;
    toast(context,
        err ?? 'Login created. The user must set a new password at first sign-in.');
  }

  Future<void> _role(UserEntity u) async {
    final r = await formDialog(context, 'Change role for ${u.username}', [
      F('role', 'Role',
          type: 'dropdown', required: true, options: kRoles, initial: u.role),
    ]);
    if (r == null) return;
    await _controller.updateUser(u.id!, {'role': r['role']});
  }

  Future<void> _reset(UserEntity u) async {
    final r =
        await formDialog(context, 'Reset password: ${u.username}', const [
      F('pw', 'New temporary password (min 6)',
          type: 'password', required: true),
    ]);
    if (r == null) return;
    final pw = r['pw'] as String;
    if (pw.length < 6) {
      toast(context, 'Password must be at least 6 characters');
      return;
    }
    await _controller.setPassword(u.id!, pw, mustChange: true);
    if (mounted) {
      toast(context, 'Password reset. The user must change it at next sign-in.');
    }
  }

  Future<void> _toggle(UserEntity u) async {
    if (u.id == Session.user!['id']) {
      toast(context, 'You cannot deactivate your own account');
      return;
    }
    await _controller.updateUser(
        u.id!, {'active': u.active == 1 ? 0 : 1});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return PageBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Header(
            'Users & Access',
            actions: [
              FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('Create Login'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = _controller.users;

                if (users.isEmpty) {
                  return const Center(child: Text('No user logins found'));
                }

                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final u = users[index];
                    final isActive = u.active == 1;

                    return Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.6)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? cs.primaryContainer
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.admin_panel_settings_outlined,
                                color: isActive ? cs.primary : Colors.grey,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        u.username,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      StatusChip(isActive ? 'Active' : 'Inactive'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Employee: ${u.empName ?? '—'}  •  Role: ${kRoles[u.role] ?? u.role}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Change role',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                      Icons.manage_accounts_outlined,
                                      size: 18),
                                  onPressed: () => _role(u),
                                ),
                                IconButton(
                                  tooltip: 'Reset password',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.lock_reset, size: 18),
                                  onPressed: () => _reset(u),
                                ),
                                IconButton(
                                  tooltip: isActive ? 'Deactivate' : 'Activate',
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    isActive
                                        ? Icons.block
                                        : Icons.check_circle_outline,
                                    size: 18,
                                    color: isActive ? Colors.orange : Colors.green,
                                  ),
                                  onPressed: () => _toggle(u),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
