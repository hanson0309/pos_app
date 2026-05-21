import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../config/app_config.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConfig.databaseName);

    return await openDatabase(
      path,
      version: AppConfig.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Device Config Table
    await db.execute('''
      CREATE TABLE device_config (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Local Transactions Table
    await db.execute('''
      CREATE TABLE local_transactions (
        id TEXT PRIMARY KEY,
        transaction_number TEXT NOT NULL,
        transaction_date INTEGER NOT NULL,
        cashier_id TEXT NOT NULL,
        customer_id TEXT,
        items_json TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax_amount REAL NOT NULL,
        total_amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // Products Table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        barcode TEXT,
        price REAL NOT NULL,
        cost_price REAL,
        tax_type TEXT NOT NULL,
        tax_rate REAL NOT NULL,
        stock_quantity INTEGER DEFAULT 0,
        reorder_level INTEGER,
        batch_number TEXT,
        expiry_date INTEGER,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create index on barcode
    await db.execute('''
      CREATE INDEX idx_products_barcode ON products(barcode)
    ''');

    // Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        customer_type TEXT NOT NULL,
        address TEXT,
        tax_number TEXT,
        is_active INTEGER DEFAULT 1,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Appointments Table (Optional Module)
    await db.execute('''
      CREATE TABLE appointments (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        appointment_date INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        service_type TEXT NOT NULL,
        service_items_json TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        reminder_sent INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        action TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        max_retries INTEGER DEFAULT 10,
        next_retry_at INTEGER,
        error_message TEXT,
        status TEXT DEFAULT 'pending',
        created_at INTEGER NOT NULL
      )
    ''');

    // Inventory Log Table (Optional Module)
    await db.execute('''
      CREATE TABLE inventory_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        quantity_change INTEGER NOT NULL,
        before_quantity INTEGER NOT NULL,
        after_quantity INTEGER NOT NULL,
        reference_id TEXT,
        notes TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('''
      CREATE INDEX idx_transactions_date ON local_transactions(transaction_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_queue_status ON sync_queue(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_appointments_date ON appointments(appointment_date)
    ''');

    // Printer Configs Table
    await db.execute('''
      CREATE TABLE printer_configs (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        address TEXT NOT NULL,
        paper_width INTEGER DEFAULT 80,
        is_default INTEGER DEFAULT 0,
        last_connected INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
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
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add printer-related tables in version 2
      await db.execute('''
        CREATE TABLE printer_configs (
          id TEXT PRIMARY KEY,
          tenant_id TEXT NOT NULL,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          address TEXT NOT NULL,
          paper_width INTEGER DEFAULT 80,
          is_default INTEGER DEFAULT 0,
          last_connected INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
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

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> count(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    final result = await db.query(
      table,
      columns: ['COUNT(*) as count'],
      where: where,
      whereArgs: whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Transaction support
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // Clear all data (for testing or logout)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('local_transactions');
    await db.delete('products');
    await db.delete('customers');
    await db.delete('appointments');
    await db.delete('sync_queue');
    await db.delete('inventory_log');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
