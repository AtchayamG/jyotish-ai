// lib/core/utils/shared_widgets.dart
// Production-quality reusable widgets for the entire app.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

// ── JyotishCard ───────────────────────────────────────────────────────────────

class JyotishCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;

  const JyotishCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        padding: padding ?? AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: borderColor ?? Colors.white.withOpacity(0.07),
            width: 0.5,
          ),
          boxShadow: shadows ?? AppShadows.card,
        ),
        child: child,
      ),
    );
  }
}

// ── GlowCard — gold/violet bordered card ─────────────────────────────────────

class GlowCard extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final EdgeInsets? padding;

  const GlowCard({
    super.key,
    required this.child,
    this.glowColor = AppColors.violet,
    this.padding,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? AppSpacing.cardPadding,
    decoration: BoxDecoration(
      color: glowColor.withOpacity(0.08),
      borderRadius: AppRadius.card,
      border: Border.all(color: glowColor.withOpacity(0.25), width: 0.5),
      boxShadow: AppShadows.cardGlow(glowColor),
    ),
    child: child,
  );
}

// ── JyotishChip ───────────────────────────────────────────────────────────────

class JyotishChip extends StatelessWidget {
  final String label;
  final Color color;
  final String? prefix;
  final VoidCallback? onTap;

  const JyotishChip({
    super.key,
    required this.label,
    this.color = AppColors.gold,
    this.prefix,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppRadius.chip,
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (prefix != null) ...[
          Text(prefix!, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
        ],
        Text(label, style: AppTextStyles.labelSmall(color)),
      ]),
    ),
  );
}

// ── ScoreBar ──────────────────────────────────────────────────────────────────

class ScoreBar extends StatelessWidget {
  final String label;
  final double score; // 0–10
  final String emoji;
  final Color color;

  const ScoreBar({
    super.key,
    required this.label,
    required this.score,
    required this.emoji,
    this.color = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.label(AppColors.textSecondary)),
        const Spacer(),
        Text('${score.toStringAsFixed(1)}/10',
          style: AppTextStyles.mono(color, size: 11)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: AppRadius.chip,
        child: LinearProgressIndicator(
          value: score / 10,
          minHeight: 4,
          backgroundColor: Colors.white.withOpacity(0.06),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ],
  );
}

// ── StatMiniCard ──────────────────────────────────────────────────────────────

class StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String? subtitle;

  const StatMiniCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = AppColors.gold,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) => JyotishCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.overline(AppColors.textSecondary)),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.display3(valueColor)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: AppTextStyles.caption(AppColors.textSecondary)),
        ],
      ],
    ),
  );
}

// ── PlanetBadge ───────────────────────────────────────────────────────────────

class PlanetStatusBadge extends StatelessWidget {
  final String status;
  const PlanetStatusBadge(this.status, {super.key});

  Color get _color {
    switch (status) {
      case 'Exalted': return AppColors.gold;
      case 'Debilitated': return AppColors.rose;
      case 'Own Sign': return AppColors.teal;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => JyotishChip(label: status, color: _color);
}

// ── LoadingShimmer ────────────────────────────────────────────────────────────

class JyotishShimmer extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? radius;

  const JyotishShimmer({
    super.key,
    required this.height,
    this.width,
    this.radius,
  });

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: AppColors.surface2,
    highlightColor: AppColors.surface3,
    child: Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: radius ?? AppRadius.card,
      ),
    ),
  );
}

// ── ErrorState ────────────────────────────────────────────────────────────────

class JyotishErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const JyotishErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('✧', style: TextStyle(fontSize: 40, color: AppColors.rose.withOpacity(0.5))),
        const SizedBox(height: 16),
        Text('Something went wrong', style: AppTextStyles.h3(AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(message, style: AppTextStyles.body2(AppColors.textSecondary), textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ]),
    ),
  );
}

// ── EmptyState ────────────────────────────────────────────────────────────────

class JyotishEmptyState extends StatelessWidget {
  final String message;
  final String? action;
  final VoidCallback? onAction;

  const JyotishEmptyState({super.key, required this.message, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('✦', style: TextStyle(fontSize: 40, color: AppColors.gold.withOpacity(0.4))),
        const SizedBox(height: 16),
        Text(message, style: AppTextStyles.body1(AppColors.textSecondary), textAlign: TextAlign.center),
        if (action != null) ...[
          const SizedBox(height: 20),
          ElevatedButton(onPressed: onAction, child: Text(action!)),
        ],
      ]),
    ),
  );
}

// ── SectionHeader ─────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String tag;
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.tag,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(tag.toUpperCase(), style: AppTextStyles.overline(AppColors.gold)),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(child: Text(title, style: AppTextStyles.h2(AppColors.textPrimary))),
        if (action != null)
          TextButton(onPressed: onAction,
            child: Text(action!, style: AppTextStyles.label(AppColors.gold))),
      ]),
    ],
  );
}

// Keep AppConstants accessible from here
import '../../core/utils/app_constants.dart';
