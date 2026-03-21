import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/auth/auth_provider.dart';
import 'features/projects/projects_screen.dart';
import 'features/setup/setup_screen.dart';
import 'features/shell/home_shell.dart';
import 'features/timer/timer_screen.dart';
import 'features/timesheet/timesheet_screen.dart';
import 'features/week/week_screen.dart';

GoRouter appRouter(WidgetRef ref) => GoRouter(
      initialLocation: '/home/projects',
      redirect: (context, state) async {
        final authAsync = ref.read(authStateProvider);
        final autenticato = authAsync.valueOrNull ?? false;
        if (!autenticato && !state.matchedLocation.startsWith('/setup')) {
          return '/setup';
        }
        if (autenticato && state.matchedLocation.startsWith('/setup')) {
          return '/home/projects';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/setup', builder: (ctx, s) => const SetupScreen()),
        StatefulShellRoute.indexedStack(
          builder: (ctx, s, shell) => HomeShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/home/projects', builder: (ctx, s) => const ProjectsScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/home/timer', builder: (ctx, s) => const TimerScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/home/today', builder: (ctx, s) => const TimesheetScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/home/week', builder: (ctx, s) => const WeekScreen())]),
          ],
        ),
      ],
    );
