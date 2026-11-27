
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
  final _formKey = GlobalKey<FormState>();

  late final AuthController _controller;

  bool _obscurePassword = true;

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
    if (_controller.busy) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final ok = await _controller.login(
      _user.text.trim(),
      _pass.text,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const Shell(),
        ),
      );
    }
  }

  Widget _feature(
      ColorScheme cs,
      IconData icon,
      String title,
      String subtitle,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandPanel(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            Color.lerp(cs.primary, Colors.black, 0.35)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: _decorationCircle(300),
          ),
          Positioned(
            bottom: -130,
            left: -100,
            child: _decorationCircle(350),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 55,
              vertical: 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 62,
                  width: 62,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.business_center_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Welcome to',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  kCompany,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Human Resource Management System',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 42),

                _feature(
                  cs,
                  Icons.people_alt_outlined,
                  'Employee Management',
                  'Employee directory and profiles',
                ),
                _feature(
                  cs,
                  Icons.access_time_rounded,
                  'Attendance Tracking',
                  'Daily attendance and working hours',
                ),
                _feature(
                  cs,
                  Icons.event_available_rounded,
                  'Leave Management',
                  'Leave requests and balances',
                ),
                _feature(
                  cs,
                  Icons.payments_outlined,
                  'Payroll Management',
                  'Salary details and payslips',
                ),
                _feature(
                  cs,
                  Icons.trending_up_rounded,
                  'Performance & Recruitment',
                  'Goals, reviews and hiring',
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your workplace, organized in one place',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorationCircle(double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _inputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 19),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 17,
      ),
      hintStyle: TextStyle(
        fontSize: 12,
        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
          color: cs.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: cs.error, width: 1.5),
      ),
    );
  }

  Widget _errorMessage(ColorScheme cs) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final error = _controller.error;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: error == null
              ? const SizedBox.shrink()
              : Container(
            key: ValueKey(error),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.error.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: cs.onErrorContainer,
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    error,
                    style: TextStyle(
                      color: cs.onErrorContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _loginButton() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final busy = _controller.busy;

        return SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: busy ? null : _login,
            style: FilledButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: busy
                  ? const Row(
                key: ValueKey('loading'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Signing in...',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              )
                  : const Row(
                key: ValueKey('login'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign in',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 9),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _loginForm(ColorScheme cs, {required bool wide}) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: wide ? 40 : 25,
          vertical: 30,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!wide) ...[
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.business_center_rounded,
                      size: 27,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                Text(
                  'Welcome back!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to access your ${kCompany} workspace.',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 34),

                _inputLabel('Username'),
                TextFormField(
                  controller: _user,
                  autofocus: wide,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: _inputDecoration(
                    hint: 'Enter your username',
                    icon: Icons.person_outline_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).nextFocus();
                  },
                ),

                const SizedBox(height: 20),

                _inputLabel('Password'),
                TextFormField(
                  controller: _pass,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    hint: 'Enter your password',
                    icon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 19,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _login(),
                ),

                const SizedBox(height: 16),

                _errorMessage(cs),

                const SizedBox(height: 24),

                _loginButton(),

                const SizedBox(height: 25),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 13,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Secure access to your workplace',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;

          if (wide) {
            return Row(
              children: [
                Expanded(
                  flex: 11,
                  child: _brandPanel(cs),
                ),
                Expanded(
                  flex: 9,
                  child: _loginForm(cs, wide: true),
                ),
              ],
            );
          }

          return SafeArea(
            child: _loginForm(cs, wide: false),
          );
        },
      ),
    );
  }
}
