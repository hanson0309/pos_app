import 'api_service.dart';

class DeviceApi {
  final ApiService _apiService = ApiService.instance;

  // Pair device with pairing code
  Future<Map<String, dynamic>> pairDevice({
    required String pairingCode,
    required Map<String, dynamic> deviceInfo,
  }) async {
    final response = await _apiService.post(
      '/pos/devices/pair',
      data: {
        'pairing_code': pairingCode,
        'device_info': deviceInfo,
      },
    );

    // 返回整个 data 对象
    return Map<String, dynamic>.from(response.data);
  }

  // Update device last sync time
  Future<void> updateLastSync(String deviceId) async {
    await _apiService.put(
      '/pos/devices/$deviceId',
      data: {
        'last_sync_at': DateTime.now().toIso8601String(),
      },
    );
  }
}

class TransactionApi {
  final ApiService _apiService = ApiService.instance;

  // Sync transactions (batch)
  Future<List<Map<String, dynamic>>> syncTransactions(
    List<Map<String, dynamic>> transactions,
  ) async {
    final response = await _apiService.post(
      '/pos/transactions',
      data: {
        'transactions': transactions,
      },
    );

    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  // Get transactions
  Future<List<Map<String, dynamic>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) async {
    final response = await _apiService.get(
      '/pos/transactions',
      queryParameters: {
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    );

    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  // Process refund
  Future<Map<String, dynamic>> processRefund(String transactionId) async {
    final response = await _apiService.post(
      '/pos/transactions/$transactionId/refund',
    );

    return response.data['data'];
  }
}

class ProductApi {
  final ApiService _apiService = ApiService.instance;

  // Get products
  Future<List<Map<String, dynamic>>> getProducts({
    String? search,
    String? barcode,
    int? page,
    int? limit,
  }) async {
    final response = await _apiService.get(
      '/pos/products',
      queryParameters: {
        if (search != null) 'search': search,
        if (barcode != null) 'barcode': barcode,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    );

    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  // Create product
  Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> productData,
  ) async {
    final response = await _apiService.post(
      '/pos/products',
      data: productData,
    );

    return response.data['data'];
  }

  // Update product
  Future<Map<String, dynamic>> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    final response = await _apiService.put(
      '/pos/products/$productId',
      data: productData,
    );

    return response.data['data'];
  }
}

class InventoryApi {
  final ApiService _apiService = ApiService.instance;

  // Adjust inventory
  Future<Map<String, dynamic>> adjustInventory({
    required String productId,
    required int quantityChange,
    required String transactionType,
    String? notes,
  }) async {
    final response = await _apiService.post(
      '/pos/inventory/adjust',
      data: {
        'product_id': productId,
        'quantity_change': quantityChange,
        'transaction_type': transactionType,
        'notes': notes,
      },
    );

    return response.data['data'];
  }

  // Restock inventory
  Future<Map<String, dynamic>> restockInventory({
    required String productId,
    required int quantity,
    String? batchNumber,
    DateTime? expiryDate,
  }) async {
    final response = await _apiService.post(
      '/pos/inventory/restock',
      data: {
        'product_id': productId,
        'quantity': quantity,
        if (batchNumber != null) 'batch_number': batchNumber,
        if (expiryDate != null) 'expiry_date': expiryDate.toIso8601String(),
      },
    );

    return response.data['data'];
  }

  // Get inventory logs
  Future<List<Map<String, dynamic>>> getInventoryLogs({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _apiService.get(
      '/pos/inventory/logs',
      queryParameters: {
        if (productId != null) 'product_id': productId,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      },
    );

    return List<Map<String, dynamic>>.from(response.data['data']);
  }
}

class SettingsApi {
  final ApiService _apiService = ApiService.instance;

  // Get POS settings
  Future<Map<String, dynamic>> getSettings() async {
    final response = await _apiService.get('/pos/settings');
    return response.data['data'];
  }

  // Update POS settings
  Future<Map<String, dynamic>> updateSettings(
    Map<String, dynamic> settings,
  ) async {
    final response = await _apiService.put(
      '/pos/settings',
      data: settings,
    );

    return response.data['data'];
  }
}
