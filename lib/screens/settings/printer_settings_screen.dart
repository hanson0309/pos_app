import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/printer_config.dart';
import '../../services/database/printer_database.dart';
import '../../services/printer_service.dart';
import 'widgets/printer_card.dart';
import 'widgets/add_bluetooth_printer_dialog.dart';

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

      await _printerDb.insertPrinterConfig(configToAdd);
      await _loadPrinters();

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
      final success = await _printerService.setActivePrinter(printer);
      if (success) {
        // Update last connected timestamp
        await _printerDb.updateLastConnected(printer.id!, DateTime.now());
        await _loadPrinters();
        if (mounted) {
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
    showDialog(
      context: context,
      builder: (context) => AddBluetoothPrinterDialog(
        tenantId: widget.tenantId,
        onAdd: _addPrinter,
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
          : _errorMessage != null
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPrinterDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Printer'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
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
              'Add a Bluetooth printer to start printing receipts',
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
      padding: const EdgeInsets.all(16),
      children: [
        // Connection Status Card
        if (_printerService.activePrinter != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.successGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Printer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _printerService.activePrinter!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Printers List
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
          );
        }),

        // Bottom padding for FAB
        const SizedBox(height: 80),
      ],
    );
  }
}
