// lib/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../horoscope/presentation/bloc/horoscope_bloc.dart';
import '../../../../core/network/connectivity_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/no_network_page.dart';
import '../../../../core/widgets/error_page.dart';
import '../../../../core/router/app_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _selectedSign = 'Mesha';

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  void _loadForecast() =>
      context.read<HoroscopeBloc>().add(FetchHoroscope(_selectedSign));

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Session expired mid-use → redirect to login
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
                IconButton(
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.surface,
                    child: Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName[0].toUpperCase()
                          : '?',
                      style:
                          AppTextStyles.labelMd.copyWith(color: AppColors.gold),
                    ),
                  ),
                  onPressed: () =>
                      context.read<AuthBloc>().add(const LogoutRequested()),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Namaskaram, ${user?.fullName.split(' ').first ?? 'Seeker'}',
                    style: AppTextStyles.bodySm,
                  ),
                  const SizedBox(height: 4),
                  const Text('Your Cosmos Today',
                      style: AppTextStyles.displaySm),
                  const SizedBox(height: AppSpacing.lg),

                  // Forecast card with full error handling
                  _ForecastCard(onRetry: _loadForecast),
                  const SizedBox(height: AppSpacing.lg),

                  // Quick stats
                  const Row(children: [
                    Expanded(
                        child: _StatCard(
                            label: 'Lucky Number',
                            value: '7',
                            color: AppColors.gold)),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: _StatCard(
                            label: 'Active Dasha',
                            value: 'Rahu–Venus',
                            color: AppColors.violetLight)),
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
                      _ActionCard(
                          icon: '🪐',
                          title: 'Kundli',
                          sub: 'Birth chart',
                          route: AppRoutes.kundli,
                          color: AppColors.goldDim),
                      _ActionCard(
                          icon: '💫',
                          title: 'Matchmaking',
                          sub: 'Guna Milan',
                          route: AppRoutes.matchmaking,
                          color: AppColors.surface),
                      _ActionCard(
                          icon: '🤖',
                          title: 'AI Astrologer',
                          sub: 'Ask anything',
                          route: AppRoutes.aiChat,
                          color: AppColors.violetDim),
                      _ActionCard(
                          icon: '✦',
                          title: 'Horoscope',
                          sub: 'Daily forecast',
                          route: AppRoutes.horoscope,
                          color: AppColors.surface),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x3l),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _ForecastCard({required this.onRetry});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<HoroscopeBloc, HoroscopeState>(
        builder: (context, state) {
          if (state is HoroscopeLoading) return const ShimmerBox(height: 160);

          if (state is HoroscopeError) {
            return InlineError(
              message: state.msg,
              onRetry: onRetry,
            );
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppChip.violet("Today's Forecast"),
                      Text(
                        '${d.overallScore.toStringAsFixed(1)} / 10',
                        style: AppTextStyles.monoMd
                            .copyWith(color: AppColors.gold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    d.prediction.length > 120
                        ? '${d.prediction.substring(0, 120)}…'
                        : d.prediction,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textSecondary, height: 1.6),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(children: [
                    _MiniScore('💼', 'Career', d.careerScore),
                    _MiniScore('💕', 'Love', d.loveScore),
                    _MiniScore('🌿', 'Health', d.healthScore),
                    _MiniScore('💰', 'Finance', d.financeScore),
                  ]),
                ],
              ),
            );
          }

          // Initial state — show load prompt
          return GestureDetector(
            onTap: onRetry,
            child: GradientCard(
              colors: [
                AppColors.violetDim.withOpacity(0.2),
                Colors.transparent
              ],
              borderColor: AppColors.violet.withOpacity(0.2),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text('Tap to load your forecast ✦'),
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
                style: AppTextStyles.bodyXs.copyWith(color: AppColors.gold)),
            Text('${score.toStringAsFixed(0)}/10', style: AppTextStyles.monoSm),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.bodyXs),
          const SizedBox(height: 6),
          Text(value,
              style:
                  AppTextStyles.displayXs.copyWith(color: color, fontSize: 15)),
        ]),
      );
}

class _ActionCard extends StatelessWidget {
  final String icon, title, sub, route;
  final Color color;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.route,
    required this.color,
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
            ],
          ),
        ),
      );
}
