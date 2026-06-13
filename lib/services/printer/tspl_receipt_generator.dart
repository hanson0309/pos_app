import '../../models/printer_config.dart';
import '../../models/receipt.dart';

/// TSPL commands for label printers (Xprinter XP-320B, XP-420B, etc.).
class TsplReceiptGenerator {
  static const _dotsPerMm = 8;
  static const _margin = 16;
  /// BLE MTU 100 → max ~97 bytes per packet; QRCODE must not be split across writes.
  static const _maxBleLineLength = 94;

  late int _widthMm;
  late int _widthDots;
  late int _contentWidth;
  final List<String> _lines = [];
  int _y = 0;
  bool _printSound = true;
  String _bodyFont = '2';
  String _headerFont = '3';
  int _headerXMul = 2;
  int _headerYMul = 2;
  int _bodyLineStep = 22;

  List<int> generateReceipt(Receipt receipt, PrinterConfig printerConfig) {
    _applyPrinterStyle(printerConfig);
    _lines.clear();
    _lines.addAll(_header());
    _y = 24;

    _centerText(
      receipt.storeName,
      font: _headerFont,
      xMul: _headerXMul,
      yMul: _headerYMul,
    );
    _y += 4;

    if (receipt.storeAddress != null && receipt.storeAddress!.isNotEmpty) {
      _centerText(receipt.storeAddress!, font: _bodyFont);
    }
    if (receipt.storePhone != null && receipt.storePhone!.isNotEmpty) {
      _centerText('Tel: ${receipt.storePhone}', font: _bodyFont);
    }
    if (receipt.taxNumber != null && receipt.taxNumber!.isNotEmpty) {
      _centerText('SST/TIN: ${receipt.taxNumber}', font: _bodyFont);
    }

    _divider();
    _labelValueRow('Receipt', receipt.transactionNumber);
    _labelValueRow('Date', _formatDateTime(receipt.transactionDate));
    _divider();

    _itemTableHeader();
    for (final item in receipt.items) {
      _itemRow(item);
    }

    _divider();
    _labelValueRow('Subtotal', 'RM ${receipt.subtotal.toStringAsFixed(2)}');
    if (receipt.discount > 0) {
      _labelValueRow(
        'Discount',
        '- RM ${receipt.discount.toStringAsFixed(2)}',
      );
    }
    if (receipt.serviceTax > 0) {
      _labelValueRow(
        'Service tax',
        'RM ${receipt.serviceTax.toStringAsFixed(2)}',
      );
    }
    _labelValueRow(
      'Tax (${receipt.taxRate.toStringAsFixed(0)}%)',
      'RM ${receipt.tax.toStringAsFixed(2)}',
    );
    _divider(thick: true);
    _labelValueRow(
      'TOTAL',
      'RM ${receipt.total.toStringAsFixed(2)}',
      bold: true,
    );
    _divider();
    _labelValueRow('Payment', _payLabel(receipt.paymentMethod));
    if (receipt.paymentMethod == 'cash') {
      _labelValueRow(
        'Received',
        'RM ${receipt.receivedAmount.toStringAsFixed(2)}',
      );
      _labelValueRow(
        'Change',
        'RM ${receipt.changeAmount.toStringAsFixed(2)}',
      );
    }

    _y += 8;
    _centerText('Thank you!', font: _headerFont, bold: true);

    final claimUrl = receipt.einvoiceClaimUrl?.trim();
    if (claimUrl != null && claimUrl.isNotEmpty) {
      _divider();
      _centerText('Scan to request e-Invoice', font: _headerFont, bold: true);
      _centerText(receipt.transactionNumber, font: _bodyFont);
      _y += 8;
      _qrCode(claimUrl);
    }

    final heightMm = ((_y + 32) / _dotsPerMm).ceil().clamp(50, 250);
    _lines.insert(0, 'SIZE $_widthMm mm, $heightMm mm');
    if (_printSound) {
      _lines.add('SOUND 2,30');
    }
    _lines.add('PRINT 1,1');

    return _encode(_lines);
  }

  List<int> generateTestReceipt(PrinterConfig printerConfig) {
    _applyPrinterStyle(printerConfig);
    _lines.clear();
    _y = 40;

    final lines = <String>[
      'SIZE $_widthMm mm, 35 mm',
      ..._header(),
      'TEXT $_margin,40,"3",0,1,1,"TEST PRINT"',
      'TEXT $_margin,80,"2",0,1,1,"${_safe(printerConfig.name)}"',
      'TEXT $_margin,110,"2",0,1,1,"Label TSPL OK"',
      if (_printSound) 'SOUND 2,30',
      'PRINT 1,1',
    ];
    return _encode(lines);
  }

  void _applyPrinterStyle(PrinterConfig config) {
    _printSound = config.printSound;
    _widthMm = config.paperWidth.clamp(40, 80);
    _widthDots = _widthMm * _dotsPerMm;
    _contentWidth = _widthDots - (_margin * 2);

    switch (config.textSize) {
      case PrinterTextSize.small:
        _bodyFont = '1';
        _headerFont = '2';
        _headerXMul = 1;
        _headerYMul = 1;
        _bodyLineStep = 18;
      case PrinterTextSize.normal:
        _bodyFont = '2';
        _headerFont = '3';
        _headerXMul = 2;
        _headerYMul = 2;
        _bodyLineStep = 22;
      case PrinterTextSize.large:
        _bodyFont = '3';
        _headerFont = '3';
        _headerXMul = 2;
        _headerYMul = 2;
        _bodyLineStep = 26;
    }
  }

