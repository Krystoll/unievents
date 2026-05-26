import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/api/auth_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final AuthService _authService = AuthService();

  QrTokenResponse? _token;
  String? _error;
  bool _loading = true;
  Timer? _tickTimer;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadToken() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _authService.fetchQrToken();
      if (!mounted) return;
      setState(() {
        _token = token;
        _loading = false;
      });
      _scheduleRefresh(token.expiresAt);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось получить QR-код. Проверьте подключение.';
      });
    }
  }

  void _scheduleRefresh(DateTime expiresAt) {
    _refreshTimer?.cancel();
    final refreshIn = expiresAt.difference(DateTime.now()) - const Duration(seconds: 5);
    final delay = refreshIn.isNegative ? Duration.zero : refreshIn;
    _refreshTimer = Timer(delay, _loadToken);
  }

  int get _secondsLeft {
    final expiresAt = _token?.expiresAt;
    if (expiresAt == null) return 0;
    final diff = expiresAt.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  String _formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    _tickTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _token == null) return;
      if (_secondsLeft <= 0) {
        _loadToken();
      } else {
        setState(() {});
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('QR-код')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Покажите этот код на входе',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Код обновляется каждые 2 минуты',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_loading)
                const SizedBox(
                  width: 220,
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: _loadToken,
                      child: const Text('Повторить'),
                    ),
                  ],
                )
              else if (_token != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(color: AppColors.outline),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _token!.qrToken,
                    size: 220,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: AppColors.primary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              if (_token != null && !_loading) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: _secondsLeft <= 15 ? AppColors.warning : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Действителен ещё ${_formatCountdown(_secondsLeft)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _secondsLeft <= 15 ? AppColors.warning : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(user?.name ?? '', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
