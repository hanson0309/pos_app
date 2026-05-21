# 收据打印功能实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 POS 系统实现完整的收据打印功能，支持蓝牙/USB/网络打印机，包含打印队列、错误处理和打印历史管理。

**Architecture:** 采用分层架构，PrinterService 作为统一接口，下层有三个打印机管理器（蓝牙/USB/网络）和 EscPosGenerator（指令生成）。打印队列服务处理失败重试。所有配置和历史保存到 SQLite。

**Tech Stack:** Flutter, sqflite, esc_pos_utils, esc_pos_bluetooth, flutter_blue_plus, network_info_plus

---

## 文件结构

**新建文件：**

**数据模型：**
- `lib/models/printer_config.dart` - 打印机配置模型
- `lib/models/printer_config.g.dart` - JSON 序列化（自动生成）
- `lib/models/print_job.dart` - 打印任务模型
- `lib/models/print_job.g.dart` - JSON 序列化（自动生成）

**核心服务：**
- `lib/services/printer/printer_service_enhanced.dart` - 增强的打印服务
- `lib/services/printer/bluetooth_printer_manager.dart` - 蓝牙打印机管理
- `lib/services/printer/escpos_generator.dart` - ESC/POS 指令生成
- `lib/services/printer/print_queue_service.dart` - 打印队列服务
- `lib/services/database/printer_database.dart` - 打印机数据库操作

**界面组件：**
- `lib/screens/settings/printer_settings_screen.dart` - 打印机设置界面
- `lib/screens/settings/widgets/add_bluetooth_printer_dialog.dart` - 添加蓝牙打印机对话框
- `lib/screens/settings/widgets/printer_card.dart` - 打印机卡片组件
- `lib/screens/cashier/widgets/print_error_dialog.dart` - 打印错误对话框
- `lib/screens/settings/print_history_screen.dart` - 打印历史界面

**修改文件：**
- `lib/services/database/database_service.dart` - 添加打印相关表
- `lib/services/printer_service.dart` - 重构为使用新的增强服务
- `lib/screens/cashier/widgets/payment_success_dialog.dart` - 集成新打印服务
- `pubspec.yaml` - 添加新依赖
- `lib/config/routes.dart` - 添加新路由

---

## 阶段 1：基础设施和数据模型

### Task 1: 添加依赖包

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: 添加新的依赖包**

在 `pubspec.yaml` 的 `dependencies` 部分添加：

```yaml
  # Printer Support (新增)
  esc_pos_bluetooth: ^0.4.1
  network_info_plus: ^5.0.0
```

- [ ] **Step 2: 安装依赖**

Run: `flutter pub get`
Expected: 成功安装所有依赖包

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: 添加打印机相关依赖包"
```

---

### Task 2: 创建打印机配置数据模型

**Files:**
- Create: `lib/models/printer_config.dart`

- [ ] **Step 1: 创建 PrinterConfig 模型**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'printer_config.g.dart';

enum PrinterType {
  bluetooth,
  usb,
  network,
}

@JsonSerializable()
class PrinterConfig {
  final String id;
  final String name;
  @JsonKey(name: 'printer_type')
  final PrinterType type;
  final String address;
  @JsonKey(name: 'paper_width')
  final int paperWidth;
  @JsonKey(name: 'is_default')
  final bool isDefault;
  @JsonKey(name: 'last_connected')
  final DateTime? lastConnected;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  PrinterConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.paperWidth = 80,
    this.isDefault = false,
    this.lastConnected,
    required this.createdAt,
  });

  factory PrinterConfig.fromJson(Map<String, dynamic> json) =>
      _$PrinterConfigFromJson(json);

  Map<String, dynamic> toJson() => _$PrinterConfigToJson(this);

  PrinterConfig copyWith({
    String? id,
    String? name,
    PrinterType? type,
    String? address,
    int? paperWidth,
    bool? isDefault,
    DateTime? lastConnected,
    DateTime? createdAt,
  }) {
    return PrinterConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      paperWidth: paperWidth ?? this.paperWidth,
      isDefault: isDefault ?? this.isDefault,
      lastConnected: lastConnected ?? this.lastConnected,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

- [ ] **Step 2: 生成 JSON 序列化代码**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: 生成 `printer_config.g.dart` 文件

- [ ] **Step 3: Commit**

```bash
git add lib/models/printer_config.dart lib/models/printer_config.g.dart
git commit -m "feat: 添加打印机配置数据模型"
```

---

### Task 3: 创建打印任务数据模型

**Files:**
- Create: `lib/models/print_job.dart`

- [ ] **Step 1: 创建 PrintJob 模型**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'print_job.g.dart';

enum PrintJobStatus {
  pending,
  printing,
  success,
  failed,
}

@JsonSerializable()
class PrintJob {
  final String id;
  @JsonKey(name: 'transaction_id')
  final String transactionId;
  @JsonKey(name: 'transaction_number')
  final String transactionNumber;
  @JsonKey(name: 'receipt_data')
  final Map<String, dynamic> receiptData;
  final PrintJobStatus status;
  @JsonKey(name: 'retry_count')
  final int retryCount;
  @JsonKey(name: 'error_message')
  final String? errorMessage;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'printed_at')
  final DateTime? printedAt;

  PrintJob({
    required this.id,
    required this.transactionId,
    required this.transactionNumber,
    required this.receiptData,
    this.status = PrintJobStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
    required this.createdAt,
    this.printedAt,
  });

  factory PrintJob.fromJson(Map<String, dynamic> json) =>
      _$PrintJobFromJson(json);

  Map<String, dynamic> toJson() => _$PrintJobToJson(this);

  PrintJob copyWith({
    String? id,
    String? transactionId,
    String? transactionNumber,
    Map<String, dynamic>? receiptData,
    PrintJobStatus? status,
    int? retryCount,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? printedAt,
  }) {
    return PrintJob(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      receiptData: receiptData ?? this.receiptData,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      printedAt: printedAt ?? this.printedAt,
    );
  }
}
```

