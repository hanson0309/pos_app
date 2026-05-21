import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import '../printer_service.dart';

/// ESC/POS 指令生成器
/// 用于生成标准的 ESC/POS 打印指令
class EscPosGenerator {
  /// 纸张宽度（字符数）
  final PaperSize paperSize;

  /// 字符编码
  final CapabilityProfile profile;

  EscPosGenerator({
    this.paperSize = PaperSize.mm58,
    CapabilityProfile? profile,
  }) : profile = profile ?? (CapabilityProfile.load() as CapabilityProfile);

  /// 生成收据打印指令
  ///
  /// 参数:
  /// - [transactionNumber]: 交易单号
  /// - [transactionDate]: 交易日期时间
  /// - [items]: 商品列表
  /// - [subtotal]: 小计金额
  /// - [discount]: 折扣金额
  /// - [discountLabel]: 折扣标签
  /// - [tax]: 税额
  /// - [total]: 总金额
  /// - [paymentMethod]: 支付方式
  /// - [receivedAmount]: 收款金额（现金支付时）
  /// - [changeAmount]: 找零金额（现金支付时）
  /// - [customerName]: 客户名称（可选）
  /// - [cashierName]: 收银员名称（可选）
  ///
  /// 返回: ESC/POS 指令字节数组
  Future<Uint8List> generateReceipt({
    required String transactionNumber,
    required DateTime transactionDate,
    required List<ReceiptItem> items,
    required double subtotal,
    required double discount,
    required String discountLabel,
    required double tax,
    required double total,
    required String paymentMethod,
    required double receivedAmount,
    required double changeAmount,
    String? customerName,
    String? cashierName,
  }) async {
    final Generator generator = Generator(paperSize, profile);
    final List<int> bytes = [];

    // 初始化打印机
    bytes.addAll(generator.reset());

    // ========== 店铺信息 ==========
    bytes.addAll(generator.text(
      'POS SYSTEM',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    ));

    bytes.addAll(generator.text(
      'Malaysia E-Invoice',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    ));

    bytes.addAll(generator.hr());
    bytes.addAll(generator.emptyLines(1));

    // ========== 交易信息 ==========
    bytes.addAll(generator.text(
      'Receipt: $transactionNumber',
      styles: const PosStyles(align: PosAlign.left),
    ));

    bytes.addAll(generator.text(
      'Date: ${_formatDateTime(transactionDate)}',
      styles: const PosStyles(align: PosAlign.left),
    ));

    if (cashierName != null && cashierName.isNotEmpty) {
      bytes.addAll(generator.text(
        'Cashier: $cashierName',
        styles: const PosStyles(align: PosAlign.left),
      ));
    }

    if (customerName != null && customerName.isNotEmpty) {
      bytes.addAll(generator.text(
        'Customer: $customerName',
        styles: const PosStyles(align: PosAlign.left),
      ));
    }

    bytes.addAll(generator.hr());

    // ========== 商品列表 ==========
    // 表头
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
    for (final item in items) {
      // 商品名称（可能需要换行）
      bytes.addAll(generator.text(
        item.name,
        styles: const PosStyles(align: PosAlign.left),
      ));

      // 数量和价格
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

      // 备注（如果有）
      if (item.note.isNotEmpty) {
        bytes.addAll(generator.text(
          '  Note: ${item.note}',
          styles: const PosStyles(align: PosAlign.left),
        ));
      }
    }

    bytes.addAll(generator.hr());

    // ========== 金额汇总 ==========
    // 小计
    bytes.addAll(generator.row([
      PosColumn(
        text: 'Subtotal:',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: 'RM ${subtotal.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));

    // 折扣（如果有）
    if (discount > 0) {
      bytes.addAll(generator.row([
        PosColumn(
          text: 'Discount ($discountLabel):',
          width: 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: '- RM ${discount.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    // 税额
    bytes.addAll(generator.row([
      PosColumn(
        text: 'Tax (6%):',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: 'RM ${tax.toStringAsFixed(2)}',
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
        text: 'RM ${total.toStringAsFixed(2)}',
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

    // ========== 支付信息 ==========
    bytes.addAll(generator.text(
      'Payment: ${_getPaymentMethodLabel(paymentMethod)}',
      styles: const PosStyles(align: PosAlign.left, bold: true),
    ));

    // 现金支付显示收款和找零
    if (paymentMethod == 'cash') {
      bytes.addAll(generator.row([
        PosColumn(
          text: 'Received:',
          width: 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: 'RM ${receivedAmount.toStringAsFixed(2)}',
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
          text: 'RM ${changeAmount.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.emptyLines(1));

    // ========== 感谢语 ==========
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
      styles: const PosStyles(
        align: PosAlign.center,
      ),
    ));

    bytes.addAll(generator.emptyLines(1));
    bytes.addAll(generator.hr());

    // ========== 走纸和切纸 ==========
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return Uint8List.fromList(bytes);
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 获取支付方式标签
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
