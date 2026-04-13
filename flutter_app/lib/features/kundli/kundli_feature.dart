// lib/features/kundli/kundli_feature.dart
// Complete Kundli feature — Domain + Data layers

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Domain Entities ───────────────────────────────────────────────────────────

class PlanetEntity extends Equatable {
  final String name;
  final String symbol;
  final String rasi;
  final String degree;
  final String nakshatra;
  final int pada;
  final int house;
  final bool isRetrograde;
  final String status;

  const PlanetEntity({
    required this.name, required this.symbol, required this.rasi,
    required this.degree, required this.nakshatra, required this.pada,
    required this.house, required this.isRetrograde, required this.status,
  });

  @override
  List<Object?> get props => [name, rasi];
}

class ChartSummaryEntity extends Equatable {
  final String lagna;
  final String lagnaLord;
  final String rasi;
  final String rasiLord;
  final String nakshatra;
  final int pada;
  final String tithi;
  final String yoga;
  final String karana;
  final String ayana;

  const ChartSummaryEntity({
    required this.lagna, required this.lagnaLord, required this.rasi,
    required this.rasiLord, required this.nakshatra, required this.pada,
    required this.tithi, required this.yoga, required this.karana, required this.ayana,
  });

  @override
  List<Object?> get props => [lagna, nakshatra];
}

class DashaEntity extends Equatable {
  final String planet;
  final String startDate;
  final String endDate;
  final bool isCurrent;
  final List<DashaEntity> antardasha;

  const DashaEntity({
    required this.planet, required this.startDate, required this.endDate,
    required this.isCurrent, this.antardasha = const [],
  });

  @override
  List<Object?> get props => [planet];
}

class KundliEntity extends Equatable {
  final ChartSummaryEntity summary;
  final List<PlanetEntity> planets;
  final String currentDasha;
  final List<DashaEntity> dashas;
  final String? aiInsight;

  const KundliEntity({
    required this.summary, required this.planets,
    required this.currentDasha, required this.dashas, this.aiInsight,
  });

  @override
  List<Object?> get props => [summary.lagna];
}

class BirthDetailsParams {
  final String name;
  final int year, month, day, hour, minute;
  final double latitude, longitude;
  final double timezone;

  const BirthDetailsParams({
    required this.name, required this.year, required this.month,
    required this.day, required this.hour, required this.minute,
    required this.latitude, required this.longitude, this.timezone = 5.5,
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'year': year, 'month': month, 'day': day,
    'hour': hour, 'minute': minute,
    'latitude': latitude, 'longitude': longitude, 'timezone': timezone,
    'ayanamsa': 'lahiri',
  };
}

// ── Domain Repository Interface ───────────────────────────────────────────────

abstract class KundliRepository {
  Future<KundliEntity> getKundli(BirthDetailsParams params);
}

// ── Use Case ──────────────────────────────────────────────────────────────────

class GetKundliUseCase {
  final KundliRepository _repo;
  GetKundliUseCase(this._repo);
  Future<KundliEntity> call(BirthDetailsParams params) => _repo.getKundli(params);
}

// ── Data Models ───────────────────────────────────────────────────────────────

class PlanetModel {
  final String name, symbol, rasi, degree, nakshatra, status;
  final int pada, house;
  final bool isRetrograde;

  PlanetModel.fromJson(Map<String, dynamic> j)
    : name = j['name'] ?? '', symbol = j['symbol'] ?? '●',
      rasi = j['rasi'] ?? '', degree = j['degree'] ?? '0°',
      nakshatra = j['nakshatra'] ?? '', status = j['status'] ?? 'Neutral',
      pada = j['pada'] ?? 1, house = j['house'] ?? 1,
      isRetrograde = j['is_retrograde'] ?? false;

  PlanetEntity toEntity() => PlanetEntity(
    name: name, symbol: symbol, rasi: rasi, degree: degree,
    nakshatra: nakshatra, pada: pada, house: house,
    isRetrograde: isRetrograde, status: status,
  );
}

class ChartSummaryModel {
  final String lagna, lagnaLord, rasi, rasiLord, nakshatra, tithi, yoga, karana, ayana;
  final int pada;

  ChartSummaryModel.fromJson(Map<String, dynamic> j)
    : lagna = j['lagna'] ?? '', lagnaLord = j['lagna_lord'] ?? '',
      rasi = j['rasi'] ?? '', rasiLord = j['rasi_lord'] ?? '',
      nakshatra = j['nakshatra'] ?? '', tithi = j['tithi'] ?? '',
      yoga = j['yoga'] ?? '', karana = j['karana'] ?? '',
      ayana = j['ayana'] ?? '', pada = j['pada'] ?? 1;

