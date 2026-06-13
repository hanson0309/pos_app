import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../config/navigate_receipt_claim.dart';
import '../../../models/receipt.dart';

/// On-screen thermal receipt + e-invoice QR at bottom of same slip.
class ReceiptEmulatorPreviewDialog extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback? onPrintToEmulator;

  const ReceiptEmulatorPreviewDialog({
    super.key,
    required this.receipt,
    this.onPrintToEmulator,
  });

  static Future<void> show(
    BuildContext context, {
    required Receipt receipt,
    VoidCallback? onPrintToEmulator,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ReceiptEmulatorPreviewDialog(
        receipt: receipt,
        onPrintToEmulator: onPrintToEmulator,
      ),
    );
  }

  Future<void> _openClaimUrl(BuildContext context) async {
    final url = receipt.einvoiceClaimUrl;
    if (url == null || url.isEmpty) return;
    await openReceiptClaimUrl(context, url);
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4F46E5);
    const text = Color(0xFF111827);
    const muted = Color(0xFF6B7280);
    const border = Color(0xFFE5E7EB);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 440, maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long, color: primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt preview',
                          style: TextStyle(
                            color: text,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Thermal slip with e-Invoice QR',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: muted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _ReceiptPaper(receipt: receipt),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: border)),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (receipt.einvoiceClaimUrl != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openClaimUrl(context),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Open claim page'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  if (onPrintToEmulator != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onPrintToEmulator,
                        icon: const Icon(Icons.save_alt, size: 18),
                        label: const Text('Save receipt'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: text,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ReceiptPaper extends StatelessWidget {
  final Receipt receipt;

  const _ReceiptPaper({required this.receipt});

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 13, color: Colors.black87, height: 1.35);
    const bold = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: Colors.black,
      height: 1.35,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          receipt.storeName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
        ),
        if (receipt.storeAddress != null && receipt.storeAddress!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(receipt.storeAddress!, textAlign: TextAlign.center, style: textStyle),
        ],
        if (receipt.storePhone != null && receipt.storePhone!.isNotEmpty)
          Text('Tel: ${receipt.storePhone}', textAlign: TextAlign.center, style: textStyle),
        if (receipt.taxNumber != null && receipt.taxNumber!.isNotEmpty)
          Text('SST/TIN: ${receipt.taxNumber}', textAlign: TextAlign.center, style: textStyle),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(height: 1, color: Color(0xFF9CA3AF)),
        ),
        _row('Receipt', receipt.transactionNumber),
        _row('Date', _fmt(receipt.transactionDate)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: Color(0xFFD1D5DB)),
        ),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FixedColumnWidth(28),
            2: FixedColumnWidth(44),
            3: FixedColumnWidth(44),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: [
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('Item', style: bold),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('Qty', style: bold, textAlign: TextAlign.center),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('Unit', style: bold, textAlign: TextAlign.right),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('Total', style: bold, textAlign: TextAlign.right),
                ),
              ],
            ),
            ...receipt.items.map(
              (item) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, right: 6),
                    child: Text(
                      item.name,
                      style: textStyle,
                      softWrap: true,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                      style: textStyle,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      item.unitPrice.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: textStyle,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      item.lineTotal.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: textStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: Color(0xFFD1D5DB)),
        ),
        _row('Subtotal', 'RM ${receipt.subtotal.toStringAsFixed(2)}'),
        if (receipt.discount > 0)
          _row('Discount', '- RM ${receipt.discount.toStringAsFixed(2)}'),
        if (receipt.serviceTax > 0)
          _row('Service tax', 'RM ${receipt.serviceTax.toStringAsFixed(2)}'),
        _row('Tax (${receipt.taxRate.toStringAsFixed(0)}%)', 'RM ${receipt.tax.toStringAsFixed(2)}'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: Colors.black),
        ),
        _row('TOTAL', 'RM ${receipt.total.toStringAsFixed(2)}', bold: true),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: Color(0xFFD1D5DB)),
        ),
        _row('Payment', _payLabel(receipt.paymentMethod)),
        if (receipt.paymentMethod == 'cash') ...[
          _row('Received', 'RM ${receipt.receivedAmount.toStringAsFixed(2)}'),
          _row('Change', 'RM ${receipt.changeAmount.toStringAsFixed(2)}'),
        ],
        const SizedBox(height: 14),
        const Text('Thank you!', textAlign: TextAlign.center, style: bold),
        if (receipt.einvoiceClaimUrl != null &&
            receipt.einvoiceClaimUrl!.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFF9CA3AF)),
          ),
          const Text(
            'Scan to request e-Invoice',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: receipt.einvoiceClaimUrl!,
                size: 148,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    const normal = TextStyle(fontSize: 13, color: Colors.black87);
    const emphasized = TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: bold ? emphasized : normal),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: bold ? emphasized : normal,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _payLabel(String m) {
    switch (m) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'ewallet':
        return 'E-Wallet';
      default:
        return m;
    }
  }
}
