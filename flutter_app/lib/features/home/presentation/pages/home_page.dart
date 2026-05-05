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
import '../../../auth/domain/entities/user_entity.dart';

// ── Day-of-week astronomy data ─────────────────────────────────────────────────

class _DayInfo {
  final String planet;
  final String symbol;
  final String mantra;
  final String focus;
  final String rahuKaal;
  final Color  color;
  const _DayInfo({
    required this.planet, required this.symbol,
    required this.mantra, required this.focus,
    required this.rahuKaal, required this.color,
  });
}

const _dayData = [
  // Monday = 0 in weekday-1 (DateTime.monday = 1)
  _DayInfo(planet: 'Moon',    symbol: '☽', mantra: 'Om Chandraya Namah',      focus: 'Emotions · Intuition · Home',      rahuKaal: '7:30 – 9:00 AM',   color: AppColors.planetMoon),
  _DayInfo(planet: 'Mars',    symbol: '♂', mantra: 'Om Angarakaya Namah',     focus: 'Courage · Action · Leadership',    rahuKaal: '3:00 – 4:30 PM',   color: AppColors.planetMars),
  _DayInfo(planet: 'Mercury', symbol: '☿', mantra: 'Om Budhaya Namah',        focus: 'Communication · Learning · Trade', rahuKaal: '12:00 – 1:30 PM',  color: AppColors.planetMercury),
  _DayInfo(planet: 'Jupiter', symbol: '♃', mantra: 'Om Gurave Namah',         focus: 'Wisdom · Expansion · Dharma',      rahuKaal: '1:30 – 3:00 PM',   color: AppColors.planetJupiter),
  _DayInfo(planet: 'Venus',   symbol: '♀', mantra: 'Om Shukraya Namah',       focus: 'Beauty · Love · Arts · Pleasure',  rahuKaal: '10:30 AM – 12:00', color: AppColors.planetVenus),
  _DayInfo(planet: 'Saturn',  symbol: '♄', mantra: 'Om Shanaischaraya Namah', focus: 'Discipline · Service · Patience',  rahuKaal: '9:00 – 10:30 AM',  color: AppColors.planetSaturn),
  _DayInfo(planet: 'Sun',     symbol: '☉', mantra: 'Om Suryaya Namah',        focus: 'Vitality · Authority · Clarity',   rahuKaal: '4:30 – 6:00 PM',   color: AppColors.planetSun),
];

_DayInfo _todayInfo() {
  // DateTime.weekday: 1=Mon … 7=Sun → map to 0-based index
  final idx = DateTime.now().weekday - 1; // 0 = Monday … 6 = Sunday
  return _dayData[idx % 7];
}

// ── Moon phase ─────────────────────────────────────────────────────────────────

class _MoonPhase {
  final String name;
  final String emoji;
  final int daysToNext;
  final String nextEvent;
  const _MoonPhase({required this.name, required this.emoji,
      required this.daysToNext, required this.nextEvent});
}

_MoonPhase _moonPhase() {
  // Reference new moon: 29 Jan 2025, approximate lunar cycle 29.53 days
  const refNewMoon = 2460704.5; // Julian Day ~Jan 29 2025
  final jd = DateTime.now().millisecondsSinceEpoch / 86400000.0 + 2440587.5;
  final lunation = ((jd - refNewMoon) % 29.53 + 29.53) % 29.53;

  if (lunation < 1.85) {
    return _MoonPhase(name: 'New Moon', emoji: '🌑', daysToNext: (7 - lunation).round(), nextEvent: 'First Quarter');
  } else if (lunation < 7.38) {
    return _MoonPhase(name: 'Waxing Crescent', emoji: '🌒', daysToNext: (7.38 - lunation).round(), nextEvent: 'First Quarter');
  } else if (lunation < 9.22) {
    return _MoonPhase(name: 'First Quarter', emoji: '🌓', daysToNext: (14.77 - lunation).round(), nextEvent: 'Full Moon');
  } else if (lunation < 14.77) {
    return _MoonPhase(name: 'Waxing Gibbous', emoji: '🌔', daysToNext: (14.77 - lunation).round(), nextEvent: 'Full Moon');
  } else if (lunation < 16.61) {
    return _MoonPhase(name: 'Full Moon', emoji: '🌕', daysToNext: (22.15 - lunation).round(), nextEvent: 'Last Quarter');
  } else if (lunation < 22.15) {
    return _MoonPhase(name: 'Waning Gibbous', emoji: '🌖', daysToNext: (22.15 - lunation).round(), nextEvent: 'Last Quarter');
  } else if (lunation < 23.99) {
    return _MoonPhase(name: 'Last Quarter', emoji: '🌗', daysToNext: (29.53 - lunation).round(), nextEvent: 'New Moon');
  } else {
    return _MoonPhase(name: 'Waning Crescent', emoji: '🌘', daysToNext: (29.53 - lunation).round(), nextEvent: 'New Moon');
  }
}


