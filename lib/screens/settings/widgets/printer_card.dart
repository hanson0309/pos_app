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

  const PrinterCard({
    super.key,
    required this.printer,
    required this.isConnected,
    required this.onConnect,
    required this.onDisconnect,
    required this.onTest,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Printer Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.surfaceLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPrinterIcon(),
                    size: 28,
                    color: isConnected
                        ? AppTheme.successColor
                        : AppTheme.textSecondaryDark,
                  ),
                ),
                const SizedBox(width: 16),
                // Printer Info
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getPrinterTypeLabel(),
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Connection Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.surfaceLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isConnected
                              ? AppTheme.successColor
                              : AppTheme.textTertiaryDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConnected ? 'Connected' : 'Disconnected',
                        style: AppTheme.caption.copyWith(
                          color: isConnected
                              ? AppTheme.successColor
                              : AppTheme.textSecondaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Printer Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    'Address',
                    printer.address,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.straighten_outlined,
                    'Paper Width',
                    '${printer.paperWidth}mm',
                  ),
                  if (printer.lastConnected != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.access_time_outlined,
                      'Last Connected',
                      _formatDateTime(printer.lastConnected!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              children: [
                // Connect/Disconnect Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? onDisconnect : onConnect,
                    icon: Icon(
                      isConnected ? Icons.link_off : Icons.link,
                      size: 18,
                    ),
                    label: Text(isConnected ? 'Disconnect' : 'Connect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected
                          ? AppTheme.surfaceLight
                          : AppTheme.primaryColor,
                      foregroundColor: isConnected
                          ? AppTheme.textPrimaryDark
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Test Print Button
                ElevatedButton.icon(
                  onPressed: isConnected ? onTest : null,
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceLight,
                    foregroundColor: AppTheme.textPrimaryDark,
                    disabledBackgroundColor:
                        AppTheme.surfaceLight.withOpacity(0.3),
                    disabledForegroundColor:
                        AppTheme.textTertiaryDark.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // More Options Button
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppTheme.textSecondaryDark,
                  ),
                  color: AppTheme.surfaceDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppTheme.cardBorderColor.withOpacity(0.3),
                    ),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'default':
                        onSetDefault();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!printer.isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_outline,
                              size: 20,
                              color: AppTheme.textSecondaryDark,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Set as Default',
                              style: AppTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textTertiaryDark,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textTertiaryDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryDark,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  IconData _getPrinterIcon() {
    switch (printer.type) {
      case PrinterType.bluetooth:
        return Icons.bluetooth;
      case PrinterType.usb:
        return Icons.usb;
      case PrinterType.network:
        return Icons.wifi;
    }
  }

  String _getPrinterTypeLabel() {
    switch (printer.type) {
      case PrinterType.bluetooth:
        return 'Bluetooth Printer';
      case PrinterType.usb:
        return 'USB Printer';
      case PrinterType.network:
        return 'Network Printer';
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
