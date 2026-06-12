import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../../models/printer_config.dart';

/// ESC/POS network printer (RAW TCP, default port 9100).
/// Address format: `192.168.1.100` or `192.168.1.100:9100`
class NetworkPrinterManager {
  static final NetworkPrinterManager instance = NetworkPrinterManager._init();

  NetworkPrinterManager._init();

  Socket? _socket;
  bool _isConnected = false;
  PrinterConfig? _currentPrinter;

  bool get isConnected => _isConnected;
  PrinterConfig? get currentPrinter => _currentPrinter;

  ({String host, int port}) _parseAddress(String address) {
    final trimmed = address.trim();
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      final host = parts[0].trim();
      final port = int.tryParse(parts[1].trim()) ?? 9100;
      return (host: host, port: port);
    }
    return (host: trimmed, port: 9100);
  }

  Future<bool> connect(PrinterConfig config) async {
    try {
      await disconnect();
      final target = _parseAddress(config.address);
      if (target.host.isEmpty) {
        throw Exception('Invalid printer IP address');
      }

      _socket = await Socket.connect(
        target.host,
        target.port,
        timeout: const Duration(seconds: 8),
      );

      _currentPrinter = config;
      _isConnected = true;
      return true;
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }

  Future<bool> print(List<int> bytes) async {
    if (!_isConnected || _socket == null) {
      throw Exception('Network printer not connected');
    }

    try {
      final data = Uint8List.fromList(bytes);
      _socket!.add(data);
      await _socket!.flush();
      return true;
    } catch (e) {
      throw Exception('Network print failed: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      await _socket?.close();
    } catch (_) {
      // ignore close errors
    } finally {
      _socket = null;
      _currentPrinter = null;
      _isConnected = false;
    }
  }
}
