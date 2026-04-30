// lib/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../horoscope/presentation/bloc/horoscope_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/error_page.dart';
import '../../../../core/widgets/no_network_page.dart';
import '../../../../core/router/app_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  /// Load horoscope for user's moon sign (rashi).
  /// Falls back to Mesha if moon sign not computed yet.
  void _loadForecast() {
    final authState = context.read<AuthBloc>().state;
    String sign = 'Mesha';
    if (authState is AuthAuthenticated) {
      final u = authState.user;
      if (u.moonSign != null && u.moonSign!.isNotEmpty) {
        sign = u.moonSign!;
      }
    }
    context.read<HoroscopeBloc>().add(FetchHoroscope(sign));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final firstName = user?.fullName.split(' ').first ?? 'Seeker';
    final sign = user?.moonSign ?? 'Mesha';

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) context.go(AppRoutes.login);
      },
      child: NetworkGuard(
        child: Scaffold(
          backgroundColor: AppColors.ink,
          body: CustomScrollView(slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.ink2,
              title: Text('JYOTISH AI', style: AppTextStyles.sectionTag),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => _showProfileMenu(context),
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.goldDim,
                      child: Text(
                        user?.fullName.isNotEmpty == true
                            ? user!.fullName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.labelMd
                            .copyWith(color: AppColors.gold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Greeting
                  Text('Namaskaram, $firstName',
                      style: AppTextStyles.bodySm),
                  const SizedBox(height: 4),
                  const Text('Your Cosmos Today',
                      style: AppTextStyles.displaySm),

                  // Birth info row
                  if (user?.placeOfBirth != null || user?.moonSign != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      if (user?.placeOfBirth != null) ...[
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.rose),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user!.placeOfBirth!,
                            style: AppTextStyles.bodyXs
                                .copyWith(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (user?.moonSign != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.goldDim.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.gold.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${_signSymbol(user!.moonSign!)} ${user.moonSign}',
                            style: AppTextStyles.bodyXs
                                .copyWith(color: AppColors.gold),
                          ),
                        ),
                      ],
                    ]),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // Forecast card
                  _ForecastCard(onRetry: _loadForecast, sign: sign),
                  const SizedBox(height: AppSpacing.lg),

                  // Quick stats
                  Row(children: [
                    Expanded(child: _StatCard(
                      label: 'Moon Sign',
                      value: user?.moonSign ?? '—',
                      color: AppColors.gold,
                    )),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _StatCard(
                      label: 'Birth Place',
                      value: user?.placeOfBirth?.split(',').first ?? '—',
                      color: AppColors.teal,
                    )),
                  ]),
                  const SizedBox(height: AppSpacing.lg),

                  Text('QUICK ACTIONS', style: AppTextStyles.sectionTag),
                  const SizedBox(height: AppSpacing.md),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.5,
                    children: const [
                      _ActionCard(icon: '🪐', title: 'Kundli',
                          sub: 'Birth chart', route: AppRoutes.kundli,
                          color: AppColors.goldDim),
                      _ActionCard(icon: '💫', title: 'Matchmaking',
                          sub: 'Guna Milan', route: AppRoutes.matchmaking,
                          color: AppColors.surface),
                      _ActionCard(icon: '🤖', title: 'AI Astrologer',
                          sub: 'Ask anything', route: AppRoutes.aiChat,
                          color: AppColors.violetDim),
                      _ActionCard(icon: '✦', title: 'Horoscope',
                          sub: 'Daily forecast', route: AppRoutes.horoscope,
                          color: AppColors.surface),
                    ],
                  ),

                  // Prompt to complete profile if birth details missing
                  if (user != null && !user.hasBirthDetails) ...[
                    const SizedBox(height: AppSpacing.lg),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.kundli),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.goldDim.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                              color: AppColors.gold.withOpacity(0.25)),
                        ),
                        child: Row(children: [
                          const Text('✦',
                              style: TextStyle(
                                  color: AppColors.gold, fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                              Text('Complete Your Profile',
                                  style: AppTextStyles.labelMd),
                              const SizedBox(height: 2),
                              Text(
                                'Add birth date, time & place for personalised predictions',
                                style: AppTextStyles.bodyXs.copyWith(
                                    color: AppColors.textSecondary),
                              ),
                            ]),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.gold),
                        ]),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.x3l),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.ink2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.logout_outlined,
                  color: AppColors.rose),
              title: Text('Sign Out',
                  style: AppTextStyles.bodyMd),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(const LogoutRequested());
              },
            ),
          ]),
        ),
      ),
    );
  }

  String _signSymbol(String sign) {
    const map = {
      'Mesha': '♈', 'Vrishabha': '♉', 'Mithuna': '♊', 'Karka': '♋',
      'Simha': '♌', 'Kanya': '♍', 'Tula': '♎', 'Vrischika': '♏',
      'Dhanu': '♐', 'Makara': '♑', 'Kumbha': '♒', 'Meena': '♓',
    };
    return map[sign] ?? '✦';
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _ForecastCard extends StatelessWidget {
  final VoidCallback onRetry;
  final String sign;
  const _ForecastCard({required this.onRetry, required this.sign});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<HoroscopeBloc, HoroscopeState>(
        builder: (context, state) {
          if (state is HoroscopeLoading) return const ShimmerBox(height: 160);
          if (state is HoroscopeError) {
            return InlineError(message: state.msg, onRetry: onRetry);
          }
          if (state is HoroscopeLoaded) {
            final d = state.data;
            return GradientCard(
              colors: [
                AppColors.violetDim.withOpacity(0.3),
                AppColors.goldDim.withOpacity(0.15),
              ],
              borderColor: AppColors.violet.withOpacity(0.25),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  const AppChip.violet("Today's Forecast"),
                  Text('${d.overallScore.toStringAsFixed(1)} / 10',
                      style: AppTextStyles.monoMd
                          .copyWith(color: AppColors.gold)),
                ]),
                const SizedBox(height: AppSpacing.md),
                Text(
                  d.prediction.length > 130
                      ? '${d.prediction.substring(0, 130)}…'
                      : d.prediction,
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textSecondary, height: 1.6),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  _MiniScore('💼', 'Career',  d.careerScore),
                  _MiniScore('💕', 'Love',    d.loveScore),
                  _MiniScore('🌿', 'Health',  d.healthScore),
                  _MiniScore('💰', 'Finance', d.financeScore),
                ]),
              ]),
            );
          }
          return GestureDetector(
            onTap: onRetry,
            child: GradientCard(
              colors: [
                AppColors.violetDim.withOpacity(0.2),
                Colors.transparent,
              ],
              borderColor: AppColors.violet.withOpacity(0.2),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text('Tap to load your forecast  ✦'),
                ),
              ),
            ),
          );
        },
      );
}

class _MiniScore extends StatelessWidget {
  final String icon, label;
  final double score;
  const _MiniScore(this.icon, this.label, this.score);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    AppTextStyles.bodyXs.copyWith(color: AppColors.gold)),
            Text('${score.toStringAsFixed(0)}/10',
                style: AppTextStyles.monoSm),
          ]),
        ),
      );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(label, style: AppTextStyles.bodyXs),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.displayXs
                  .copyWith(color: color, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      );
}

class _ActionCard extends StatelessWidget {
  final String icon, title, sub, route;
  final Color color;
  const _ActionCard({
    required this.icon, required this.title,
    required this.sub, required this.route, required this.color,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.go(route),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const Spacer(),
            Text(title, style: AppTextStyles.labelMd),
            Text(sub, style: AppTextStyles.bodyXs),
          ]),
        ),
      );
}
