import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

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
      appBar: AppBar(title: Text(widget.eventTitle)),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final raw = capture.barcodes.first.rawValue;
              if (raw != null && raw.isNotEmpty) {
                _handleCode(raw);
              }
            },
          ),
          if (_message != null)
            Container(
              color: (_allowed ? Colors.green : Colors.red).withValues(alpha: 0.9),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_userName != null && _userName!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _userName!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