// ── HomePage ───────────────────────────────────────────────────────────────────

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

  void _loadForecast() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final u = authState.user;
      if (u.hasBirthDetails) {
        context.read<HoroscopeBloc>().add(const FetchMyHoroscope());
        return;
      }
      if (u.moonSign != null && u.moonSign!.isNotEmpty) {
        context.read<HoroscopeBloc>().add(FetchHoroscope(u.moonSign!));
        return;
      }
    }
    context.read<HoroscopeBloc>().add(const FetchHoroscope('Mesha'));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user      = authState is AuthAuthenticated ? authState.user : null;
    final firstName = user?.fullName.split(' ').first ?? 'Seeker';
    final sign      = user?.moonSign ?? 'Mesha';
    final day       = _todayInfo();
    final moon      = _moonPhase();

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(AppRoutes.login);
        } else if (state is AuthAuthenticated) {
          _loadForecast();
        }
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

                  // ── Greeting ───────────────────────────────────────────────
                  Text('Namaskaram, $firstName',
                      style: AppTextStyles.bodySm),
                  const SizedBox(height: 4),
                  const Text('Your Cosmos Today',
                      style: AppTextStyles.displaySm),

                  // ── Birth info row ─────────────────────────────────────────
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

                  // ── Forecast card ──────────────────────────────────────────
                  _ForecastCard(onRetry: _loadForecast, sign: sign),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Quick stats ────────────────────────────────────────────
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

                  // ── TODAY'S COSMIC SNAPSHOT ────────────────────────────────
                  Text('TODAY\'S COSMIC SNAPSHOT', style: AppTextStyles.sectionTag),
                  const SizedBox(height: AppSpacing.md),
                  _CosmicSnapshotCard(day: day),
                  const SizedBox(height: AppSpacing.md),

                  // ── Moon Phase + Daily Mantra ──────────────────────────────
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _MoonPhaseCard(moon: moon)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _DailyMantraCard(day: day)),
                  ]),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Auspicious Times ───────────────────────────────────────
                  Text('AUSPICIOUS TIMES TODAY', style: AppTextStyles.sectionTag),
                  const SizedBox(height: AppSpacing.md),
                  _AuspiciousTimesCard(day: day),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Your Chart Highlights (if birth details available) ──────
                  if (user != null && user.hasBirthDetails) ...[
                    Text('YOUR CHART', style: AppTextStyles.sectionTag),
                    const SizedBox(height: AppSpacing.md),
                    _ChartHighlightsCard(user: user!),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // ── Complete profile prompt ────────────────────────────────
                  if (user != null && !user.hasBirthDetails) ...[
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.kundli),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.goldDim.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  const SizedBox(height: AppSpacing.lg),
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
              leading: const Icon(Icons.settings_outlined,
                  color: AppColors.textSecondary),
              title: Text('Settings', style: AppTextStyles.bodyMd),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.settings);
              },
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            ListTile(
              leading: const Icon(Icons.people_alt_outlined,
                  color: AppColors.violet),
              title: Text('Switch Profile', style: AppTextStyles.bodyMd),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.switchProfile);
              },
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            ListTile(
              leading: const Icon(Icons.star_outline,
                  color: AppColors.gold),
              title: Text('Upgrade Plan', style: AppTextStyles.bodyMd),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.pricing);
              },
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            ListTile(
              leading: const Icon(Icons.logout_outlined,
                  color: AppColors.rose),
              title: Text('Sign Out', style: AppTextStyles.bodyMd),
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


// ── New Feature Widgets ───────────────────────────────────────────────────────

class _CosmicSnapshotCard extends StatelessWidget {
  final _DayInfo day;
  const _CosmicSnapshotCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final weekdayName = weekdays[now.weekday - 1];
    final dateStr = '${now.day} ${_monthName(now.month)} ${now.year}';

    return GradientCard(
      colors: [
        day.color.withOpacity(0.12),
        AppColors.surface.withOpacity(0.5),
      ],
      borderColor: day.color.withOpacity(0.3),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(weekdayName,
                style: AppTextStyles.displayXs.copyWith(color: day.color)),
            Text(dateStr,
                style: AppTextStyles.bodyXs.copyWith(
                    color: AppColors.textSecondary)),
          ]),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: day.color.withOpacity(0.15),
              border: Border.all(color: day.color.withOpacity(0.4)),
            ),
            child: Center(child: Text(day.symbol,
                style: TextStyle(fontSize: 24, color: day.color))),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: day.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: day.color.withOpacity(0.25)),
          ),
          child: Text('${day.planet}\'s Day · ${day.focus}',
              style: AppTextStyles.bodyXs.copyWith(color: day.color)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Today is ruled by ${day.planet}. Channel its energy through ${day.focus.toLowerCase().split(' · ').first}-oriented activities for best results.',
          style: AppTextStyles.bodyXs.copyWith(
              color: AppColors.textSecondary, height: 1.5),
        ),
      ]),
    );
  }

  String _monthName(int m) => const ['Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

class _MoonPhaseCard extends StatelessWidget {
  final _MoonPhase moon;
  const _MoonPhaseCard({required this.moon});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MOON PHASE', style: AppTextStyles.bodyXs.copyWith(
          color: AppColors.textHint, letterSpacing: 0.8)),
      const SizedBox(height: AppSpacing.sm),
      Row(children: [
        Text(moon.emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(moon.name,
                style: AppTextStyles.labelMd.copyWith(color: AppColors.planetMoon),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${moon.daysToNext}d to ${moon.nextEvent}',
                style: AppTextStyles.bodyXs.copyWith(
                    color: AppColors.textSecondary)),
          ]),
        ),
      ]),
    ]),
  );
}