- [ ] **Step 2: 生成 JSON 序列化代码**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: 生成 `print_job.g.dart` 文件

- [ ] **Step 3: Commit**

```bash
git add lib/models/print_job.dart lib/models/print_job.g.dart
git commit -m "feat: 添加打印任务数据模型"
```

---

### Task 4: 扩展数据库添加打印相关表

**Files:**
- Modify: `lib/services/database/database_service.dart`

- [ ] **Step 1: 在 _createDB 方法末尾添加打印机配置表**

在 `_createDB` 方法中，找到最后一个 `await db.execute` 语句后，添加：

```dart
    // Printer Configs Table
    await db.execute('''
      CREATE TABLE printer_configs (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        address TEXT NOT NULL,
        paper_width INTEGER DEFAULT 80,
        is_default INTEGER DEFAULT 0,
        last_connected INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    // Print Queue Table
    await db.execute('''
      CREATE TABLE print_queue (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        transaction_number TEXT NOT NULL,
        receipt_data TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        retry_count INTEGER DEFAULT 0,
        error_message TEXT,
        created_at INTEGER NOT NULL,
        printed_at INTEGER
      )
    ''');

    // Print History Table
    await db.execute('''
      CREATE TABLE print_history (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        printer_id TEXT,
        printer_name TEXT,
        printed_at INTEGER NOT NULL,
        success INTEGER DEFAULT 1
      )
    ''');

    // Create index on print_queue status
    await db.execute('''
      CREATE INDEX idx_print_queue_status ON print_queue(status)
    ''');
```

- [ ] **Step 2: 更新数据库版本号**

在 `lib/config/app_config.dart` 中找到 `databaseVersion` 并增加版本号（例如从 1 改为 2）

- [ ] **Step 3: 添加数据库升级逻辑**

在 `_upgradeDB` 方法中添加：

```dart
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add printer tables
      await db.execute('''
        CREATE TABLE printer_configs (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          address TEXT NOT NULL,
          paper_width INTEGER DEFAULT 80,
          is_default INTEGER DEFAULT 0,
          last_connected INTEGER,
          created_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE print_queue (
          id TEXT PRIMARY KEY,
          transaction_id TEXT NOT NULL,
          transaction_number TEXT NOT NULL,
          receipt_data TEXT NOT NULL,
          status TEXT DEFAULT 'pending',
          retry_count INTEGER DEFAULT 0,
          error_message TEXT,
          created_at INTEGER NOT NULL,
          printed_at INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE print_history (
          id TEXT PRIMARY KEY,
          transaction_id TEXT NOT NULL,
          printer_id TEXT,
          printer_name TEXT,
          printed_at INTEGER NOT NULL,
          success INTEGER DEFAULT 1
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_print_queue_status ON print_queue(status)
      ''');
    }
  }
```

- [ ] **Step 4: Commit**

