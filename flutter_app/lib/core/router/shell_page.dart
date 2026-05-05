// lib/core/router/shell_page.dart
import "package:flutter/foundation.dart" show kIsWeb;
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../theme/app_theme.dart";
import "app_router.dart";

class ShellPage extends StatelessWidget {
  final Widget child;
  final String location;
  const ShellPage({super.key, required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    final tabs = <({String route, IconData icon, IconData activeIcon, String label})>[
      (route: AppRoutes.home,        icon: Icons.home_outlined,          activeIcon: Icons.home,          label: "Home"),
      (route: AppRoutes.kundli,      icon: Icons.blur_circular_outlined, activeIcon: Icons.blur_circular, label: "Kundli"),
      (route: AppRoutes.horoscope,   icon: Icons.auto_awesome_outlined,  activeIcon: Icons.auto_awesome,  label: "Horoscope"),
      (route: AppRoutes.matchmaking, icon: Icons.favorite_border,        activeIcon: Icons.favorite,      label: "Match"),
      (route: AppRoutes.aiChat,      icon: Icons.smart_toy_outlined,     activeIcon: Icons.smart_toy,     label: "AI"),
    ];

    int idx = 0;
    for (var i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].route)) { idx = i; break; }
    }

    // ── Web: proper sidebar + content layout ────────────────────────────────
    if (kIsWeb) {
      return _WebShell(tabs: tabs, currentIdx: idx, child: child);
    }

    // ── Mobile: bottom navigation bar ───────────────────────────────────────
    return Scaffold(
      backgroundColor: AppColors.ink,
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

// ── Web shell ──────────────────────────────────────────────────────────────────

class _WebShell extends StatelessWidget {
  final List<({String route, IconData icon, IconData activeIcon, String label})> tabs;
  final int currentIdx;
  final Widget child;

  const _WebShell({
    required this.tabs,
    required this.currentIdx,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkDeep,
      body: Row(
        children: [
          // Left sidebar navigation
          _WebSidebar(tabs: tabs, currentIdx: currentIdx),
          // Main content — centered with max width for readability
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Web sidebar ────────────────────────────────────────────────────────────────

class _WebSidebar extends StatelessWidget {
  final List<({String route, IconData icon, IconData activeIcon, String label})> tabs;
  final int currentIdx;

  const _WebSidebar({required this.tabs, required this.currentIdx});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.ink2,
        border: Border(right: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Brand / logo ─────────────────────────────────────────────────
          const SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(22, 28, 22, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('✦',
                    style: TextStyle(fontSize: 22, color: AppColors.gold)),
                  SizedBox(width: 10),
                  Text('JYOTISH AI',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary, letterSpacing: 1.6)),
                ]),
                SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(left: 32),
                  child: Text('Vedic Astrology',
                    style: TextStyle(fontSize: 10, color: AppColors.textHint,
                      letterSpacing: 0.5)),
                ),
              ]),
            ),
          ),

          // Thin divider
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 10),

          // ── Navigation items ─────────────────────────────────────────────
          ...List.generate(tabs.length, (i) {
            final t = tabs[i];
            final active = currentIdx == i;
            return _NavItem(
              icon: active ? t.activeIcon : t.icon,
              label: t.label,
              active: active,
              onTap: () => context.go(t.route),
            );
          }),

          const Spacer(),

          // ── Footer ───────────────────────────────────────────────────────
          const Divider(color: AppColors.borderSubtle, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Row(children: [
              Container(
                width: 7, height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.teal, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text('Live · IST',
                style: TextStyle(fontSize: 11, color: AppColors.textHint,
                  letterSpacing: 0.3)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar nav item ───────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: active ? AppColors.gold.withAlpha(28) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border.all(color: AppColors.gold.withAlpha(55), width: 0.8)
                : null,
          ),
          child: Row(children: [
            Icon(icon,
              size: 18,
              color: active ? AppColors.gold : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppColors.gold : AppColors.textSecondary,
                )),
            ),
            if (active)
              Container(
                width: 5, height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.gold, shape: BoxShape.circle),
              ),
          ]),
        ),
      ),
    );
  }
}
