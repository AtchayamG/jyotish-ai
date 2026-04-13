// lib/core/router/shell_page.dart
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "../../features/auth/presentation/bloc/auth_bloc.dart";
import "../theme/app_theme.dart";
import "app_router.dart";

class ShellPage extends StatelessWidget {
  final Widget child;
  final String location;
  const ShellPage({super.key, required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

    final tabs = <({String route, IconData icon, IconData activeIcon, String label})>[
      (route: AppRoutes.home,        icon: Icons.home_outlined,          activeIcon: Icons.home,          label: "Home"),
      (route: AppRoutes.kundli,      icon: Icons.blur_circular_outlined, activeIcon: Icons.blur_circular, label: "Kundli"),
      (route: AppRoutes.horoscope,   icon: Icons.auto_awesome_outlined,  activeIcon: Icons.auto_awesome,  label: "Horoscope"),
      (route: AppRoutes.matchmaking, icon: Icons.favorite_border,        activeIcon: Icons.favorite,      label: "Match"),
      (route: AppRoutes.aiChat,      icon: Icons.smart_toy_outlined,     activeIcon: Icons.smart_toy,     label: "AI"),
      if (isAdmin)
        (route: AppRoutes.admin, icon: Icons.admin_panel_settings_outlined,
         activeIcon: Icons.admin_panel_settings, label: "Admin"),
    ];

    int idx = 0;
    for (var i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].route)) { idx = i; break; }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.ink2,
          border: Border(top: BorderSide(color: AppColors.borderSubtle))),
        child: SafeArea(child: SizedBox(height: 60, child: Row(
          children: List.generate(tabs.length, (i) {
            final t = tabs[i]; final active = idx == i;
            return Expanded(child: InkWell(
              onTap: () => context.go(t.route),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(active ? t.activeIcon : t.icon,
                  color: active ? AppColors.gold : AppColors.textHint, size: 20),
                const SizedBox(height: 2),
                Text(t.label, style: TextStyle(fontSize: 9,
                  color: active ? AppColors.gold : AppColors.textHint,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
              ]),
            ));
          }),
        ))),
      ),
    );
  }
}
