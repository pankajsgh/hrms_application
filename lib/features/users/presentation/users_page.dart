import 'package:flutter/material.dart';

import 'package:hrms/core/common.dart';
import 'package:hrms/core/session.dart';
import 'package:hrms/core/ui.dart';
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
    final haveLogin = _controller.users.map((u) => u['employee_id']).toSet();
    final free = {
      for (final e in emps)
        if (!haveLogin.contains(e['id']))
          '${e['id']}': '${e.s('code')} - ${e.s('name')}',
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

  Future<void> _role(Rec u) async {
    final r = await formDialog(context, 'Change role for ${u.s('username')}', [
      F('role', 'Role',
          type: 'dropdown', required: true, options: kRoles, initial: u['role']),
    ]);
    if (r == null) return;
    await _controller.updateUser(u.i('id')!, {'role': r['role']});
  }

  Future<void> _reset(Rec u) async {
    final r =
        await formDialog(context, 'Reset password: ${u.s('username')}', const [
      F('pw', 'New temporary password (min 6)',
          type: 'password', required: true),
    ]);
    if (r == null) return;
    final pw = r['pw'] as String;
    if (pw.length < 6) {
      toast(context, 'Password must be at least 6 characters');
      return;
    }
    await _controller.setPassword(u.i('id')!, pw, mustChange: true);
    if (mounted) {
      toast(context, 'Password reset. The user must change it at next sign-in.');
    }
  }

  Future<void> _toggle(Rec u) async {
    if (u['id'] == Session.user!['id']) {
      toast(context, 'You cannot deactivate your own account');
      return;
    }
    await _controller.updateUser(
        u.i('id')!, {'active': u.i('active') == 1 ? 0 : 1});
  }

  @override
  Widget build(BuildContext context) {
    return PageBox(
      child: Column(children: [
        Header('Users & Access', actions: [
          FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Create login')),
        ]),
        Expanded(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return TableCard(
                columns: const [
                  DataColumn(label: Text('Username')),
                  DataColumn(label: Text('Employee')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Active')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  for (final u in _controller.users)
                    DataRow(cells: [
                      DataCell(Text(u.s('username'))),
                      DataCell(Text(u.s('emp_name'))),
                      DataCell(Text(kRoles[u.s('role')] ?? u.s('role'))),
                      DataCell(StatusChip(
                          u.i('active') == 1 ? 'Active' : 'Inactive')),
                      DataCell(Row(children: [
                        IconButton(
                            tooltip: 'Change role',
                            icon: const Icon(Icons.manage_accounts_outlined),
                            onPressed: () => _role(u)),
                        IconButton(
                            tooltip: 'Reset password',
                            icon: const Icon(Icons.lock_reset),
                            onPressed: () => _reset(u)),
                        IconButton(
                            tooltip: u.i('active') == 1
                                ? 'Deactivate'
                                : 'Activate',
                            icon: Icon(u.i('active') == 1
                                ? Icons.block
                                : Icons.check_circle_outline),
                            onPressed: () => _toggle(u)),
                      ])),
                    ]),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}