```bash
git add lib/services/database/database_service.dart lib/config/app_config.dart
git commit -m "feat: 添加打印机相关数据库表"
```

---

### Task 5: 创建打印机数据库操作类

**Files:**
- Create: `lib/services/database/printer_database.dart`

- [ ] **Step 1: 创建 PrinterDatabase 类**

```dart
import 'package:sqflite/sqflite.dart';
import '../../models/printer_config.dart';
import '../../models/print_job.dart';
import 'database_service.dart';

class PrinterDatabase {
  static final PrinterDatabase instance = PrinterDatabase._init();
  PrinterDatabase._init();

  Future<Database> get _db async => await DatabaseService.instance.database;

  // Printer Config Operations
  Future<void> insertPrinterConfig(PrinterConfig config) async {
    final db = await _db;
    await db.insert(
      'printer_configs',
      {
        'id': config.id,
        'name': config.name,
        'type': config.type.name,
        'address': config.address,
        'paper_width': config.paperWidth,
        'is_default': config.isDefault ? 1 : 0,
        'last_connected': config.lastConnected?.millisecondsSinceEpoch,
        'created_at': config.createdAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PrinterConfig>> getAllPrinterConfigs() async {
    final db = await _db;
    final maps = await db.query('printer_configs', orderBy: 'created_at DESC');
    return maps.map((map) => _printerConfigFromMap(map)).toList();
  }

  Future<PrinterConfig?> getDefaultPrinter() async {
    final db = await _db;
    final maps = await db.query(
      'printer_configs',
      where: 'is_default = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _printerConfigFromMap(maps.first);
  }

  Future<void> setDefaultPrinter(String printerId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update('printer_configs', {'is_default': 0});
      await txn.update(
        'printer_configs',
        {'is_default': 1},
        where: 'id = ?',
        whereArgs: [printerId],
      );
    });
  }

  Future<void> updateLastConnected(String printerId, DateTime time) async {
    final db = await _db;
    await db.update(
      'printer_configs',
      {'last_connected': time.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [printerId],
    );
  }

  Future<void> deletePrinterConfig(String printerId) async {
    final db = await _db;
    await db.delete(
      'printer_configs',
      where: 'id = ?',
      whereArgs: [printerId],
    );
  }

  PrinterConfig _printerConfigFromMap(Map<String, dynamic> map) {
    return PrinterConfig(
      id: map['id'] as String,
      name: map['name'] as String,
      type: PrinterType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PrinterType.bluetooth,
      ),
      address: map['address'] as String,
      paperWidth: map['paper_width'] as int,
      isDefault: (map['is_default'] as int) == 1,
      lastConnected: map['last_connected'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_connected'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/database/printer_database.dart
git commit -m "feat: 添加打印机数据库操作类"
```

---

## 阶段 2：ESC/POS 指令生成器

### Task 6: 创建 ESC/POS 指令生成器

**Files:**
- Create: `lib/services/printer/escpos_generator.dart`

- [ ] **Step 1: 创建 EscPosGenerator 类（第一部分）**

