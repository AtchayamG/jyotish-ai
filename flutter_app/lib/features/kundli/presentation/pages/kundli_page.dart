// lib/features/kundli/presentation/pages/kundli_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/kundli_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/no_network_page.dart';
import '../../../../core/widgets/error_page.dart';

class KundliPage extends StatefulWidget {
  const KundliPage({super.key});
  @override State<KundliPage> createState() => _KundliPageState();
}

class _KundliPageState extends State<KundliPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _name = TextEditingController(text: 'My Chart');
  int _year = 1990, _month = 4, _day = 12, _hour = 6, _minute = 30;
  final double _lat = 13.0827, _lng = 80.2707;
  bool _showForm = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _name.dispose();
    super.dispose();
  }

  void _fetch() {
    setState(() => _showForm = false);
    context.read<KundliBloc>().add(FetchKundli(
      year: _year, month: _month, day: _day,
      hour: _hour, minute: _minute,
      lat: _lat, lng: _lng, name: _name.text,
    ));
  }

  @override
  Widget build(BuildContext context) => NetworkGuard(
    child: Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink2,
        title: const Text('Janma Kundli', style: AppTextStyles.displayXs),
        actions: [
          if (!_showForm)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.gold),
              onPressed: () => setState(() => _showForm = true),
            ),
        ],
      ),
      body: _showForm ? _buildForm() : _buildChart(),
    ),
  );

  Widget _buildForm() => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BIRTH DETAILS', style: AppTextStyles.sectionTag),
      const SizedBox(height: AppSpacing.lg),
      TextFormField(
        controller: _name,
        style: AppTextStyles.bodyMd,
        decoration: const InputDecoration(labelText: 'Full Name'),
      ),
      const SizedBox(height: AppSpacing.lg),
      Row(children: [
        Expanded(child: _numField('Year', _year,
            (v) => setState(() => _year = v), 1900, 2100)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _numField('Month', _month,
            (v) => setState(() => _month = v), 1, 12)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _numField('Day', _day,
            (v) => setState(() => _day = v), 1, 31)),
      ]),
      const SizedBox(height: AppSpacing.lg),
      Row(children: [
        Expanded(child: _numField('Hour', _hour,
            (v) => setState(() => _hour = v), 0, 23)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _numField('Minute', _minute,
            (v) => setState(() => _minute = v), 0, 59)),
      ]),
      const SizedBox(height: AppSpacing.lg),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LOCATION', style: AppTextStyles.sectionTag),
        const SizedBox(height: AppSpacing.sm),
        Text('Chennai, Tamil Nadu', style: AppTextStyles.bodySm),
        Text('Lat: ${_lat.toStringAsFixed(4)}  Lng: ${_lng.toStringAsFixed(4)}',
            style: AppTextStyles.monoSm),
      ])),
      const SizedBox(height: AppSpacing.xxl),
      ElevatedButton(
        onPressed: _fetch,
        child: const Text('Generate Kundli ✦'),
      ),
    ]),
  );

  Widget _numField(String label, int val, Function(int) onChanged, int min, int max) =>
      TextFormField(
        initialValue: val.toString(),
        keyboardType: TextInputType.number,
        style: AppTextStyles.bodyMd,
        decoration: InputDecoration(labelText: label),
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null && n >= min && n <= max) onChanged(n);
        },
      );

  Widget _buildChart() => BlocBuilder<KundliBloc, KundliState>(
    builder: (context, state) {
      if (state is KundliLoading) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        );
      }
      if (state is KundliError) {
        return InlineError(message: state.msg, onRetry: _fetch);
      }
      if (state is KundliLoaded) {
        final k = state.kundli;
        return Column(children: [
          Container(
            color: AppColors.ink2,
            child: TabBar(
              controller: _tabs,
              indicatorColor: AppColors.gold,
              labelColor: AppColors.gold,
              unselectedLabelColor: AppColors.textHint,
              tabs: const [
                Tab(text: 'Planets'),
                Tab(text: 'Summary'),
                Tab(text: 'Dashas'),
              ],
            ),
          ),
          Expanded(child: TabBarView(controller: _tabs, children: [
            // Planets tab
            ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: k.planets.length,
              itemBuilder: (_, i) {
                final p = k.planets[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(children: [
                    Text(p.symbol,
                        style: TextStyle(
                            fontSize: 18,
                            color: AppColors.planetColor(p.name))),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: AppTextStyles.labelMd),
                        Text('${p.rasi} · H${p.house} · ${p.nakshatra}',
                            style: AppTextStyles.bodyXs),
                      ],
                    )),
                    StatusBadge(p.status),
                    const SizedBox(width: AppSpacing.sm),
                    Text(p.degree,
                        style: AppTextStyles.monoSm
                            .copyWith(color: AppColors.violetLight)),
                  ]),
                );
              },
            ),
            // Summary tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(children: [
                if (k.aiInsight != null)
                  GradientCard(
                    colors: [
                      AppColors.violetDim.withOpacity(0.2),
                      Colors.transparent,
                    ],
                    borderColor: AppColors.violet.withOpacity(0.25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Text('✦',
                              style: TextStyle(
                                  color: AppColors.violetLight, fontSize: 14)),
                          const SizedBox(width: 8),
                          Text('AI Insight',
                              style: AppTextStyles.labelMd
                                  .copyWith(color: AppColors.violetLight)),
                        ]),
                        const SizedBox(height: AppSpacing.sm),
                        Text(k.aiInsight!,
                            style: AppTextStyles.bodySm
                                .copyWith(height: 1.7)),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(child: Column(children: [
                  _row('Lagna', k.lagna),
                  _row('Rasi', k.rasi),
                  _row('Nakshatra', k.nakshatra),
                  _row('Dasha', k.currentDasha),
                ])),
              ]),
            ),
            // Dashas tab
            ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: k.planets.length,
              itemBuilder: (_, i) => ListTile(
                leading: Text(k.planets[i].symbol,
                    style: const TextStyle(fontSize: 20)),
                title: Text(k.planets[i].name,
                    style: AppTextStyles.labelMd),
                subtitle: Text('House ${k.planets[i].house}',
                    style: AppTextStyles.bodyXs),
              ),
            ),
          ])),
        ]);
      }
      return const SizedBox.shrink();
    },
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.bodyXs),
      Text(value,
          style: AppTextStyles.labelMd.copyWith(color: AppColors.gold)),
    ]),
  );
}
