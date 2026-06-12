import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/printer_config.dart';
import '../models/receipt.dart';
import '../models/transaction.dart';
import '../models/product.dart';
import 'printer/bluetooth_printer_manager.dart';
import 'printer/network_printer_manager.dart';
import 'printer/virtual_printer_manager.dart';
import 'printer/receipt_generator.dart';

class PrinterService extends ChangeNotifier {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final BluetoothPrinterManager _bluetoothManager =
      BluetoothPrinterManager.instance;
  final NetworkPrinterManager _networkManager = NetworkPrinterManager.instance;
  final VirtualPrinterManager _virtualManager = VirtualPrinterManager.instance;
  final ReceiptGenerator _receiptGenerator = ReceiptGenerator();

  PrinterConfig? _activePrinter;
  bool _isPrinting = false;
  String? _lastError;

  PrinterConfig? get activePrinter => _activePrinter;
  bool get isPrinting => _isPrinting;
  String? get lastError => _lastError;
  String? get lastEmulatorFilePath => _virtualManager.lastSavedFilePath;

  bool get isConnected {
    if (_activePrinter == null) return false;
    switch (_activePrinter!.type) {
      case PrinterType.bluetooth:
        return _bluetoothManager.isConnected;
      case PrinterType.virtual:
        return _virtualManager.isConnected;
      case PrinterType.network:
      case PrinterType.usb:
        return _networkManager.isConnected;
    }
  }

