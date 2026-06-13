import 'package:flutter/foundation.dart';

class AppConfig {
  /// Your Vercel deployment (API at `/api/v1`, Flutter web at site root for claim QR).
  static const String publicBaseUrl =
      'https://backend-kappa-five-21.vercel.app';

  static const String apiBaseUrl = '$publicBaseUrl/api/v1';

  /// Where customers open the claim page after scanning QR (Flutter web on same domain).
  /// Override at build: `--dart-define=CLAIM_BASE_URL=https://...`
  static const String receiptClaimBaseUrl = String.fromEnvironment(
    'CLAIM_BASE_URL',
    defaultValue: publicBaseUrl,
  );

  /// Debug builds: on-screen receipt + virtual printer (no hardware).
  static bool get useReceiptEmulator => kDebugMode;

  /// Claim URL encoded in receipt QR (preview, ESC/POS, etc.).
  /// Customer scans → opens in **phone browser** → claim page calls [apiBaseUrl].
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

    // Flutter web uses hash routes — required for direct browser open after QR scan.
    return '$receiptClaimBaseUrl#/receipt/$encoded$tenantQuery';
  }

  /// BLE TSPL printers (MTU 100) allow ~97 bytes per write; QRCODE must fit in one packet.
  static const int maxTsplQrLineLength = 94;

  /// Claim URL for label QR — omits tenant query when needed to stay under [maxTsplQrLineLength].
  static String buildReceiptClaimUrlForQr(
    String receiptNo, {
    String? tenantId,
  }) {
    final encoded = Uri.encodeComponent(receiptNo);
    final base = kIsWeb
        ? '${Uri.base.origin}#/receipt/$encoded'
        : '$receiptClaimBaseUrl#/receipt/$encoded';

    if (tenantId != null) {
      final withTenant = '$base?tenant=$tenantId';
      if (_qrLineLength(withTenant) <= maxTsplQrLineLength) {
        return withTenant;
      }
    }
    return base;
  }

  static int _qrLineLength(String url, {int x = 120, int y = 400}) {
    return 'QRCODE $x,$y,H,4,A,0,"$url"'.length;
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
  static const int databaseVersion = 4;

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
