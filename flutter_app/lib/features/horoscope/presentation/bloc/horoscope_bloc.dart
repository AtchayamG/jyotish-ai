import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/horoscope_model.dart';
import '../../domain/usecases/get_horoscope_usecase.dart';

abstract class HoroscopeEvent extends Equatable { const HoroscopeEvent(); @override List<Object?> get props => []; }
class FetchHoroscope extends HoroscopeEvent {
  final String sign, type; const FetchHoroscope(this.sign, {this.type = 'daily'});
  @override List<Object?> get props => [sign, type];
}
abstract class HoroscopeState extends Equatable { const HoroscopeState(); @override List<Object?> get props => []; }
class HoroscopeInitial extends HoroscopeState { const HoroscopeInitial(); }
class HoroscopeLoading extends HoroscopeState { const HoroscopeLoading(); }
class HoroscopeLoaded  extends HoroscopeState { final HoroscopeModel data; const HoroscopeLoaded(this.data); @override List<Object?> get props => [data]; }
class HoroscopeError   extends HoroscopeState { final String msg; const HoroscopeError(this.msg); @override List<Object?> get props => [msg]; }

class HoroscopeBloc extends Bloc<HoroscopeEvent, HoroscopeState> {
  final GetHoroscopeUseCase _uc;
  HoroscopeBloc(this._uc) : super(const HoroscopeInitial()) {
    on<FetchHoroscope>((e, emit) async {
      emit(const HoroscopeLoading());
      try { emit(HoroscopeLoaded(await _uc(e.sign, e.type))); }
      catch (err) { emit(HoroscopeError(err.toString())); }
    });
  }
}
