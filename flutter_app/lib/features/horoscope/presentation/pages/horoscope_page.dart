// lib/features/horoscope/presentation/pages/horoscope_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/horoscope_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/no_network_page.dart';
import '../../../../core/widgets/error_page.dart';

const _signs   = ['Mesha','Vrishabha','Mithuna','Karka','Simha','Kanya','Tula','Vrischika','Dhanu','Makara','Kumbha','Meena'];
const _symbols = ['♈','♉','♊','♋','♌','♍','♎','♏','♐','♑','♒','♓'];

class HoroscopePage extends StatefulWidget {
  const HoroscopePage({super.key});
  @override State<HoroscopePage> createState() => _HoroscopePageState();
}

class _HoroscopePageState extends State<HoroscopePage> {
  int _idx = 0;
  String _type = 'daily';

  @override void initState() { super.initState(); _fetch(); }

  void _fetch() =>
      context.read<HoroscopeBloc>().add(FetchHoroscope(_signs[_idx], type: _type));

  @override
  Widget build(BuildContext context) => NetworkGuard(
    child: Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink2,
        title: const Text('Horoscope', style: AppTextStyles.displayXs),
      ),
      body: Column(children: [
        // Type selector
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            for (final t in ['daily', 'weekly', 'monthly', 'yearly'])
              Expanded(child: GestureDetector(
                onTap: () { setState(() => _type = t); _fetch(); },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _type == t ? AppColors.gold : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                        color: _type == t ? AppColors.gold : AppColors.borderSubtle),
                  ),
                  child: Text(
                    t[0].toUpperCase() + t.substring(1),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSm.copyWith(
                      color: _type == t ? AppColors.ink : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              )),
          ]),
        ),
        // Sign picker
        SizedBox(height: 90, child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: _signs.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () { setState(() => _idx = i); _fetch(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60, margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _idx == i ? AppColors.goldDim : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: _idx == i ? AppColors.gold : AppColors.borderSubtle),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_symbols[i], style: TextStyle(
                    fontSize: 20,
                    color: _idx == i ? AppColors.gold : AppColors.textSecondary)),
                const SizedBox(height: 3),
                Text(_signs[i].substring(0, 3), style: AppTextStyles.bodyXs.copyWith(
                    color: _idx == i ? AppColors.gold : AppColors.textHint,
                    fontSize: 9)),
              ]),
            ),
          ),
        )),
        // Content
        Expanded(child: BlocBuilder<HoroscopeBloc, HoroscopeState>(
          builder: (_, state) {
            if (state is HoroscopeLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold));
            }
            if (state is HoroscopeError) {
              return InlineError(message: state.msg, onRetry: _fetch);
            }
            if (state is HoroscopeLoaded) {
              final d = state.data;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(children: [
                  GradientCard(
                    colors: [
                      AppColors.violetDim.withOpacity(0.25),
                      AppColors.goldDim.withOpacity(0.1),
                    ],
                    borderColor: AppColors.violet.withOpacity(0.25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_signs[_idx]} ${_symbols[_idx]}',
                                style: AppTextStyles.displayXs),
                            Text('${d.overallScore.toStringAsFixed(1)} / 10',
                                style: AppTextStyles.monoMd
                                    .copyWith(color: AppColors.gold)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(d.prediction,
                            style: AppTextStyles.bodySm.copyWith(height: 1.7)),
                        const SizedBox(height: AppSpacing.lg),
                        ScoreBar(label: 'Career', score: d.careerScore),
                        const SizedBox(height: AppSpacing.sm),
                        ScoreBar(label: 'Love', score: d.loveScore,
                            color: AppColors.rose),
                        const SizedBox(height: AppSpacing.sm),
                        ScoreBar(label: 'Health', score: d.healthScore,
                            color: AppColors.teal),
                        const SizedBox(height: AppSpacing.sm),
                        ScoreBar(label: 'Finance', score: d.financeScore,
                            color: AppColors.violet),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(children: [
                    Expanded(child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(children: [
                        Text('Lucky Number', style: AppTextStyles.bodyXs),
                        const SizedBox(height: 4),
                        Text('${d.luckyNumber}',
                            style: AppTextStyles.displaySm
                                .copyWith(color: AppColors.gold, fontSize: 28)),
                      ]),
                    )),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(children: [
                        Text('Lucky Color', style: AppTextStyles.bodyXs),
                        const SizedBox(height: 4),
                        Text(d.luckyColor,
                            style: AppTextStyles.labelMd
                                .copyWith(color: AppColors.teal)),
                      ]),
                    )),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lucky Gemstone', style: AppTextStyles.bodyXs),
                          const SizedBox(height: 4),
                          Text(d.luckyGemstone,
                              style: AppTextStyles.labelMd
                                  .copyWith(color: AppColors.violetLight)),
                        ]),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (d.doToday.isNotEmpty) ...[
                    _ListCard('DO TODAY', d.doToday, AppColors.teal),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (d.avoidToday.isNotEmpty)
                    _ListCard('AVOID TODAY', d.avoidToday, AppColors.rose),
                ]),
              );
            }
            return const SizedBox.shrink();
          },
        )),
      ]),
    ),
  );

  Widget _ListCard(String title, List<String> items, Color color) =>
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.sectionTag.copyWith(color: color)),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Container(
              width: 5, height: 5,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Expanded(child: Text(s, style: AppTextStyles.bodySm)),
          ]),
        )),
      ]));
}
