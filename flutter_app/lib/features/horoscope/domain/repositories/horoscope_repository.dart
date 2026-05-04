import '../../../horoscope/data/models/horoscope_model.dart';

abstract class HoroscopeRepository {
  Future<HoroscopeModel> getHoroscope(String sign, String type);
  Future<HoroscopeModel> getMyHoroscope(String type);
}
