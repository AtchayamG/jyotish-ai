// lib/features/settings/presentation/pages/switch_profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class SwitchProfilePage extends StatelessWidget {
  const SwitchProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (ctx, state) {
      final user = state is AuthAuthenticated ? state.user : null;

      return Scaffold(
        backgroundColor: AppColors.ink,
        appBar: AppBar(
          backgroundColor: AppColors.ink2,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18,
                color: AppColors.textSecondary),
            onPressed: () => context.pop(),
          ),
          title: const Text('Switch Profile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          centerTitle: true,
          actions: [
            if ((user?.userTier.maxProfiles ?? 0) > 0)
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.gold),
                onPressed: () => context.push(AppRoutes.addProfile),
              ),
          ],
        ),
        body: Column(children: [
          // Current (self) profile
          _ProfileTile(
            name: user?.fullName ?? 'Me',
            subtitle: user?.placeOfBirth ?? 'Birth details on file',
            emoji: '🌟',
            isCurrent: true,
            onTap: () => context.pop(),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              const Expanded(child: Divider(color: AppColors.borderSubtle)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Family Profiles',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint,
                        letterSpacing: 0.8)),
              ),
              const Expanded(child: Divider(color: AppColors.borderSubtle)),
            ]),
          ),

          // If free tier → upgrade prompt
          if ((user?.userTier.maxProfiles ?? 0) == 0)
            Expanded(child: _UpgradePrompt())
          else
            // TODO: Load actual profiles from API
            Expanded(child: _EmptyProfiles(
              onAdd: () => context.push(AppRoutes.addProfile),
            )),
        ]),
      );
    });
  }
}

class _ProfileTile extends StatelessWidget {
  final String name, subtitle, emoji;
  final bool isCurrent;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.ink2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? AppColors.gold.withAlpha(120) : AppColors.borderSubtle,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent
                ? AppColors.gold.withAlpha(30)
                : AppColors.surface,
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
        ),
        title: Row(children: [
          Text(name, style: const TextStyle(fontSize: 14,
              fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          if (isCurrent) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Active', style: TextStyle(fontSize: 9,
                  color: AppColors.gold, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12,
            color: AppColors.textSecondary)),
        trailing: isCurrent
            ? const Icon(Icons.check_circle, color: AppColors.gold, size: 18)
            : const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
      ),
    );
  }
}

class _EmptyProfiles extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyProfiles({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const Text('No family profiles yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text(
          'Add your family members to view their birth charts,\n'
          'horoscopes, and compatibility reports.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('Add First Profile'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    ));
  }
}

class _UpgradePrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🔒', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const Text('Family Profiles — Premium Feature',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text(
          'Upgrade to Premium to add your spouse, children,\n'
          'or parents and view their Vedic birth charts.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => context.push(AppRoutes.pricing),
          icon: const Text('⭐', style: TextStyle(fontSize: 14)),
          label: const Text('View Plans'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    ));
  }
}
