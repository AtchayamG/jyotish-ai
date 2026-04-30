// lib/core/utils/places_service.dart
//
// Proxies Google Places calls through the Jyotish AI backend to avoid
// CORS issues on Flutter Web (GitHub Pages / any browser context).
// Backend endpoints: GET /api/v1/places/autocomplete  and  /api/v1/places/details
// The backend holds the actual GOOGLE_MAPS_API_KEY env var.

import 'dart:async';
import 'package:dio/dio.dart';
import '../api/api_constants.dart';

class PlacePrediction {
  final String description;
  final String placeId;
  const PlacePrediction({required this.description, required this.placeId});
}

class PlaceDetails {
  final String name;
  final double latitude;
  final double longitude;
  final double timezone; // UTC offset in hours, e.g. 5.5 for IST
  const PlaceDetails({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });
}

class PlacesService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Returns up to 5 city predictions matching [input].
  Future<List<PlacePrediction>> autocomplete(String input) async {
    if (input.trim().length < 3) return [];
    try {
      final resp = await _dio.get(
        ApiConstants.placesAutocomplete,
        queryParameters: {'input': input.trim()},
      );
      final list = resp.data as List<dynamic>;
      return list
          .map((p) => PlacePrediction(
                description: p['description'] as String,
                placeId: p['place_id'] as String,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches lat/lng and UTC-offset timezone for the selected [placeId].
  Future<PlaceDetails?> getDetails(String placeId) async {
    try {
      final resp = await _dio.get(
        ApiConstants.placesDetails,
        queryParameters: {'place_id': placeId},
      );
      final d = resp.data as Map<String, dynamic>;
      return PlaceDetails(
        name:      d['name'] as String? ?? '',
        latitude:  (d['latitude']  as num).toDouble(),
        longitude: (d['longitude'] as num).toDouble(),
        timezone:  (d['timezone']  as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
