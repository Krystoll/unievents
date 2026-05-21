import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/providers/auth_provider.dart';

class QrScreen extends StatelessWidget {
  const QrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userId = user?.id ?? '';
    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('QR-код')),
        body: const Center(child: Text('Нет данных пользователя')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('QR-код')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(data: userId, size: 250),
            const SizedBox(height: 16),
            Text(user?.name ?? '', style: Theme.of(context).textTheme.titleMedium),
            Text(user?.email ?? ''),
          ],
        ),
      ),
    );
  }
}
