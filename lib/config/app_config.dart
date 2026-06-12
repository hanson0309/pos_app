import 'package:flutter/foundation.dart';

class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';

  /// E-invoice claim site (React app). Used on mobile/desktop when not using web POS.
  static const String receiptClaimBaseUrl = 'http://localhost:5173';

  /// Debug builds: on-screen receipt + virtual printer (no hardware).
  static bool get useReceiptEmulator => kDebugMode;

  /// Claim URL encoded in receipt QR.
  /// Web POS (e.g. http://localhost:62610/): same origin + hash route.
  /// Otherwise: separate frontend at [receiptClaimBaseUrl].
  static String buildReceiptClaimUrl(
    String receiptNo, {
    String? tenantId,
  }) {
    final encoded = Uri.encodeComponent(receiptNo);
    final tenantQuery = tenantId != null ? '?tenant=$tenantId' : '';

    if (kIsWeb) {
      final origin = Uri.base.origin;
      return '$origin#/receipt/$encoded$tenantQuery';
    }

    return '$receiptClaimBaseUrl/receipt/$encoded$tenantQuery';
  }

  // App Configuration
  static const String appName = 'POS App';
  static const String appVersion = '1.0.0';

  // Pairing Configuration
  static const int pairingCodeLength = 6;
  static const int pairingCodeExpiryMinutes = 15;

  // Sync Configuration
  static const int maxSyncBatchSize = 50;
  static const int syncRetryMaxAttempts = 10;
  static const Duration syncInterval = Duration(minutes: 5);

  // Database Configuration
  static const String databaseName = 'pos_app.db';
  static const int databaseVersion = 2;

  // Cache Configuration
  static const Duration cacheExpiry = Duration(hours: 24);
  static const int maxCacheSize = 500 * 1024 * 1024; // 500MB

  // Network Configuration
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
