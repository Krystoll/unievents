import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/auth_scaffold.dart';
import '../../widgets/common/error_banner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted || !success) {
      return;
    }

    final role = authProvider.role;
    if (role == 'ADMIN') {
      context.go('/admin/events');
    } else if (role == 'CHECKER') {
      context.go('/checker/select');
    } else {
      context.go('/student/events');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AuthScaffold(
      title: 'Добро пожаловать',
      subtitle: 'Войдите в аккаунт, чтобы продолжить',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите email';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Пароль',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите пароль';
                }
                return null;
              },
            ),
            if (authProvider.error != null) ...[
              const SizedBox(height: AppSpacing.md),
              ErrorBanner(message: authProvider.error!),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: authProvider.isLoading ? null : _submit,
              child: authProvider.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Войти'),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: authProvider.isLoading ? null : () => context.go('/register'),
                child: const Text('Нет аккаунта? Зарегистрироваться'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
