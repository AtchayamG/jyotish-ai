import '../entities/kundli_entity.dart';
import '../repositories/kundli_repository.dart';
class GetKundliUseCase {
  final KundliRepository _r; GetKundliUseCase(this._r);
  Future<KundliEntity> call({required int year, required int month, required int day, required int hour, required int minute, required double lat, required double lng, required String name}) =>
    _r.getKundli(year: year, month: month, day: day, hour: hour, minute: minute, latitude: lat, longitude: lng, name: name);
}