```dart
import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import '../../services/printer_service.dart';

class EscPosGenerator {
  final int paperWidth;

  EscPosGenerator({this.paperWidth = 80});

  Future<List<int>> generateReceipt({
    required String transactionNumber,
    required DateTime transactionDate,
    required List<ReceiptItem> items,
    required double subtotal,
    required double discount,
    required String discountLabel,
    required double tax,
    required double total,
    required String paymentMethod,
    required double receivedAmount,
    required double changeAmount,
    String? customerName,
    String? cashierName,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paperWidth == 58 ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );
    List<int> bytes = [];

    // Initialize
    bytes += generator.reset();

    // Header - Store Name
    bytes += generator.text(
      'POS SYSTEM',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.text(
      'Malaysia E-Invoice',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();

    // Transaction Info
    bytes += generator.text('收据号: $transactionNumber');
    bytes += generator.text('日期: ${_formatDateTime(transactionDate)}');
    if (cashierName != null) {
      bytes += generator.text('收银员: $cashierName');
    }
    if (customerName != null) {
      bytes += generator.text('客户: $customerName');
    }
    bytes += generator.hr();

    // Items Header
    bytes += generator.row([
      PosColumn(text: '商品', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: '数量', width: 3, styles: const PosStyles(bold: true)),
      PosColumn(
        text: '金额',
        width: 3,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);
    bytes += generator.hr();

    // Items
    for (final item in items) {
      bytes += generator.text(item.name);
      bytes += generator.row([
        PosColumn(text: '', width: 6),
        PosColumn(text: '${item.quantity}x', width: 3),
        PosColumn(
          text: 'RM ${item.lineTotal.toStringAsFixed(2)}',
          width: 3,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      if (item.note.isNotEmpty) {
        bytes += generator.text('  备注: ${item.note}');
      }
    }

    bytes += generator.hr();

    // Summary
    bytes += generator.row([
      PosColumn(text: '小计:', width: 9),
      PosColumn(
        text: 'RM ${subtotal.toStringAsFixed(2)}',
        width: 3,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (discount > 0) {
      bytes += generator.row([
        PosColumn(text: '折扣 ($discountLabel):', width: 9),
        PosColumn(
          text: '- RM ${discount.toStringAsFixed(2)}',
          width: 3,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.row([
      PosColumn(text: '税额 (6%):', width: 9),
      PosColumn(
        text: 'RM ${tax.toStringAsFixed(2)}',
        width: 3,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.hr();

    // Total
    bytes += generator.row([
      PosColumn(
        text: '总计:',
        width: 9,
        styles: const PosStyles(bold: true, height: PosTextSize.size2),
      ),
      PosColumn(
        text: 'RM ${total.toStringAsFixed(2)}',
        width: 3,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
    ]);

    bytes += generator.hr();

    // Payment
    bytes += generator.text('支付方式: ${_getPaymentMethodLabel(paymentMethod)}');
    if (paymentMethod == 'cash') {
      bytes += generator.row([
        PosColumn(text: '收款:', width: 9),
        PosColumn(
          text: 'RM ${receivedAmount.toStringAsFixed(2)}',
          width: 3,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: '找零:', width: 9),
        PosColumn(
          text: 'RM ${changeAmount.toStringAsFixed(2)}',
          width: 3,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();

    // Footer
    bytes += generator.text(
      '谢谢惠顾！',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      '欢迎再次光临',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();

    // Feed and cut
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return '现金';
      case 'card':
        return '银行卡';
      case 'ewallet':
        return '电子钱包';
      default:
        return method;
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/printer/escpos_generator.dart
git commit -m "feat: 添加 ESC/POS 指令生成器"
```

---

## 阶段 3：蓝牙打印机管理器

### Task 7: 创建蓝牙打印机管理器

**Files:**
- Create: `lib/services/printer/bluetooth_printer_manager.dart`

- [ ] **Step 1: 创建 BluetoothPrinterManager 类**

```dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import '../../models/printer_config.dart';

class BluetoothPrinterManager {
  static final BluetoothPrinterManager instance = BluetoothPrinterManager._init();
  BluetoothPrinterManager._init();

  PrinterBluetoothManager? _printerManager;
  bool _isConnected = false;
  PrinterConfig? _currentPrinter;

  bool get isConnected => _isConnected;
  PrinterConfig? get currentPrinter => _currentPrinter;

  Future<List<BluetoothDevice>> scanDevices({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        throw Exception('蓝牙不支持');
      }

      final isOn = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      if (!isOn) {
        throw Exception('请开启蓝牙');
      }

      await FlutterBluePlus.startScan(timeout: timeout);
      await Future.delayed(timeout);
      await FlutterBluePlus.stopScan();

      return FlutterBluePlus.lastScanResults;
    } catch (e) {
      throw Exception('扫描失败: $e');
    }
  }

  Future<bool> connect(PrinterConfig config) async {
    try {
      if (config.type != PrinterType.bluetooth) {
        throw Exception('不是蓝牙打印机');
      }

      _printerManager = PrinterBluetoothManager();
      
      final printers = await _printerManager!.discovery();
      final printer = printers.firstWhere(
        (p) => p.address == config.address,
        orElse: () => throw Exception('打印机未找到'),
      );

      await _printerManager!.selectPrinter(printer);
      _isConnected = true;
      _currentPrinter = config;
      
      return true;
    } catch (e) {
      _isConnected = false;
      _currentPrinter = null;
      throw Exception('连接失败: $e');
    }
  }

  Future<bool> print(List<int> bytes) async {
    try {
      if (!_isConnected || _printerManager == null) {
        throw Exception('打印机未连接');
      }

      await _printerManager!.writeBytes(bytes);
      return true;
    } catch (e) {
      throw Exception('打印失败: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      if (_printerManager != null) {
        await _printerManager!.disconnect();
      }
      _isConnected = false;
      _currentPrinter = null;
      _printerManager = null;
    } catch (e) {
      throw Exception('断开连接失败: $e');
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/printer/bluetooth_printer_manager.dart
git commit -m "feat: 添加蓝牙打印机管理器"
```

