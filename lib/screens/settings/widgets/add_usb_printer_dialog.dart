import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/printer_config.dart';
import '../../../services/printer/usb_printer_manager.dart';

class AddUsbPrinterDialog extends StatefulWidget {
  final String tenantId;
  final Function(PrinterConfig) onAdd;

  const AddUsbPrinterDialog({
    super.key,
    required this.tenantId,
    required this.onAdd,
  });

  @override
  State<AddUsbPrinterDialog> createState() => _AddUsbPrinterDialogState();
}

class _AddUsbPrinterDialogState extends State<AddUsbPrinterDialog> {
  final TextEditingController _nameController = TextEditingController();

  List<String> _ports = [];
  String? _selectedPort;
  bool _isAdding = false;
  String? _errorMessage;
  int _paperWidth = 80;

  @override
  void initState() {
    super.initState();
    _refreshPorts();
  }

  void _refreshPorts() {
    setState(() {
      _ports = UsbPrinterManager.availablePorts();
      if (_ports.isNotEmpty && _selectedPort == null) {
        _selectedPort = _ports.first;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addPrinter() async {
    if (_selectedPort == null) {
      setState(() => _errorMessage = 'No USB port selected');
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a printer name');
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    final now = DateTime.now();
    widget.onAdd(
      PrinterConfig(
        tenantId: widget.tenantId,
        name: name,
        type: PrinterType.usb,
        address: _selectedPort!,
        paperWidth: _paperWidth,
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add USB Printer'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              kIsWeb
                  ? 'USB printers are not supported in the browser. Use the Windows or Android app.'
                  : 'Connect the thermal printer via USB, then select its COM / serial port.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryDark),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text('Available ports', style: AppTheme.bodySmall),
                ),
                TextButton.icon(
                  onPressed: _refreshPorts,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            if (_ports.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No USB serial ports detected. Plug in the printer and tap Refresh.',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiaryDark),
                ),
              )
            else
              ..._ports.map(
                (port) => ListTile(
                  dense: true,
                  tileColor: _selectedPort == port
                      ? AppTheme.primaryColor.withOpacity(0.15)
                      : AppTheme.surfaceLight.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: const Icon(Icons.usb, color: Colors.white70),
                  title: Text(port, style: const TextStyle(color: Colors.white)),
                  onTap: () => setState(() => _selectedPort = port),
                ),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Printer Name',
                hintText: 'Counter USB Printer',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _paperWidth,
              decoration: const InputDecoration(labelText: 'Paper Width'),
              items: const [
                DropdownMenuItem(value: 58, child: Text('58 mm')),
                DropdownMenuItem(value: 80, child: Text('80 mm')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _paperWidth = value);
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: TextStyle(color: AppTheme.errorColor, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isAdding ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isAdding || kIsWeb || _ports.isEmpty) ? null : _addPrinter,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