  /// 设置活动打印机
  Future<bool> setActivePrinter(PrinterConfig config) async {
    try {
      _lastError = null;
      notifyListeners();

      // 断开当前连接
      if (_activePrinter != null) {
        await _disconnectCurrent();
      }

      bool connected = false;
      switch (config.type) {
        case PrinterType.bluetooth:
          connected = await _bluetoothManager.connect(config);
          break;
        case PrinterType.virtual:
          connected = await _virtualManager.connect(config);
          break;
        case PrinterType.network:
        case PrinterType.usb:
          connected = await _networkManager.connect(config);
          break;
      }

      if (connected) {
        _activePrinter = config;
        notifyListeners();
        return true;
      } else {
        _lastError = 'Failed to connect to printer';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 打印小票（新接口）
  Future<bool> printReceiptNew(Receipt receipt) async {
    if (_activePrinter == null) {
      _lastError = 'No active printer';
      notifyListeners();
      return false;
    }

    if (_isPrinting) {
      _lastError = 'Printer is busy';
      notifyListeners();
      return false;
    }

    try {
      _isPrinting = true;
      _lastError = null;
      notifyListeners();

      // 生成打印数据
      final bytes = await _receiptGenerator.generateReceipt(
        receipt,
        _activePrinter!,
      );

      final success = await _sendToPrinter(bytes);
      if (!success) {
        _lastError = 'Print failed';
      }
      return success;
    } catch (e) {
      _lastError = e.toString();
      return false;
    } finally {
      _isPrinting = false;
      notifyListeners();
    }
  }

  Future<bool> _sendToPrinter(List<int> bytes) async {
    switch (_activePrinter!.type) {
      case PrinterType.bluetooth:
        return _bluetoothManager.print(bytes);
      case PrinterType.virtual:
        return _virtualManager.print(bytes);
      case PrinterType.network:
      case PrinterType.usb:
        return _networkManager.print(bytes);
    }
  }

  /// 测试打印
  Future<bool> testPrint() async {
    if (_activePrinter == null) {
      _lastError = 'No active printer';
      notifyListeners();
      return false;
    }

    try {
      _isPrinting = true;
      _lastError = null;
      notifyListeners();

      // 生成测试打印数据
      final bytes = await _receiptGenerator.generateTestReceipt(_activePrinter!);

      final success = await _sendToPrinter(bytes);
      if (!success) {
        _lastError = 'Test print failed';
      }
      return success;
    } catch (e) {
      _lastError = e.toString();
      return false;
    } finally {
      _isPrinting = false;
      notifyListeners();
    }
  }

  /// 断开当前打印机
  Future<void> disconnect() async {
    await _disconnectCurrent();
    _activePrinter = null;
    notifyListeners();
  }

  /// 断开当前连接（内部方法）
  Future<void> _disconnectCurrent() async {
    if (_activePrinter == null) return;

    try {
      switch (_activePrinter!.type) {
        case PrinterType.bluetooth:
          await _bluetoothManager.disconnect();
          break;
        case PrinterType.virtual:
          await _virtualManager.disconnect();
          break;
        case PrinterType.network:
        case PrinterType.usb:
          await _networkManager.disconnect();
          break;
      }
    } catch (e) {
      // 忽略断开连接时的错误
    }
  }

  /// 清除错误
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // ========== 旧接口（保持向后兼容）==========

  /// Initialize printer connection (deprecated)
  @Deprecated('Use setActivePrinter instead')
  Future<bool> connect() async {
    // 保持向后兼容，但不做实际操作
    return isConnected;
  }

  /// Print receipt (旧接口，保持向后兼容)
  Future<bool> printReceipt({
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
    try {
      // Generate receipt content
      final receiptContent = _generateReceiptContent(
        transactionNumber: transactionNumber,
        transactionDate: transactionDate,
        items: items,
        subtotal: subtotal,
        discount: discount,
        discountLabel: discountLabel,
        tax: tax,
        total: total,
        paymentMethod: paymentMethod,
        receivedAmount: receivedAmount,
        changeAmount: changeAmount,
        customerName: customerName,
        cashierName: cashierName,
      );

      // TODO: Send to actual printer
      // For now, just print to console
      print('=== RECEIPT ===');
      print(receiptContent);
      print('===============');

      await Future.delayed(const Duration(milliseconds: 1000));
      return true;
    } catch (e) {
      print('Print error: $e');
      return false;
    }
  }

  /// Generate receipt content as plain text
  String _generateReceiptContent({
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
  }) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(_center('POS SYSTEM', 32));
    buffer.writeln(_center('Malaysia E-Invoice', 32));
    buffer.writeln(_line(32));

    // Transaction Info
    buffer.writeln('Receipt: $transactionNumber');
    buffer.writeln('Date: ${_formatDateTime(transactionDate)}');
    if (cashierName != null) {
      buffer.writeln('Cashier: $cashierName');
    }
    if (customerName != null) {
      buffer.writeln('Customer: $customerName');
    }
    buffer.writeln(_line(32));

    // Items
    buffer.writeln(_row('Item', 'Qty', 'Price', widths: [16, 4, 12]));
    buffer.writeln(_line(32));

    for (final item in items) {
      buffer.writeln(_leftAlign(item.name, 32));
      buffer.writeln(_row(
        '',
        '${item.quantity}x',
        'RM ${item.lineTotal.toStringAsFixed(2)}',
        widths: [16, 4, 12],
      ));
      if (item.note.isNotEmpty) {
        buffer.writeln('  Note: ${item.note}');
      }
    }

    buffer.writeln(_line(32));

    // Summary
    buffer.writeln(_row('Subtotal:', '', 'RM ${subtotal.toStringAsFixed(2)}', widths: [20, 0, 12]));

    if (discount > 0) {
      buffer.writeln(_row('Discount ($discountLabel):', '', '- RM ${discount.toStringAsFixed(2)}', widths: [20, 0, 12]));
    }

    buffer.writeln(_row('Tax (6%):', '', 'RM ${tax.toStringAsFixed(2)}', widths: [20, 0, 12]));
    buffer.writeln(_line(32));
    buffer.writeln(_row('TOTAL:', '', 'RM ${total.toStringAsFixed(2)}', widths: [20, 0, 12]));
    buffer.writeln(_line(32));

    // Payment
    buffer.writeln('Payment: ${_getPaymentMethodLabel(paymentMethod)}');
    if (paymentMethod == 'cash') {
      buffer.writeln(_row('Received:', '', 'RM ${receivedAmount.toStringAsFixed(2)}', widths: [20, 0, 12]));
      buffer.writeln(_row('Change:', '', 'RM ${changeAmount.toStringAsFixed(2)}', widths: [20, 0, 12]));
    }
    buffer.writeln(_line(32));

    // Footer
    buffer.writeln(_center('Thank You!', 32));
    buffer.writeln(_center('Please Come Again', 32));
    buffer.writeln(_line(32));

    return buffer.toString();
  }

  String _center(String text, int width) {
    if (text.length >= width) return text;
    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  String _leftAlign(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    return text.padRight(width);
  }

  String _rightAlign(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    return text.padLeft(width);
  }

  String _line(int width) {
    return '-' * width;
  }

  String _row(String col1, String col2, String col3, {required List<int> widths}) {
    return _leftAlign(col1, widths[0]) +
        _leftAlign(col2, widths[1]) +
        _rightAlign(col3, widths[2]);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
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

/// Receipt item model
class ReceiptItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String note;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.note = '',
  });
}
