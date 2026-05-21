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
  Future<Map<String, dynamic>> getProducts({
    String? search,
    String? barcode,
    DateTime? updatedSince,
    int? page,
    int? limit,
  }) async {
    final response = await _apiService.get(
      '/pos/products',
      queryParameters: {
        if (search != null) 'search': search,
        if (barcode != null) 'barcode': barcode,
        if (updatedSince != null) 'updated_since': updatedSince.toIso8601String(),
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    );

    return {
      'data': response.data['data'] ?? [],
      'pagination': response.data['pagination'] ?? {},
    };
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

class InvoiceApi {
  final ApiService _apiService = ApiService.instance;

  // Create invoice from POS transaction
  // Uses the general invoice endpoint with source: 'pos'
  Future<Map<String, dynamic>> createInvoice(
    Map<String, dynamic> invoiceData,
  ) async {
    final response = await _apiService.post(
      '/invoices',  // Changed from /pos/invoices to /invoices
      data: invoiceData,
    );

    // Handle different response structures
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;

      // If response has 'data' wrapper
      if (data.containsKey('data')) {
        return Map<String, dynamic>.from(data['data']);
      }

      // If response is direct invoice object (has _id)
      if (data.containsKey('_id')) {
        return {
          'invoice_id': data['_id'],
          'invoice_number': data['invoice_number'],
          'status': data['status'],
          'created_at': data['created_at'],
        };
      }

      // Otherwise return as is
      return data;
    }

    throw Exception('Invalid response format');
  }

  // Get invoice by ID
  Future<Map<String, dynamic>> getInvoice(String invoiceId) async {
    final response = await _apiService.get('/invoices/$invoiceId');
    return response.data['data'];
  }

  // Get invoices list
  Future<List<Map<String, dynamic>>> getInvoices({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? page,
    int? limit,
  }) async {
    final response = await _apiService.get(
      '/invoices',
      queryParameters: {
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (status != null) 'status': status,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    );

    return List<Map<String, dynamic>>.from(response.data['data']);
  }
}
