// lib/core/di/injection.dart
// GetIt service locator — single registration point for ALL dependencies.
// Call setupDependencies() once in main() before runApp.

import 'package:get_it/get_it.dart';

import '../api/api_client.dart';
import '../api/secure_storage.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/kundli/data/datasources/kundli_remote_datasource.dart';
import '../../features/kundli/data/repositories/kundli_repository_impl.dart';
import '../../features/kundli/domain/repositories/kundli_repository.dart';
import '../../features/kundli/domain/usecases/get_kundli_usecase.dart';
import '../../features/kundli/presentation/bloc/kundli_bloc.dart';
import '../../features/horoscope/data/datasources/horoscope_remote_datasource.dart';
import '../../features/horoscope/data/repositories/horoscope_repository_impl.dart';
import '../../features/horoscope/domain/repositories/horoscope_repository.dart';
import '../../features/horoscope/domain/usecases/get_horoscope_usecase.dart';
import '../../features/horoscope/presentation/bloc/horoscope_bloc.dart';
import '../../features/matchmaking/data/datasources/match_remote_datasource.dart';
import '../../features/matchmaking/data/repositories/match_repository_impl.dart';
import '../../features/matchmaking/domain/repositories/match_repository.dart';
import '../../features/matchmaking/domain/usecases/get_match_usecase.dart';
import '../../features/matchmaking/presentation/bloc/match_bloc.dart';
import '../../features/ai_chat/data/datasources/chat_remote_datasource.dart';
import '../../features/ai_chat/data/repositories/chat_repository_impl.dart';
import '../../features/ai_chat/domain/repositories/chat_repository.dart';
import '../../features/ai_chat/domain/usecases/send_message_usecase.dart';
import '../../features/ai_chat/presentation/bloc/chat_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  // ── Core ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ApiClient>(() => ApiClient.instance);
  sl.registerLazySingleton<SecureStorage>(() => SecureStorage.instance);

  // ── Auth ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerFactory(() => AuthBloc(sl(), sl(), sl()));

  // ── Kundli ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<KundliRemoteDataSource>(
    () => KundliRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<KundliRepository>(
    () => KundliRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetKundliUseCase(sl()));
  sl.registerFactory(() => KundliBloc(sl()));

  // ── Horoscope ───────────────────────────────────────────────────────────
  sl.registerLazySingleton<HoroscopeRemoteDataSource>(
    () => HoroscopeRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<HoroscopeRepository>(
    () => HoroscopeRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetHoroscopeUseCase(sl()));
  sl.registerFactory(() => HoroscopeBloc(sl()));

  // ── Matchmaking ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<MatchRemoteDataSource>(
    () => MatchRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<MatchRepository>(
    () => MatchRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetMatchUseCase(sl()));
  sl.registerFactory(() => MatchBloc(sl()));

  // ── AI Chat ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerFactory(() => ChatBloc(sl()));
}
