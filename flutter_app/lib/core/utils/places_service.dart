// lib/core/utils/places_service.dart
// Google Places Autocomplete + Place Details + Timezone — via REST (no plugin needed).
// Uses the same Dio instance pattern as the rest of the app.

import 'dart:async';
import 'package:dio/dio.dart';

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
  // Set your Google Maps API key here (or in AppConstants and reference it).
  // Enable: Places API + Geocoding API + Time Zone API in Google Cloud Console.
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Returns up to 5 city predictions matching [input].
  Future<List<PlacePrediction>> autocomplete(String input) async {
    if (input.trim().length < 3) return [];
    try {
      final resp = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': input.trim(),
          'key': _apiKey,
          'types': '(cities)',
          'language': 'en',
        },
      );
      if (resp.data['status'] != 'OK' && resp.data['status'] != 'ZERO_RESULTS') {
        return [];
      }
      final predictions = resp.data['predictions'] as List<dynamic>;
      return predictions
          .take(5)
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
      // 1. Geometry (lat/lng + name)
      final detailsResp = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'name,geometry',
          'key': _apiKey,
        },
      );
      final result = detailsResp.data['result'] as Map<String, dynamic>;
      final location =
          result['geometry']['location'] as Map<String, dynamic>;
      final lat = (location['lat'] as num).toDouble();
      final lng = (location['lng'] as num).toDouble();
      final name = result['name'] as String? ?? '';

      // 2. Timezone (UTC offset)
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final tzResp = await _dio.get(
        'https://maps.googleapis.com/maps/api/timezone/json',
        queryParameters: {
          'location': '$lat,$lng',
          'timestamp': timestamp,
          'key': _apiKey,
        },
      );
      final rawOffset = (tzResp.data['rawOffset'] as num? ?? 0).toDouble();
      final dstOffset = (tzResp.data['dstOffset'] as num? ?? 0).toDouble();
      // rawOffset + dstOffset gives total seconds offset; divide by 3600 for hours
      final tzHours = (rawOffset + dstOffset) / 3600;

      return PlaceDetails(
        name: name,
        latitude: lat,
        longitude: lng,
        timezone: tzHours,
      );
    } catch (_) {
      return null;
    }
  }
}