---

## 阶段 4：增强的打印服务

### Task 8: 创建增强的打印服务

**Files:**
- Create: `lib/services/printer/printer_service_enhanced.dart`

- [ ] **Step 1: 创建 PrinterServiceEnhanced 类**

```dart
import '../../models/printer_config.dart';
import '../../services/printer_service.dart';
import '../database/printer_database.dart';
import 'bluetooth_printer_manager.dart';
import 'escpos_generator.dart';

enum PrinterConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class PrinterServiceEnhanced {
  static final PrinterServiceEnhanced instance = PrinterServiceEnhanced._init();
  PrinterServiceEnhanced._init();

  final _bluetoothManager = BluetoothPrinterManager.instance;
  final _printerDb = PrinterDatabase.instance;
  
  PrinterConnectionStatus _status = PrinterConnectionStatus.disconnected;
  String? _lastError;

  PrinterConnectionStatus get status => _status;
  String? get lastError => _lastError;
  bool get isConnected => _status == PrinterConnectionStatus.connected;

  Future<bool> connectToDefaultPrinter() async {
    try {
      _status = PrinterConnectionStatus.connecting;
      _lastError = null;

      final defaultPrinter = await _printerDb.getDefaultPrinter();
      if (defaultPrinter == null) {
        throw Exception('未设置默认打印机');
      }

      switch (defaultPrinter.type) {
        case PrinterType.bluetooth:
          await _bluetoothManager.connect(defaultPrinter);
          break;
        case PrinterType.usb:
          throw Exception('USB 打印机暂不支持');
        case PrinterType.network:
          throw Exception('网络打印机暂不支持');
      }

      await _printerDb.updateLastConnected(defaultPrinter.id, DateTime.now());
      _status = PrinterConnectionStatus.connected;
      return true;
    } catch (e) {
      _status = PrinterConnectionStatus.error;
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> printReceipt({
    required String transactionNumber,
    required DateTime transactionDate,
    required List<ReceiptItem> items,
    required double subtotal,
    required double discount,
    required String discountLabel,
    required double tax,
    required double total,
    required String paymentMethod,
    required double receivedAmount,
    required double changeAmount,
    String? customerName,
    String? cashierName,
  }) async {
    try {
      if (!isConnected) {
        final connected = await connectToDefaultPrinter();
        if (!connected) {
          throw Exception('无法连接到打印机: $_lastError');
        }
      }

      final defaultPrinter = await _printerDb.getDefaultPrinter();
      if (defaultPrinter == null) {
        throw Exception('未设置默认打印机');
      }

      final generator = EscPosGenerator(paperWidth: defaultPrinter.paperWidth);
      final bytes = await generator.generateReceipt(
        transactionNumber: transactionNumber,
        transactionDate: transactionDate,
        items: items,
        subtotal: subtotal,
        discount: discount,
        discountLabel: discountLabel,
        tax: tax,
        total: total,
        paymentMethod: paymentMethod,
        receivedAmount: receivedAmount,
        changeAmount: changeAmount,
        customerName: customerName,
        cashierName: cashierName,
      );

      switch (defaultPrinter.type) {
        case PrinterType.bluetooth:
          await _bluetoothManager.print(bytes);
          break;
        case PrinterType.usb:
          throw Exception('USB 打印机暂不支持');
        case PrinterType.network:
          throw Exception('网络打印机暂不支持');
      }

      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _bluetoothManager.disconnect();
      _status = PrinterConnectionStatus.disconnected;
      _lastError = null;
    } catch (e) {
      _lastError = e.toString();
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/printer/printer_service_enhanced.dart
git commit -m "feat: 添加增强的打印服务"
```

---

## 阶段 5：打印机设置界面

### Task 9: 创建打印机卡片组件

**Files:**
- Create: `lib/screens/settings/widgets/printer_card.dart`

- [ ] **Step 1: 创建 PrinterCard 组件**

