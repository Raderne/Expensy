import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../application/auth_controller.dart';
import 'auth_error_message.dart';
import 'widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _serverError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _serverError = null);
    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _email.text.trim(),
            password: _password.text,
          );
    } catch (e) {
      setState(() => _serverError = authErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isLoading;
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to keep your expenses on track.',
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
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Email is required';
                if (!s.contains('@') || !s.contains('.')) return 'Enter a valid email';
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
              onSubmitted: (_) => _submit(),
              validator: (v) {
                if ((v ?? '').isEmpty) return 'Password is required';
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
          AuthPrimaryButton(label: 'Sign in', onPressed: _submit, busy: busy),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('New here? ', style: AppTextStyles.body),
              GestureDetector(
                onTap: busy ? null : () => context.go('/signup'),
                child: Text(
                  'Create an account',
                  style: AppTextStyles.labelStrong.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
