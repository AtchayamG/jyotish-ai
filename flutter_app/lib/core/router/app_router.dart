// lib/core/router/app_router.dart
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../features/auth/presentation/bloc/auth_bloc.dart";
import "../../features/auth/presentation/pages/login_page.dart";
import "../../features/auth/presentation/pages/register_page.dart";
import "../../features/auth/presentation/pages/splash_page.dart";
import "../../features/home/presentation/pages/home_page.dart";
import "../../features/kundli/presentation/pages/kundli_page.dart";
import "../../features/horoscope/presentation/pages/horoscope_page.dart";
import "../../features/matchmaking/presentation/pages/matchmaking_page.dart";
import "../../features/ai_chat/presentation/pages/ai_chat_page.dart";
import "../../features/admin/presentation/pages/admin_page.dart";
import "shell_page.dart";

class AppRoutes {
  static const splash = "/";
  static const login = "/login";
  static const register = "/register";
  static const home = "/home";
  static const kundli = "/kundli";
  static const horoscope = "/horoscope";
  static const matchmaking = "/matchmaking";
  static const aiChat = "/ai-chat";
  static const admin = "/admin";
}

GoRouter createRouter(AuthBloc authBloc) => GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: _GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final s = authBloc.state;
        final going = state.matchedLocation;
        final isAuth = s is AuthAuthenticated;
        final isUnauth = s is AuthUnauthenticated;
        final isChecking = s is AuthInitial || s is AuthLoading;
        final publicRoutes = [AppRoutes.login, AppRoutes.register];
        final onSplash = going == AppRoutes.splash;

        // Guard: admin route only for admin users
        if (going == AppRoutes.admin && isAuth && !(s).user.isAdmin) {
          return AppRoutes.home;
        }

        if (isChecking) return onSplash ? null : AppRoutes.splash;
        if (isUnauth && !publicRoutes.contains(going) && !onSplash)
          return AppRoutes.login;
        if (isAuth && (onSplash || publicRoutes.contains(going)))
          return AppRoutes.home;
        return null;
      },
      routes: [
        GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashPage()),
        GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
        GoRoute(
            path: AppRoutes.register, builder: (_, __) => const RegisterPage()),
        ShellRoute(
          builder: (ctx, state, child) =>
              ShellPage(location: state.matchedLocation, child: child),
          routes: [
            GoRoute(path: AppRoutes.home, builder: (_, __) => const HomePage()),
            GoRoute(
                path: AppRoutes.kundli, builder: (_, __) => const KundliPage()),
            GoRoute(
                path: AppRoutes.horoscope,
                builder: (_, __) => const HoroscopePage()),
            GoRoute(
                path: AppRoutes.matchmaking,
                builder: (_, __) => const MatchmakingPage()),
            GoRoute(
                path: AppRoutes.aiChat, builder: (_, __) => const AiChatPage()),
            GoRoute(
                path: AppRoutes.admin, builder: (_, __) => const AdminPage()),
          ],
        ),
      ],
    );

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }
  late final dynamic _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
