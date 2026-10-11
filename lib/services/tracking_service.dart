
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
  static const String _selectedVehicleKey =
      'fleetops_selected_vehicle_id';

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
    if (_isUpdating) {
      print('FleetOps GPS update already running. Skipping.');
      return;
    }

    _isUpdating = true;

    try {
      // Check that location services are enabled.
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        print('FleetOps GPS: location service is disabled.');
        return;
      }

      // Check location permission.
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('FleetOps GPS: location permission unavailable.');
        return;
      }

      // Read the selected vehicle ID saved by main.dart.
      final savedVehicleId = await _storage.read(
        key: _selectedVehicleKey,
      );

      final vehicleId = int.tryParse(
        savedVehicleId ?? '',
      );

      if (vehicleId == null || vehicleId <= 0) {
        print(
          'FleetOps tracking: no valid selected vehicle ID. '
          'Stopping tracking to avoid updating the wrong vehicle.',
        );

        await FlutterForegroundTask.stopService();
        return;
      }

      // Read the authenticated account token.
      final token = await _storage.read(
        key: 'sanctum_token',
      );

      if (token == null || token.isEmpty) {
        print(
          'FleetOps tracking: authentication token missing.',
        );

        await FlutterForegroundTask.stopService();
        return;
      }

      // Get the device's current position.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Convert meters per second to kilometers per hour.
      final speedKmh = (position.speed * 3.6).clamp(
        0.0,
        double.infinity,
      );

      // Send the location to the authenticated Laravel API.
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
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        print(
          'FleetOps GPS update successful. '
          'Vehicle ID: $vehicleId; '
          'coordinates: '
          '${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)}',
        );
      } else {
        print(
          'FleetOps GPS update failed: '
          'HTTP ${response.statusCode}',
        );
        print('Response: ${response.body}');

        // Stop if the server rejects authentication.
        if (response.statusCode == 401) {
          await FlutterForegroundTask.stopService();
        }
      }
    } catch (e) {
      // An individual GPS/network failure should not crash
      // the foreground task.
      print('FleetOps tracking error: $e');
    } finally {
      _isUpdating = false;
    }
  }

  @override
  Future<void> onDestroy(
    DateTime timestamp,
    bool isTimeout,
  ) async {
    print('FleetOps tracking service stopped.');
    _isUpdating = false;
  }

  @override
  void onReceiveData(Object data) {
    print('FleetOps received data: $data');
  }

  @override
  void onNotificationButtonPressed(String id) {
    print('FleetOps notification button pressed: $id');

    if (id == 'stop_tracking') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    print('FleetOps tracking notification pressed.');
  }

  @override
  void onNotificationDismissed() {
    print('FleetOps tracking notification dismissed.');
  }
}
