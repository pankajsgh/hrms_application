import 'package:flutter/material.dart';

import 'package:hrms/core/ui.dart';
import '../../shell/presentation/shell.dart';
import 'auth_controller.dart';

class AuthFeaturePage extends StatefulWidget {
  const AuthFeaturePage({super.key});

  @override
  State<AuthFeaturePage> createState() => AuthFeaturePageState();
}

class AuthFeaturePageState extends State<AuthFeaturePage> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  late final AuthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthController();
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final ok = await _controller.login(_user.text, _pass.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));
    }
  }

  Widget _feature(ColorScheme cs, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.onPrimary.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: cs.onPrimary),
          ),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: cs.onPrimary, fontSize: 15)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final wide = MediaQuery.of(context).size.width > 820;

    final form = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!wide) ...[
                Icon(Icons.badge_outlined, size: 44, color: cs.primary),
                const SizedBox(height: 12),
              ],
              Text('Welcome back',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Sign in to continue to $kCompany',
                  style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 28),
              TextField(
                controller: _user,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: cs.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: cs.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onSubmitted: (_) => _login(),
              ),
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  if (_controller.error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline,
                            size: 18, color: cs.onErrorContainer),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_controller.error!,
                                style: TextStyle(color: cs.onErrorContainer))),
                      ]),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => FilledButton(
                    onPressed: _controller.busy ? null : _login,
                    child: const Text('Sign in'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: Row(children: [
        if (wide)
          Expanded(
            child: Container(
              color: cs.primary,
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.badge_outlined, size: 64, color: cs.onPrimary),
                  const SizedBox(height: 24),
                  Text(kCompany,
                      style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Human Resource Management System',
                      style: TextStyle(
                          color: cs.onPrimary.withOpacity(0.8), fontSize: 18)),
                  const SizedBox(height: 40),
                  _feature(cs, Icons.people_outline,
                      'Employee directory & profiles'),
                  _feature(cs, Icons.access_time, 'Attendance & time tracking'),
                  _feature(cs, Icons.beach_access_outlined,
                      'Leave management & balances'),
                  _feature(cs, Icons.payments_outlined,
                      'Payroll & downloadable payslips'),
                  _feature(cs, Icons.assessment_outlined,
                      'Performance reviews & reports'),
                ],
              ),
            ),
          ),
        Expanded(child: form),
      ]),
    );
  }
}


