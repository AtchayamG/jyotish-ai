// lib/features/settings/presentation/pages/pricing_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (ctx, state) {
      final currentTier = state is AuthAuthenticated
          ? state.user.userTier
          : UserTier.free;

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
          title: const Text('Choose Your Plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _Header(),
            const SizedBox(height: 28),
            _PlanCard(
              tier: UserTier.free,
              currentTier: currentTier,
              price: 'Free',
              period: 'forever',
              color: AppColors.textSecondary,
              emoji: '✦',
              features: const [
                '1 birth chart (yours)',
                'Daily/weekly/monthly horoscopes',
                'Matchmaking analysis',
                'Basic AI chat (10/day)',
                'Auspicious times & muhurtham',
              ],
              restrictions: const [
                'No family profiles',
                'Limited AI responses',
              ],
              onSubscribe: null,
            ),
            const SizedBox(height: 16),
            _PlanCard(
              tier: UserTier.premium,
              currentTier: currentTier,
              price: '₹199',
              period: '/month',
              color: AppColors.gold,
              emoji: '⭐',
              isPopular: true,
              features: const [
                'Everything in Free',
                '2 additional family profiles',
                'AI chat — unlimited messages',
                'Personalized daily predictions',
                'Compatibility reports',
                'Priority email support',
              ],
              onSubscribe: () => _showDemoDialog(context, 'Premium', '₹199/month'),
            ),
            const SizedBox(height: 16),
            _PlanCard(
              tier: UserTier.max,
              currentTier: currentTier,
              price: '₹499',
              period: '/month',
              color: AppColors.violet,
              emoji: '💎',
              features: const [
                'Everything in Premium',
                '5 additional family profiles',
                'Full Dasha timeline analysis',
                'Yearly transit predictions',
                'Advanced Sarpa Dosha & remedies',
                'Dedicated astro consultant chat',
                'Export charts as PDF',
              ],
              onSubscribe: () => _showDemoDialog(context, 'Max', '₹499/month'),
            ),
            const SizedBox(height: 24),
            _Disclaimer(),
          ]),
        ),
      );
    });
  }

  void _showDemoDialog(BuildContext context, String plan, String price) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Text('🚀 ', style: TextStyle(fontSize: 20)),
          Text('$plan Plan', style: const TextStyle(fontSize: 18,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Subscribe for $price', style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gold)),
          const SizedBox(height: 12),
          const Text(
            '🏗️  Payment gateway coming soon!\n\n'
            'We\'re integrating with Razorpay to accept UPI, cards, and net banking. '
            'Your subscription will be activated instantly after payment.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withAlpha(60)),
            ),
            child: const Row(children: [
              Icon(Icons.mail_outline, color: AppColors.gold, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Email us at support@jyotish.ai to get early access.',
                style: TextStyle(fontSize: 12, color: AppColors.gold),
              )),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Got It', style: TextStyle(color: Colors.black,
                fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.gold.withAlpha(80), AppColors.violet.withAlpha(60)],
          ),
        ),
        child: const Center(child: Text('✨', style: TextStyle(fontSize: 30))),
      ),
      const SizedBox(height: 14),
      const Text('Unlock the Full Cosmos',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      const Text(
        'Get deeper astrological insights for you and your family',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
      ),
    ]);
  }
}

// ── Plan Card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final UserTier tier;
  final UserTier currentTier;
  final String price, period, emoji;
  final Color color;
  final List<String> features;
  final List<String> restrictions;
  final bool isPopular;
  final VoidCallback? onSubscribe;

  const _PlanCard({
    required this.tier,
    required this.currentTier,
    required this.price,
    required this.period,
    required this.emoji,
    required this.color,
    required this.features,
    this.restrictions = const [],
    this.isPopular = false,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = tier == currentTier;
    final borderColor = isCurrent ? color : (isPopular ? color.withAlpha(100) : AppColors.borderSubtle);

    return Stack(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.ink2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
          gradient: isCurrent || isPopular
              ? LinearGradient(
                  colors: [color.withAlpha(15), AppColors.ink2],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(tier.label, style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.w700, color: color)),
            const Spacer(),
            RichText(text: TextSpan(children: [
              TextSpan(text: price,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              TextSpan(text: period,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ])),
          ]),
          const SizedBox(height: 16),
          ...features.map((f) => _FeatureRow(text: f, icon: Icons.check_circle,
              iconColor: color)),
          if (restrictions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...restrictions.map((r) => _FeatureRow(text: r, icon: Icons.cancel_outlined,
                iconColor: AppColors.textHint, textColor: AppColors.textHint)),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent ? null : onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? AppColors.surface2 : color,
                foregroundColor: isCurrent ? AppColors.textHint
                    : (tier == UserTier.free ? Colors.black : Colors.white),
                disabledBackgroundColor: AppColors.surface2,
                disabledForegroundColor: AppColors.textHint,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                isCurrent ? 'Current Plan'
                    : (tier == UserTier.free ? 'Downgrade to Free' : 'Subscribe Now'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ]),
      ),
      if (isPopular)
        Positioned(top: 0, right: 16,
          child: Transform.translate(offset: const Offset(0, -12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Most Popular',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.black)),
            ),
          ),
        ),
    ]);
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color iconColor;
  final Color textColor;

  const _FeatureRow({
    required this.text,
    required this.icon,
    required this.iconColor,
    this.textColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: textColor))),
      ]),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Subscriptions auto-renew monthly. Cancel anytime from Settings.\n'
      'Prices include GST where applicable.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 11, color: AppColors.textHint, height: 1.6),
    );
  }
}
