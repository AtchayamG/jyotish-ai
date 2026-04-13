// lib/features/horoscope/horoscope_feature.dart

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── HOROSCOPE ─────────────────────────────────────────────────────────────────

class HoroscopeEntity extends Equatable {
  final String zodiacSign, type, dateRange, prediction;
  final double overallScore, careerScore, loveScore, healthScore, financeScore;
  final int luckyNumber;
  final String luckyColor, luckyGemstone;
  final List<String> doToday, avoidToday;

  const HoroscopeEntity({
    required this.zodiacSign, required this.type, required this.dateRange,
    required this.prediction, required this.overallScore, required this.careerScore,
    required this.loveScore, required this.healthScore, required this.financeScore,
    required this.luckyNumber, required this.luckyColor, required this.luckyGemstone,
    required this.doToday, required this.avoidToday,
  });

  @override List<Object?> get props => [zodiacSign, type];
}

abstract class HoroscopeRepository {
  Future<HoroscopeEntity> getHoroscope(String sign, String type, String language);
}

class GetHoroscopeUseCase {
  final HoroscopeRepository _repo;
  GetHoroscopeUseCase(this._repo);
  Future<HoroscopeEntity> call(String sign, {String type = 'daily', String lang = 'en'}) =>
    _repo.getHoroscope(sign, type, lang);
}

class HoroscopeModel {
  final String zodiacSign, type, dateRange, prediction, luckyColor, luckyGemstone;
  final double overallScore, careerScore, loveScore, healthScore, financeScore;
  final int luckyNumber;
  final List<String> doToday, avoidToday;

  HoroscopeModel.fromJson(Map<String, dynamic> j)
    : zodiacSign = j['zodiac_sign'] ?? '',
      type = j['type'] ?? 'daily',
      dateRange = j['date_range'] ?? '',
      prediction = j['prediction'] ?? '',
      luckyColor = j['lucky_color'] ?? '',
      luckyGemstone = j['lucky_gemstone'] ?? '',
      overallScore = (j['overall_score'] as num?)?.toDouble() ?? 0,
      careerScore = (j['scores']?['career'] as num?)?.toDouble() ?? 0,
      loveScore = (j['scores']?['love'] as num?)?.toDouble() ?? 0,
      healthScore = (j['scores']?['health'] as num?)?.toDouble() ?? 0,
      financeScore = (j['scores']?['finance'] as num?)?.toDouble() ?? 0,
      luckyNumber = j['lucky_number'] as int? ?? 0,
      doToday = List<String>.from(j['do_today'] ?? []),
      avoidToday = List<String>.from(j['avoid_today'] ?? []);

  HoroscopeEntity toEntity() => HoroscopeEntity(
    zodiacSign: zodiacSign, type: type, dateRange: dateRange,
    prediction: prediction, overallScore: overallScore,
    careerScore: careerScore, loveScore: loveScore, healthScore: healthScore,
    financeScore: financeScore, luckyNumber: luckyNumber, luckyColor: luckyColor,
    luckyGemstone: luckyGemstone, doToday: doToday, avoidToday: avoidToday,
  );
}

abstract class HoroscopeRemoteDataSource {
  Future<HoroscopeModel> getHoroscope(String sign, String type, String language);
}

class HoroscopeRemoteDataSourceImpl implements HoroscopeRemoteDataSource {
  final Dio _dio;
  HoroscopeRemoteDataSourceImpl(this._dio);

  @override
  Future<HoroscopeModel> getHoroscope(String sign, String type, String language) async {
    final res = await _dio.post('/astrology/horoscope', data: {
      'zodiac_sign': sign, 'horoscope_type': type, 'language': language,
    });
    return HoroscopeModel.fromJson(res.data as Map<String, dynamic>);
  }
}

class HoroscopeRepositoryImpl implements HoroscopeRepository {
  final HoroscopeRemoteDataSource _remote;
  HoroscopeRepositoryImpl(this._remote);

  @override
  Future<HoroscopeEntity> getHoroscope(String sign, String type, String language) async {
    return (await _remote.getHoroscope(sign, type, language)).toEntity();
  }
}

abstract class HoroscopeEvent extends Equatable {
  @override List<Object?> get props => [];
}

class HoroscopeRequested extends HoroscopeEvent {
  final String sign; final String type;
  HoroscopeRequested(this.sign, {this.type = 'daily'});
  @override List<Object?> get props => [sign, type];
}

abstract class HoroscopeState extends Equatable {
  @override List<Object?> get props => [];
}
class HoroscopeInitial extends HoroscopeState {}
class HoroscopeLoading extends HoroscopeState {}
class HoroscopeLoaded extends HoroscopeState {
  final HoroscopeEntity horoscope;
  HoroscopeLoaded(this.horoscope);
  @override List<Object?> get props => [horoscope];
}
class HoroscopeError extends HoroscopeState {
  final String message;
  HoroscopeError(this.message);
  @override List<Object?> get props => [message];
}