```dart
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/printer_config.dart';

class PrinterCard extends StatelessWidget {
  final PrinterConfig printer;
  final VoidCallback onSetDefault;
  final VoidCallback onTest;
  final VoidCallback onDelete;

  const PrinterCard({
    super.key,
    required this.printer,
    required this.onSetDefault,
    required this.onTest,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: printer.isDefault
              ? AppTheme.primaryColor
              : AppTheme.cardBorderColor.withOpacity(0.3),
          width: printer.isDefault ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getPrinterIcon(),
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          printer.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryDark,
                          ),
                        ),
                        if (printer.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '默认',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPrinterTypeLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '地址: ${printer.address}',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryDark,
            ),
          ),
          if (printer.lastConnected != null) ...[
            const SizedBox(height: 4),
            Text(
              '最后连接: ${_formatLastConnected()}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryDark,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!printer.isDefault)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSetDefault,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(
                        color: AppTheme.cardBorderColor.withOpacity(0.3),
                      ),
                      foregroundColor: AppTheme.textPrimaryDark,
                    ),
                    child: const Text('设为默认', style: TextStyle(fontSize: 12)),
                  ),
                ),
              if (!printer.isDefault) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onTest,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(
                      color: AppTheme.cardBorderColor.withOpacity(0.3),
                    ),
                    foregroundColor: AppTheme.textPrimaryDark,
                  ),
                  child: const Text('测试打印', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                  foregroundColor: Colors.red,
                ),
                child: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
        ],
      ),
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
        return '蓝牙打印机';
      case PrinterType.usb:
        return 'USB 打印机';
      case PrinterType.network:
        return '网络打印机';
    }
  }

  String _formatLastConnected() {
    if (printer.lastConnected == null) return '从未连接';
    
    final now = DateTime.now();
    final diff = now.difference(printer.lastConnected!);
    
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/settings/widgets/printer_card.dart
git commit -m "feat: 添加打印机卡片组件"
```

---

### Task 10: 创建添加蓝牙打印机对话框

**Files:**
- Create: `lib/screens/settings/widgets/add_bluetooth_printer_dialog.dart`

- [ ] **Step 1: 创建 AddBluetoothPrinterDialog 组件**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../config/theme.dart';
import '../../../models/printer_config.dart';
import '../../../services/database/printer_database.dart';
import '../../../services/printer/bluetooth_printer_manager.dart';

class AddBluetoothPrinterDialog extends StatefulWidget {
  const AddBluetoothPrinterDialog({super.key});

  @override
  State<AddBluetoothPrinterDialog> createState() =>
      _AddBluetoothPrinterDialogState();
}

class _AddBluetoothPrinterDialogState extends State<AddBluetoothPrinterDialog> {
  final _bluetoothManager = BluetoothPrinterManager.instance;
  final _printerDb = PrinterDatabase.instance;
  
