// lib/core/widgets/error_page.dart
// Reusable full-screen and inline error widgets used across all features.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Full-screen error page ─────────────────────────────────────────────────────
class ErrorPage extends StatelessWidget {
  final String title;
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorPage({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.retryLabel,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.ink,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.rose.withOpacity(0.3)),
              ),
              child: Icon(icon, size: 40, color: AppColors.rose),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(title,
              style: AppTextStyles.displaySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _friendlyMessage(message),
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary, height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.x3l),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel ?? 'Try Again'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 52),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  String _friendlyMessage(String raw) {
    if (raw.contains('unauthorized') || raw.contains('401')) {
      return 'Your session has expired. Please log in again.';
    }
    if (raw.contains('network') || raw.contains('SocketException') ||
        raw.contains('connection') || raw.contains('timeout')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (raw.contains('not_found') || raw.contains('404')) {
      return 'The requested data was not found.';
    }
    if (raw.contains('server') || raw.contains('500')) {
      return 'Server error. Our team has been notified. Please try again shortly.';
    }
    if (raw.contains('AppError')) {
      // Strip class prefix for cleaner display
      return raw.replaceAll(RegExp(r'AppError\[.*?\]:\s*'), '');
    }
    return raw.length > 120 ? '${raw.substring(0, 120)}…' : raw;
  }
}

// ── Inline error widget (inside a screen, not full screen) ────────────────────
class InlineError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const InlineError({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.x3l),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.roseDim,
            border: Border.all(color: AppColors.rose.withOpacity(0.3)),
          ),
          child: const Icon(Icons.error_outline, color: AppColors.rose, size: 28),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          _clean(message),
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(140, 44),
              foregroundColor: AppColors.gold,
              side: const BorderSide(color: AppColors.gold),
            ),
          ),
        ],
      ]),
    ),
  );

  String _clean(String raw) {
    if (raw.contains('AppError')) {
      return raw.replaceAll(RegExp(r'AppError\[.*?\]:\s*'), '');
    }
    if (raw.contains('network') || raw.contains('timeout')) {
      return 'Network error. Please retry.';
    }
    return raw.length > 100 ? '${raw.substring(0, 100)}…' : raw;
  }
}

// ── Unauthorised error — shown when token expired mid-session ─────────────────
class SessionExpiredBanner extends StatelessWidget {
  final VoidCallback onLogin;
  const SessionExpiredBanner({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(AppSpacing.lg),
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.roseDim,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.rose.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.lock_outline, color: AppColors.rose, size: 20),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: Text(
        'Session expired. Please log in again.',
        style: AppTextStyles.bodySm.copyWith(color: AppColors.rose),
      )),
      TextButton(
        onPressed: onLogin,
        child: Text('Login',
          style: AppTextStyles.labelSm.copyWith(color: AppColors.gold)),
      ),
    ]),
  );
}
