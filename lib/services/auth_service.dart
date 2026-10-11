import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AuthService {
  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  static const String _tokenKey = 'sanctum_token';
  static const String _emailKey = 'login_email';

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

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      await _storage.write(
        key: _emailKey,
        value: email,
      );

      return data;
    }

    throw Exception(
      data['message'] ?? 'Login failed.',
    );
  }

  Future<Map<String, dynamic>> verifyTwoFactor(
    String email,
    String code,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConfig.verify2FA),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      final token = data['token'];

      if (token == null || token.toString().isEmpty) {
        throw Exception(
          'Login succeeded but no authentication token was returned.',
        );
      }

      await _storage.write(
        key: _tokenKey,
        value: token.toString(),
      );

      return data;
    }

    throw Exception(
      data['message'] ?? 'Verification failed.',
    );
  }

  Future<Map<String, dynamic>> resendTwoFactor(
    String email,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConfig.resend2FA),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Could not resend verification code.',
    );
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Not authenticated.');
    }

    final response = await http.get(
      Uri.parse(ApiConfig.user),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Could not get user information.',
    );
  }

  Future<void> logout() async {
    final token = await getToken();

    if (token != null) {
      try {
        await http.post(
          Uri.parse(ApiConfig.logout),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } finally {
        await _storage.delete(key: _tokenKey);
        await _storage.delete(key: _emailKey);
      }
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getLoginEmail() async {
    return await _storage.read(key: _emailKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'message': response.body,
      };
    } catch (_) {
      return {
        'message': response.body.isNotEmpty
            ? response.body
            : 'Unknown server error.',
      };
    }
  }
}