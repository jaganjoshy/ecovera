import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  String? _currentUser;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _currentUser = _prefs.getString('current_user');
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> isLoggedIn() async {
    if (!_isInitialized) await initialize();
    return _currentUser != null;
  }

  Future<bool> signUp(String email, String password) async {
    try {
      await initialize();
      await _storage.write(key: email, value: password);
      await _prefs.setString('current_user', email);
      _currentUser = email;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error during sign up: $e');
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      await initialize();
      final storedPassword = await _storage.read(key: email);
      if (storedPassword == password) {
        await _prefs.setString('current_user', email);
        _currentUser = email;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error during sign in: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle(String email) async {
    try {
      await initialize();
      await _prefs.setString('current_user', email);
      _currentUser = email;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error during Google sign in: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await initialize();
      await _prefs.remove('current_user');
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      // For demo purposes, accept any non-empty email/password
      if (email.isNotEmpty && password.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', email);
        _currentUser = email;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signup(String email, String password) async {
    try {
      // For demo purposes, accept any non-empty email/password
      if (email.isNotEmpty && password.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', email);
        _currentUser = email;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    _currentUser = null;
    notifyListeners();
  }

  String? get currentUser => _currentUser;
}
