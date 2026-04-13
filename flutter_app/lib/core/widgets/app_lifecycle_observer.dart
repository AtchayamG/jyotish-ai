// lib/core/widgets/app_lifecycle_observer.dart
// Watches app foreground/background transitions.
// On resume: re-validates auth token. If expired → logout → login page.
// If token still valid → stay on current screen (no disruption).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../network/connectivity_cubit.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

class AppLifecycleObserver extends StatefulWidget {
  final Widget child;
  const AppLifecycleObserver({super.key, required this.child});

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResume();
    }
  }

  void _onResume() {
    if (!mounted) return;

    // 1. Re-check network connectivity
    context.read<ConnectivityCubit>().retry();

    // 2. Re-validate auth — CheckAuthStatus reads stored token.
    //    If token is missing or expired, BLoC emits AuthUnauthenticated
    //    and GoRouter's redirect sends user to login automatically.
    //    If token is valid, BLoC emits AuthAuthenticated — user stays put.
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      // Re-check silently — only emits new state if something changed
      context.read<AuthBloc>().add(const CheckAuthStatus());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