class HoroscopeBloc extends Bloc<HoroscopeEvent, HoroscopeState> {
  final GetHoroscopeUseCase _useCase;
  HoroscopeBloc(this._useCase) : super(HoroscopeInitial()) {
    on<HoroscopeRequested>((e, emit) async {
      emit(HoroscopeLoading());
      try { emit(HoroscopeLoaded(await _useCase(e.sign, type: e.type))); }
      catch (err) { emit(HoroscopeError(err.toString())); }
    });
  }
}

// ── MATCHMAKING ───────────────────────────────────────────────────────────────

class KutaScoreEntity extends Equatable {
  final String name, description;
  final int maxScore, obtainedScore;
  const KutaScoreEntity({required this.name, required this.description, required this.maxScore, required this.obtainedScore});
  @override List<Object?> get props => [name];
}

class MatchEntity extends Equatable {
  final int totalScore; final double percentage; final String verdict;
  final List<KutaScoreEntity> kutaScores;
  final bool hasDosha; final String? doshaType, remedy;
  final String? aiAnalysis;

  const MatchEntity({
    required this.totalScore, required this.percentage, required this.verdict,
    required this.kutaScores, required this.hasDosha,
    this.doshaType, this.remedy, this.aiAnalysis,
  });
  @override List<Object?> get props => [totalScore];
}

abstract class MatchRepository {
  Future<MatchEntity> getMatch(Map<String, dynamic> person1, Map<String, dynamic> person2);
}

class GetMatchUseCase {
  final MatchRepository _repo;
  GetMatchUseCase(this._repo);
  Future<MatchEntity> call(Map<String, dynamic> p1, Map<String, dynamic> p2) =>
    _repo.getMatch(p1, p2);
}

class MatchModel {
  final int totalScore; final double percentage; final String verdict;
  final List<Map<String, dynamic>> kutaScores;
  final bool hasDosha; final String? doshaType, remedy, aiAnalysis;

  MatchModel.fromJson(Map<String, dynamic> j)
    : totalScore = j['total_score'] as int? ?? 0,
      percentage = (j['percentage'] as num?)?.toDouble() ?? 0,
      verdict = j['verdict'] ?? '',
      kutaScores = List<Map<String, dynamic>>.from(j['kuta_scores'] ?? []),
      hasDosha = j['dosha']?['has_dosha'] as bool? ?? false,
      doshaType = j['dosha']?['dosha_type'] as String?,
      remedy = j['dosha']?['remedy'] as String?,
      aiAnalysis = j['ai_analysis'] as String?;

  MatchEntity toEntity() => MatchEntity(
    totalScore: totalScore, percentage: percentage, verdict: verdict,
    hasDosha: hasDosha, doshaType: doshaType, remedy: remedy, aiAnalysis: aiAnalysis,
    kutaScores: kutaScores.map((k) => KutaScoreEntity(
      name: k['name'] ?? '', description: k['description'] ?? '',
      maxScore: k['max_score'] as int? ?? 0,
      obtainedScore: k['obtained_score'] as int? ?? 0,
    )).toList(),
  );
}

abstract class MatchRemoteDataSource {
  Future<MatchModel> getMatch(Map<String, dynamic> p1, Map<String, dynamic> p2);
}

class MatchRemoteDataSourceImpl implements MatchRemoteDataSource {
  final Dio _dio;
  MatchRemoteDataSourceImpl(this._dio);

  @override
  Future<MatchModel> getMatch(Map<String, dynamic> p1, Map<String, dynamic> p2) async {
    final res = await _dio.post('/astrology/match', data: {'person1': p1, 'person2': p2});
    return MatchModel.fromJson(res.data as Map<String, dynamic>);
  }
}

class MatchRepositoryImpl implements MatchRepository {
  final MatchRemoteDataSource _remote;
  MatchRepositoryImpl(this._remote);
  @override
  Future<MatchEntity> getMatch(Map<String, dynamic> p1, Map<String, dynamic> p2) async =>
    (await _remote.getMatch(p1, p2)).toEntity();
}

abstract class MatchEvent extends Equatable { @override List<Object?> get props => []; }
class MatchRequested extends MatchEvent {
  final Map<String, dynamic> person1, person2;
  MatchRequested(this.person1, this.person2);
  @override List<Object?> get props => [person1, person2];
}

abstract class MatchState extends Equatable { @override List<Object?> get props => []; }
class MatchInitial extends MatchState {}
class MatchLoading extends MatchState {}
class MatchLoaded extends MatchState {
  final MatchEntity result;
  MatchLoaded(this.result);
  @override List<Object?> get props => [result];
}
class MatchError extends MatchState {
  final String message;
  MatchError(this.message);
  @override List<Object?> get props => [message];
}

