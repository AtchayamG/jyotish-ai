// lib/features/auth/presentation/pages/splash_page.dart
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
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scale = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.6, curve: Curves.easeOutBack)));
    _ctrl.forward();
    Future.microtask(() {
      if (mounted) context.read<AuthBloc>().add(const CheckAuthStatus());
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go(AppRoutes.home);
          } else if (state is AuthUnauthenticated || state is AuthError)
            context.go(AppRoutes.login);
        },
        child: Scaffold(
          backgroundColor: AppColors.inkDeep,
          body: Stack(children: [
            Positioned.fill(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: RadialGradient(
              center: const Alignment(0, 0.4),
              radius: 1.1,
              colors: [
                AppColors.violetDim.withOpacity(0.35),
                Colors.transparent
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
                                    SizedBox(
                                        width: 160,
                                        height: 160,
                                        child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              _ring(160, AppColors.goldDim),
                                              _ring(126, AppColors.violetDim),
                                              _ring(94, AppColors.tealDim),
                                              Container(
                                                  width: 72,
                                                  height: 72,
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color:
                                                          AppColors.violetDim,
                                                      border: Border.all(
                                                          color: AppColors
                                                              .violet
                                                              .withOpacity(
                                                                  0.4))),
                                                  child: const Center(
                                                      child: Text("☽",
                                                          style: TextStyle(
                                                              fontSize: 34)))),
                                            ])),
                                    const SizedBox(height: 28),
                                    Text("JYOTISH AI",
                                        style: AppTextStyles.sectionTag
                                            .copyWith(
                                                fontSize: 11,
                                                letterSpacing: 0.25)),
                                    const SizedBox(height: 8),
                                    const Text(
                                        "Ancient Wisdom.\nModern Clarity.",
                                        style: AppTextStyles.displayMd,
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 10),
                                    Text("Vedic & Tamil Astrology",
                                        style: AppTextStyles.bodySm),
                                    const SizedBox(height: 40),
                                    SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.gold
                                                .withOpacity(0.5))),
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
