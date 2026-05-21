import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../models/printer_config.dart';

/// 蓝牙打印机管理器
/// 使用 flutter_blue_plus 实现蓝牙打印机的连接和打印功能
class BluetoothPrinterManager {
  static final BluetoothPrinterManager instance =
      BluetoothPrinterManager._init();

  BluetoothPrinterManager._init();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  bool _isConnected = false;
  PrinterConfig? _currentPrinter;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  bool get isConnected => _isConnected;
  PrinterConfig? get currentPrinter => _currentPrinter;

  /// 扫描蓝牙设备
  ///
  /// 参数:
  /// - [timeout]: 扫描超时时间，默认 10 秒
  ///
  /// 返回: 扫描到的蓝牙设备列表
  Future<List<BluetoothDevice>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final List<BluetoothDevice> devices = [];
    final Set<String> deviceIds = {};

    try {
      // 检查蓝牙是否可用
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth not supported by this device');
      }

      // 检查蓝牙是否开启
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw Exception('Bluetooth is turned off');
      }

      // 开始扫描
      await FlutterBluePlus.startScan(timeout: timeout);

      // 监听扫描结果
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          final device = result.device;
          // 避免重复添加
          if (!deviceIds.contains(device.remoteId.toString())) {
            deviceIds.add(device.remoteId.toString());
            devices.add(device);
          }
        }
      });

      // 等待扫描完成
      await Future.delayed(timeout);

      // 停止扫描
      await FlutterBluePlus.stopScan();
      await subscription.cancel();

      return devices;
    } catch (e) {
      // 确保停止扫描
      await FlutterBluePlus.stopScan();
      rethrow;
    }
  }

  /// 连接到打印机
  ///
  /// 参数:
  /// - [config]: 打印机配置，address 字段应为蓝牙设备的 MAC 地址
  ///
  /// 返回: 连接是否成功
  Future<bool> connect(PrinterConfig config) async {
    try {
      // 如果已连接到其他设备，先断开
      if (_isConnected && _connectedDevice != null) {
        await disconnect();
      }

      // 查找设备
      BluetoothDevice? targetDevice;

      // 先检查已连接的设备
      final connectedDevices = FlutterBluePlus.connectedDevices;
      for (var device in connectedDevices) {
        if (device.remoteId.toString() == config.address) {
          targetDevice = device;
          break;
        }
      }

      // 如果没有找到已连接的设备，尝试扫描
      if (targetDevice == null) {
        final devices = await scanDevices(timeout: const Duration(seconds: 5));
        for (var device in devices) {
          if (device.remoteId.toString() == config.address) {
            targetDevice = device;
            break;
          }
        }
      }

      if (targetDevice == null) {
        throw Exception('Printer device not found: ${config.address}');
      }

      // 连接设备
      await targetDevice.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      // 监听连接状态
      _connectionStateSubscription =
          targetDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // 发现服务
      final services = await targetDevice.discoverServices();

      // 查找可写特征
      BluetoothCharacteristic? writeChar;
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          // 查找具有写入属性的特征
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            writeChar = characteristic;
            break;
          }
        }
        if (writeChar != null) break;
      }

      if (writeChar == null) {
        await targetDevice.disconnect();
        throw Exception('No writable characteristic found on printer');
      }

      // 保存连接信息
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

  /// 打印数据
  ///
  /// 参数:
  /// - [bytes]: 要打印的字节数据（ESC/POS 指令）
  ///
  /// 返回: 打印是否成功
  Future<bool> print(List<int> bytes) async {
    if (!_isConnected ||
        _connectedDevice == null ||
        _writeCharacteristic == null) {
      throw Exception('Printer not connected');
    }

    try {
      // 将数据分块发送（蓝牙传输有 MTU 限制）
      const int chunkSize = 512; // 每次发送 512 字节
      final Uint8List data = Uint8List.fromList(bytes);

      for (int i = 0; i < data.length; i += chunkSize) {
        final int end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
        final chunk = data.sublist(i, end);

        // 根据特征属性选择写入方式
        if (_writeCharacteristic!.properties.writeWithoutResponse) {
          await _writeCharacteristic!.write(
            chunk,
            withoutResponse: true,
          );
        } else {
          await _writeCharacteristic!.write(chunk);
        }

        // 短暂延迟，避免数据丢失
        if (end < data.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      return true;
    } catch (e) {
      throw Exception('Print failed: $e');
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } catch (e) {
      // 忽略断开连接时的错误
    } finally {
      _handleDisconnection();
    }
  }

  /// 处理断开连接
  void _handleDisconnection() {
    _connectedDevice = null;
    _writeCharacteristic = null;
    _currentPrinter = null;
    _isConnected = false;
  }

  /// 获取设备名称
  ///
  /// 参数:
  /// - [device]: 蓝牙设备
  ///
  /// 返回: 设备名称，如果没有名称则返回 MAC 地址
  Future<String> getDeviceName(BluetoothDevice device) async {
    try {
      final name = device.platformName;
      if (name.isNotEmpty) {
        return name;
      }
    } catch (e) {
      // 忽略错误
    }
    return device.remoteId.toString();
  }

  /// 清理资源
  Future<void> dispose() async {
    await disconnect();
  }
}