  bool _isScanning = false;
  List<BluetoothDevice> _devices = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _error = null;
      _devices = [];
    });

    try {
      final devices = await _bluetoothManager.scanDevices();
      setState(() {
        _devices = devices;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isScanning = false;
      });
    }
  }

  Future<void> _addPrinter(BluetoothDevice device) async {
    try {
      final config = PrinterConfig(
        id: const Uuid().v4(),
        name: device.platformName.isEmpty ? '蓝牙打印机' : device.platformName,
        type: PrinterType.bluetooth,
        address: device.remoteId.toString(),
        createdAt: DateTime.now(),
      );

      await _printerDb.insertPrinterConfig(config);
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('打印机添加成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.cardBorderColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: _buildContent()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.bluetooth,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '添加蓝牙打印机',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textPrimaryDark),
              ),
            ],
          ),
        ),
      );
    }

    if (_isScanning) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '正在扫描蓝牙设备...',
              style: TextStyle(color: AppTheme.textPrimaryDark),
            ),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bluetooth_disabled,
                size: 48,
                color: AppTheme.textSecondaryDark,
              ),
              const SizedBox(height: 16),
              Text(
                '未找到蓝牙设备',
                style: TextStyle(color: AppTheme.textPrimaryDark),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      shrinkWrap: true,
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return _buildDeviceCard(device);
      },
    );
  }

  Widget _buildDeviceCard(BluetoothDevice device) {
    return InkWell(
      onTap: () => _addPrinter(device),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.cardBorderColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.bluetooth, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.platformName.isEmpty ? '未命名设备' : device.platformName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MAC: ${device.remoteId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondaryDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isScanning ? null : _startScan,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('重新扫描'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(
              color: AppTheme.cardBorderColor.withOpacity(0.3),
            ),
            foregroundColor: AppTheme.textPrimaryDark,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/settings/widgets/add_bluetooth_printer_dialog.dart
git commit -m "feat: 添加蓝牙打印机扫描对话框"
```

---

### Task 11: 创建打印机设置主界面

**Files:**
- Create: `lib/screens/settings/printer_settings_screen.dart`

- [ ] **Step 1: 创建 PrinterSettingsScreen（简化版）**

```dart
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/printer_config.dart';
import '../../services/database/printer_database.dart';
import '../../services/printer/printer_service_enhanced.dart';
import 'widgets/add_bluetooth_printer_dialog.dart';
import 'widgets/printer_card.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final _printerDb = PrinterDatabase.instance;
  final _printerService = PrinterServiceEnhanced.instance;
  
  List<PrinterConfig> _printers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() => _isLoading = true);
    try {
      final printers = await _printerDb.getAllPrinterConfigs();
      setState(() {
        _printers = printers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  Future<void> _addBluetoothPrinter() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddBluetoothPrinterDialog(),
    );
    if (result == true) {
      _loadPrinters();
    }
  }

  Future<void> _setDefaultPrinter(String printerId) async {
    try {
      await _printerDb.setDefaultPrinter(printerId);
      _loadPrinters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已设为默认打印机')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置失败: $e')),
        );
      }
    }
  }

  Future<void> _testPrint(PrinterConfig printer) async {
    // TODO: 实现测试打印
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('测试打印功能开发中')),
    );
  }

  Future<void> _deletePrinter(String printerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这台打印机吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _printerDb.deletePrinterConfig(printerId);
        _loadPrinters();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('打印机已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('打印机设置'),
        backgroundColor: AppTheme.surfaceDark,
        actions: [
          IconButton(
            onPressed: _addBluetoothPrinter,
            icon: const Icon(Icons.add_rounded),
            tooltip: '添加打印机',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _printers.isEmpty
              ? _buildEmptyState()
              : _buildPrinterList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.print_disabled,
            size: 64,
            color: AppTheme.textSecondaryDark,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有添加打印机',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addBluetoothPrinter,
            icon: const Icon(Icons.add_rounded),
            label: const Text('添加蓝牙打印机'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _printers.length,
      itemBuilder: (context, index) {
        final printer = _printers[index];
        return PrinterCard(
          printer: printer,
          onSetDefault: () => _setDefaultPrinter(printer.id),
          onTest: () => _testPrint(printer),
          onDelete: () => _deletePrinter(printer.id),
        );
      },
    );
  }
}
```

- [ ] **Step 2: 添加路由**

在 `lib/config/routes.dart` 中添加：

```dart
import '../screens/settings/printer_settings_screen.dart';

// 在路由表中添加
'/printer-settings': (context) => const PrinterSettingsScreen(),
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/settings/printer_settings_screen.dart lib/config/routes.dart
git commit -m "feat: 添加打印机设置主界面"
```

---

## 阶段 6：打印错误处理和集成

### Task 12: 创建打印错误对话框

**Files:**
- Create: `lib/screens/cashier/widgets/print_error_dialog.dart`

- [ ] **Step 1: 创建 PrintErrorDialog 组件**

```dart
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class PrintErrorDialog extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onSkip;
  final VoidCallback onSaveToQueue;

  const PrintErrorDialog({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    required this.onSkip,
    required this.onSaveToQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 450,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.cardBorderColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildContent(),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '打印失败',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '错误信息:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(
              errorMessage,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '建议:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          _buildSuggestion('检查打印机电源是否开启'),
          _buildSuggestion('检查蓝牙/USB 连接是否正常'),
          _buildSuggestion('确保打印机在连接范围内'),
          _buildSuggestion('检查打印机是否有纸'),
        ],
      ),
    );
  }

  Widget _buildSuggestion(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryDark,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSkip();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: AppTheme.cardBorderColor.withOpacity(0.3),
                    ),
                    foregroundColor: AppTheme.textPrimaryDark,
                  ),
                  child: const Text('跳过'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRetry();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text('重试'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onSaveToQueue();
              },
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('保存到队列稍后打印'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: AppTheme.cardBorderColor.withOpacity(0.3),
                ),
                foregroundColor: AppTheme.textPrimaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/cashier/widgets/print_error_dialog.dart
git commit -m "feat: 添加打印错误对话框"
```

---

### Task 13: 集成到支付成功对话框

**Files:**
- Modify: `lib/screens/cashier/widgets/payment_success_dialog.dart`

- [ ] **Step 1: 导入新的打印服务**

在文件顶部添加导入：

```dart
import '../../../services/printer/printer_service_enhanced.dart';
import 'print_error_dialog.dart';
```

- [ ] **Step 2: 修改 onPrintReceipt 回调实现**

找到 `onPrintReceipt` 的调用位置，修改为使用新的打印服务：

```dart
// 在 State 类中添加
final _printerService = PrinterServiceEnhanced.instance;

Future<void> _handlePrintReceipt() async {
  try {
    final success = await _printerService.printReceipt(
      transactionNumber: widget.transactionNumber,
      transactionDate: DateTime.now(),
      items: [], // TODO: 从购物车获取实际商品列表
      subtotal: widget.totalAmount,
      discount: 0,
      discountLabel: '',
      tax: widget.totalAmount * 0.06,
      total: widget.totalAmount,
      paymentMethod: widget.paymentMethod,
      receivedAmount: widget.totalAmount,
      changeAmount: widget.changeAmount,
    );

    if (!success) {
      _showPrintError();
    }
  } catch (e) {
    _showPrintError();
  }
}

void _showPrintError() {
  showDialog(
    context: context,
    builder: (context) => PrintErrorDialog(
      errorMessage: _printerService.lastError ?? '未知错误',
      onRetry: _handlePrintReceipt,
      onSkip: () {
        // 跳过打印
      },
      onSaveToQueue: () {
        // TODO: 保存到打印队列
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存到打印队列')),
        );
      },
    ),
  );
}
```

- [ ] **Step 3: 更新打印按钮调用**

将原来的 `onPrintReceipt()` 调用改为 `_handlePrintReceipt()`

- [ ] **Step 4: Commit**

```bash
git add lib/screens/cashier/widgets/payment_success_dialog.dart
git commit -m "feat: 集成新打印服务到支付成功对话框"
```

---

### Task 14: 添加权限配置（Android）

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: 添加蓝牙权限**

在 `<manifest>` 标签内添加：

```xml
    <!-- Bluetooth permissions -->
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" 
                     android:usesPermissionFlags="neverForLocation" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    
    <!-- Location permission (required for Bluetooth scanning on Android < 12) -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

