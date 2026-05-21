class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';

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
  static const int databaseVersion = 3;

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
