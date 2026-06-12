import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'web_hash_route.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/pairing/pairing_screen.dart';
import '../screens/cashier/cashier_screen.dart';
import '../screens/receipt/receipt_claim_screen.dart';

class AppRoutes {
  // Route Names
  static const String splash = '/';
  static const String pairing = '/pairing';
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
  static const String receiptClaimPrefix = '/receipt/';

  /// Current route from browser hash (web only), else [cashier].
  static String routeFromWebFragment() {
    if (!kIsWeb) return cashier;
    return webHashToRoute();
  }

  /// Web hash URL: `#/receipt/INV-202606-0001?tenant=...`
  static ({String receiptNo, String? tenantId})? parseReceiptClaimRoute(
    String? routeName,
  ) {
    if (routeName == null || !routeName.startsWith(receiptClaimPrefix)) {
      return null;
    }
    final uri = Uri.parse('http://local$routeName');
    final segments = uri.pathSegments;
    if (segments.length < 2 || segments[0] != 'receipt') return null;
    return (
      receiptNo: Uri.decodeComponent(segments[1]),
      tenantId: uri.queryParameters['tenant'],
    );
  }

  // Route Generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final claim = parseReceiptClaimRoute(settings.name);
    if (claim != null) {
      return MaterialPageRoute(
        builder: (_) => ReceiptClaimScreen(
          receiptNo: claim.receiptNo,
          tenantId: claim.tenantId,
        ),
      );
    }

    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case pairing:
        return MaterialPageRoute(
          builder: (_) => const PairingScreen(),
        );

      case cashier:
        return MaterialPageRoute(
          builder: (_) => const CashierScreen(),
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
