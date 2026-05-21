import 'package:sqflite/sqflite.dart';
import '../../models/printer_config.dart';
import 'database_service.dart';

class PrinterDatabase {
  static const String tableName = 'printer_configs';

  final DatabaseService _dbService = DatabaseService.instance;

  // Insert a new printer configuration
  Future<String> insertPrinterConfig(PrinterConfig config) async {
    final db = await _dbService.database;

    final data = {
      'id': config.id ?? _generateId(),
      'tenant_id': config.tenantId,
      'name': config.name,
      'type': config.type.name,
      'address': config.address,
      'paper_width': config.paperWidth,
      'is_default': config.isDefault ? 1 : 0,
      'last_connected': config.lastConnected?.millisecondsSinceEpoch,
      'created_at': config.createdAt.millisecondsSinceEpoch,
      'updated_at': config.updatedAt.millisecondsSinceEpoch,
    };

    await db.insert(
      tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return data['id'] as String;
  }

  // Get all printer configurations
  Future<List<PrinterConfig>> getAllPrinterConfigs() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'is_default DESC, name ASC',
    );

    return maps.map((map) => _printerConfigFromMap(map)).toList();
  }

  // Get printer configurations by tenant
  Future<List<PrinterConfig>> getPrinterConfigsByTenant(String tenantId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
      orderBy: 'is_default DESC, name ASC',
    );

    return maps.map((map) => _printerConfigFromMap(map)).toList();
  }

  // Get a printer configuration by ID
  Future<PrinterConfig?> getPrinterConfigById(String id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _printerConfigFromMap(maps.first);
  }

  // Get the default printer configuration
  Future<PrinterConfig?> getDefaultPrinterConfig() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_default = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _printerConfigFromMap(maps.first);
  }

  // Get the default printer configuration for a specific tenant
  Future<PrinterConfig?> getDefaultPrinterConfigByTenant(String tenantId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'tenant_id = ? AND is_default = ?',
      whereArgs: [tenantId, 1],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _printerConfigFromMap(maps.first);
  }

  // Update a printer configuration
  Future<int> updatePrinterConfig(PrinterConfig config) async {
    final db = await _dbService.database;

    final data = {
      'tenant_id': config.tenantId,
      'name': config.name,
      'type': config.type.name,
      'address': config.address,
      'paper_width': config.paperWidth,
      'is_default': config.isDefault ? 1 : 0,
      'last_connected': config.lastConnected?.millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };

    return await db.update(
      tableName,
      data,
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  // Update last connected timestamp
  Future<int> updateLastConnected(String id, DateTime timestamp) async {
    final db = await _dbService.database;

    return await db.update(
      tableName,
      {
        'last_connected': timestamp.millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Set a printer as default (and unset others)
  Future<void> setDefaultPrinter(String id) async {
    final db = await _dbService.database;

    await db.transaction((txn) async {
      // First, unset all default printers
      await txn.update(
        tableName,
        {
          'is_default': 0,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // Then set the specified printer as default
      await txn.update(
        tableName,
        {
          'is_default': 1,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // Set a printer as default for a specific tenant (and unset others in that tenant)
  Future<void> setDefaultPrinterByTenant(String id, String tenantId) async {
    final db = await _dbService.database;

    await db.transaction((txn) async {
      // First, unset all default printers for this tenant
      await txn.update(
        tableName,
        {
          'is_default': 0,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'tenant_id = ?',
        whereArgs: [tenantId],
      );

      // Then set the specified printer as default
      await txn.update(
        tableName,
        {
          'is_default': 1,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ? AND tenant_id = ?',
        whereArgs: [id, tenantId],
      );
    });
  }

  // Delete a printer configuration
  Future<int> deletePrinterConfig(String id) async {
    final db = await _dbService.database;

    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all printer configurations for a tenant
  Future<int> deletePrinterConfigsByTenant(String tenantId) async {
    final db = await _dbService.database;

    return await db.delete(
      tableName,
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
    );
  }

  // Check if a printer with the given address already exists
  Future<bool> printerExists(String address, {String? excludeId}) async {
    final db = await _dbService.database;

    String where = 'address = ?';
    List<dynamic> whereArgs = [address];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  // Get printer count
  Future<int> getPrinterCount() async {
    final db = await _dbService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get printer count by tenant
  Future<int> getPrinterCountByTenant(String tenantId) async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE tenant_id = ?',
      [tenantId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Helper method to convert database map to PrinterConfig
  PrinterConfig _printerConfigFromMap(Map<String, dynamic> map) {
    return PrinterConfig(
      id: map['id'] as String,
      tenantId: map['tenant_id'] as String,
      name: map['name'] as String,
      type: PrinterType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PrinterType.bluetooth,
      ),
      address: map['address'] as String,
      paperWidth: map['paper_width'] as int? ?? 80,
      isDefault: (map['is_default'] as int) == 1,
      lastConnected: map['last_connected'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_connected'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  // Helper method to generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
