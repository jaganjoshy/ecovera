class Config {
  static const String apiBaseUrl =
      'http://localhost:5000'; // Change this to your server's IP when running on a device
  static const int apiTimeout = 30000;
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
