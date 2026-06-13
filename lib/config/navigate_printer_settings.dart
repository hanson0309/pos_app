import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../screens/settings/printer_settings_screen.dart';
import '../utils/constants.dart';

/// Opens printer settings for the paired tenant.
Future<void> openPrinterSettings(BuildContext context) async {
  const storage = FlutterSecureStorage();
  final tenantId = await storage.read(key: Constants.keyTenantId);

  if (!context.mounted) return;

  if (tenantId == null || tenantId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pair this device first to configure printers'),
      ),
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PrinterSettingsScreen(tenantId: tenantId),
    ),
  );
}
