import 'dart:async';
import 'product_sync_service.dart';

class SyncManager {
  final ProductSyncService _productSync = ProductSyncService();
  Timer? _syncTimer;

  void startAutoSync() {
    _productSync.incrementalSync();
    _syncTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _productSync.incrementalSync(),
    );
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> manualSync() async {
    await _productSync.incrementalSync();
  }

  bool get isAutoSyncRunning => _syncTimer != null && _syncTimer!.isActive;
}
