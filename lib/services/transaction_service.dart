import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/transaction.dart';
import '../models/invoice.dart';
import '../utils/constants.dart';
import 'api/endpoints.dart';
import 'database/database_service.dart';

class TransactionService {
  static final TransactionService instance = TransactionService._init();
  TransactionService._init();

  final _invoiceApi = InvoiceApi();
  final _databaseService = DatabaseService.instance;
  final _storage = const FlutterSecureStorage();
  final _uuid = const Uuid();

  /// Process payment and create invoice
  /// This is called when payment is completed
  Future<TransactionResult> processPayment({
    required List<TransactionItem> items,
    String? customerId,
    required double subtotal,
    required double taxAmount,
    required double totalAmount,
    required String paymentMethod,
    String invoiceType = '01', // Default: Standard invoice (B2C without customer = simplified)
  }) async {
    try {
      // Get tenant_id, cashier_id, and device_id from secure storage
      final tenantId = await _storage.read(key: Constants.keyTenantId);
      final userId = await _storage.read(key: Constants.keyUserId);
      final deviceId = await _storage.read(key: Constants.keyDeviceId);

      if (tenantId == null || deviceId == null) {
        return TransactionResult(
          success: false,
          error: 'Device not paired. Please pair your device first.',
        );
      }

      // Use userId as cashier_id, fallback to 'unknown' if not available
      final cashierId = userId ?? 'unknown';

      // 1. Generate transaction ID and number
      final transactionId = _uuid.v4();
      final transactionNumber = _generateTransactionNumber();
      final now = DateTime.now();

      // 2. Create POS transaction
      final transaction = PosTransaction(
        transactionId: transactionId,
        tenantId: tenantId,
        transactionNumber: transactionNumber,
        transactionDate: now,
        cashierId: cashierId,
        customerId: customerId,
        items: items,
        subtotal: subtotal,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        paymentStatus: 'paid',
        deviceId: await _getDeviceId(),
        createdAt: now,
      );

      // 3. Save transaction to local database (skip on Web)
      if (!kIsWeb) {
        try {
          await _databaseService.insertTransaction(transaction);
        } catch (e) {
          print('Warning: Failed to save to local database: $e');
          // Continue anyway - we'll sync to server
        }
      }

      // 4. Create invoice data
      final invoiceItems = items.map((item) => InvoiceItem(
        productId: item.productId,
        description: item.description,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        taxType: item.taxType,
        taxRate: item.taxRate,
        taxAmount: item.taxAmount,
        lineTotal: item.lineTotal,
      )).toList();

      final invoice = Invoice.fromTransaction(
        transactionId: transactionId,
        transactionNumber: transactionNumber,
        invoiceType: invoiceType,
        customerId: customerId,
        issueDate: now,
        items: invoiceItems,
        paymentMethod: paymentMethod,
        subtotal: subtotal,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
      );

      // 5. Try to sync immediately (create invoice on backend)
      String? invoiceId;
      bool syncSuccess = false;

      try {
        final invoiceJson = invoice.toJson();

        // Remove null values to avoid backend validation errors
        invoiceJson.removeWhere((key, value) => value == null);

        final result = await _invoiceApi.createInvoice(invoiceJson);
        invoiceId = result['invoice_id'];
        syncSuccess = true;

        // Update transaction with invoice ID (skip on Web)
        if (!kIsWeb) {
          try {
            final updatedTransaction = transaction.copyWith(
              invoiceId: invoiceId,
              syncedAt: DateTime.now(),
            );
            await _databaseService.updateTransaction(updatedTransaction);
          } catch (e) {
            print('Warning: Failed to update local database: $e');
          }
        }
      } catch (e) {
        // If sync fails, add to sync queue for later (skip on Web)
        print('Failed to sync invoice immediately: $e');
        if (!kIsWeb) {
          try {
            await _addToSyncQueue(transaction, invoice);
          } catch (e) {
            print('Warning: Failed to add to sync queue: $e');
          }
        }
      }

      return TransactionResult(
        success: true,
        transaction: transaction,
        invoiceId: invoiceId,
        syncedImmediately: syncSuccess,
      );
    } catch (e) {
      print('Error processing payment: $e');
      return TransactionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Generate transaction number (format: TXN-YYYYMMDD-XXXXXX)
  String _generateTransactionNumber() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomStr = now.millisecondsSinceEpoch.toString().substring(7);
    return 'TXN-$dateStr-$randomStr';
  }

  /// Get device ID from secure storage
  Future<String> _getDeviceId() async {
    final deviceId = await _storage.read(key: Constants.keyDeviceId);
    return deviceId ?? 'unknown';
  }

  /// Get tenant ID from secure storage
  Future<String?> _getTenantId() async {
    return await _storage.read(key: Constants.keyTenantId);
  }

  /// Get user/cashier ID from secure storage
  Future<String?> _getUserId() async {
    return await _storage.read(key: Constants.keyUserId);
  }

  /// Add transaction and invoice to sync queue
  Future<void> _addToSyncQueue(PosTransaction transaction, Invoice invoice) async {
    await _databaseService.addToSyncQueue(
      entityType: 'transaction_with_invoice',
      action: 'create',
      payload: {
        'transaction': transaction.toJson(),
        'invoice': invoice.toJson(),
      },
    );
  }

  /// Retry syncing failed transactions
  Future<void> retrySyncQueue() async {
    // Skip on Web (no local database)
    if (kIsWeb) {
      print('Sync queue not available on Web platform');
      return;
    }

    try {
      final pendingItems = await _databaseService.getPendingSyncItems();

    for (final item in pendingItems) {
      try {
        if (item['entity_type'] == 'transaction_with_invoice') {
          final payload = item['payload_json'];
          final invoiceData = payload['invoice'];

          // Try to create invoice
          final result = await _invoiceApi.createInvoice(invoiceData);
          final invoiceId = result['invoice_id'];

          // Update transaction with invoice ID
          final transactionData = payload['transaction'];
          final transaction = PosTransaction.fromJson(transactionData);
          final updatedTransaction = transaction.copyWith(
            invoiceId: invoiceId,
            syncedAt: DateTime.now(),
          );
          await _databaseService.updateTransaction(updatedTransaction);

          // Mark sync item as success
          await _databaseService.markSyncItemSuccess(item['id']);
        }
      } catch (e) {
        print('Failed to sync item ${item['id']}: $e');
        await _databaseService.incrementSyncRetry(item['id']);
      }
    }
    } catch (e) {
      print('Error in retrySyncQueue: $e');
    }
  }
}

class TransactionResult {
  final bool success;
  final PosTransaction? transaction;
  final String? invoiceId;
  final bool syncedImmediately;
  final String? error;

  TransactionResult({
    required this.success,
    this.transaction,
    this.invoiceId,
    this.syncedImmediately = false,
    this.error,
  });
}
