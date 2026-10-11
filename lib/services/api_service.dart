
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Login failed: ${response.body}',
    );
  }

  Future<List<dynamic>> getRiders() async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse(ApiConfig.riders),
      headers: {
        'Accept': 'application/json',
        if (token != null)
          'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to load riders: ${response.body}',
    );
  }

  // Load active dispatches assigned to the logged-in driver.
  Future<List<dynamic>> getMyActiveDispatches() async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Please log in again to load dispatches.',
      );
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/mobile/dispatches',
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};
    } catch (_) {
      data = <String, dynamic>{};
    }

    if (response.statusCode == 200 &&
        data['success'] == true) {
      final dispatches = data['dispatches'];

      if (dispatches is List) {
        return dispatches;
      }

      throw Exception(
        'The server returned an invalid dispatch list.',
      );
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Your session expired. Please log in again.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        data['error'] ??
            'No driver profile is linked to this account.',
      );
    }

    throw Exception(
      data['error'] ??
          data['message'] ??
          'Failed to load dispatches '
              '(${response.statusCode}).',
    );
  }

  Future<void> updateLocation(
    int riderId,
    double latitude,
    double longitude,
  ) async {
    final token = await _authService.getToken();

    final response = await http.post(
      Uri.parse(
        ApiConfig.riderLocation(riderId),
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null)
          'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update location: ${response.body}',
      );
    }
  }
}
