class ApiConfig {
  static const String baseUrl =
      'https://fleetops.archonnellincorporated.com/api';

  // Mobile authentication
  static const String login =
      '$baseUrl/mobile/login';

  static const String verify2FA =
      '$baseUrl/mobile/verify-2fa';

  static const String resend2FA =
      '$baseUrl/mobile/resend-2fa';

  static const String user =
      '$baseUrl/mobile/user';

  static const String logout =
      '$baseUrl/mobile/logout';

  // Fleet data
  static const String riders =
      '$baseUrl/riders';

  static String riderLocation(int riderId) {
    return '$baseUrl/riders/$riderId/location';
  }
}