import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import '../../models/receipt.dart';
import '../../models/printer_config.dart';

/// 收据生成器
/// 根据 Receipt 模型生成 ESC/POS 打印指令
class ReceiptGenerator {
  /// 生成收据打印指令
  Future<List<int>> generateReceipt(
    Receipt receipt,
    PrinterConfig printerConfig,
  ) async {
    final paperSize = printerConfig.paperWidth == 58
        ? PaperSize.mm58
        : PaperSize.mm80;

    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    final List<int> bytes = [];

    // 初始化
    bytes.addAll(generator.reset());

    // 店铺信息
    bytes.addAll(generator.text(
      receipt.storeName,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    ));

    if (receipt.storeAddress != null) {
      bytes.addAll(generator.text(
        receipt.storeAddress!,
        styles: const PosStyles(align: PosAlign.center),
      ));
    }

    if (receipt.storePhone != null) {
      bytes.addAll(generator.text(
        'Tel: ${receipt.storePhone}',
        styles: const PosStyles(align: PosAlign.center),
      ));
    }

    if (receipt.taxNumber != null) {
      bytes.addAll(generator.text(
        'Tax No: ${receipt.taxNumber}',
        styles: const PosStyles(align: PosAlign.center),
      ));
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.emptyLines(1));

    // 交易信息
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

    if (receipt.customerName != null && receipt.customerName!.isNotEmpty) {
      bytes.addAll(generator.text(
        'Customer: ${receipt.customerName}',
        styles: const PosStyles(align: PosAlign.left),
      ));
    }

    bytes.addAll(generator.hr());

    // 商品列表表头
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
        text: 'Price',
        width: 4,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]));

    bytes.addAll(generator.hr());

    // 商品明细
    for (final item in receipt.items) {
      bytes.addAll(generator.text(
        item.name,
        styles: const PosStyles(align: PosAlign.left),
      ));

      bytes.addAll(generator.row([
        PosColumn(
          text: item.unitPrice.toStringAsFixed(2),
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: '${item.quantity}x',
          width: 2,
          styles: const PosStyles(align: PosAlign.center),
        ),
        PosColumn(
          text: 'RM ${item.lineTotal.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));

      if (item.note.isNotEmpty) {
        bytes.addAll(generator.text(
          '  Note: ${item.note}',
          styles: const PosStyles(align: PosAlign.left),
        ));
      }
    }

    bytes.addAll(generator.hr());

    // 金额汇总
    bytes.addAll(generator.row([
      PosColumn(
        text: 'Subtotal:',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: 'RM ${receipt.subtotal.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));

    if (receipt.discount > 0) {
      bytes.addAll(generator.row([
        PosColumn(
          text: 'Discount (${receipt.discountLabel}):',
          width: 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: '- RM ${receipt.discount.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    bytes.addAll(generator.row([
      PosColumn(
        text: 'Tax (${(receipt.taxRate * 100).toStringAsFixed(0)}%):',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: 'RM ${receipt.tax.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));

    bytes.addAll(generator.hr());

    // 总计
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

    // 支付信息
    bytes.addAll(generator.text(
      'Payment: ${_getPaymentMethodLabel(receipt.paymentMethod)}',
      styles: const PosStyles(align: PosAlign.left, bold: true),
    ));

    if (receipt.paymentMethod == 'cash') {
      bytes.addAll(generator.row([
        PosColumn(
          text: 'Received:',
          width: 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: 'RM ${receipt.receivedAmount.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));

      bytes.addAll(generator.row([
        PosColumn(
          text: 'Change:',
          width: 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: 'RM ${receipt.changeAmount.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.emptyLines(1));

    // 感谢语
    bytes.addAll(generator.text(
      'Thank You!',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));

    bytes.addAll(generator.text(
      'Please Come Again',
      styles: const PosStyles(align: PosAlign.center),
    ));

    bytes.addAll(generator.emptyLines(1));
    bytes.addAll(generator.hr());

    // 走纸和切纸
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return bytes;
  }

  /// 生成测试打印
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

    bytes.addAll(generator.text(
      'Printer: ${printerConfig.name}',
      styles: const PosStyles(align: PosAlign.left),
    ));

    bytes.addAll(generator.text(
      'Type: ${printerConfig.type.name}',
      styles: const PosStyles(align: PosAlign.left),
    ));

    bytes.addAll(generator.text(
      'Paper: ${printerConfig.paperWidth}mm',
      styles: const PosStyles(align: PosAlign.left),
    ));

    bytes.addAll(generator.text(
      'Time: ${_formatDateTime(DateTime.now())}',
      styles: const PosStyles(align: PosAlign.left),
    ));

    bytes.addAll(generator.hr());
    bytes.addAll(generator.emptyLines(1));

    bytes.addAll(generator.text(
      'Print Test Successful!',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    ));

    bytes.addAll(generator.emptyLines(1));
    bytes.addAll(generator.hr());
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
