import 'package:go_router/go_router.dart';
import '../screens/login/login_screen.dart';
import '../screens/main_shell_screen.dart';
import '../screens/new_job/new_job_screen.dart';
import '../screens/job_card/job_card_screen.dart';
import '../screens/invoice/invoice_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRouter {
  static GoRouter getRouter(String? token) {
    return GoRouter(
      initialLocation: token != null ? '/dashboard' : '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const MainShellScreen(initialIndex: 0),
        ),
        GoRoute(
          path: '/jobs',
          builder: (context, state) => const MainShellScreen(initialIndex: 1),
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) => const MainShellScreen(initialIndex: 2),
        ),
        GoRoute(
          path: '/vehicles',
          builder: (context, state) => const MainShellScreen(initialIndex: 3),
        ),
        GoRoute(
          path: '/services',
          builder: (context, state) => const MainShellScreen(initialIndex: 4),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const MainShellScreen(initialIndex: 5),
        ),
        GoRoute(
          path: '/new-job',
          builder: (context, state) => const NewJobScreen(),
        ),
        GoRoute(
          path: '/job-card/:id',
          builder: (context, state) => JobCardScreen(id: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/invoice/:id',
          builder: (context, state) => InvoiceScreen(id: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const MainShellScreen(initialIndex: 7),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const MainShellScreen(initialIndex: 8),
        ),
      ],
    );
  }
}
