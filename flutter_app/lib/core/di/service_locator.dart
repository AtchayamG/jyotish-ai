// lib/core/di/service_locator.dart
import "package:get_it/get_it.dart";
import "../api/api_client.dart";
import "../api/api_constants.dart";
import "../api/token_interceptor.dart";
import "../storage/secure_storage.dart";
import "../../features/auth/data/datasources/auth_remote_datasource.dart";
import "../../features/auth/data/repositories/auth_repository_impl.dart";
import "../../features/auth/domain/repositories/auth_repository.dart";
import "../../features/auth/domain/usecases/login_usecase.dart";
import "../../features/auth/domain/usecases/register_usecase.dart";
import "../../features/auth/presentation/bloc/auth_bloc.dart";
import "../../features/kundli/data/datasources/kundli_remote_datasource.dart";
import "../../features/kundli/data/repositories/kundli_repository_impl.dart";
import "../../features/kundli/domain/repositories/kundli_repository.dart";
import "../../features/kundli/domain/usecases/get_kundli_usecase.dart";
import "../../features/kundli/presentation/bloc/kundli_bloc.dart";
import "../../features/horoscope/data/datasources/horoscope_remote_datasource.dart";
import "../../features/horoscope/data/repositories/horoscope_repository_impl.dart";
import "../../features/horoscope/domain/repositories/horoscope_repository.dart";
import "../../features/horoscope/domain/usecases/get_horoscope_usecase.dart";
import "../../features/horoscope/presentation/bloc/horoscope_bloc.dart";
import "../../features/matchmaking/data/datasources/match_remote_datasource.dart";
import "../../features/matchmaking/data/repositories/match_repository_impl.dart";
import "../../features/matchmaking/domain/repositories/match_repository.dart";
import "../../features/matchmaking/domain/usecases/get_match_usecase.dart";
import "../../features/matchmaking/presentation/bloc/match_bloc.dart";
import "../../features/ai_chat/data/datasources/chat_remote_datasource.dart";
import "../../features/ai_chat/data/repositories/chat_repository_impl.dart";
import "../../features/ai_chat/domain/repositories/chat_repository.dart";
import "../../features/ai_chat/domain/usecases/send_message_usecase.dart";
import "../../features/ai_chat/presentation/bloc/chat_bloc.dart";

final sl = GetIt.instance;

Future<void> setupLocator() async {
  final storage = SecureStorage();
  sl.registerSingleton<TokenStorage>(storage);
  sl.registerSingleton<SecureStorage>(storage);
  sl.registerSingleton<ApiClient>(
    ApiClient(baseUrl: ApiConstants.baseUrl, tokenStorage: storage));

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()));
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => AuthBloc(
    login: sl<LoginUseCase>(), register: sl<RegisterUseCase>(),
    remoteDs: sl<AuthRemoteDataSource>(), storage: sl<SecureStorage>()));

  sl.registerLazySingleton<KundliRemoteDataSource>(
    () => KundliRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<KundliRepository>(
    () => KundliRepositoryImpl(sl<KundliRemoteDataSource>()));
  sl.registerLazySingleton(() => GetKundliUseCase(sl<KundliRepository>()));
  sl.registerFactory(() => KundliBloc(sl<GetKundliUseCase>()));

  sl.registerLazySingleton<HoroscopeRemoteDataSource>(
    () => HoroscopeRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<HoroscopeRepository>(
    () => HoroscopeRepositoryImpl(sl<HoroscopeRemoteDataSource>()));
  sl.registerLazySingleton(() => GetHoroscopeUseCase(sl<HoroscopeRepository>()));
  sl.registerFactory(() => HoroscopeBloc(sl<GetHoroscopeUseCase>()));

  sl.registerLazySingleton<MatchRemoteDataSource>(
    () => MatchRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<MatchRepository>(
    () => MatchRepositoryImpl(sl<MatchRemoteDataSource>()));
  sl.registerLazySingleton(() => GetMatchUseCase(sl<MatchRepository>()));
  sl.registerFactory(() => MatchBloc(sl<GetMatchUseCase>()));

  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(sl<ChatRemoteDataSource>()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl<ChatRepository>()));
  sl.registerFactory(() => ChatBloc(sl<SendMessageUseCase>()));
}
