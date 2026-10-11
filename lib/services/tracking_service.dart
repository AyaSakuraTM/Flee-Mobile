import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(
    FleetOpsTaskHandler(),
  );
}

class FleetOpsTaskHandler extends TaskHandler {
  static const int vehicleId = 1;

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  bool _isUpdating = false;

  @override
  Future<void> onStart(
    DateTime timestamp,
    TaskStarter starter,
  ) async {
    print('FleetOps tracking service started.');
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    // Prevent another GPS request from starting while
    // the previous one is still running.
    if (_isUpdating) {
      print('FleetOps GPS update already running. Skipping.');
      return;
    }

    _isUpdating = true;

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      print(
        'FleetOps GPS service enabled: $serviceEnabled',
      );

      if (!serviceEnabled) {
        print(
          'FleetOps GPS: location service is disabled.',
        );
        return;
      }

      final permission =
          await Geolocator.checkPermission();

      print(
        'FleetOps GPS permission: $permission',
      );

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print(
          'FleetOps GPS: location permission unavailable.',
        );
        return;
      }

      // Get current emulator/device position.
      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      print(
        'FleetOps GPS position: '
        '${position.latitude.toStringAsFixed(6)}, '
        '${position.longitude.toStringAsFixed(6)}',
      );

      // Get authentication token.
      final token = await _storage.read(
        key: 'sanctum_token',
      );

      if (token == null || token.isEmpty) {
        print(
          'FleetOps tracking: authentication token missing.',
        );
        return;
      }

      // Convert meters/second to kilometers/hour.
      final speedKmh =
          (position.speed * 3.6).clamp(
        0.0,
        double.infinity,
      );

      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/location/update',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'vehicle_id': vehicleId,
              'latitude': position.latitude,
              'longitude': position.longitude,
              'speed': speedKmh,
              'timestamp':
                  DateTime.now().toIso8601String(),
            }),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        print(
          'FleetOps GPS update: '
          '${response.statusCode} '
          '(${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)})',
        );
      } else {
        print(
          'FleetOps GPS update failed: '
          'HTTP ${response.statusCode}',
        );

        print(
          'Response: ${response.body}',
        );
      }
    } catch (e) {
      // Don't allow an individual GPS/API error
      // to kill the foreground service.
      print(
        'FleetOps tracking error: $e',
      );
    } finally {
      // Always allow the next update to run.
      _isUpdating = false;
    }
  }

  @override
  Future<void> onDestroy(
    DateTime timestamp,
    bool isTimeout,
  ) async {
    print(
      'FleetOps tracking service stopped.',
    );

    // Mark the current update as finished so the
    // service can shut down cleanly.
    _isUpdating = false;
  }

  @override
  void onReceiveData(Object data) {
    print(
      'FleetOps received data: $data',
    );
  }

  @override
  void onNotificationButtonPressed(
    String id,
  ) {
    print(
      'Notification button pressed: $id',
    );

    if (id == 'stop_tracking') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    print(
      'FleetOps notification pressed.',
    );
  }

  @override
  void onNotificationDismissed() {
    print(
      'FleetOps notification dismissed.',
    );
  }
}