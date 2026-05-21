import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/admin/admin_wide_required_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/checker/checker_scan_screen.dart';
import 'screens/checker/checker_select_event_screen.dart';
import 'screens/student/event_detail_screen.dart';
import 'screens/student/qr_screen.dart';
import 'screens/student/student_shell.dart';

class UniEventsApp extends StatelessWidget {
  const UniEventsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final router = _createRouter(authProvider);
        return MaterialApp.router(
          title: 'UniEvents',
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          routerConfig: router,
        );
      },
    );
  }

  GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isAuthRoute =
            state.matchedLocation == '/login' || state.matchedLocation == '/register';

        if (!isLoggedIn && !isAuthRoute) {
          return '/login';
        }

        if (isLoggedIn && isAuthRoute) {
          return _homePath(context, authProvider.role);
        }

        if (isLoggedIn && authProvider.role == 'ADMIN' && !isWideScreen(context)) {
          final allowed = state.matchedLocation == '/admin/wide-required';
          if (!allowed) return '/admin/wide-required';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/student/events',
          builder: (context, state) => const StudentShell(),
        ),
        GoRoute(
          path: '/student/events/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return EventDetailScreen(eventId: id);
          },
        ),
        GoRoute(
          path: '/student/qr',
          builder: (context, state) => const QrScreen(),
        ),
        GoRoute(
          path: '/admin/events',
          builder: (context, state) => const AdminShell(),
        ),
        GoRoute(
          path: '/admin/wide-required',
          builder: (context, state) => const AdminWideRequiredScreen(),
        ),
        GoRoute(
          path: '/checker/select',
          builder: (context, state) => const CheckerSelectEventScreen(),
        ),
        GoRoute(
          path: '/checker/scan/:eventId',
          builder: (context, state) {
            final eventId = state.pathParameters['eventId']!;
            final eventTitle = (state.extra as String?) ?? 'Сканирование';
            return CheckerScanScreen(eventId: eventId, eventTitle: eventTitle);
          },
        ),
      ],
    );
  }

  String _homePath(BuildContext context, String? role) {
    if (role == 'ADMIN') {
      return isWideScreen(context) ? '/admin/events' : '/admin/wide-required';
    }
    if (role == 'CHECKER') {
      return '/checker/select';
    }
    return '/student/events';
  }
}

bool isWideScreen(BuildContext context) {
  return MediaQuery.of(context).size.width > 800;
}
