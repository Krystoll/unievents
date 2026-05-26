import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_logo.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 720;
          if (wide) {
            return Row(
              children: [
                Expanded(child: _BrandPanel()),
                Expanded(
                  child: _FormPanel(
                    title: title,
                    subtitle: subtitle,
                    formChild: child,
                  ),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: _BrandPanel(compact: true),
                  ),
                  _FormPanel(
                    title: title,
                    subtitle: subtitle,
                    formChild: child,
                    compact: true,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.authGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(light: true),
              if (!compact) ...[
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Записывайтесь на события,\nотслеживайте заявки и посещаемость',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.title,
    required this.formChild,
    this.subtitle,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final Widget formChild;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              compact ? AppSpacing.lg : AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: AppSpacing.xl),
                formChild,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
