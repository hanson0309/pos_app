import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../../models/printer_config.dart';

/// USB / serial ESC/POS printer (COM port on Windows, /dev/tty* on Linux).
class UsbPrinterManager {
  static final UsbPrinterManager instance = UsbPrinterManager._init();
  UsbPrinterManager._init();

  SerialPort? _port;
  bool _isConnected = false;
  PrinterConfig? _currentPrinter;

  bool get isConnected => _isConnected;
  PrinterConfig? get currentPrinter => _currentPrinter;

  static List<String> availablePorts() {
    try {
      return SerialPort.availablePorts;
    } catch (_) {
      return [];
    }
  }

  Future<bool> connect(PrinterConfig config) async {
    await disconnect();

    final portName = config.address.trim();
    if (portName.isEmpty) {
      throw Exception('Invalid USB port name');
    }

    final port = SerialPort(portName);
    if (!port.openReadWrite()) {
      final err = SerialPort.lastError;
      port.dispose();
      throw Exception(err?.message ?? 'Could not open $portName');
    }

    final portConfig = SerialPortConfig();
    portConfig.baudRate = 115200;
    portConfig.bits = 8;
    portConfig.stopBits = 1;
    portConfig.parity = SerialPortParity.none;
    port.config = portConfig;

    _port = port;
    _currentPrinter = config;
    _isConnected = true;
    return true;
  }

  Future<bool> print(List<int> bytes) async {
    if (!_isConnected || _port == null) {
      throw Exception('USB printer not connected');
    }

    try {
      final data = Uint8List.fromList(bytes);
      final written = _port!.write(data);
      if (written != data.length) {
        throw Exception('Incomplete write to USB printer');
      }
      return true;
    } catch (e) {
      throw Exception('USB print failed: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      _port?.close();
      _port?.dispose();
    } catch (_) {
      // ignore
    } finally {
      _port = null;
      _currentPrinter = null;
      _isConnected = false;
    }
  }
}
