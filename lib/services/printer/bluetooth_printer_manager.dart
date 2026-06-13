import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../models/printer_config.dart';

/// BLE thermal printer service/characteristic UUIDs (Xprinter, ESC/POS, etc.).
const _printerServiceHints = [
  '18f0',
  'ff00',
  '49535343',
  'e7810a71',
];

const _printerWriteHints = [
  '2af1',
  'ff02',
  '8841-43f4',
  'bef8d6c9',
];

/// Bluetooth printer manager using flutter_blue_plus (BLE).
class BluetoothPrinterManager {
  static final BluetoothPrinterManager instance =
      BluetoothPrinterManager._init();

  BluetoothPrinterManager._init();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  bool _isConnected = false;
  PrinterConfig? _currentPrinter;
  int _chunkSize = 20;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  bool get isConnected => _isConnected;
  PrinterConfig? get currentPrinter => _currentPrinter;

  Future<List<BluetoothDevice>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final List<BluetoothDevice> devices = [];
    final Set<String> deviceIds = {};

    try {
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth not supported by this device');
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw Exception('Bluetooth is turned off');
      }

      await FlutterBluePlus.startScan(timeout: timeout);

      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final device = result.device;
          final id = device.remoteId.toString();
          if (!deviceIds.contains(id)) {
            deviceIds.add(id);
            devices.add(device);
          }
        }
      });

      await Future.delayed(timeout);
      await FlutterBluePlus.stopScan();
      await subscription.cancel();

      return devices;
    } catch (e) {
      await FlutterBluePlus.stopScan();
      rethrow;
    }
  }

  Future<bool> connect(PrinterConfig config) async {
    try {
      if (_isConnected && _connectedDevice != null) {
        await disconnect();
      }

      BluetoothDevice? targetDevice = _findKnownDevice(config.address);

      if (targetDevice == null || !targetDevice.isConnected) {
        targetDevice = BluetoothDevice.fromId(config.address);
        await targetDevice.connect(
          timeout: const Duration(seconds: 15),
          autoConnect: false,
        );
      }

      _connectionStateSubscription?.cancel();
      _connectionStateSubscription =
          targetDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      try {
        await targetDevice.requestMtu(512);
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 200));
      _chunkSize = _resolveChunkSize(targetDevice.mtuNow);

      final services = await targetDevice.discoverServices();
      final writeChar = _findWriteCharacteristic(services);

      if (writeChar == null) {
        await targetDevice.disconnect();
        throw Exception('No writable print characteristic found on printer');
      }

      if (kDebugMode) {
        debugPrint(
          'BLE printer: service=${writeChar.serviceUuid}, '
          'char=${writeChar.uuid}, mtu=${targetDevice.mtuNow}, chunk=$_chunkSize',
        );
      }

      _connectedDevice = targetDevice;
      _writeCharacteristic = writeChar;
      _currentPrinter = config;
      _isConnected = true;

      return true;
    } catch (e) {
      _handleDisconnection();
      rethrow;
    }
  }

  BluetoothDevice? _findKnownDevice(String address) {
    for (final device in FlutterBluePlus.connectedDevices) {
      if (device.remoteId.toString() == address) {
        return device;
      }
    }
    return null;
  }

  int _resolveChunkSize(int mtu) {
    if (mtu <= 0) return 20;
    return (mtu - 3).clamp(20, 512);
  }

  BluetoothCharacteristic? _findWriteCharacteristic(
    List<BluetoothService> services,
  ) {
    BluetoothCharacteristic? fallback;

    for (final service in services) {
      final serviceId = service.uuid.toString().toLowerCase();
      final isPrinterService = _printerServiceHints
          .any((hint) => serviceId.contains(hint.toLowerCase()));

      for (final characteristic in service.characteristics) {
        final canWrite = characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse;
        if (!canWrite) continue;

        fallback ??= characteristic;

        final charId = characteristic.uuid.toString().toLowerCase();
        final isPrinterChar = _printerWriteHints
            .any((hint) => charId.contains(hint.toLowerCase()));

        if (isPrinterService && isPrinterChar) {
          return characteristic;
        }
        if (isPrinterService || isPrinterChar) {
          fallback = characteristic;
        }
      }
    }

    return fallback;
  }

  Future<bool> print(List<int> bytes, {bool lineOriented = false}) async {
    if (!_isConnected ||
        _connectedDevice == null ||
        _writeCharacteristic == null) {
      throw Exception('Printer not connected');
    }

    try {
      _chunkSize = _resolveChunkSize(_connectedDevice!.mtuNow);

      if (lineOriented) {
        await _printLineOriented(bytes);
      } else {
        await _printChunked(bytes);
      }
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    } catch (e) {
      throw Exception('Print failed: $e');
    }
  }

  bool _preferWithoutResponse() {
    final props = _writeCharacteristic!.properties;
    return !props.write && props.writeWithoutResponse;
  }

  /// Send bytes over BLE, splitting when a single packet exceeds MTU.
  Future<void> _writeBytes(
    List<int> payload, {
    required bool withoutResponse,
  }) async {
    if (payload.length <= _chunkSize) {
      await _writeCharacteristic!.write(
        payload,
        withoutResponse: withoutResponse,
      );
      return;
    }

    for (int i = 0; i < payload.length; i += _chunkSize) {
      final end =
          (i + _chunkSize < payload.length) ? i + _chunkSize : payload.length;
      await _writeCharacteristic!.write(
        payload.sublist(i, end),
        withoutResponse: withoutResponse,
      );
      if (end < payload.length) {
        await Future.delayed(const Duration(milliseconds: 15));
      }
    }
  }

  Future<void> _printLineOriented(List<int> bytes) async {
    final text = String.fromCharCodes(bytes);
    final rawLines = text.split(RegExp(r'\r?\n'));
    final withoutResponse = _preferWithoutResponse();

    for (final line in rawLines) {
      if (line.trim().isEmpty) continue;
      final payload = [...line.codeUnits, 0x0d, 0x0a];
      // QRCODE must arrive in one GATT write — printer ignores split commands.
      if (line.startsWith('QRCODE') && payload.length > _chunkSize) {
        throw Exception(
          'QRCODE command too long (${payload.length} > $_chunkSize bytes). '
          'Use a shorter claim URL.',
        );
      }
      await _writeBytes(payload, withoutResponse: withoutResponse);
      await Future.delayed(const Duration(milliseconds: 25));
    }
  }

  Future<void> _printChunked(List<int> bytes) async {
    final withoutResponse = _preferWithoutResponse();

    for (int i = 0; i < bytes.length; i += _chunkSize) {
      final end =
          (i + _chunkSize < bytes.length) ? i + _chunkSize : bytes.length;
      await _writeCharacteristic!.write(
        bytes.sublist(i, end),
        withoutResponse: withoutResponse,
      );
      if (end < bytes.length) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
  }

  Future<void> disconnect() async {
    try {
      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } catch (_) {
    } finally {
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    _connectedDevice = null;
    _writeCharacteristic = null;
    _currentPrinter = null;
    _isConnected = false;
    _chunkSize = 20;
  }

  Future<String> getDeviceName(BluetoothDevice device) async {
    try {
      final name = device.platformName;
      if (name.isNotEmpty) return name;
    } catch (_) {}
    return device.remoteId.toString();
  }

  Future<void> dispose() async {
    await disconnect();
  }
}
