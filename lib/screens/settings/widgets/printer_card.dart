import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/printer_config.dart';

class PrinterCard extends StatelessWidget {
  final PrinterConfig printer;
  final bool isConnected;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onTest;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;
  final ValueChanged<PrinterProtocol>? onProtocolChanged;
  final ValueChanged<bool>? onAutoPrintChanged;
  final ValueChanged<PrinterTextSize>? onTextSizeChanged;
  final ValueChanged<bool>? onPrintSoundChanged;
  final VoidCallback? onEdit;

  const PrinterCard({
    super.key,
    required this.printer,
    required this.isConnected,
    required this.onConnect,
    required this.onDisconnect,
    required this.onTest,
    required this.onDelete,
    required this.onSetDefault,
    this.onProtocolChanged,
    this.onAutoPrintChanged,
    this.onTextSizeChanged,
    this.onPrintSoundChanged,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final showPrintOptions = printer.type != PrinterType.virtual;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildInfoStrip(),
            if (showPrintOptions) ...[
              const SizedBox(height: 16),
              _buildSettingsPanel(context),
            ],
            const SizedBox(height: 16),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isConnected
                ? AppTheme.successColor.withValues(alpha: 0.12)
                : AppTheme.surfaceLight.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getPrinterIcon(),
            size: 26,
            color: isConnected
                ? AppTheme.successColor
                : AppTheme.textSecondaryDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      printer.name,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (printer.isDefault)
                    _chip('Default', AppTheme.primaryColor),
                ],
              ),
              const SizedBox(height: 4),
              Text(_getPrinterTypeLabel(), style: AppTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _chip(
          isConnected ? 'Connected' : 'Offline',
          isConnected ? AppTheme.successColor : AppTheme.textTertiaryDark,
          dot: true,
        ),
      ],
    );
  }

  Widget _chip(String label, Color color, {bool dot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTheme.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStrip() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _infoPill(Icons.straighten_outlined, '${printer.paperWidth} mm'),
        _infoPill(_getPrinterIcon(), _shortAddress(printer.address)),
        if (printer.lastConnected != null)
          _infoPill(
            Icons.schedule,
            _formatDateTime(printer.lastConnected!),
          ),
      ],
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textTertiaryDark),
          const SizedBox(width: 6),
          Text(text, style: AppTheme.caption),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.cardBorderColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Print options',
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _settingLabel('Print type'),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<PrinterProtocol>(
              segments: const [
                ButtonSegment(
                  value: PrinterProtocol.escPos,
                  label: Text('Receipt'),
                  icon: Icon(Icons.receipt_long_outlined, size: 18),
                ),
                ButtonSegment(
                  value: PrinterProtocol.tsplLabel,
                  label: Text('Label'),
                  icon: Icon(Icons.label_outline, size: 18),
                ),
              ],
              selected: {printer.protocol},
              onSelectionChanged: onProtocolChanged == null
                  ? null
                  : (s) => onProtocolChanged!(s.first),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: 14),
          _settingLabel('Text size'),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<PrinterTextSize>(
              segments: const [
                ButtonSegment(value: PrinterTextSize.small, label: Text('S')),
                ButtonSegment(value: PrinterTextSize.normal, label: Text('M')),
                ButtonSegment(value: PrinterTextSize.large, label: Text('L')),
              ],
              selected: {printer.textSize},
              onSelectionChanged: onTextSizeChanged == null
                  ? null
                  : (s) => onTextSizeChanged!(s.first),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 420;
              final autoPrint = _toggleTile(
                title: 'Auto-print',
                subtitle: 'After payment',
                value: printer.autoPrintReceipt,
                onChanged: onAutoPrintChanged,
              );
              final sound = _toggleTile(
                title: 'Beep',
                subtitle: 'When done',
                value: printer.printSound,
                onChanged: onPrintSoundChanged,
              );

              if (wide) {
                return Row(
                  children: [
                    Expanded(child: autoPrint),
                    const SizedBox(width: 12),
                    Expanded(child: sound),
                  ],
                );
              }
              return Column(
                children: [
                  autoPrint,
                  const SizedBox(height: 8),
                  sound,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _settingLabel(String text) {
    return Text(
      text,
      style: AppTheme.bodySmall.copyWith(
        color: AppTheme.textSecondaryDark,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(subtitle, style: AppTheme.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: isConnected ? onDisconnect : onConnect,
                icon: Icon(isConnected ? Icons.link_off : Icons.link, size: 18),
                label: Text(isConnected ? 'Disconnect' : 'Connect'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isConnected ? AppTheme.surfaceLight : AppTheme.primaryColor,
                  foregroundColor:
                      isConnected ? AppTheme.textPrimaryDark : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isConnected ? onTest : null,
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Test'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (onEdit != null)
              Expanded(
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
            if (!printer.isDefault)
              Expanded(
                child: TextButton.icon(
                  onPressed: onSetDefault,
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: const Text('Set default'),
                ),
              ),
            TextButton.icon(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
              label: Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
            ),
          ],
        ),
      ],
    );
  }

  String _shortAddress(String address) {
    if (address.length <= 17) return address;
    return '${address.substring(0, 8)}…${address.substring(address.length - 5)}';
  }

  IconData _getPrinterIcon() {
    switch (printer.type) {
      case PrinterType.bluetooth:
        return Icons.bluetooth;
      case PrinterType.usb:
        return Icons.usb;
      case PrinterType.network:
        return Icons.wifi;
      case PrinterType.virtual:
        return Icons.developer_mode;
    }
  }

  String _getPrinterTypeLabel() {
    switch (printer.type) {
      case PrinterType.bluetooth:
        return 'Bluetooth · ${printer.protocol == PrinterProtocol.tsplLabel ? 'Label TSPL' : 'Receipt ESC/POS'}';
      case PrinterType.usb:
        return 'USB Printer';
      case PrinterType.network:
        return 'Network Printer';
      case PrinterType.virtual:
        return 'Virtual (Emulator)';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
