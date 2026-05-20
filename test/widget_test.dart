// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/app.dart';
import 'package:flutter_app/core/providers/auth_provider.dart';

void main() {
  testWidgets('Shows login screen by default', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: const UniEventsApp(),
      ),
    );
    await tester.pump();
    expect(find.text('Вход'), findsOneWidget);
  });
}
