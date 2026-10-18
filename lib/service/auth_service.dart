import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  Future<bool> register(String email, String password) async {
    await _storage.write(key: email, value: password);
    return true; // Simulate success (replace with real API call)
  }

  Future<bool> login(String email, String password) async {
    String? storedPassword = await _storage.read(key: email);
    return storedPassword ==
        password; // Simulate login (replace with real API call)
  }
}