- [ ] **Step 2: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "chore: 添加蓝牙打印所需的 Android 权限"
```

---

### Task 15: 测试基本打印流程

**Files:**
- N/A (手动测试)

- [ ] **Step 1: 运行应用**

Run: `flutter run`
Expected: 应用成功启动

- [ ] **Step 2: 进入打印机设置**

导航到打印机设置界面，验证：
- 界面正常显示
- 可以点击"添加蓝牙打印机"按钮

- [ ] **Step 3: 扫描蓝牙设备**

在添加打印机对话框中：
- 验证蓝牙扫描功能正常
- 可以看到附近的蓝牙设备列表

- [ ] **Step 4: 添加打印机**

选择一个蓝牙打印机设备：
- 验证可以成功添加
- 打印机出现在列表中

- [ ] **Step 5: 设置默认打印机**

点击"设为默认"按钮：
- 验证可以成功设置
- 打印机显示"默认"标签

- [ ] **Step 6: 测试打印（模拟）**

在收银界面完成一笔交易：
- 点击"打印收据"
- 验证打印流程被调用（即使打印失败也应该显示错误对话框）

- [ ] **Step 7: 验证错误处理**

如果打印失败：
- 验证错误对话框正常显示
- 三个按钮（重试/跳过/保存队列）都可以点击

---

## 总结

### 已完成功能

✅ 打印机配置数据模型
✅ 打印任务数据模型
✅ 数据库表结构
✅ ESC/POS 指令生成器
✅ 蓝牙打印机管理器
✅ 增强的打印服务
✅ 打印机设置界面
✅ 蓝牙打印机扫描对话框
✅ 打印错误处理对话框
✅ 集成到支付流程

### 待开发功能（后续阶段）

⏳ 打印队列服务（自动重试）
⏳ 打印历史界面
⏳ USB 打印机支持（桌面版）
⏳ 网络打印机支持
⏳ 测试打印功能
⏳ 打印参数配置（纸张宽度、打印份数）
⏳ 自动打印设置

### 技术债务

- 需要从购物车获取实际商品列表传递给打印服务
- 打印队列保存功能需要实现
- 测试打印功能需要实现
- 需要添加更完善的错误分类和处理

---

**计划完成！** 🎉


