// lib/features/auth/presentation/pages/splash_page.dart
import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "../bloc/auth_bloc.dart";
import "../../../../core/router/app_router.dart";
import "../../../../core/theme/app_theme.dart";

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale, _pulse;

  // Navigation gate: both must be true before we navigate
  bool _timerDone = false;
  AuthState? _pendingAuthState; // auth resolved before timer → hold here

  @override
  void initState() {
    super.initState();

    // Animation setup — logo fades + scales in over 1.4s, then pulses gently
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ctrl, curve: const Interval(0, 0.55, curve: Curves.easeOut)));
    _scale = Tween<double>(begin: 0.75, end: 1).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.55, curve: Curves.easeOutBack)));
    _pulse = Tween<double>(begin: 1, end: 1.04).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.6, 1, curve: Curves.easeInOut)));
    _ctrl.forward().then((_) {
      if (mounted) _ctrl.repeat(reverse: true, period: const Duration(milliseconds: 1200));
    });

    // Minimum 3-second display
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _timerDone = true;
      if (_pendingAuthState != null) _navigate(_pendingAuthState!);
    });

    // Kick off auth check
    Future.microtask(() {
      if (mounted) context.read<AuthBloc>().add(const CheckAuthStatus());
    });
  }

  void _navigate(AuthState state) {
    if (!mounted) return;
    if (state is AuthAuthenticated) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated ||
              state is AuthUnauthenticated ||
              state is AuthError) {
            if (_timerDone) {
              _navigate(state);
            } else {
              // Timer not done yet — park the state and wait
              _pendingAuthState = state;
            }
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.inkDeep,
          body: Stack(children: [
            // Radial glow background
            Positioned.fill(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: RadialGradient(
              center: const Alignment(0, 0.35),
              radius: 1.1,
              colors: [
                AppColors.violetDim.withOpacity(0.4),
                Colors.transparent,
              ],
            )))),
            Center(
                child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => FadeTransition(
                          opacity: _fade,
                          child: ScaleTransition(
                              scale: _scale,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Pulsing logo rings
                                    ScaleTransition(
                                      scale: _pulse,
                                      child: SizedBox(
                                          width: 164,
                                          height: 164,
                                          child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                _ring(164, AppColors.goldDim.withOpacity(0.5)),
                                                _ring(128, AppColors.violetDim),
                                                _ring(96,  AppColors.tealDim),
                                                Container(
                                                    width: 72,
                                                    height: 72,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: AppColors.violetDim,
                                                        border: Border.all(
                                                            color: AppColors.violet.withOpacity(0.5),
                                                            width: 1.5)),
                                                    child: const Center(
                                                        child: Text("☽",
                                                            style: TextStyle(
                                                                fontSize: 34)))),
                                              ])),
                                    ),
                                    const SizedBox(height: 32),
                                    Text("JYOTISH AI",
                                        style: AppTextStyles.sectionTag
                                            .copyWith(fontSize: 11, letterSpacing: 0.3)),
                                    const SizedBox(height: 10),
                                    const Text(
                                        "Ancient Wisdom.\nModern Clarity.",
                                        style: AppTextStyles.displayMd,
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 8),
                                    Text("Vedic & Tamil Astrology",
                                        style: AppTextStyles.bodySm),
                                    const SizedBox(height: 48),
                                    // Loading dots
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(3, (i) =>
                                        _LoadingDot(delay: i * 220)),
                                    ),
                                  ])),
                        ))),
          ]),
        ),
      );

  Widget _ring(double size, Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5)));
}

class _LoadingDot extends StatefulWidget {
  final int delay;
  const _LoadingDot({required this.delay});
  @override
  State<_LoadingDot> createState() => _LoadingDotState();
}

class _LoadingDotState extends State<_LoadingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _a = Tween<double>(begin: 0.2, end: 1).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FadeTransition(
          opacity: _a,
          child: Container(
              width: 7, height: 7,
              decoration: const BoxDecoration(
                  color: AppColors.gold, shape: BoxShape.circle)),
        ),
      );
}
