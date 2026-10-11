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