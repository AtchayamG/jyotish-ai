import '../../data/models/horoscope_model.dart';
import '../repositories/horoscope_repository.dart';
class GetHoroscopeUseCase {
  final HoroscopeRepository _r; GetHoroscopeUseCase(this._r);
  Future<HoroscopeModel> call(String sign, String type) => _r.getHoroscope(sign, type);
}
