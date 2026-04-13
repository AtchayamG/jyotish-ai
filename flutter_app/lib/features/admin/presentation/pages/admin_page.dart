// lib/features/admin/presentation/pages/admin_page.dart
// Visible ONLY to is_admin=true users — guarded in router and shell

import "package:flutter/material.dart";
import "../../../../core/theme/app_theme.dart";
import "../widgets/admin_users_tab.dart";
import "../widgets/admin_notifications_tab.dart";
import "../widgets/admin_stats_tab.dart";

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.ink,
        appBar: AppBar(
          backgroundColor: AppColors.ink2,
          title: Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.goldDim,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.admin_panel_settings,
                  size: 16, color: AppColors.gold),
            ),
            const SizedBox(width: 10),
            const Text("Admin Console", style: AppTextStyles.displayXs),
          ]),
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textHint,
            tabs: const [
              Tab(text: "Dashboard"),
              Tab(text: "Users"),
              Tab(text: "Notifications"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: const [
            AdminStatsTab(),
            AdminUsersTab(),
            AdminNotificationsTab(),
          ],
        ),
      );
}
