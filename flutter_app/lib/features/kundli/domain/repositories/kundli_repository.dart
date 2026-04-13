import '../entities/kundli_entity.dart';
abstract class KundliRepository {
  Future<KundliEntity> getKundli({required int year, required int month, required int day, required int hour, required int minute, required double latitude, required double longitude, required String name});
}
