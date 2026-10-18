// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../lib/screens/splash_screen.dart';
import '../lib/screens/login_screen.dart';
import '../lib/services/auth_service.dart';

void main() {
  testWidgets('App should show splash screen initially',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>(
        create: (_) => MockAuthService(),
        child: const MaterialApp(
          home: SplashScreen(isTest: true),
        ),
      ),
    );

    expect(find.text('Ecovera'), findsOneWidget);
    expect(find.text('Smart Soil Analysis'), findsOneWidget);
    expect(find.byIcon(Icons.eco), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Login screen should show all required elements',
      (WidgetTester tester) async {
    final mockAuthService = MockAuthService();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>(
        create: (_) => mockAuthService,
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pump();

    // Check for main UI elements
    expect(find.text('Welcome to Ecovera'), findsOneWidget);
    expect(find.text('Smart Soil Analysis'), findsOneWidget);
    expect(find.byIcon(Icons.eco), findsOneWidget);

    // Check for form fields
    expect(find.byIcon(Icons.email), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}

class MockAuthService extends AuthService {
  bool _isSignedIn = false;

  @override
  Future<bool> isLoggedIn() async {
    return _isSignedIn;
  }

  @override
  Future<bool> signIn(String email, String password) async {
    _isSignedIn = true;
    return true;
  }

  @override
  Future<bool> signUp(String email, String password) async {
    _isSignedIn = true;
    return true;
  }

  @override
  Future<bool> signInWithGoogle(String email) async {
    _isSignedIn = true;
    return true;
  }

  @override
  Future<void> initialize() async {
    // Mock initialization
  }
}
