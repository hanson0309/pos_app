import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'config/web_hash_route.dart';

void main() {
  // Web: FFI web factory. Desktop: FFI. Android/iOS: native sqflite (default).
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
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