  List<String> _header() {
    return [
      'GAP 2 mm, 0 mm',
      'DIRECTION 0',
      'REFERENCE 0,0',
      'OFFSET 0 mm',
      'SET PEEL OFF',
      'SET CUTTER OFF',
      'SET TEAR ON',
      'CLS',
    ];
  }

  void _divider({bool thick = false}) {
    _y += 6;
    final h = thick ? 3 : 2;
    _lines.add('BAR $_margin,$_y,$_contentWidth,$h');
    _y += 10;
  }

  void _centerText(
    String text, {
    String font = '2',
    int xMul = 1,
    int yMul = 1,
    bool bold = false,
  }) {
    final xMulFinal = bold ? xMul.clamp(1, 2) : xMul;
    final yMulFinal = bold ? yMul.clamp(1, 2) : yMul;
    // Approximate center: shorter strings need less offset.
    final charWidth = 8 * xMulFinal;
    final textWidth = text.length * charWidth;
    final x = ((_widthDots - textWidth) / 2).round().clamp(_margin, _widthDots);
    _lines.add(
      'TEXT $x,$_y,"$font",0,$xMulFinal,$yMulFinal,"${_safe(text)}"',
    );
    _y += _bodyLineStep * yMulFinal;
  }

  void _labelValueRow(String label, String value, {bool bold = false}) {
    final yMul = bold ? 2 : 1;
    final font = bold ? _headerFont : _bodyFont;
    _lines.add('TEXT $_margin,$_y,"$font",0,1,$yMul,"${_safe(label)}"');
    final valueX = _margin + (_contentWidth * 0.45).round();
    _lines.add(
      'TEXT $valueX,$_y,"$font",0,1,$yMul,"${_safe(value)}"',
    );
    _y += _bodyLineStep * yMul;
  }

  void _itemTableHeader() {
    final font = _bodyFont;
    _lines.add('TEXT $_margin,$_y,"$font",0,1,1,"Item"');
    _lines.add('TEXT ${_colQty()},$_y,"$font",0,1,1,"Qty"');
    _lines.add('TEXT ${_colUnit()},$_y,"$font",0,1,1,"Unit"');
    _lines.add('TEXT ${_colTotal()},$_y,"$font",0,1,1,"Total"');
    _y += _bodyLineStep;
  }

  void _itemRow(ReceiptItem item) {
    final font = _bodyFont;
    _lines.add('TEXT $_margin,$_y,"$font",0,1,1,"${_safe(item.name)}"');
    _y += 20;
    _lines.add('TEXT ${_colQty()},$_y,"$font",0,1,1,"${item.quantity}"');
    _lines.add(
      'TEXT ${_colUnit()},$_y,"$font",0,1,1,"${item.unitPrice.toStringAsFixed(2)}"',
    );
    _lines.add(
      'TEXT ${_colTotal()},$_y,"$font",0,1,1,"${item.lineTotal.toStringAsFixed(2)}"',
    );
    _y += _bodyLineStep + 2;
  }

  int _colQty() => _margin + (_contentWidth * 0.42).round();
  int _colUnit() => _margin + (_contentWidth * 0.55).round();
  int _colTotal() => _margin + (_contentWidth * 0.72).round();

  void _qrCode(String claimUrl) {
    final qrSize = 120;
    final x = ((_widthDots - qrSize) / 2).round().clamp(_margin, _widthDots);
    final url = _fitQrUrl(claimUrl, x: x, y: _y);
    _lines.add('QRCODE $x,$_y,H,4,A,0,"${_safeQr(url)}"');
    _y += qrSize + 12;
  }

  /// Keep QRCODE command on one BLE packet (splitting mid-command breaks the QR).
  String _fitQrUrl(String url, {required int x, required int y}) {
    final cleaned = url.replaceAll('"', "'").trim();
    final prefix = 'QRCODE $x,$y,H,4,A,0,"';
    final maxUrlLen = _maxBleLineLength - prefix.length - 1; // closing quote

    if (cleaned.length <= maxUrlLen) return cleaned;

    // Drop ?tenant=… first — claim API resolves by receipt number alone.
    final withoutQuery = cleaned.split('?').first;
    if (withoutQuery.length <= maxUrlLen) return withoutQuery;

    return withoutQuery.substring(0, maxUrlLen);
  }

  String _safe(String input) {
    return input
        .replaceAll('"', "'")
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), ' ');
  }

  /// Keep URL characters intact for a scannable claim QR.
  String _safeQr(String url) {
    return url.replaceAll('"', "'");
  }

  List<int> _encode(List<String> lines) {
    return '${lines.join('\r\n')}\r\n'.codeUnits;
  }

  String _formatDateTime(DateTime d) =>
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
