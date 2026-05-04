// lib/features/horoscope/presentation/pages/horoscope_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/horoscope_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/no_network_page.dart';
import '../../../../core/widgets/error_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

const _signs       = ['Mesha','Vrishabha','Mithuna','Karka','Simha','Kanya','Tula','Vrischika','Dhanu','Makara','Kumbha','Meena'];
const _symbols     = ['♈','♉','♊','♋','♌','♍','♎','♏','♐','♑','♒','♓'];
const _englishNames = ['Aries','Taurus','Gemini','Cancer','Leo','Virgo','Libra','Scorpio','Sagittarius','Capricorn','Aquarius','Pisces'];

// Period tab definitions
const _periods = [
  _Period('daily',   'Today',   'TODAY'),
  _Period('weekly',  'Weekly',  'WEEKLY'),
  _Period('monthly', 'Monthly', 'MONTHLY'),
  _Period('yearly',  'Yearly',  'YEARLY'),
];

class _Period {
  final String key, label, short;
  const _Period(this.key, this.label, this.short);
}

class HoroscopePage extends StatefulWidget {
  const HoroscopePage({super.key});
  @override State<HoroscopePage> createState() => _HoroscopePageState();
}

class _HoroscopePageState extends State<HoroscopePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _type = 'daily';
  String? _userRasi;
  bool _hasBirthDetails = false;
  bool _browseOpen = false;
  int  _browseIdx  = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _periods.length, vsync: this);
    _tabCtrl.addListener(_onTabChange);
    _initFromUser();
    _loadHoroscope();
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChange);
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (_tabCtrl.indexIsChanging) return;
    setState(() => _type = _periods[_tabCtrl.index].key);
    if (_browseOpen) {
      _loadForSign(_signs[_browseIdx]);
    } else {
      _loadHoroscope();
    }
  }

  void _initFromUser() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final u = authState.user;
      _userRasi        = u.moonSign;
      _hasBirthDetails = u.hasBirthDetails;
      if (u.moonSign != null) {
        final idx = _signs.indexOf(u.moonSign!);
        if (idx >= 0) _browseIdx = idx;
      }
    }
  }

  void _loadHoroscope() {
    if (_hasBirthDetails) {
      context.read<HoroscopeBloc>().add(FetchMyHoroscope(type: _type));
    } else if (_userRasi != null) {
      context.read<HoroscopeBloc>().add(FetchHoroscope(_userRasi!, type: _type));
    } else {
      context.read<HoroscopeBloc>().add(FetchHoroscope('Mesha', type: _type));
    }
  }

  void _loadForSign(String sign) {
    context.read<HoroscopeBloc>().add(FetchHoroscope(sign, type: _type));
  }

  String get _periodShort => _periods[_tabCtrl.index].short;
  String get _periodLabel => _periods[_tabCtrl.index].label;

  String get _displaySign =>
      _browseOpen ? _signs[_browseIdx] : (_userRasi ?? 'Mesha');

  @override
  Widget build(BuildContext context) => NetworkGuard(
    child: Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink2,
        title: const Text('Horoscope', style: AppTextStyles.displayXs),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: AppColors.ink2,
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppColors.gold,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppColors.gold,
              unselectedLabelColor: AppColors.textHint,
              labelStyle: AppTextStyles.sectionTag.copyWith(fontSize: 10),
              unselectedLabelStyle: AppTextStyles.sectionTag.copyWith(
                  fontSize: 10, color: AppColors.textHint),
              tabs: _periods.map((p) => Tab(text: p.label)).toList(),
            ),
          ),
        ),
      ),
      body: BlocBuilder<HoroscopeBloc, HoroscopeState>(
        builder: (_, state) {
          if (state is HoroscopeLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.gold));
          }
          if (state is HoroscopeError) {
            return InlineError(
              message: state.msg,
              onRetry: () => _browseOpen
                  ? _loadForSign(_signs[_browseIdx])
                  : _loadHoroscope(),
            );
          }
          if (state is HoroscopeLoaded) return _buildContent(state.data);
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  Widget _buildContent(dynamic d) {
    final currentSign = _browseOpen ? _signs[_browseIdx] : (_userRasi ?? d.zodiacSign);
    final signIdx     = _signs.indexOf(currentSign);
    final idx         = signIdx >= 0 ? signIdx : 0;
    final isUserRasi  = _userRasi != null && currentSign == _userRasi;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Rasi header card ───────────────────────────────────────────────
        GradientCard(
          colors: [
            AppColors.violetDim.withOpacity(0.3),
            AppColors.goldDim.withOpacity(0.12),
          ],
          borderColor: AppColors.violet.withOpacity(0.3),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Text(_symbols[idx],
                    style: const TextStyle(fontSize: 36, color: AppColors.gold)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_signs[idx], style: AppTextStyles.displaySm),
                  Text(_englishNames[idx],
                      style: AppTextStyles.bodyXs
                          .copyWith(color: AppColors.textHint, fontSize: 11)),
                  if (isUserRasi) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border:
                            Border.all(color: AppColors.teal.withOpacity(0.4)),
                      ),
                      child: Text('Your Rasi',
                          style: AppTextStyles.bodyXs
                              .copyWith(color: AppColors.teal, fontSize: 9)),
                    ),
                  ],
                ]),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${d.overallScore.toStringAsFixed(1)} / 10',
                    style: AppTextStyles.monoLg.copyWith(color: AppColors.gold)),
                Text(_periodLabel,
                    style: AppTextStyles.bodyXs
                        .copyWith(color: AppColors.textHint, fontSize: 10)),
              ]),
            ]),

            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: AppSpacing.md),

            // ── Prediction ─────────────────────────────────────────────────
            Row(children: [
              Text('✦',
                  style: TextStyle(color: AppColors.violetLight, fontSize: 12)),
              const SizedBox(width: 6),
              Text(
                '${_signs[idx].toUpperCase()} · $_periodShort PREDICTION',
                style: AppTextStyles.sectionTag
                    .copyWith(color: AppColors.violetLight),
              ),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Text(d.prediction,
                style: AppTextStyles.bodySm.copyWith(height: 1.8)),
          ]),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Life areas ─────────────────────────────────────────────────────
        Text('LIFE AREAS · $_periodShort', style: AppTextStyles.sectionTag),
        const SizedBox(height: AppSpacing.md),
        AppCard(child: Column(children: [
          _ScoreRow('💼', 'Career',  d.careerScore,  AppColors.gold),
          const Divider(color: AppColors.borderSubtle, height: 24),
          _ScoreRow('💕', 'Love',    d.loveScore,    AppColors.rose),
          const Divider(color: AppColors.borderSubtle, height: 24),
          _ScoreRow('🌿', 'Health',  d.healthScore,  AppColors.teal),
          const Divider(color: AppColors.borderSubtle, height: 24),
          _ScoreRow('💰', 'Finance', d.financeScore, AppColors.violet),
        ])),

        const SizedBox(height: AppSpacing.lg),

        // ── Lucky factors ──────────────────────────────────────────────────
        Text('LUCKY FACTORS', style: AppTextStyles.sectionTag),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: _LuckyCard(
              '🔢', 'Number', '${d.luckyNumber}', AppColors.gold)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _LuckyCard(
              '🎨', 'Color', d.luckyColor, AppColors.teal)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _LuckyCard(
              '💎', 'Gemstone', d.luckyGemstone, AppColors.violetLight)),
        ]),

        const SizedBox(height: AppSpacing.lg),

        // ── Do & Avoid ─────────────────────────────────────────────────────
        if (d.doToday.isNotEmpty) ...[
          Text('✅  WHAT TO DO · $_periodShort', style: AppTextStyles.sectionTag),
          const SizedBox(height: AppSpacing.sm),
          _BulletCard(d.doToday, AppColors.teal),
          const SizedBox(height: AppSpacing.md),
        ],
        if (d.avoidToday.isNotEmpty) ...[
          Text('⚠️  WHAT TO AVOID · $_periodShort',
              style: AppTextStyles.sectionTag),
          const SizedBox(height: AppSpacing.sm),
          _BulletCard(d.avoidToday, AppColors.rose),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── Browse other signs ─────────────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _browseOpen = !_browseOpen),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Browse Other Signs',
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.textSecondary)),
                Icon(
                  _browseOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textHint,
                  size: 18,
                ),
              ],
            ),
          ),
        ),

        if (_browseOpen) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _signs.length,
              itemBuilder: (_, i) {
                final isSel      = _browseIdx == i;
                final isUserSign = _userRasi != null && _signs[i] == _userRasi;
                return GestureDetector(
                  onTap: () {
                    setState(() => _browseIdx = i);
                    _loadForSign(_signs[i]);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 62,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.goldDim : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSel
                            ? AppColors.gold
                            : isUserSign
                                ? AppColors.teal.withOpacity(0.5)
                                : AppColors.borderSubtle,
                        width: isUserSign && !isSel ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Text(_symbols[i],
                          style: TextStyle(
                              fontSize: 18,
                              color: isSel
                                  ? AppColors.gold
                                  : AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(_signs[i].substring(0, 3),
                          style: AppTextStyles.bodyXs.copyWith(
                              color: isSel
                                  ? AppColors.gold
                                  : AppColors.textHint,
                              fontSize: 9)),
                      if (isUserSign)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: const BoxDecoration(
                              color: AppColors.teal, shape: BoxShape.circle),
                        ),
                    ]),
                  ),
                );
              },
            ),
          ),
          if (_userRasi != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() => _browseOpen = false);
                _loadHoroscope();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border:
                      Border.all(color: AppColors.teal.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.my_location, size: 14, color: AppColors.teal),
                  const SizedBox(width: 6),
                  Text('Back to My Rasi ($_userRasi)',
                      style: AppTextStyles.bodyXs
                          .copyWith(color: AppColors.teal, fontSize: 10)),
                ]),
              ),
            ),
          ],
        ],

        const SizedBox(height: AppSpacing.x3l),
      ]),
    );
  }

  Widget _ScoreRow(String icon, String label, double score, Color color) =>
      Row(children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: AppTextStyles.labelSm),
            Text('${score.toStringAsFixed(1)} / 10',
                style: AppTextStyles.monoSm.copyWith(color: color)),
          ]),
          const SizedBox(height: 5),
          ScoreBar(label: '', score: score, color: color),
        ])),
      ]);

  Widget _LuckyCard(String icon, String label, String value, Color color) =>
      AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.bodyXs.copyWith(fontSize: 9),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.labelSm.copyWith(color: color),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ]),
      );

  Widget _BulletCard(List<String> items, Color color) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin:
                            const EdgeInsets.only(right: 10, top: 5),
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                      Expanded(
                          child: Text(s,
                              style: AppTextStyles.bodySm
                                  .copyWith(height: 1.55))),
                    ]),
                  ))
              .toList(),
        ),
      );
}
