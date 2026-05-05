// lib/features/settings/presentation/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (ctx, state) {
      final user = state is AuthAuthenticated ? state.user : null;
      return Scaffold(
        backgroundColor: AppColors.ink,
        body: SafeArea(
          child: Column(children: [
            _Header(user: user),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(children: [
                  _ProfileSection(user: user),
                  const SizedBox(height: 16),
                  _AccountSection(user: user),
                  const SizedBox(height: 16),
                  _PreferencesSection(),
                  const SizedBox(height: 16),
                  _AboutSection(),
                  const SizedBox(height: 16),
                  _SignOutButton(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final UserEntity? user;
  const _Header({this.user});

  @override
  Widget build(BuildContext context) {
    final tier = user?.userTier ?? UserTier.free;
    final tierColor = _tierColor(tier);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.ink2,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [tierColor.withAlpha(200), tierColor.withAlpha(100)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              user?.fullName.isNotEmpty == true
                  ? user!.fullName[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user?.fullName ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(user?.email ?? '', style: const TextStyle(fontSize: 12,
              color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tierColor.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tierColor.withAlpha(120), width: 0.8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_tierEmoji(tier), style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              Text('${tier.label} Plan',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: tierColor)),
            ]),
          ),
        ])),
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
          onPressed: () => context.pop(),
        ),
      ]),
    );
  }

  Color _tierColor(UserTier t) {
    switch (t) {
      case UserTier.free:    return AppColors.textHint.withAlpha(200);
      case UserTier.premium: return AppColors.gold;
      case UserTier.max:     return AppColors.violet;
      case UserTier.admin:   return AppColors.teal;
    }
  }

  String _tierEmoji(UserTier t) {
    switch (t) {
      case UserTier.free:    return '✦';
      case UserTier.premium: return '⭐';
      case UserTier.max:     return '💎';
      case UserTier.admin:   return '🌌';
    }
  }
}

// ── Profile / Profiles Section ────────────────────────────────────────────────

class _ProfileSection extends StatelessWidget {
  final UserEntity? user;
  const _ProfileSection({this.user});

  @override
  Widget build(BuildContext context) {
    final tier = user?.userTier ?? UserTier.free;
    final maxProfiles = tier.maxProfiles;

    return _SectionCard(
      title: 'Profiles',
      icon: Icons.people_alt_outlined,
      children: [
        _SettingsTile(
          icon: Icons.person_outlined,
          label: 'My Profile',
          subtitle: user?.placeOfBirth ?? 'Birth details on file',
          onTap: () {},
        ),
        const Divider(color: AppColors.borderSubtle, height: 1),
        _SettingsTile(
          icon: Icons.person_add_outlined,
          label: 'Add Profile',
          subtitle: maxProfiles == 0
              ? 'Upgrade to add family profiles'
              : 'Add up to $maxProfiles family profiles',
          trailing: maxProfiles == 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Upgrade', style: TextStyle(fontSize: 10,
                      color: AppColors.gold, fontWeight: FontWeight.w600)),
                )
              : null,
          onTap: () {
            if (maxProfiles == 0) {
              context.push(AppRoutes.pricing);
            } else {
              context.push(AppRoutes.addProfile);
            }
          },
        ),
        const Divider(color: AppColors.borderSubtle, height: 1),
        _SettingsTile(
          icon: Icons.switch_account_outlined,
          label: 'Switch Profile',
          subtitle: 'View charts for your family members',
          onTap: () => context.push(AppRoutes.switchProfile),
        ),
      ],
    );
  }
}

// ── Account Section ───────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  final UserEntity? user;
  const _AccountSection({this.user});

  @override
  Widget build(BuildContext context) {
    final tier = user?.userTier ?? UserTier.free;

    return _SectionCard(
      title: 'Account',
      icon: Icons.manage_accounts_outlined,
      children: [
        if (tier == UserTier.free) ...[
          _UpgradeBanner(onTap: () => context.push(AppRoutes.pricing)),
          const Divider(color: AppColors.borderSubtle, height: 1),
        ],
        _SettingsTile(
          icon: Icons.star_outline,
          label: 'Subscription Plan',
          subtitle: '${tier.label} — ${_planDetail(tier)}',
          onTap: () => context.push(AppRoutes.pricing),
        ),
        const Divider(color: AppColors.borderSubtle, height: 1),
        _SettingsTile(
          icon: Icons.notifications_none_outlined,
          label: 'Notifications',
          subtitle: 'Daily cosmic reminders',
          trailing: Switch(
            value: true,
            onChanged: (_) {},
            activeColor: AppColors.gold,
          ),
          onTap: null,
        ),
        const Divider(color: AppColors.borderSubtle, height: 1),
        _SettingsTile(
          icon: Icons.language_outlined,
          label: 'Language',
          subtitle: 'English',
          onTap: () {},
        ),
      ],
    );
  }

  String _planDetail(UserTier t) {
    switch (t) {
      case UserTier.free:    return 'Basic features';
      case UserTier.premium: return '₹199/month · 2 profiles';
      case UserTier.max:     return '₹499/month · 5 profiles';
      case UserTier.admin:   return 'Unlimited access';
    }
  }
}

