import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/printer_config.dart';

class AddNetworkPrinterDialog extends StatefulWidget {
  final String tenantId;
  final Function(PrinterConfig) onAdd;

  const AddNetworkPrinterDialog({
    super.key,
    required this.tenantId,
    required this.onAdd,
  });

  @override
  State<AddNetworkPrinterDialog> createState() =>
      _AddNetworkPrinterDialogState();
}

class _AddNetworkPrinterDialogState extends State<AddNetworkPrinterDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController(
    text: '127.0.0.1:9100',
  );

  bool _isAdding = false;
  String? _errorMessage;
  int _paperWidth = 80;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _addPrinter() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a printer name');
      return;
    }
    if (address.isEmpty) {
      setState(() => _errorMessage = 'Please enter IP address (e.g. 192.168.1.100:9100)');
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    final now = DateTime.now();
    final config = PrinterConfig(
      tenantId: widget.tenantId,
      name: name,
      type: PrinterType.network,
      address: address,
      paperWidth: _paperWidth,
      createdAt: now,
      updatedAt: now,
    );

    widget.onAdd(config);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Network Printer'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Use a virtual RAW printer on port 9100 (e.g. PaperCut, ESC/POS Network).',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryDark),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Printer Name',
                hintText: 'Virtual Receipt Printer',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'IP : Port',
                hintText: '127.0.0.1:9100',
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
              Text(
                _errorMessage!,
                style: TextStyle(color: AppTheme.errorColor),
              ),
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
          onPressed: _isAdding ? null : _addPrinter,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isAdding
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}
