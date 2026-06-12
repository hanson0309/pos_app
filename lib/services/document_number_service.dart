import 'package:shared_preferences/shared_preferences.dart';
import 'api/endpoints.dart';

/// Allocates sequential INV numbers shared with manual invoices (INV-YYYYMM-0001 … 9999).
/// POS receipt number, transaction number, and invoice_number are the same value.
class DocumentNumberService {
  static final DocumentNumberService instance = DocumentNumberService._();
  DocumentNumberService._();

  static const _localSeqPrefix = 'inv_seq_';
  final InvoiceApi _invoiceApi = InvoiceApi();

  /// INV-YYYYMM-#### — next number from server, or local counter when offline.
  Future<String> allocateInvoiceNumber() async {
    try {
      final result = await _invoiceApi.getNextInvoiceNumber();
      final number = result['transaction_number'] as String? ??
          result['invoice_number'] as String?;
      if (number != null && number.isNotEmpty) {
        return number;
      }
    } catch (e) {
      // Fall back to local sequence when offline
    }
    return _allocateLocal();
  }

  Future<String> _allocateLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final period = '${now.year}${now.month.toString().padLeft(2, '0')}';
    final key = '$_localSeqPrefix$period';
    final current = prefs.getInt(key) ?? 0;
    if (current >= 9999) {
      throw Exception('INV number limit reached for $period (max 9999)');
    }
    final next = current + 1;
    await prefs.setInt(key, next);
    return 'INV-$period-${next.toString().padLeft(4, '0')}';
  }
}
