import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/auth_repository.dart';
import 'auth_error_message.dart';
import 'widgets/auth_scaffold.dart';

enum _Step { requestEmail, enterCode, done }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();

  _Step _step = _Step.requestEmail;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> _run(
    Future<void> Function() action, {
    required _Step next,
  }) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _step = next);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _sendCode() => _run(
    () => _repo.forgotPassword(_email.text.trim()),
    next: _Step.enterCode,
  );

  void _resetPassword() => _run(
    () => _repo.resetPassword(
      email: _email.text.trim(),
      code: _code.text.trim(),
      newPassword: _password.text,
    ),
    next: _Step.done,
  );

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _Step.requestEmail => _buildRequestEmail(),
      _Step.enterCode => _buildEnterCode(),
      _Step.done => _buildDone(),
    };
  }

  // ─── Step 1: ask for the email ─────────────────────────────────────────────

  Widget _buildRequestEmail() {
    return AuthScaffold(
      title: 'Forgot password',
      subtitle: 'Enter your email and we\'ll send you a reset code.',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              icon: Icons.mail_outline_rounded,
              hint: 'you@example.com',
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _sendCode(),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Email is required';
                if (!s.contains('@') || !s.contains('.'))
                  return 'Enter a valid email';
                return null;
              },
            ),
            _errorText(),
          ],
        ),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthPrimaryButton(
            label: 'Send code',
            onPressed: _sendCode,
            busy: _busy,
          ),
          const SizedBox(height: 12),
          _backToSignIn(),
        ],
      ),
    );
  }

  // ─── Step 2: enter code + new password ─────────────────────────────────────

  Widget _buildEnterCode() {
    return AuthScaffold(
      title: 'Check your email',
      subtitle:
          'We sent a 6-digit code to ${_email.text.trim()}. '
          'Enter it with your new password.',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: 'Reset code',
              controller: _code,
              keyboardType: TextInputType.number,
              icon: Icons.pin_outlined,
              hint: '123456',
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Enter the 6-digit code';
                if (!RegExp(r'^\d{6}$').hasMatch(s))
                  return 'Code must be 6 digits';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'New password',
              controller: _password,
              obscure: true,
              icon: Icons.lock_outline_rounded,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _resetPassword(),
              validator: (v) {
                if ((v ?? '').length < 8) return 'At least 8 characters';
                return null;
              },
            ),
            _errorText(),
          ],
        ),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthPrimaryButton(
            label: 'Reset password',
            onPressed: _resetPassword,
            busy: _busy,
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: _busy
                  ? null
                  : () => setState(() {
                      _error = null;
                      _step = _Step.requestEmail;
                    }),
              child: Text(
                'Use a different email',
                style: AppTextStyles.labelStrong.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 3: done ──────────────────────────────────────────────────────────

  Widget _buildDone() {
    return AuthScaffold(
      title: 'Password updated',
      subtitle: 'You can now sign in with your new password.',
      form: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 36,
          ),
        ),
      ),
      footer: AuthPrimaryButton(
        label: 'Back to sign in',
        onPressed: () => context.go('/login'),
      ),
    );
  }

  // ─── Shared bits ───────────────────────────────────────────────────────────

  Widget _errorText() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        _error!,
        style: AppTextStyles.label.copyWith(color: AppColors.danger),
      ),
    );
  }

  Widget _backToSignIn() {
    return Center(
      child: GestureDetector(
        onTap: _busy ? null : () => context.go('/login'),
        child: Text(
          'Back to sign in',
          style: AppTextStyles.labelStrong.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}
