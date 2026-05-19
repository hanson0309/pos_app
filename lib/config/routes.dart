import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/pairing/pairing_screen.dart';
import '../screens/login/login_screen.dart';

class AppRoutes {
  // Route Names
  static const String splash = '/';
  static const String pairing = '/pairing';
  static const String login = '/login';
  static const String pinLogin = '/pin-login';
  static const String home = '/home';
  static const String cashier = '/cashier';
  static const String inventory = '/inventory';
  static const String inventoryDetail = '/inventory/detail';
  static const String appointments = '/appointments';
  static const String appointmentDetail = '/appointments/detail';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String sync = '/sync';
  static const String products = '/products';
  static const String productDetail = '/products/detail';
  static const String customers = '/customers';
  static const String customerDetail = '/customers/detail';

  // Route Generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case pairing:
        return MaterialPageRoute(
          builder: (_) => const PairingScreen(),
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Home Screen')),
          ),
        );

      case cashier:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Cashier Screen')),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