// ── Upgrade Banner ────────────────────────────────────────────────────────────

class _UpgradeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _UpgradeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.gold.withAlpha(30), AppColors.violet.withAlpha(20)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withAlpha(80)),
        ),
        child: Row(children: [
          const Text('⭐', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Upgrade to Premium', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.gold)),
            const SizedBox(height: 2),
            Text('Add family profiles · AI-powered insights · ₹199/month',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.gold, size: 20),
        ]),
      ),
    );
  }
}

// ── Preferences Section ───────────────────────────────────────────────────────

class _PreferencesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Astrology Preferences',
      icon: Icons.tune_outlined,
      children: [
        _SettingsTile(
          icon: Icons.calculate_outlined,
          label: 'Ayanamsa System',
          subtitle: 'Lahiri (Default)',
          onTap: () {},
        ),
        const Divider(color: AppColors.borderSubtle, height: 1),
        _SettingsTile(
          icon: Icons.calendar_today_outlined,
          label: 'Calendar System',
          subtitle: 'Gregorian + Panchang',
          onTap: () {},
        ),
        const Divider(color: AppColors.borderSubtle, height: 1),
        _SettingsTile(
          icon: Icons.access_time_outlined,
          label: 'Daily Reminders',
          subtitle: 'Brahma Muhurta, Rahu Kaal alerts',
          trailing: Switch(
            value: false,
            onChanged: (_) {},
            activeColor: AppColors.gold,
          ),
          onTap: null,
        ),
      ],
    );
  }
}

// ── About Section ─────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'About',
      icon: Icons.info_outline,
      children: [
        _SettingsTile(
          icon: Icons.auto_awesome_outlined,
          label: 'Jyotish AI',
          subtitle: 'Version 1.0.0 · Vedic Astrology Companion',
          onTap: () {},
        ),
        const Divider(color: AppColors.borderSubtle, height: 1),
        _SettingsTile(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Policy',
          onTap: () {},
        ),
        const Divider(color: AppColors.borderSubtle, height: 1),
        _SettingsTile(
          icon: Icons.description_outlined,
          label: 'Terms of Service',
          onTap: () {},
        ),
        const Divider(color: AppColors.borderSubtle, height: 1),
        _SettingsTile(
          icon: Icons.star_rate_outlined,
          label: 'Rate the App',
          onTap: () {},
        ),
        const Divider(color: AppColors.borderSubtle, height: 1),
        _SettingsTile(
          icon: Icons.feedback_outlined,
          label: 'Send Feedback',
          onTap: () {},
        ),
      ],
    );
  }
}

// ── Sign Out ──────────────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Sign Out', style: TextStyle(color: AppColors.textPrimary)),
            content: const Text('Are you sure you want to sign out?',
                style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
              TextButton(onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Sign Out', style: TextStyle(color: AppColors.error))),
            ],
          ),
        );
        if (ok == true && context.mounted) {
          context.read<AuthBloc>().add(const LogoutRequested());
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withAlpha(60)),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.logout, color: AppColors.error, size: 18),
          SizedBox(width: 8),
          Text('Sign Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
              color: AppColors.error)),
        ]),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Row(children: [
          Icon(icon, size: 14, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(title.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: AppColors.gold, letterSpacing: 1.2)),
        ]),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppColors.ink2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(children: children),
      ),
    ]);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: const TextStyle(fontSize: 12,
                  color: AppColors.textSecondary)),
            ],
          ])),
          trailing ?? (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18)
              : const SizedBox.shrink()),
        ]),
      ),
    );
  }
}
