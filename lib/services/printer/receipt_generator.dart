import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:image/image.dart' as img;
import '../../models/receipt.dart';
import '../../models/printer_config.dart';
import 'receipt_qr_helper.dart';

/// Generates ESC/POS bytes for thermal receipts.
class ReceiptGenerator {
  final Dio _dio = Dio();

  Future<List<int>> generateReceipt(
    Receipt receipt,
    PrinterConfig printerConfig,
  ) async {
    final paperSize = printerConfig.paperWidth == 58
        ? PaperSize.mm58
        : PaperSize.mm80;
    final maxImageWidth = printerConfig.paperWidth == 58 ? 384 : 576;

    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    final List<int> bytes = [];

    bytes.addAll(generator.reset());

    // Company logo (optional)
    if (receipt.storeLogoUrl != null && receipt.storeLogoUrl!.isNotEmpty) {
      final logoImage = await _loadLogoImage(receipt.storeLogoUrl!, maxImageWidth);
      if (logoImage != null) {
        bytes.addAll(generator.image(logoImage, align: PosAlign.center));
        bytes.addAll(generator.emptyLines(1));
      }
    }

    // Store header
    bytes.addAll(generator.text(
      receipt.storeName,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    ));

    if (receipt.storeAddress != null && receipt.storeAddress!.isNotEmpty) {
      bytes.addAll(generator.text(
        receipt.storeAddress!,
        styles: const PosStyles(align: PosAlign.center),
      ));
    }

    if (receipt.storePhone != null && receipt.storePhone!.isNotEmpty) {
      bytes.addAll(generator.text(
        'Tel: ${receipt.storePhone}',
        styles: const PosStyles(align: PosAlign.center),
      ));
    }

    if (receipt.taxNumber != null && receipt.taxNumber!.isNotEmpty) {
      bytes.addAll(generator.text(
        'SST/TIN: ${receipt.taxNumber}',
        styles: const PosStyles(align: PosAlign.center),
      ));
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.emptyLines(1));

    bytes.addAll(generator.text(
      'Receipt: ${receipt.transactionNumber}',
      styles: const PosStyles(align: PosAlign.left),
    ));
    bytes.addAll(generator.text(
      'Date: ${_formatDateTime(receipt.transactionDate)}',
      styles: const PosStyles(align: PosAlign.left),
    ));

    if (receipt.cashierName != null && receipt.cashierName!.isNotEmpty) {
      bytes.addAll(generator.text(
        'Cashier: ${receipt.cashierName}',
        styles: const PosStyles(align: PosAlign.left),
      ));
    }

    bytes.addAll(generator.hr());

    // Items header
    bytes.addAll(generator.row([
      PosColumn(
        text: 'Item',
        width: 6,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: 'Qty',
        width: 2,
        styles: const PosStyles(bold: true, align: PosAlign.center),
      ),
      PosColumn(
        text: 'Unit',
        width: 2,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
      PosColumn(
        text: 'Total',
        width: 2,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]));
    bytes.addAll(generator.hr());

    for (final item in receipt.items) {
      bytes.addAll(generator.text(
        item.name,
        styles: const PosStyles(align: PosAlign.left),
      ));
      bytes.addAll(generator.row([
        PosColumn(text: '', width: 6),
        PosColumn(
          text: '${item.quantity}',
          width: 2,
          styles: const PosStyles(align: PosAlign.center),
        ),
        PosColumn(
          text: item.unitPrice.toStringAsFixed(2),
          width: 2,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: item.lineTotal.toStringAsFixed(2),
          width: 2,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
      if (item.note.isNotEmpty) {
        bytes.addAll(generator.text('  ${item.note}'));
      }
    }

    bytes.addAll(generator.hr());

    bytes.addAll(_summaryRow(generator, 'Subtotal:', receipt.subtotal));

    if (receipt.discount > 0) {
      bytes.addAll(_summaryRow(
        generator,
        'Discount (${receipt.discountLabel}):',
        -receipt.discount,
      ));
    }

    if (receipt.serviceTax > 0) {
      final label = receipt.serviceTaxRate > 0
          ? 'Service Tax (${receipt.serviceTaxRate.toStringAsFixed(0)}%):'
          : 'Service Tax:';
      bytes.addAll(_summaryRow(generator, label, receipt.serviceTax));
    }

    bytes.addAll(_summaryRow(
      generator,
      'Tax (${receipt.taxRate.toStringAsFixed(0)}%):',
      receipt.tax,
    ));

    bytes.addAll(generator.hr());

    bytes.addAll(generator.row([
      PosColumn(
        text: 'TOTAL:',
        width: 8,
        styles: const PosStyles(
          align: PosAlign.left,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
      PosColumn(
        text: 'RM ${receipt.total.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    ]));

    bytes.addAll(generator.hr());

    bytes.addAll(generator.text(
      'Payment: ${_getPaymentMethodLabel(receipt.paymentMethod)}',
      styles: const PosStyles(bold: true),
    ));

    if (receipt.paymentMethod == 'cash') {
      bytes.addAll(_summaryRow(generator, 'Received:', receipt.receivedAmount));
      bytes.addAll(_summaryRow(generator, 'Change:', receipt.changeAmount));
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.emptyLines(1));

    bytes.addAll(generator.text(
      'Thank You!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    ));

    // E-invoice claim QR
    if (receipt.einvoiceClaimUrl != null &&
        receipt.einvoiceClaimUrl!.isNotEmpty) {
      bytes.addAll(generator.emptyLines(1));
      bytes.addAll(generator.text(
        'Scan to request e-Invoice',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ));
      bytes.addAll(generator.text(
        receipt.transactionNumber,
        styles: const PosStyles(align: PosAlign.center),
      ));

      final qrImage = ReceiptQrHelper.generateQrImage(
        receipt.einvoiceClaimUrl!,
        size: printerConfig.paperWidth == 58 ? 160 : 200,
      );
      bytes.addAll(generator.image(qrImage, align: PosAlign.center));
      bytes.addAll(generator.text(
        receipt.einvoiceClaimUrl!,
        styles: const PosStyles(align: PosAlign.center),
      ));
    }

    bytes.addAll(generator.emptyLines(1));
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return bytes;
  }

  List<int> _summaryRow(Generator generator, String label, double amount) {
    final prefix = amount < 0 ? '- RM ' : 'RM ';
    return generator.row([
      PosColumn(text: label, width: 8),
      PosColumn(
        text: '$prefix${amount.abs().toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
  }

  Future<img.Image?> _loadLogoImage(String url, int maxWidth) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data ?? []);
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      if (decoded.width > maxWidth) {
        return img.copyResize(decoded, width: maxWidth);
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Future<List<int>> generateTestReceipt(PrinterConfig printerConfig) async {
    final paperSize = printerConfig.paperWidth == 58
        ? PaperSize.mm58
        : PaperSize.mm80;

    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    final List<int> bytes = [];

    bytes.addAll(generator.reset());
    bytes.addAll(generator.text(
      'TEST PRINT',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    ));
    bytes.addAll(generator.emptyLines(1));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text('Printer: ${printerConfig.name}'));
    bytes.addAll(generator.text('Type: ${printerConfig.type.name}'));
    bytes.addAll(generator.text('Address: ${printerConfig.address}'));
    bytes.addAll(generator.text('Paper: ${printerConfig.paperWidth}mm'));
    bytes.addAll(generator.text('Time: ${_formatDateTime(DateTime.now())}'));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text(
      'Network test OK',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    ));
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return bytes;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'ewallet':
        return 'E-Wallet';
      default:
        return method;
    }
  }
}
