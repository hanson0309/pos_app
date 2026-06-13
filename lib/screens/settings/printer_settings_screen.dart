import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../models/printer_config.dart';
import '../../services/database/printer_database.dart';
import '../../services/printer_service.dart';
import 'widgets/edit_printer_dialog.dart';
import 'widgets/printer_card.dart';
import 'widgets/add_bluetooth_printer_dialog.dart';
import 'widgets/add_network_printer_dialog.dart';
import 'widgets/add_usb_printer_dialog.dart';

class PrinterSettingsScreen extends StatefulWidget {
  final String tenantId;

  const PrinterSettingsScreen({
    super.key,
    required this.tenantId,
  });

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterDatabase _printerDb = PrinterDatabase();
  final PrinterService _printerService = PrinterService();

  List<PrinterConfig> _printers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
    _restorePrinterConnection();
  }

  Future<void> _updatePrinterSettings(
    PrinterConfig printer, {
    PrinterProtocol? protocol,
    bool? autoPrintReceipt,
    PrinterTextSize? textSize,
    bool? printSound,
    String? name,
    int? paperWidth,
  }) async {
    final updated = printer.copyWith(
      protocol: protocol,
      autoPrintReceipt: autoPrintReceipt,
      textSize: textSize,
      printSound: printSound,
      name: name,
      paperWidth: paperWidth,
      updatedAt: DateTime.now(),
    );
    await _printerDb.updatePrinterConfig(updated);
    _printerService.updateActivePrinterConfig(updated);
    await _loadPrinters();
  }

  Future<void> _editPrinter(PrinterConfig printer) async {
    final updated = await showDialog<PrinterConfig>(
      context: context,
      builder: (context) => EditPrinterDialog(printer: printer),
    );
    if (updated == null) return;
    await _updatePrinterSettings(
      printer,
      name: updated.name,
      paperWidth: updated.paperWidth,
    );
    if (mounted) {
      _showSuccessSnackBar('Printer updated');
    }
  }

  Future<void> _restorePrinterConnection() async {
    final ok = await _printerService.restoreConnection(widget.tenantId);
    if (mounted && ok) setState(() {});
  }

  Future<void> _loadPrinters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final printers = await _printerDb.getPrinterConfigsByTenant(widget.tenantId);
      setState(() {
        _printers = printers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addVirtualEmulatorPrinter() async {
    final now = DateTime.now();
    await _addPrinter(
      PrinterConfig(
        tenantId: widget.tenantId,
        name: 'Receipt Emulator',
        type: PrinterType.virtual,
        address: 'emulator',
        paperWidth: 80,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final printers = await _printerDb.getPrinterConfigsByTenant(widget.tenantId);
    PrinterConfig? emulator;
    for (final p in printers) {
      if (p.type == PrinterType.virtual) emulator = p;
    }
    if (emulator != null) {
      await _connectPrinter(emulator);
    }
  }

  Future<void> _addPrinter(PrinterConfig config) async {
    try {
      // Check if printer already exists
      final exists = await _printerDb.printerExists(config.address);
      if (exists) {
        if (mounted) {
          _showErrorSnackBar('A printer with this address already exists');
        }
        return;
      }

      // If this is the first printer, make it default
      final count = await _printerDb.getPrinterCountByTenant(widget.tenantId);
      final configToAdd = count == 0
          ? config.copyWith(isDefault: true)
          : config;

      final id = await _printerDb.insertPrinterConfig(configToAdd);
      await _loadPrinters();

      final saved = await _printerDb.getPrinterConfigById(id);
      if (saved != null) {
        await _connectPrinter(saved);
      }

      if (mounted) {
        _showSuccessSnackBar('Printer added successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to add printer: $e');
      }
    }
  }

  Future<void> _connectPrinter(PrinterConfig printer) async {
    try {
      final fresh = printer.id != null
          ? await _printerDb.getPrinterConfigById(printer.id!) ?? printer
          : printer;
      final success = await _printerService.setActivePrinter(fresh);
      if (success) {
        // Update last connected timestamp
        await _printerDb.updateLastConnected(printer.id!, DateTime.now());
        await _loadPrinters();
        if (mounted) {
          setState(() {});
          _showSuccessSnackBar('Connected to ${printer.name}');
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(_printerService.lastError ?? 'Failed to connect');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Connection failed: $e');
      }
    }
  }

  Future<void> _disconnectPrinter() async {
    try {
      await _printerService.disconnect();
      setState(() {});
      if (mounted) {
        _showSuccessSnackBar('Printer disconnected');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to disconnect: $e');
      }
    }
  }

  Future<void> _testPrint() async {
    try {
      final success = await _printerService.testPrint();
      if (success) {
        if (mounted) {
          _showSuccessSnackBar('Test print sent successfully');
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(_printerService.lastError ?? 'Test print failed');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Test print failed: $e');
      }
    }
  }

  Future<void> _setDefaultPrinter(PrinterConfig printer) async {
    try {
      await _printerDb.setDefaultPrinterByTenant(printer.id!, widget.tenantId);
      await _loadPrinters();
      if (mounted) {
        _showSuccessSnackBar('${printer.name} set as default');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to set default: $e');
      }
    }
  }

  Future<void> _deletePrinter(PrinterConfig printer) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Printer'),
        content: Text(
          'Are you sure you want to delete "${printer.name}"?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Disconnect if this is the active printer
      if (_printerService.activePrinter?.id == printer.id) {
        await _printerService.disconnect();
      }

      await _printerDb.deletePrinterConfig(printer.id!);
      await _loadPrinters();

      if (mounted) {
        _showSuccessSnackBar('Printer deleted');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete printer: $e');
      }
    }
  }

  void _showAddPrinterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb) ...[
              ListTile(
                leading: const Icon(Icons.wifi, color: Colors.white),
                title: const Text('WiFi Printer'),
                subtitle: Text(
                  'Scan printers on the same Wi‑Fi network (port 9100)',
                  style: AppTheme.bodySmall,
                ),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AddNetworkPrinterDialog(
                      tenantId: widget.tenantId,
                      onAdd: _addPrinter,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bluetooth, color: Colors.white),
                title: const Text('Bluetooth Printer'),
                subtitle: Text(
                  'Scan and pair nearby Bluetooth thermal printers',
                  style: AppTheme.bodySmall,
                ),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AddBluetoothPrinterDialog(
                      tenantId: widget.tenantId,
                      onAdd: _addPrinter,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.usb, color: Colors.white),
                title: const Text('USB Printer'),
                subtitle: Text(
                  'Connect via USB cable (COM port)',
                  style: AppTheme.bodySmall,
                ),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AddUsbPrinterDialog(
                      tenantId: widget.tenantId,
                      onAdd: _addPrinter,
                    ),
                  );
                },
              ),
            ],
            if (AppConfig.useReceiptEmulator)
              ListTile(
                leading: const Icon(Icons.developer_mode, color: Colors.white),
                title: const Text('Receipt emulator (no hardware)'),
                subtitle: Text(
                  'Preview on screen — for testing only',
                  style: AppTheme.bodySmall,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _addVirtualEmulatorPrinter();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Settings'),
        actions: [
          IconButton(
            onPressed: _loadPrinters,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (AppConfig.useReceiptEmulator) _buildDebugBanner(),
                Expanded(
                  child: _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppTheme.errorColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading printers',
                                style: AppTheme.heading3,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                style: AppTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadPrinters,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _printers.isEmpty
                          ? _buildEmptyState()
                          : _buildPrinterList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPrinterDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Printer'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDebugBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Debug build',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Receipts use the on-screen emulator automatically after checkout. '
            'Add a Bluetooth or network printer here when you have hardware; '
            'release builds will not use the emulator.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.print_disabled,
                size: 80,
                color: AppTheme.textTertiaryDark,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Printers Configured',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 12),
            Text(
              AppConfig.useReceiptEmulator
                  ? 'Debug mode: checkout opens the receipt emulator automatically.\n'
                      'Add a real printer here when ready.'
                  : 'Add a Bluetooth or network printer to print receipts',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddPrinterDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Printer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        ..._printers.map((printer) {
          final isConnected = _printerService.activePrinter?.id == printer.id;
          return PrinterCard(
            printer: printer,
            isConnected: isConnected,
            onConnect: () => _connectPrinter(printer),
            onDisconnect: _disconnectPrinter,
            onTest: _testPrint,
            onDelete: () => _deletePrinter(printer),
            onSetDefault: () => _setDefaultPrinter(printer),
            onProtocolChanged: (protocol) =>
                _updatePrinterSettings(printer, protocol: protocol),
            onAutoPrintChanged: (enabled) =>
                _updatePrinterSettings(printer, autoPrintReceipt: enabled),
            onTextSizeChanged: (size) =>
                _updatePrinterSettings(printer, textSize: size),
            onPrintSoundChanged: (enabled) =>
                _updatePrinterSettings(printer, printSound: enabled),
            onEdit: () => _editPrinter(printer),
          );
        }),
      ],
    );
  }
}
