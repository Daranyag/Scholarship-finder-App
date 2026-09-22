import 'package:flutter/material.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthProvider _authProvider = AuthProvider();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamil Nadu Scholarship Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ListenableBuilder(
        listenable: _authProvider,
        builder: (context, child) {
          switch (_authProvider.status) {
            case AuthStatus.checking:
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            case AuthStatus.authenticated:
              final isProfileComplete = _authProvider.user?['profileComplete'] == true;
              if (!isProfileComplete) {
                return ProfileScreen(
                  isInitialSetup: true,
                  authProvider: _authProvider,
                );
              }
              return HomeScreen(authProvider: _authProvider);
            case AuthStatus.unauthenticated:
              return LoginScreen(authProvider: _authProvider);
          }
        },
      ),
    );
  }
}
