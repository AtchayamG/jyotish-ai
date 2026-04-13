// lib/core/network/connectivity_cubit.dart
// Monitors network by pinging the backend health endpoint every 5s.
// Works on web + mobile with no native plugins needed.

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../api/api_constants.dart';

abstract class ConnectivityState {}
class ConnectivityOnline  extends ConnectivityState {}
class ConnectivityOffline extends ConnectivityState {}

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 4),
  ));
  Timer? _timer;

  ConnectivityCubit() : super(ConnectivityOnline()) {
    _check();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _check());
  }

  Future<void> _check() async {
    try {
      final resp = await _dio.get('${ApiConstants.baseUrl}/health');
      if (resp.statusCode == 200) {
        if (state is! ConnectivityOnline) emit(ConnectivityOnline());
      } else {
        if (state is! ConnectivityOffline) emit(ConnectivityOffline());
      }
    } catch (_) {
      if (state is! ConnectivityOffline) emit(ConnectivityOffline());
    }
  }

  Future<void> retry() => _check();

  @override
  Future<void> close() {
    _timer?.cancel();
    _dio.close();
    return super.close();
  }
}