class _DailyMantraCard extends StatelessWidget {
  final _DayInfo day;
  const _DailyMantraCard({required this.day});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('DAILY MANTRA', style: AppTextStyles.bodyXs.copyWith(
          color: AppColors.textHint, letterSpacing: 0.8)),
      const SizedBox(height: AppSpacing.sm),
      Text('108×', style: AppTextStyles.displayXs.copyWith(
          color: day.color, fontSize: 13)),
      const SizedBox(height: 4),
      Text(day.mantra,
          style: AppTextStyles.labelMd.copyWith(
              color: AppColors.textPrimary, fontSize: 11),
          maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      Text('Chant for ${day.planet}\'s blessings',
          style: AppTextStyles.bodyXs.copyWith(
              color: AppColors.textSecondary, fontSize: 10)),
    ]),
  );
}

class _AuspiciousTimesCard extends StatelessWidget {
  final _DayInfo day;
  const _AuspiciousTimesCard({required this.day});

  @override
  Widget build(BuildContext context) => GradientCard(
    colors: [AppColors.tealDim.withOpacity(0.3), Colors.transparent],
    borderColor: AppColors.teal.withOpacity(0.2),
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(children: [
      _TimeRow(
        icon: '✦',
        label: 'Brahma Muhurta',
        time: '4:30 – 6:00 AM',
        sub: 'Ideal for meditation & prayers',
        color: AppColors.gold,
      ),
      const SizedBox(height: AppSpacing.sm),
      _TimeRow(
        icon: '☀',
        label: 'Abhijit Muhurta',
        time: '11:48 AM – 12:36 PM',
        sub: 'Best for important decisions',
        color: AppColors.teal,
      ),
      const SizedBox(height: AppSpacing.sm),
      _TimeRow(
        icon: '⚠',
        label: 'Rahu Kaal (Avoid)',
        time: day.rahuKaal,
        sub: 'Avoid new ventures & travel',
        color: AppColors.rose,
      ),
    ]),
  );
}

class _TimeRow extends StatelessWidget {
  final String icon, label, time, sub;
  final Color color;
  const _TimeRow({required this.icon, required this.label,
      required this.time, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(
      width: 22,
      child: Text(icon, style: TextStyle(color: color, fontSize: 14),
          textAlign: TextAlign.center),
    ),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.labelSm.copyWith(color: color, fontSize: 11)),
      Text(sub, style: AppTextStyles.bodyXs.copyWith(color: AppColors.textHint, fontSize: 10)),
    ])),
    Text(time, style: AppTextStyles.monoSm.copyWith(color: color, fontSize: 11)),
  ]);
}

class _ChartHighlightsCard extends StatelessWidget {
  final UserEntity user;
  const _ChartHighlightsCard({required this.user});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.go(AppRoutes.kundli),
    child: GradientCard(
      colors: [
        AppColors.violetDim.withOpacity(0.3),
        AppColors.goldDim.withOpacity(0.1),
      ],
      borderColor: AppColors.violet.withOpacity(0.25),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const AppChip.violet('Birth Chart'),
          Row(children: [
            Text('View Kundli',
                style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.gold, fontSize: 11)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.gold, size: 16),
          ]),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          _ChartPill('☽', 'Rasi', user.moonSign ?? '—', AppColors.planetMoon),
          const SizedBox(width: AppSpacing.sm),
          _ChartPill('📍', 'Place', (user.placeOfBirth ?? '—').split(',').first, AppColors.teal),
          const SizedBox(width: AppSpacing.sm),
          _ChartPill('📅', 'DOB', _formatDob(user.dateOfBirth ?? ''), AppColors.violet),
        ]),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tap to open your full birth chart — Lagna, Nakshatra, planetary positions, and Dasha analysis await.',
          style: AppTextStyles.bodyXs.copyWith(
              color: AppColors.textSecondary, height: 1.5),
        ),
      ]),
    ),
  );

  String _formatDob(String dob) {
    final parts = dob.split('-');
    if (parts.length != 3) return dob;
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final m = int.tryParse(parts[1]) ?? 1;
    return '${parts[2]} ${months[m - 1]}';
  }
}

class _ChartPill extends StatelessWidget {
  final String icon, label, value;
  final Color color;
  const _ChartPill(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 3),
        Text(label, style: AppTextStyles.bodyXs.copyWith(
            color: AppColors.textHint, fontSize: 9)),
        Text(value,
            style: AppTextStyles.labelSm.copyWith(color: color, fontSize: 10),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}


// ── Existing Widgets ──────────────────────────────────────────────────────────

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
                  d.prediction,
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
                style: AppTextStyles.bodyXs.copyWith(color: AppColors.gold)),
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
