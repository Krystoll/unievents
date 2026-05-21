import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/events_provider.dart';

class CheckerScanScreen extends StatefulWidget {
  const CheckerScanScreen({super.key, required this.eventId, required this.eventTitle});

  final String eventId;
  final String eventTitle;

  @override
  State<CheckerScanScreen> createState() => _CheckerScanScreenState();
}

class _CheckerScanScreenState extends State<CheckerScanScreen> {
  bool _locked = false;
  String? _message;
  String? _userName;
  bool _allowed = false;

  Future<void> _handleCode(String userId) async {
    if (_locked) return;
    setState(() => _locked = true);
    final result = await context.read<EventsProvider>().scan(
          userId: userId,
          eventId: widget.eventId,
        );
    if (!mounted) return;
    setState(() {
      _allowed = result?.allowed ?? false;
      _message = result?.message ?? 'Ошибка сканирования';
      _userName = result?.userName;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _locked = false;
      _message = null;
      _userName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Сканирование', style: TextStyle(fontSize: 14, color: Colors.white70)),
            Text(
              widget.eventTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Сменить мероприятие',
            onPressed: () => context.go('/checker/select'),
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
          IconButton(
            tooltip: 'Выйти',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: (capture) {
              final raw = capture.barcodes.first.rawValue;
              if (raw != null && raw.isNotEmpty) {
                _handleCode(raw);
              }
            },
          ),
          const _ScanFrameOverlay(),
          if (_locked && _message == null)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          if (_message != null) _ResultOverlay(
            allowed: _allowed,
            message: _message!,
            userName: _userName,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ScanHintPanel(locked: _locked),
          ),
        ],
      ),
    );
  }
}

class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 3),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Stack(
            children: [
              Positioned(top: -1, left: -1, child: _ScanCorner(top: true, left: true)),
              Positioned(top: -1, right: -1, child: _ScanCorner(top: true, left: false)),
              Positioned(bottom: -1, left: -1, child: _ScanCorner(top: false, left: true)),
              Positioned(bottom: -1, right: -1, child: _ScanCorner(top: false, left: false)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanCorner extends StatelessWidget {
  const _ScanCorner({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
          bottom: !top ? const BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
          left: left ? const BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
          right: !left ? const BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.allowed,
    required this.message,
    this.userName,
  });

  final bool allowed;
  final String message;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final color = allowed ? AppColors.success : AppColors.error;
    return Container(
      color: color.withValues(alpha: 0.92),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allowed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: Colors.white,
            size: 72,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (userName != null && userName!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              userName!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScanHintPanel extends StatelessWidget {
  const _ScanHintPanel({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(
            locked ? Icons.hourglass_top_rounded : Icons.qr_code_scanner_rounded,
            color: locked ? AppColors.warning : AppColors.secondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              locked
                  ? 'Обработка... подождите'
                  : 'Наведите камеру на QR-код студента',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
