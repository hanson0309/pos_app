import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'config/web_hash_route.dart';

void main() {
  // Initialize database factory for Web and Desktop
  if (kIsWeb) {
    // Use sqflite_common_ffi_web for web platform
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    // Use sqflite_common_ffi for desktop platforms (Windows, Linux, macOS)
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String _initialRoute;

  @override
  void initState() {
    super.initState();
    _initialRoute = kIsWeb
        ? AppRoutes.routeFromWebFragment()
        : AppRoutes.cashier;
    _activeWebRoute = _initialRoute;
    if (kIsWeb) {
      listenWebHashRoute(_navigateToWebRoute);
    }
  }

  String? _activeWebRoute;

  void _navigateToWebRoute(String route) {
    if (_activeWebRoute == route) return;
    _activeWebRoute = route;
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    nav.pushNamedAndRemoveUntil(route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      navigatorKey: rootNavigatorKey,
      initialRoute: _initialRoute,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
