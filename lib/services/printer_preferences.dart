import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Persists last connected printer per tenant.
class PrinterPreferences {
  static String _lastPrinterKey(String tenantId) =>
      '${Constants.keyLastConnectedPrinterId}_$tenantId';

  static Future<String?> getLastConnectedPrinterId(String tenantId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastPrinterKey(tenantId));
  }

  static Future<void> setLastConnectedPrinterId(
    String tenantId,
    String printerId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPrinterKey(tenantId), printerId);
  }

  static Future<void> clearLastConnectedPrinterId(String tenantId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastPrinterKey(tenantId));
  }
}
