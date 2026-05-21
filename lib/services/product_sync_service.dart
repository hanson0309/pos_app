import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import 'api/endpoints.dart';
import 'database/database_service.dart';

class ProductSyncService {
  final DatabaseService _db = DatabaseService.instance;
  final ProductApi _api = ProductApi();
  final _storage = const FlutterSecureStorage();

  static const String _lastSyncKey = 'last_product_sync';

  // Initial full sync (called after device pairing)
  Future<void> initialSync() async {
    try {
      print('Starting initial product sync...');

      int page = 1;
      int totalSynced = 0;

      while (true) {
        print('Fetching page $page...');
        final response = await _api.getProducts(
          page: page,
          limit: 100,
        );

        final products = response['data'] as List;
        print('Received ${products.length} products from API');
        if (products.isEmpty) break;

        print('Saving ${products.length} products to local database...');
        await _saveProductsToLocal(products);
        totalSynced += products.length;
        print('Synced $totalSynced products...');

        final pagination = response['pagination'];
        if (pagination['has_next'] != true) break;

        page++;
      }

      print('Writing last sync timestamp...');
      await _storage.write(
        key: _lastSyncKey,
        value: DateTime.now().toIso8601String(),
      );

      print('Initial sync completed: $totalSynced products');
    } catch (e, stackTrace) {
      print('Initial sync error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Incremental sync (called periodically)
  Future<void> incrementalSync() async {
    try {
      final lastSyncStr = await _storage.read(key: _lastSyncKey);

      if (lastSyncStr == null) {
        return await initialSync();
      }

      final lastSync = DateTime.parse(lastSyncStr);
      print('Starting incremental sync from $lastSync...');

      int page = 1;
      int totalUpdated = 0;

      while (true) {
        final response = await _api.getProducts(
          updatedSince: lastSync,
          page: page,
          limit: 100,
        );

        final products = response['data'] as List;
        if (products.isEmpty) break;

        await _saveProductsToLocal(products);
        totalUpdated += products.length;

        final pagination = response['pagination'];
        if (pagination['has_next'] != true) break;

        page++;
      }

      await _storage.write(
        key: _lastSyncKey,
        value: DateTime.now().toIso8601String(),
      );

      print('Incremental sync completed: $totalUpdated products updated');
    } catch (e) {
      print('Incremental sync error: $e');
    }
  }

  Future<void> _saveProductsToLocal(List<dynamic> products) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      for (final productJson in products) {
        final product = Product.fromJson(productJson);

        await txn.insert(
          'products',
          {
            'id': product.id,
            'tenant_id': product.tenantId,
            'name': product.name,
            'description': product.description,
            'barcode': product.barcode,
            'unit_price': product.price,
            'cost_price': product.costPrice,
            'tax_type': product.taxType,
            'tax_rate': product.taxRate,
            'stock_quantity': product.stockQuantity,
            'reorder_level': product.reorderLevel,
            'batch_number': product.batchNumber,
            'expiry_date': product.expiryDate?.millisecondsSinceEpoch,
            'image_url': product.imageUrl,
            'is_active': product.isActive ? 1 : 0,
            'deleted_at': product.isActive ? null : DateTime.now().millisecondsSinceEpoch,
            'created_at': product.createdAt.millisecondsSinceEpoch,
            'updated_at': product.updatedAt.millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Product>> getLocalProducts({
    String? search,
    bool activeOnly = true,
  }) async {
    final db = await _db.database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (activeOnly) {
      where = 'is_active = ?';
      whereArgs.add(1);
    }

    if (search != null && search.isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += '(name LIKE ? OR description LIKE ? OR barcode LIKE ?)';
      final searchPattern = '%$search%';
      whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
    }

    final results = await db.query(
      'products',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
    );

    return results.map((row) => _productFromDb(row)).toList();
  }

  Future<Product?> findByBarcode(String barcode) async {
    final db = await _db.database;
    final results = await db.query(
      'products',
      where: 'barcode = ? AND is_active = ?',
      whereArgs: [barcode, 1],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return _productFromDb(results.first);
  }

  Product _productFromDb(Map<String, dynamic> row) {
    return Product(
      id: row['id'],
      tenantId: row['tenant_id'],
      name: row['name'],
      description: row['description'],
      barcode: row['barcode'],
      price: row['unit_price'],
      costPrice: row['cost_price'],
      taxType: row['tax_type'],
      taxRate: row['tax_rate'],
      stockQuantity: row['stock_quantity'],
      reorderLevel: row['reorder_level'],
      batchNumber: row['batch_number'],
      expiryDate: row['expiry_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['expiry_date'])
          : null,
      imageUrl: row['image_url'],
      isActive: row['is_active'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']),
    );
  }
}