  ChartSummaryEntity toEntity() => ChartSummaryEntity(
    lagna: lagna, lagnaLord: lagnaLord, rasi: rasi, rasiLord: rasiLord,
    nakshatra: nakshatra, pada: pada, tithi: tithi, yoga: yoga,
    karana: karana, ayana: ayana,
  );
}

class DashaModel {
  final String planet, startDate, endDate;
  final bool isCurrent;
  final List<DashaModel> antardasha;

  DashaModel.fromJson(Map<String, dynamic> j)
    : planet = j['planet'] ?? '', startDate = j['start_date'] ?? '',
      endDate = j['end_date'] ?? '', isCurrent = j['is_current'] ?? false,
      antardasha = (j['antardasha'] as List<dynamic>? ?? [])
        .map((e) => DashaModel.fromJson(e as Map<String, dynamic>)).toList();

  DashaEntity toEntity() => DashaEntity(
    planet: planet, startDate: startDate, endDate: endDate, isCurrent: isCurrent,
    antardasha: antardasha.map((d) => d.toEntity()).toList(),
  );
}

class KundliModel {
  final ChartSummaryModel summary;
  final List<PlanetModel> planets;
  final String currentDasha;
  final List<DashaModel> dashas;
  final String? aiInsight;

  KundliModel.fromJson(Map<String, dynamic> j)
    : summary = ChartSummaryModel.fromJson(j['summary'] as Map<String, dynamic>),
      planets = (j['planets'] as List<dynamic>)
        .map((e) => PlanetModel.fromJson(e as Map<String, dynamic>)).toList(),
      currentDasha = j['current_dasha'] ?? '',
      dashas = (j['dashas'] as List<dynamic>? ?? [])
        .map((e) => DashaModel.fromJson(e as Map<String, dynamic>)).toList(),
      aiInsight = j['ai_insight'] as String?;

  KundliEntity toEntity() => KundliEntity(
    summary: summary.toEntity(),
    planets: planets.map((p) => p.toEntity()).toList(),
    currentDasha: currentDasha,
    dashas: dashas.map((d) => d.toEntity()).toList(),
    aiInsight: aiInsight,
  );
}

// ── Remote Data Source ────────────────────────────────────────────────────────

abstract class KundliRemoteDataSource {
  Future<KundliModel> getKundli(BirthDetailsParams params);
}

class KundliRemoteDataSourceImpl implements KundliRemoteDataSource {
  final Dio _dio;
  KundliRemoteDataSourceImpl(this._dio);

  @override
  Future<KundliModel> getKundli(BirthDetailsParams params) async {
    final res = await _dio.post('/astrology/kundli', data: params.toJson());
    return KundliModel.fromJson(res.data as Map<String, dynamic>);
  }
}

// ── Repository Implementation ─────────────────────────────────────────────────

class KundliRepositoryImpl implements KundliRepository {
  final KundliRemoteDataSource _remote;
  KundliRepositoryImpl(this._remote);

  @override
  Future<KundliEntity> getKundli(BirthDetailsParams params) async {
    final model = await _remote.getKundli(params);
    return model.toEntity();
  }
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

abstract class KundliEvent extends Equatable {
  @override List<Object?> get props => [];
}

class KundliRequested extends KundliEvent {
  final BirthDetailsParams params;
  KundliRequested(this.params);
  @override List<Object?> get props => [params.name];
}

abstract class KundliState extends Equatable {
  @override List<Object?> get props => [];
}

class KundliInitial extends KundliState {}
class KundliLoading extends KundliState {}

class KundliLoaded extends KundliState {
  final KundliEntity kundli;
  KundliLoaded(this.kundli);
  @override List<Object?> get props => [kundli];
}

class KundliError extends KundliState {
  final String message;
  KundliError(this.message);
  @override List<Object?> get props => [message];
}

class KundliBloc extends Bloc<KundliEvent, KundliState> {
  final GetKundliUseCase _useCase;
  KundliBloc(this._useCase) : super(KundliInitial()) {
    on<KundliRequested>(_onRequested);
  }

  Future<void> _onRequested(KundliRequested event, Emitter<KundliState> emit) async {
    emit(KundliLoading());
    try {
      final kundli = await _useCase(event.params);
      emit(KundliLoaded(kundli));
    } catch (e) {
      emit(KundliError(e.toString()));
    }
  }
}
