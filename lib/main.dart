import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'config/routes.dart';
import 'config/theme.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.cashier, // Changed to cashier for development
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
