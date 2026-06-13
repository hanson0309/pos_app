import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/printer_config.dart';
import '../../../services/printer/network_printer_discovery.dart';

class AddNetworkPrinterDialog extends StatefulWidget {
  final String tenantId;
  final Function(PrinterConfig) onAdd;

  const AddNetworkPrinterDialog({
    super.key,
    required this.tenantId,
    required this.onAdd,
  });

  @override
  State<AddNetworkPrinterDialog> createState() => _AddNetworkPrinterDialogState();
}

class _AddNetworkPrinterDialogState extends State<AddNetworkPrinterDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  List<DiscoveredNetworkPrinter> _discovered = [];
  DiscoveredNetworkPrinter? _selected;
  String? _localIp;
  bool _isScanning = false;
  double _scanProgress = 0;
  bool _isAdding = false;
  String? _errorMessage;
  int _paperWidth = 80;

  @override
  void initState() {
    super.initState();
    _loadLocalIp();
  }

  Future<void> _loadLocalIp() async {
    if (kIsWeb) return;
    final ip = await NetworkPrinterDiscovery.localWifiIp();
    if (mounted) setState(() => _localIp = ip);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _scanWifiPrinters() async {
    setState(() {
      _isScanning = true;
      _scanProgress = 0;
      _errorMessage = null;
      _discovered = [];
      _selected = null;
    });

    try {
      final printers = await NetworkPrinterDiscovery.scan(
        onProgress: (p) {
          if (mounted) setState(() => _scanProgress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _discovered = printers;
        _isScanning = false;
        if (printers.isEmpty) {
          _errorMessage =
              'No printers found on port 9100. Ensure the printer is on the same Wi‑Fi and supports network printing.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isScanning = false;
      });
    }
  }

  void _selectPrinter(DiscoveredNetworkPrinter printer) {
    setState(() {
      _selected = printer;
      _addressController.text = printer.address;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = 'WiFi Printer ${printer.host}';
      }
    });
  }

  Future<void> _addPrinter() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a printer name');
      return;
    }
    if (address.isEmpty) {
      setState(() => _errorMessage = 'Select a printer from scan or enter IP manually');
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
        type: PrinterType.network,
        address: address,
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
      title: const Text('Add WiFi Printer'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Scan for ESC/POS printers on the same Wi‑Fi network (port 9100).',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryDark),
              ),
              if (_localIp != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Your device: $_localIp',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiaryDark),
                ),
              ],
              const SizedBox(height: 14),
              if (!kIsWeb)
                OutlinedButton.icon(
                  onPressed: _isScanning ? null : _scanWifiPrinters,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_find, size: 18),
                  label: Text(_isScanning ? 'Scanning…' : 'Scan same Wi‑Fi network'),
                ),
              if (_isScanning) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(value: _scanProgress),
              ],
              if (_discovered.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Found printers', style: AppTheme.bodySmall),
                const SizedBox(height: 6),
                ..._discovered.map(
                  (p) => ListTile(
                    dense: true,
                    tileColor: _selected?.host == p.host
                        ? AppTheme.primaryColor.withOpacity(0.15)
                        : AppTheme.surfaceLight.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    leading: const Icon(Icons.print, color: Colors.white70),
                    title: Text(p.host, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Port ${p.port}', style: AppTheme.bodySmall),
                    onTap: () => _selectPrinter(p),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text('Or enter manually', style: AppTheme.bodySmall),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Printer Name',
                  hintText: 'Kitchen Printer',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'IP address (port 9100)',
                  hintText: '192.168.1.100',
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
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add'),
        ),
      ],
    );
  }
}
