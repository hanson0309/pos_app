import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../config/theme.dart';
import '../../../models/printer_config.dart';
import '../../../services/printer/bluetooth_printer_manager.dart';

class AddBluetoothPrinterDialog extends StatefulWidget {
  final String tenantId;
  final Function(PrinterConfig) onAdd;

  const AddBluetoothPrinterDialog({
    super.key,
    required this.tenantId,
    required this.onAdd,
  });

  @override
  State<AddBluetoothPrinterDialog> createState() =>
      _AddBluetoothPrinterDialogState();
}

class _AddBluetoothPrinterDialogState extends State<AddBluetoothPrinterDialog> {
  final BluetoothPrinterManager _bluetoothManager =
      BluetoothPrinterManager.instance;
  final TextEditingController _nameController = TextEditingController();

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isScanning = false;
  bool _isAdding = false;
  String? _errorMessage;
  int _paperWidth = 80;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _devices.clear();
    });

    try {
      final devices = await _bluetoothManager.scanDevices();
      setState(() {
        _devices = devices;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isScanning = false;
      });
    }
  }

  Future<void> _addPrinter() async {
    if (_selectedDevice == null) {
      setState(() {
        _errorMessage = 'Please select a printer';
      });
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a printer name';
      });
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    try {
      final config = PrinterConfig(
        tenantId: widget.tenantId,
        name: name,
        type: PrinterType.bluetooth,
        address: _selectedDevice!.remoteId.toString(),
        paperWidth: _paperWidth,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onAdd(config);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isAdding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.cardBorderColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
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
                      Icons.bluetooth,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Add Bluetooth Printer',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.errorColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppTheme.errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Scan Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Devices',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _isScanning ? null : _startScan,
                          icon: Icon(
                            _isScanning ? Icons.refresh : Icons.bluetooth_searching,
                            size: 18,
                          ),
                          label: Text(_isScanning ? 'Scanning...' : 'Scan'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Device List
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.cardBorderColor.withOpacity(0.3),
                        ),
                      ),
                      child: _isScanning
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      'Scanning for Bluetooth devices...',
                                      style: AppTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _devices.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.bluetooth_disabled,
                                          size: 48,
                                          color: AppTheme.textTertiaryDark,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No devices found',
                                          style: AppTheme.bodyMedium.copyWith(
                                            color: AppTheme.textSecondaryDark,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Make sure your printer is turned on\nand in pairing mode',
                                          style: AppTheme.bodySmall,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _devices.length,
                                  itemBuilder: (context, index) {
                                    final device = _devices[index];
                                    final isSelected = _selectedDevice == device;
                                    return FutureBuilder<String>(
                                      future: _bluetoothManager.getDeviceName(device),
                                      builder: (context, snapshot) {
                                        final deviceName = snapshot.data ?? 'Unknown Device';
                                        return ListTile(
                                          selected: isSelected,
                                          selectedTileColor:
                                              AppTheme.primaryColor.withOpacity(0.1),
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppTheme.primaryColor.withOpacity(0.2)
                                                  : AppTheme.surfaceLight.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.print,
                                              color: isSelected
                                                  ? AppTheme.primaryColor
                                                  : AppTheme.textSecondaryDark,
                                              size: 20,
                                            ),
                                          ),
                                          title: Text(
                                            deviceName,
                                            style: AppTheme.bodyMedium.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Text(
                                            device.remoteId.toString(),
                                            style: AppTheme.caption,
                                          ),
                                          trailing: isSelected
                                              ? Icon(
                                                  Icons.check_circle,
                                                  color: AppTheme.primaryColor,
                                                )
                                              : null,
                                          onTap: () {
                                            setState(() {
                                              _selectedDevice = device;
                                              _errorMessage = null;
                                              // Auto-fill name if empty
                                              if (_nameController.text.isEmpty) {
                                                _nameController.text = deviceName;
                                              }
                                            });
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                    ),
                    const SizedBox(height: 24),

                    // Printer Name
                    Text(
                      'Printer Name',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Main Counter Printer',
                        prefixIcon: const Icon(Icons.label_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Paper Width
                    Text(
                      'Paper Width',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPaperWidthOption(58),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPaperWidthOption(80),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.cardBorderColor.withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isAdding ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: AppTheme.cardBorderColor.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isAdding || _selectedDevice == null
                          ? null
                          : _addPrinter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isAdding
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Add Printer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaperWidthOption(int width) {
    final isSelected = _paperWidth == width;
    return InkWell(
      onTap: () {
        setState(() {
          _paperWidth = width;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : AppTheme.surfaceLight.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.cardBorderColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondaryDark,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              '${width}mm',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
