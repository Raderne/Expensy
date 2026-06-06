import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../application/auth_controller.dart';
import 'auth_error_message.dart';
import 'widgets/auth_scaffold.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _serverError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _serverError = null);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signup(
            email: _email.text.trim(),
            password: _password.text,
            name: _name.text.trim(),
          );
    } catch (e) {
      setState(() => _serverError = authErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isLoading;
    return AuthScaffold(
      title: 'Create account',
      subtitle: 'Track every dollar — it only takes a minute.',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: 'Name',
              controller: _name,
              icon: Icons.person_outline_rounded,
              hint: 'Alex Chen',
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Name is required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              icon: Icons.mail_outline_rounded,
              hint: 'you@example.com',
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Email is required';
                if (!s.contains('@') || !s.contains('.'))
                  return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Password',
              controller: _password,
              obscure: true,
              textInputAction: TextInputAction.done,
              icon: Icons.lock_outline_rounded,
              hint: 'At least 8 characters',
              onSubmitted: (_) => _submit(),
              validator: (v) {
                final s = v ?? '';
                if (s.isEmpty) return 'Password is required';
                if (s.length < 8) return 'Use at least 8 characters';
                return null;
              },
            ),
            if (_serverError != null) ...[
              const SizedBox(height: 12),
              Text(
                _serverError!,
                style: AppTextStyles.label.copyWith(color: AppColors.danger),
              ),
            ],
          ],
        ),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthPrimaryButton(
            label: 'Create account',
            onPressed: _submit,
            busy: busy,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account? ', style: AppTextStyles.body),
              GestureDetector(
                onTap: busy ? null : () => context.go('/login'),
                child: Text(
                  'Sign in',
                  style: AppTextStyles.labelStrong.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
