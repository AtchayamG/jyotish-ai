// lib/core/widgets/no_network_page.dart
// Full-screen overlay shown when backend is unreachable.
// Shows a retry button and reconnects automatically when network returns.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../network/connectivity_cubit.dart';
import '../theme/app_theme.dart';

class NoNetworkPage extends StatelessWidget {
  /// Called when connectivity is restored — parent rebuilds and shows normal UI.
  const NoNetworkPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.inkDeep,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.rose.withOpacity(0.3), width: 1.5),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 44,
                color: AppColors.rose,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text(
              'No Connection',
              style: AppTextStyles.displaySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to reach the Jyotish AI server.\nPlease check your internet connection\nand try again.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.x3l),
            ElevatedButton.icon(
              onPressed: () => context.read<ConnectivityCubit>().retry(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 52),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Checking every 6 seconds automatically',
              style: AppTextStyles.bodyXs,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Wraps any widget — shows [NoNetworkPage] when offline, child when online.
/// Drop-in replacement: just wrap your scaffold/page body with this.
class NetworkGuard extends StatelessWidget {
  final Widget child;
  const NetworkGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, state) =>
            state is ConnectivityOffline ? const NoNetworkPage() : child,
      );
}
