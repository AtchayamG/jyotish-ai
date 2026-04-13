// lib/core/widgets/app_widgets.dart
// Shared reusable UI components used across features.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Gold Chip ─────────────────────────────────────────────────────────────────
class AppChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final double fontSize;

  const AppChip(this.label, {
    super.key,
    this.color = AppColors.gold,
    this.bgColor = AppColors.goldDim,
    this.borderColor = const Color(0x40D4A853),
    this.fontSize = 10,
  });

  const AppChip.violet(this.label, {super.key, this.fontSize = 10})
    : color = AppColors.violetLight, bgColor = AppColors.violetDim,
      borderColor = const Color(0x408B6FE8);

  const AppChip.teal(this.label, {super.key, this.fontSize = 10})
    : color = AppColors.teal, bgColor = AppColors.tealDim,
      borderColor = const Color(0x402EC4B6);

  const AppChip.rose(this.label, {super.key, this.fontSize = 10})
    : color = AppColors.rose, bgColor = AppColors.roseDim,
      borderColor = const Color(0x40E85D8B);

  const AppChip.muted(this.label, {super.key, this.fontSize = 10})
    : color = AppColors.textSecondary, bgColor = AppColors.surface2,
      borderColor = AppColors.borderDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: borderColor),
      ),
      child: Text(label, style: TextStyle(fontSize: fontSize, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

// ── Section Tag ───────────────────────────────────────────────────────────────
class SectionTag extends StatelessWidget {
  final String text;
  const SectionTag(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: AppTextStyles.sectionTag,
  );
}

// ── App Card ──────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final Color? borderColor;
  final double? borderRadius;
  const AppCard({super.key, required this.child, this.padding, this.color, this.borderColor, this.borderRadius});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.lg),
      border: Border.all(color: borderColor ?? AppColors.borderSubtle),
    ),
    child: child,
  );
}

// ── Gradient Card ─────────────────────────────────────────────────────────────
class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final Color borderColor;
  final EdgeInsets? padding;
  const GradientCard({super.key, required this.child, required this.colors, required this.borderColor, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: borderColor),
    ),
    child: child,
  );
}

// ── Loading Shimmer ───────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double height, width;
  final double? borderRadius;
  const ShimmerBox({super.key, required this.height, this.width = double.infinity, this.borderRadius});

  @override
  Widget build(BuildContext context) => Container(
    height: height, width: width,
    decoration: BoxDecoration(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.md),
    ),
  );
}

// ── Error Retry ───────────────────────────────────────────────────────────────
class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.x3l),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AppColors.rose, size: 40),
        const SizedBox(height: AppSpacing.md),
        Text(message, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: 160,
          child: ElevatedButton(onPressed: onRetry,
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Retry'),
          ),
        ),
      ]),
    ),
  );
}

// ── Star Rating ───────────────────────────────────────────────────────────────
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  const StarRating({super.key, required this.rating, this.size = 12});

  @override
  Widget build(BuildContext context) {
    final full  = rating.floor();
    final half  = (rating - full) >= 0.5 ? 1 : 0;
    final empty = 5 - full - half;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ...List.generate(full,  (_) => Icon(Icons.star,           size: size, color: AppColors.gold)),
      ...List.generate(half,  (_) => Icon(Icons.star_half,      size: size, color: AppColors.gold)),
      ...List.generate(empty, (_) => Icon(Icons.star_border,    size: size, color: AppColors.gold)),
    ]);
  }
}

// ── Score Bar ─────────────────────────────────────────────────────────────────
class ScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final double maxScore;
  final Color color;
  const ScoreBar({super.key, required this.label, required this.score, this.maxScore = 10, this.color = AppColors.gold});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.bodyXs),
        Text('${score.toStringAsFixed(1)}/$maxScore', style: AppTextStyles.monoSm.copyWith(color: color)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: score / maxScore,
          backgroundColor: AppColors.surface3,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 4,
        ),
      ),
    ],
  );
}

// ── Live Dot ──────────────────────────────────────────────────────────────────
class LiveDot extends StatelessWidget {
  final Color color;
  const LiveDot({super.key, this.color = AppColors.teal});
  @override
  Widget build(BuildContext context) => Container(
    width: 7, height: 7,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ── Planet Status Badge ───────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = switch (status.toLowerCase()) {
      'exalted'     => (AppColors.gold, AppColors.goldDim, const Color(0x40D4A853)),
      'debilitated' => (AppColors.rose, AppColors.roseDim, const Color(0x40E85D8B)),
      'own sign'    => (AppColors.teal, AppColors.tealDim, const Color(0x402EC4B6)),
      _             => (AppColors.textSecondary, AppColors.surface2, AppColors.borderDefault),
    };
    return AppChip(status, color: cfg.$1, bgColor: cfg.$2, borderColor: cfg.$3, fontSize: 9);
  }
}
