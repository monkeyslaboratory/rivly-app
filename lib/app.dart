import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/l10n/app_localizations.dart';
import 'core/theme/pulse_theme.dart';
import 'logic/auth/auth_cubit.dart';
import 'logic/auth/auth_state.dart';
import 'logic/dashboard/dashboard_cubit.dart';
import 'logic/insights/insights_cubit.dart';
import 'logic/sidebar/sidebar_cubit.dart';
import 'logic/theme/theme_cubit.dart';
import 'logic/theme/theme_state.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/insights/insights_screen.dart';
import 'presentation/screens/jobs/jobs_screen.dart';
import 'presentation/screens/competitors/competitor_detail_screen.dart';
import 'presentation/screens/competitors/feature_matrix_screen.dart';
import 'presentation/screens/reports/report_detail_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/run_progress/run_progress_screen.dart';
import 'presentation/screens/run_progress/run_review_screen.dart';
import 'presentation/screens/shell/app_shell.dart';

class RivlyApp extends StatefulWidget {
  const RivlyApp({super.key});

  @override
  State<RivlyApp> createState() => _RivlyAppState();
}

class _RivlyAppState extends State<RivlyApp> {
  late final AuthCubit _authCubit;
  late final ThemeCubit _themeCubit;
  late final DashboardCubit _dashboardCubit;
  late final InsightsCubit _insightsCubit;
  late final SidebarCubit _sidebarCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit()..checkAuth();
    _themeCubit = ThemeCubit();
    _dashboardCubit = DashboardCubit();
    _insightsCubit = InsightsCubit();
    _sidebarCubit = SidebarCubit();

    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: GoRouterRefreshStream(_authCubit.stream),
      redirect: (context, state) {
        final authState = _authCubit.state;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        // While auth is loading, stay on auth routes or redirect to login
        if (authState is AuthInitial || authState is AuthLoading) {
          return isAuthRoute ? null : '/login';
        }

        if (authState is Authenticated && isAuthRoute) {
          return '/dashboard';
        }

        if (authState is! Authenticated && !isAuthRoute) {
          return '/login';
        }

        return null;
      },
      routes: [
        // Auth routes — outside the shell
        GoRoute(
          path: '/login',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const AuthScreen(isRegister: true),
        ),

        // Authenticated routes — inside the shell
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/jobs',
              builder: (context, state) => const JobsScreen(),
            ),
            GoRoute(
              path: '/insights',
              builder: (context, state) => const InsightsScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: '/runs/:id',
              builder: (context, state) {
                final runId = state.pathParameters['id']!;
                return RunProgressScreen(runId: runId);
              },
            ),
            GoRoute(
              path: '/runs/:id/review',
              builder: (context, state) {
                final runId = state.pathParameters['id']!;
                return RunReviewScreen(runId: runId);
              },
            ),
            GoRoute(
              path: '/reports/:id',
              builder: (context, state) {
                final runId = state.pathParameters['id']!;
                return ReportDetailScreen(runId: runId);
              },
            ),
            GoRoute(
              path: '/feature-matrix',
              builder: (_, __) => const FeatureMatrixScreen(),
            ),
            GoRoute(
              path: '/competitors/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return CompetitorDetailScreen(competitorId: id);
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _authCubit.close();
    _themeCubit.close();
    _dashboardCubit.close();
    _insightsCubit.close();
    _sidebarCubit.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider.value(value: _themeCubit),
        BlocProvider.value(value: _sidebarCubit),
        BlocProvider.value(value: _dashboardCubit),
        BlocProvider.value(value: _insightsCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'Rivly',
            debugShowCheckedModeBanner: false,
            theme: PulseTheme.light(),
            darkTheme: PulseTheme.dark(),
            themeMode: themeState.themeMode,
            locale: themeState.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

/// Converts a [Stream] into a [Listenable] for GoRouter refresh.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    (_subscription as dynamic).cancel();
    super.dispose();
  }
}
