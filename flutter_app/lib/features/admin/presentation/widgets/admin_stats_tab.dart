// lib/features/admin/presentation/widgets/admin_stats_tab.dart
import "package:flutter/material.dart";
import "../../../../core/theme/app_theme.dart";
import "admin_api.dart";

class AdminStatsTab extends StatefulWidget {
  const AdminStatsTab({super.key});
  @override
  State<AdminStatsTab> createState() => _AdminStatsTabState();
}

class _AdminStatsTabState extends State<AdminStatsTab> {
  Map<String, dynamic>? _stats;
  List<dynamic> _recent = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await AdminApi.getStats();
      final users = await AdminApi.getUsers();
      setState(() {
        _stats = stats;
        _recent = (users).reversed.take(5).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
          child: CircularProgressIndicator(color: AppColors.gold));
    if (_error != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AppColors.rose, size: 36),
        const SizedBox(height: 12),
        Text(_error!,
            style:
                AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: const Text("Retry")),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.gold,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("OVERVIEW", style: AppTextStyles.sectionTag),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _statCard(
                  "Total Users", "${_stats!["total_users"]}", AppColors.gold),
              _statCard(
                  "Premium", "${_stats!["premium_users"]}", AppColors.violet),
              _statCard("Admins", "${_stats!["admin_users"]}", AppColors.teal),
              _statCard("Active", "${_stats!["active_users"]}", AppColors.teal),
            ],
          ),
          const SizedBox(height: 20),
          Text("RECENT REGISTRATIONS", style: AppTextStyles.sectionTag),
          const SizedBox(height: 12),
          ..._recent.map((u) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(children: [
                  CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.goldDim,
                      child: Text((u["full_name"] ?? "?")[0].toUpperCase(),
                          style: AppTextStyles.labelMd
                              .copyWith(color: AppColors.gold))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(u["full_name"] ?? "—",
                            style: AppTextStyles.labelMd),
                        Text(u["email"] ?? "", style: AppTextStyles.bodyXs),
                      ])),
                  _accessBadge(u),
                ]),
              )),
        ]),
      ),
    );
  }

  Widget _statCard(String label, String val, Color color) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.bodyXs),
          const Spacer(),
          Text(val,
              style:
                  AppTextStyles.displaySm.copyWith(color: color, fontSize: 28)),
        ]),
      );

  Widget _accessBadge(Map u) {
    if (u["is_admin"] == true) return _badge("Admin", AppColors.teal);
    if (u["is_premium"] == true) return _badge("Premium", AppColors.violet);
    return _badge("Free", AppColors.textHint);
  }

  Widget _badge(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.3)),
        ),
        child: Text(t,
            style: AppTextStyles.bodyXs
                .copyWith(color: c, fontWeight: FontWeight.w600)),
      );
}
