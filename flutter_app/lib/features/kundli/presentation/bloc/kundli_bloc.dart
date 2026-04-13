import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/kundli_entity.dart';
import '../../domain/usecases/get_kundli_usecase.dart';

abstract class KundliEvent extends Equatable { const KundliEvent(); @override List<Object?> get props => []; }
class FetchKundli extends KundliEvent {
  final int year, month, day, hour, minute;
  final double lat, lng; final String name;
  const FetchKundli({required this.year, required this.month, required this.day, required this.hour, required this.minute, required this.lat, required this.lng, required this.name});
  @override List<Object?> get props => [year, month, day];
}

abstract class KundliState extends Equatable { const KundliState(); @override List<Object?> get props => []; }
class KundliInitial extends KundliState { const KundliInitial(); }
class KundliLoading extends KundliState { const KundliLoading(); }
class KundliLoaded  extends KundliState { final KundliEntity kundli; const KundliLoaded(this.kundli); @override List<Object?> get props => [kundli]; }
class KundliError   extends KundliState { final String msg; const KundliError(this.msg); @override List<Object?> get props => [msg]; }

class KundliBloc extends Bloc<KundliEvent, KundliState> {
  final GetKundliUseCase _useCase;
  KundliBloc(this._useCase) : super(const KundliInitial()) {
    on<FetchKundli>((e, emit) async {
      emit(const KundliLoading());
      try {
        final k = await _useCase(year: e.year, month: e.month, day: e.day, hour: e.hour, minute: e.minute, lat: e.lat, lng: e.lng, name: e.name);
        emit(KundliLoaded(k));
      } catch (err) { emit(KundliError(err.toString())); }
    });
  }
}
