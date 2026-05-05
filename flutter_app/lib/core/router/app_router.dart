// lib/core/router/app_router.dart
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../features/auth/presentation/bloc/auth_bloc.dart";
import "../../features/auth/domain/entities/user_entity.dart";
import "../../features/auth/presentation/pages/login_page.dart";
import "../../features/auth/presentation/pages/register_page.dart";
import "../../features/auth/presentation/pages/splash_page.dart";
import "../../features/auth/presentation/pages/profile_complete_page.dart";
import "../../features/home/presentation/pages/home_page.dart";
import "../../features/kundli/presentation/pages/kundli_page.dart";
import "../../features/horoscope/presentation/pages/horoscope_page.dart";
import "../../features/matchmaking/presentation/pages/matchmaking_page.dart";
import "../../features/ai_chat/presentation/pages/ai_chat_page.dart";
import "../../features/settings/presentation/pages/settings_page.dart";
import "../../features/settings/presentation/pages/pricing_page.dart";
import "../../features/settings/presentation/pages/add_profile_page.dart";
import "../../features/settings/presentation/pages/switch_profile_page.dart";
import "shell_page.dart";

class AppRoutes {
  static const splash          = "/";
  static const login           = "/login";
  static const register        = "/register";
  static const profileComplete = "/complete-profile";
  static const home            = "/home";
  static const kundli          = "/kundli";
  static const horoscope       = "/horoscope";
  static const matchmaking     = "/matchmaking";
  static const aiChat          = "/ai-chat";
  static const settings        = "/settings";
  static const pricing         = "/pricing";
  static const addProfile      = "/settings/add-profile";
  static const switchProfile   = "/settings/profiles";
  static const admin           = "/admin";
}

GoRouter createRouter(AuthBloc authBloc) => GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: _GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final s     = authBloc.state;
        final going = state.matchedLocation;

        final isAuth     = s is AuthAuthenticated;
        final isUnauth   = s is AuthUnauthenticated;
        final isChecking = s is AuthInitial || s is AuthLoading;

        final publicRoutes = [AppRoutes.login, AppRoutes.register];
        final onSplash     = going == AppRoutes.splash;
        final onComplete   = going == AppRoutes.profileComplete;
        final onPricing    = going == AppRoutes.pricing;

        if (onSplash) return null;

        if (isChecking) {
          return publicRoutes.contains(going) ? null : AppRoutes.splash;
        }

        if (isUnauth && !publicRoutes.contains(going)) return AppRoutes.login;

        if (isAuth) {
          final user = (s as AuthAuthenticated).user;

          // ── Profile completion gate ────────────────────────────────────────
          if (!user.hasBirthDetails && !onComplete) {
            return AppRoutes.profileComplete;
          }

          // ── Free trial expiry gate ─────────────────────────────────────────
          // Expired free users may only access the pricing/upgrade page.
          if (user.isTrialExpired && !onPricing) {
            return AppRoutes.pricing;
          }

          if (publicRoutes.contains(going)) return AppRoutes.home;
        }

        return null;
      },
      routes: [
        GoRoute(path: AppRoutes.splash,   builder: (_, __) => const SplashPage()),
        GoRoute(path: AppRoutes.login,    builder: (_, __) => const LoginPage()),
        GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterPage()),
        GoRoute(
          path: AppRoutes.profileComplete,
          builder: (_, __) => const ProfileCompletePage(),
        ),
        // ── Settings flow (outside shell — full screen) ────────────────────
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, __) => const SettingsPage(),
        ),
        GoRoute(
          path: AppRoutes.pricing,
          builder: (_, __) => const PricingPage(),
        ),
        GoRoute(
          path: AppRoutes.addProfile,
          builder: (_, __) => const AddProfilePage(),
        ),
        GoRoute(
          path: AppRoutes.switchProfile,
          builder: (_, __) => const SwitchProfilePage(),
        ),
        // ── Shell (bottom nav) ─────────────────────────────────────────────
        ShellRoute(
          builder: (ctx, state, child) =>
              ShellPage(location: state.matchedLocation, child: child),
          routes: [
            GoRoute(path: AppRoutes.home,        builder: (_, __) => const HomePage()),
            GoRoute(path: AppRoutes.kundli,       builder: (_, __) => const KundliPage()),
            GoRoute(path: AppRoutes.horoscope,    builder: (_, __) => const HoroscopePage()),
            GoRoute(path: AppRoutes.matchmaking,  builder: (_, __) => const MatchmakingPage()),
            GoRoute(path: AppRoutes.aiChat,       builder: (_, __) => const AiChatPage()),
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
