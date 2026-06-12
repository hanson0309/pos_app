import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../../models/printer_config.dart';

/// Emulator printer: writes raw ESC/POS bytes to app documents (no hardware).
class VirtualPrinterManager {
  static final VirtualPrinterManager instance = VirtualPrinterManager._init();

  VirtualPrinterManager._init();

  bool _isConnected = false;
  PrinterConfig? _currentPrinter;
  String? lastSavedFilePath;

  bool get isConnected => _isConnected;
  PrinterConfig? get currentPrinter => _currentPrinter;

  Future<bool> connect(PrinterConfig config) async {
    _currentPrinter = config;
    _isConnected = true;
    return true;
  }

  Future<bool> print(List<int> bytes) async {
    if (!_isConnected) {
      throw Exception('Virtual printer not connected');
    }

    if (kIsWeb) {
      lastSavedFilePath = 'web-emulator (${bytes.length} bytes)';
      return true;
    }

    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${dir.path}/receipt_prints');
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${receiptsDir.path}/receipt_$timestamp.bin');
    await file.writeAsBytes(bytes);
    lastSavedFilePath = file.path;
    return true;
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _currentPrinter = null;
  }
}
