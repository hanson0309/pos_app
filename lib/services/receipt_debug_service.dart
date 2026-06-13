import '../config/app_config.dart';
import '../models/printer_config.dart';
import 'database/printer_database.dart';
import 'printer_service.dart';

/// Debug-only receipt testing without a physical printer.
class ReceiptDebugService {
  static final ReceiptDebugService instance = ReceiptDebugService._();
  ReceiptDebugService._();

  final PrinterDatabase _printerDb = PrinterDatabase();
  final PrinterService _printerService = PrinterService();

  bool get isEnabled => AppConfig.useReceiptEmulator;

  /// Ensures virtual emulator printer exists and is connected.
  /// Does not replace an already-connected physical printer.
  Future<bool> ensureEmulator(String tenantId) async {
    if (!isEnabled) return false;

    if (_printerService.isConnected &&
        _printerService.activePrinter?.type != PrinterType.virtual) {
      return true;
    }

    final printers = await _printerDb.getPrinterConfigsByTenant(tenantId);
    PrinterConfig? emulator;
    for (final p in printers) {
      if (p.type == PrinterType.virtual) {
        emulator = p;
        break;
      }
    }

    if (emulator == null) {
      final now = DateTime.now();
      final id = await _printerDb.insertPrinterConfig(
        PrinterConfig(
          tenantId: tenantId,
          name: 'Receipt Emulator (Debug)',
          type: PrinterType.virtual,
          address: 'emulator',
          paperWidth: 80,
          isDefault: printers.isEmpty,
          createdAt: now,
          updatedAt: now,
        ),
      );
      emulator = (await _printerDb.getPrinterConfigById(id))!;
    }

    return _printerService.setActivePrinter(emulator);
  }
}
