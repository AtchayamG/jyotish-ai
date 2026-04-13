// lib/features/matchmaking/presentation/pages/matchmaking_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/match_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/no_network_page.dart';
import '../../../../core/widgets/error_page.dart';

class MatchmakingPage extends StatefulWidget {
  const MatchmakingPage({super.key});
  @override State<MatchmakingPage> createState() => _MatchmakingPageState();
}

class _MatchmakingPageState extends State<MatchmakingPage> {
  final _n1 = TextEditingController(text: 'Person 1');
  int _y1 = 1990, _m1 = 4, _d1 = 12, _h1 = 6, _min1 = 30;
  final _n2 = TextEditingController(text: 'Person 2');
  int _y2 = 1993, _m2 = 8, _d2 = 5, _h2 = 8, _min2 = 0;
  bool _showForm = true;

  @override void dispose() { _n1.dispose(); _n2.dispose(); super.dispose(); }

  Map<String, dynamic> _bd(String name, int y, int m, int d, int h, int min) => {
    'name': name, 'year': y, 'month': m, 'day': d, 'hour': h, 'minute': min,
    'latitude': 13.0827, 'longitude': 80.2707, 'timezone': 5.5, 'ayanamsa': 'lahiri',
  };

  void _fetch() {
    setState(() => _showForm = false);
    context.read<MatchBloc>().add(FetchMatch(
      _bd(_n1.text, _y1, _m1, _d1, _h1, _min1),
      _bd(_n2.text, _y2, _m2, _d2, _h2, _min2),
    ));
  }

  @override
  Widget build(BuildContext context) => NetworkGuard(
    child: Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink2,
        title: const Text('Matchmaking', style: AppTextStyles.displayXs),
        actions: [
          if (!_showForm)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.gold),
              onPressed: () => setState(() => _showForm = true),
            ),
        ],
      ),
      body: _showForm ? _buildForm() : _buildResult(),
    ),
  );

  Widget _buildForm() => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(children: [
      Text('GUNA MILAN ANALYSIS', style: AppTextStyles.sectionTag),
      const SizedBox(height: AppSpacing.lg),
      Row(children: [
        Expanded(child: _PersonForm('Boy', _n1, _y1, _m1, _d1,
            (y, m, d) => setState(() { _y1 = y; _m1 = m; _d1 = d; }))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('⟷',
              style: AppTextStyles.displaySm.copyWith(color: AppColors.gold)),
        ),
        Expanded(child: _PersonForm('Girl', _n2, _y2, _m2, _d2,
            (y, m, d) => setState(() { _y2 = y; _m2 = m; _d2 = d; }))),
      ]),
      const SizedBox(height: AppSpacing.xxl),
      ElevatedButton(onPressed: _fetch,
          child: const Text('Check Compatibility ✦')),
    ]),
  );

  Widget _buildResult() => BlocBuilder<MatchBloc, MatchState>(
    builder: (_, state) {
      if (state is MatchLoading) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.gold));
      }
      if (state is MatchError) {
        return InlineError(message: state.msg, onRetry: _fetch);
      }
      if (state is MatchLoaded) {
        final d = state.data;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(children: [
            Center(child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2.5),
                color: AppColors.goldDim,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${d.totalScore}',
                    style: AppTextStyles.displayLg.copyWith(
                        color: AppColors.gold, fontSize: 36)),
                Text('/ 36 Gunas', style: AppTextStyles.bodyXs),
              ]),
            )),
            const SizedBox(height: AppSpacing.md),
            Text('${d.percentage.toStringAsFixed(1)}%',
                style: AppTextStyles.monoMd.copyWith(color: AppColors.gold)),
            const SizedBox(height: AppSpacing.sm),
            AppChip.teal(d.verdict.split('—').first.trim()),
            const SizedBox(height: AppSpacing.lg),
            if (d.dosha.hasDosha)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.roseDim,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.rose.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('⚠ ${d.dosha.doshaType}',
                      style: AppTextStyles.labelMd.copyWith(color: AppColors.rose)),
                  if (d.dosha.remedy != null) ...[
                    const SizedBox(height: 4),
                    Text(d.dosha.remedy!,
                        style: AppTextStyles.bodySm.copyWith(height: 1.6)),
                  ],
                ]),
              ),
            Text('KUTA BREAKDOWN', style: AppTextStyles.sectionTag),
            const SizedBox(height: AppSpacing.md),
            ...d.kutaScores.map((k) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(k.name, style: AppTextStyles.labelMd),
                  Text('${k.obtainedScore}/${k.maxScore}',
                      style: AppTextStyles.monoMd.copyWith(
                          color: k.obtainedScore == 0
                              ? AppColors.rose
                              : AppColors.gold)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: k.maxScore > 0 ? k.obtainedScore / k.maxScore : 0,
                    backgroundColor: AppColors.surface3,
                    valueColor: AlwaysStoppedAnimation(
                        k.obtainedScore == 0 ? AppColors.rose : AppColors.gold),
                    minHeight: 4,
                  ),
                ),
                if (k.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Align(alignment: Alignment.centerLeft,
                      child: Text(k.description, style: AppTextStyles.bodyXs)),
                ],
              ]),
            )),
            if (d.aiAnalysis != null) ...[
              const SizedBox(height: AppSpacing.lg),
              GradientCard(
                colors: [AppColors.violetDim.withOpacity(0.2), Colors.transparent],
                borderColor: AppColors.violet.withOpacity(0.25),
                child: Text(d.aiAnalysis!,
                    style: AppTextStyles.bodySm.copyWith(height: 1.7)),
              ),
            ],
          ]),
        );
      }
      return const SizedBox.shrink();
    },
  );
}

class _PersonForm extends StatelessWidget {
  final String title;
  final TextEditingController nameCtrl;
  final int year, month, day;
  final Function(int, int, int) onChanged;
  const _PersonForm(this.title, this.nameCtrl, this.year, this.month, this.day, this.onChanged);

  @override
  Widget build(BuildContext context) => AppCard(child: Column(children: [
    Text(title, style: AppTextStyles.sectionTag),
    const SizedBox(height: 8),
    TextFormField(
      controller: nameCtrl, style: AppTextStyles.bodySm,
      decoration: const InputDecoration(labelText: 'Name', isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
    ),
    const SizedBox(height: 8),
    Row(children: [
      Expanded(child: TextFormField(
        initialValue: year.toString(), keyboardType: TextInputType.number,
        style: AppTextStyles.bodySm,
        decoration: const InputDecoration(labelText: 'YYYY', isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
        onChanged: (v) { final n = int.tryParse(v); if (n != null) onChanged(n, month, day); },
      )),
      const SizedBox(width: 4),
      Expanded(child: TextFormField(
        initialValue: month.toString(), keyboardType: TextInputType.number,
        style: AppTextStyles.bodySm,
        decoration: const InputDecoration(labelText: 'MM', isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
        onChanged: (v) { final n = int.tryParse(v); if (n != null) onChanged(year, n, day); },
      )),
      const SizedBox(width: 4),
      Expanded(child: TextFormField(
        initialValue: day.toString(), keyboardType: TextInputType.number,
        style: AppTextStyles.bodySm,
        decoration: const InputDecoration(labelText: 'DD', isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
        onChanged: (v) { final n = int.tryParse(v); if (n != null) onChanged(year, month, n); },
      )),
    ]),
  ]));
}
