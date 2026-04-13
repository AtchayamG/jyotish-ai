// lib/main.dart
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "core/di/service_locator.dart";
import "core/network/connectivity_cubit.dart";
import "core/router/app_router.dart";
import "core/theme/app_theme.dart";
import "core/widgets/app_lifecycle_observer.dart";
import "features/auth/presentation/bloc/auth_bloc.dart";
import "features/kundli/presentation/bloc/kundli_bloc.dart";
import "features/horoscope/presentation/bloc/horoscope_bloc.dart";
import "features/matchmaking/presentation/bloc/match_bloc.dart";
import "features/ai_chat/presentation/bloc/chat_bloc.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await setupLocator();
  runApp(const JyotishApp());
}

class JyotishApp extends StatelessWidget {
  const JyotishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConnectivityCubit>(create: (_) => ConnectivityCubit()),
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(const CheckAuthStatus()),
        ),
        BlocProvider<KundliBloc>(create: (_) => sl<KundliBloc>()),
        BlocProvider<HoroscopeBloc>(create: (_) => sl<HoroscopeBloc>()),
        BlocProvider<MatchBloc>(create: (_) => sl<MatchBloc>()),
        BlocProvider<ChatBloc>(create: (_) => sl<ChatBloc>()),
      ],
      child: Builder(builder: (context) {
        final router = createRouter(context.read<AuthBloc>());
        return AppLifecycleObserver(
          child: MaterialApp.router(
            title: "Jyotish AI",
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            routerConfig: router,
          ),
        );
      }),
    );
  }
}