class MatchBloc extends Bloc<MatchEvent, MatchState> {
  final GetMatchUseCase _useCase;
  MatchBloc(this._useCase) : super(MatchInitial()) {
    on<MatchRequested>((e, emit) async {
      emit(MatchLoading());
      try { emit(MatchLoaded(await _useCase(e.person1, e.person2))); }
      catch (err) { emit(MatchError(err.toString())); }
    });
  }
}

// ── AI CHAT ───────────────────────────────────────────────────────────────────

class ChatMessageEntity extends Equatable {
  final String role, content;
  final DateTime timestamp;
  const ChatMessageEntity({required this.role, required this.content, required this.timestamp});
  @override List<Object?> get props => [timestamp];
}

class ChatResponseEntity extends Equatable {
  final String reply;
  final List<String> suggestedQuestions;
  const ChatResponseEntity({required this.reply, required this.suggestedQuestions});
  @override List<Object?> get props => [reply];
}

abstract class ChatRepository {
  Future<ChatResponseEntity> sendMessage(String message, List<Map<String, String>> history, String language);
}

class SendMessageUseCase {
  final ChatRepository _repo;
  SendMessageUseCase(this._repo);
  Future<ChatResponseEntity> call(String message, List<Map<String, String>> history, {String lang = 'en'}) =>
    _repo.sendMessage(message, history, lang);
}

abstract class ChatRemoteDataSource {
  Future<Map<String, dynamic>> sendMessage(String message, List<Map<String, String>> history, String language);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio _dio;
  ChatRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> sendMessage(String message, List<Map<String, String>> history, String language) async {
    final res = await _dio.post('/astrology/chat', data: {
      'message': message,
      'history': history,
      'language': language,
    });
    return res.data as Map<String, dynamic>;
  }
}

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remote;
  ChatRepositoryImpl(this._remote);

  @override
  Future<ChatResponseEntity> sendMessage(String message, List<Map<String, String>> history, String language) async {
    final data = await _remote.sendMessage(message, history, language);
    return ChatResponseEntity(
      reply: data['reply'] as String? ?? '',
      suggestedQuestions: List<String>.from(data['suggested_questions'] ?? []),
    );
  }
}

abstract class ChatEvent extends Equatable { @override List<Object?> get props => []; }
class ChatMessageSent extends ChatEvent {
  final String message;
  ChatMessageSent(this.message);
  @override List<Object?> get props => [message];
}
class ChatCleared extends ChatEvent {}

abstract class ChatState extends Equatable { @override List<Object?> get props => []; }
class ChatInitial extends ChatState {}

class ChatConversation extends ChatState {
  final List<ChatMessageEntity> messages;
  final List<String> suggestedQuestions;
  final bool isLoading;
  ChatConversation({required this.messages, this.suggestedQuestions = const [], this.isLoading = false});
  ChatConversation copyWith({List<ChatMessageEntity>? messages, List<String>? suggestedQuestions, bool? isLoading}) =>
    ChatConversation(
      messages: messages ?? this.messages,
      suggestedQuestions: suggestedQuestions ?? this.suggestedQuestions,
      isLoading: isLoading ?? this.isLoading,
    );
  @override List<Object?> get props => [messages.length, isLoading];
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
  @override List<Object?> get props => [message];
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessageUseCase _useCase;
  final List<ChatMessageEntity> _history = [];

  ChatBloc(this._useCase) : super(ChatInitial()) {
    on<ChatMessageSent>(_onSent);
    on<ChatCleared>(_onCleared);
  }

  Future<void> _onSent(ChatMessageSent event, Emitter<ChatState> emit) async {
    final userMsg = ChatMessageEntity(role: 'user', content: event.message, timestamp: DateTime.now());
    _history.add(userMsg);
    emit(ChatConversation(messages: List.from(_history), isLoading: true));

    try {
      final historyPayload = _history.take(_history.length - 1)
        .map((m) => {'role': m.role, 'content': m.content}).toList();
      final response = await _useCase(event.message, historyPayload);
      final aiMsg = ChatMessageEntity(role: 'assistant', content: response.reply, timestamp: DateTime.now());
      _history.add(aiMsg);
      emit(ChatConversation(
        messages: List.from(_history),
        suggestedQuestions: response.suggestedQuestions,
        isLoading: false,
      ));
    } catch (e) {
      _history.removeLast();
      emit(ChatError(e.toString()));
    }
  }

  void _onCleared(ChatCleared event, Emitter<ChatState> emit) {
    _history.clear();
    emit(ChatInitial());
  }
}
