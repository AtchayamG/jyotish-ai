// lib/core/router/shell_page.dart
import "package:flutter/foundation.dart" show kIsWeb;
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../theme/app_theme.dart";
import "app_router.dart";

/// Breakpoint below which we always use the mobile bottom-nav layout,
/// even if the platform is web (e.g. mobile browser).
const double _kSidebarBreakpoint = 720.0;

class ShellPage extends StatelessWidget {
  final Widget child;
  final String location;
  const ShellPage({super.key, required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    final tabs = <_Tab>[
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

    // Use LayoutBuilder so layout responds to actual available width —
    // this correctly handles mobile browsers, desktop browsers, and native apps.
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = kIsWeb && constraints.maxWidth >= _kSidebarBreakpoint;
        return isWide
            ? _DesktopShell(tabs: tabs, currentIdx: idx, child: child)
            : _MobileShell(tabs: tabs, currentIdx: idx, child: child);
      },
    );
  }
}

// ── Type alias ─────────────────────────────────────────────────────────────────

typedef _Tab = ({
  String route,
  IconData icon,
  IconData activeIcon,
  String label,
});

// ── Mobile shell (native app + mobile browsers) ────────────────────────────────

class _MobileShell extends StatelessWidget {
  final List<_Tab> tabs;
  final int currentIdx;
  final Widget child;
  const _MobileShell({required this.tabs, required this.currentIdx, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.ink2,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(tabs.length, (i) {
                final t = tabs[i];
                final active = currentIdx == i;
                return Expanded(
                  child: InkWell(
                    onTap: () => context.go(t.route),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          active ? t.activeIcon : t.icon,
                          color: active ? AppColors.gold : AppColors.textHint,
                          size: 20,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 9,
                            color: active ? AppColors.gold : AppColors.textHint,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Desktop shell (wide browser windows) ──────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  final List<_Tab> tabs;
  final int currentIdx;
  final Widget child;
  const _DesktopShell({required this.tabs, required this.currentIdx, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkDeep,
      body: Row(
        children: [
          _DesktopSidebar(tabs: tabs, currentIdx: currentIdx),
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

// ── Desktop sidebar ────────────────────────────────────────────────────────────

class _DesktopSidebar extends StatelessWidget {
  final List<_Tab> tabs;
  final int currentIdx;
  const _DesktopSidebar({required this.tabs, required this.currentIdx});

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
          // Brand
          const SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(22, 28, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('✦',
                        style: TextStyle(fontSize: 22, color: AppColors.gold)),
                    SizedBox(width: 10),
                    Text('JYOTISH AI',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.6,
                        )),
                  ]),
                  SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.only(left: 32),
                    child: Text('Vedic Astrology',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                          letterSpacing: 0.5,
                        )),
                  ),
                ],
              ),
            ),
          ),

          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 10),

          // Nav items
          ...List.generate(tabs.length, (i) {
            final t = tabs[i];
            final active = currentIdx == i;
            return _SidebarNavItem(
              icon: active ? t.activeIcon : t.icon,
              label: t.label,
              active: active,
              onTap: () => context.go(t.route),
            );
          }),

          const Spacer(),

          const Divider(color: AppColors.borderSubtle, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Row(children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: AppColors.teal, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text('Live · IST',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    letterSpacing: 0.3,
                  )),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarNavItem({
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
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppColors.gold : AppColors.textSecondary,
                ),
              ),
            ),
            if (active)
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                    color: AppColors.gold, shape: BoxShape.circle),
              ),
          ]),
        ),
      ),
    );
  }
}
