# Product API Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement product synchronization between MyEInvoice backend and POS Flutter app with offline support and incremental sync.

**Architecture:** Flutter app syncs products from backend API to local SQLite database. Initial full sync on device pairing, then hourly incremental sync using `updated_since` parameter. All operations use local database for offline support.

**Tech Stack:** Flutter, SQLite (sqflite), Dio (HTTP), json_serializable, flutter_secure_storage

---

## File Structure

### Files to Modify

1. **lib/models/product.dart** - Update model to match backend fields (unit_price, deleted_at)
2. **lib/services/database/database_service.dart** - Add missing fields to products table
3. **lib/services/api/endpoints.dart** - Update ProductApi with updated_since parameter

### Files to Create

4. **lib/services/product_sync_service.dart** - Product synchronization service
5. **lib/services/sync_manager.dart** - Auto-sync manager with timer
6. **test/services/product_sync_service_test.dart** - Unit tests for sync service

---

## Task 1: Update Product Model

**Files:**
- Modify: `lib/models/product.dart`
- Generate: `lib/models/product.g.dart`

- [ ] **Step 1: Update Product model fields**

Update the model to match backend API response:

```dart
// lib/models/product.dart
import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  @JsonKey(name: '_id')
  final String? id;

  @JsonKey(name: 'tenant_id')
  final String tenantId;

  final String name;
  final String? description;
  final String? barcode;
  
  // Backend uses 'unit_price', but we map it to 'price' in Flutter
  @JsonKey(name: 'unit_price')
  final double price;

  @JsonKey(name: 'cost_price')
  final double? costPrice;

  @JsonKey(name: 'tax_type')
  final String taxType;

  @JsonKey(name: 'tax_rate')
  final double taxRate;

  @JsonKey(name: 'stock_quantity')
  final int stockQuantity;

  @JsonKey(name: 'reorder_level')
  final int? reorderLevel;

  @JsonKey(name: 'batch_number')
  final String? batchNumber;

  @JsonKey(name: 'expiry_date')
  final DateTime? expiryDate;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Product({
    this.id,
    required this.tenantId,
    required this.name,
    this.description,
    this.barcode,
    required this.price,
    this.costPrice,
    required this.taxType,
    required this.taxRate,
    this.stockQuantity = 0,
    this.reorderLevel,
    this.batchNumber,
    this.expiryDate,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  Map<String, dynamic> toJson() => _$ProductToJson(this);

  // Check if product is low stock
  bool get isLowStock {
    if (reorderLevel == null) return false;
    return stockQuantity <= reorderLevel!;
  }

  // Check if product is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  // Check if product is expiring soon (within 30 days)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry > 0 && daysUntilExpiry <= 30;
  }

  Product copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? description,
    String? barcode,
    double? price,
    double? costPrice,
    String? taxType,
    double? taxRate,
    int? stockQuantity,
    int? reorderLevel,
    String? batchNumber,
    DateTime? expiryDate,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      taxType: taxType ?? this.taxType,
      taxRate: taxRate ?? this.taxRate,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

- [ ] **Step 2: Regenerate JSON serialization code**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: `product.g.dart` regenerated successfully

- [ ] **Step 3: Commit model changes**

```bash
git add lib/models/product.dart lib/models/product.g.dart
git commit -m "refactor: update Product model to match backend API

- Map unit_price to price field
- Add is_active field from API response
- Update JSON serialization"
```

---

## Task 2: Update Database Schema

**Files:**
- Modify: `lib/services/database/database_service.dart`

- [ ] **Step 1: Add missing fields to products table**

Update the products table creation in `_createDB` method:

```dart
// In _createDB method, update products table:
await db.execute('''
  CREATE TABLE products (
    id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    barcode TEXT,
    unit_price REAL NOT NULL,
    cost_price REAL,
    tax_type TEXT NOT NULL,
    tax_rate REAL NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    reorder_level INTEGER,
    batch_number TEXT,
    expiry_date INTEGER,
    image_url TEXT,
    is_active INTEGER DEFAULT 1,
    deleted_at INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
''');

// Create indexes
await db.execute('''
  CREATE INDEX idx_products_barcode ON products(barcode)
''');

await db.execute('''
  CREATE INDEX idx_products_updated_at ON products(updated_at)
''');

await db.execute('''
  CREATE INDEX idx_products_name ON products(name)
''');

await db.execute('''
  CREATE INDEX idx_products_active ON products(is_active)
''');
```

- [ ] **Step 2: Add database upgrade migration**

Add migration logic in `_upgradeDB` method:

```dart
Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Add tenant_id, deleted_at, created_at if upgrading from v1
    await db.execute('ALTER TABLE products ADD COLUMN tenant_id TEXT');
    await db.execute('ALTER TABLE products ADD COLUMN deleted_at INTEGER');
    await db.execute('ALTER TABLE products ADD COLUMN created_at INTEGER');
    
    // Rename price to unit_price
    await db.execute('ALTER TABLE products RENAME COLUMN price TO unit_price');
    
    // Add new indexes
    await db.execute('CREATE INDEX idx_products_updated_at ON products(updated_at)');
    await db.execute('CREATE INDEX idx_products_name ON products(name)');
    await db.execute('CREATE INDEX idx_products_active ON products(is_active)');
  }
}
```

- [ ] **Step 3: Update database version in config**

```dart
// lib/config/app_config.dart
class AppConfig {
  // ... other config
  static const int databaseVersion = 2; // Increment version
}
```

- [ ] **Step 4: Commit database changes**

```bash
git add lib/services/database/database_service.dart lib/config/app_config.dart
git commit -m "feat: update products table schema for API sync

- Add tenant_id, deleted_at, created_at fields
- Rename price to unit_price
- Add indexes for sync optimization
- Add migration from v1 to v2"
```

---

## Task 3: Update ProductApi with Incremental Sync

**Files:**
- Modify: `lib/services/api/endpoints.dart`

- [ ] **Step 1: Add updated_since parameter to getProducts**

Update the `ProductApi.getProducts` method in the existing ProductApi class:

```dart
// Get products with incremental sync support
Future<Map<String, dynamic>> getProducts({
  String? search,
  String? barcode,
  DateTime? updatedSince,  // NEW: for incremental sync
  int? page,
  int? limit,
}) async {
  final response = await _apiService.get(
    '/pos/products',
    queryParameters: {
      if (search != null) 'search': search,
      if (barcode != null) 'barcode': barcode,
      if (updatedSince != null) 'updated_since': updatedSince.toIso8601String(),
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    },
  );

  // Return the full response including pagination
  return {
    'data': response.data['data'],
    'pagination': response.data['pagination'],
  };
}
```

- [ ] **Step 2: Commit API changes**

```bash
git add lib/services/api/endpoints.dart
git commit -m "feat: add incremental sync support to ProductApi

- Add updatedSince parameter to getProducts
- Return full response with pagination data"
```

---

## Task 4: Create ProductSyncService

**Files:**
- Create: `lib/services/product_sync_service.dart`

This task creates the complete ProductSyncService in one file. We'll commit it in parts as we build it up.

- [ ] **Step 1: Create file with class structure and initialSync**

Create `lib/services/product_sync_service.dart`:

```dart
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
        final response = await _api.getProducts(
          page: page,
          limit: 100,
        );
        
        final products = response['data'] as List;
        if (products.isEmpty) break;
        
        await _saveProductsToLocal(products);
        totalSynced += products.length;
        print('Synced $totalSynced products...');
        
        final pagination = response['pagination'];
        if (pagination['has_next'] != true) break;
        
        page++;
      }
      
      await _storage.write(
        key: _lastSyncKey,
        value: DateTime.now().toIso8601String(),
      );
      
      print('Initial sync completed: $totalSynced products');
    } catch (e) {
      print('Initial sync error: $e');
      rethrow;
    }
  }

  // Placeholder for next methods
  Future<void> _saveProductsToLocal(List<dynamic> products) async {
    // Will implement in next step
  }
}
```

- [ ] **Step 2: Add incrementalSync method**

Add this method after initialSync:

```dart
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
```

- [ ] **Step 3: Implement _saveProductsToLocal**

Replace the placeholder with full implementation:

```dart
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
```

- [ ] **Step 4: Add local query methods**

```dart
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
```

- [ ] **Step 5: Commit complete ProductSyncService**

```bash
git add lib/services/product_sync_service.dart
git commit -m "feat: complete ProductSyncService implementation

- Add local query methods
- Implement barcode search
- Add database row converter"
```

---

## Task 5: Create SyncManager

**Files:**
- Create: `lib/services/sync_manager.dart`

- [ ] **Step 1: Create SyncManager class**

```dart
import 'dart:async';
import 'product_sync_service.dart';

class SyncManager {
  final ProductSyncService _productSync = ProductSyncService();
  Timer? _syncTimer;
  
  void startAutoSync() {
    _productSync.incrementalSync();
    _syncTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _productSync.incrementalSync(),
    );
  }
  
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  Future<void> manualSync() async {
    await _productSync.incrementalSync();
  }
  
  bool get isAutoSyncRunning => _syncTimer != null && _syncTimer!.isActive;
}
```

- [ ] **Step 2: Commit SyncManager**

```bash
git add lib/services/sync_manager.dart
git commit -m "feat: implement SyncManager for auto-sync

- Hourly automatic sync
- Manual sync trigger
- Start/stop controls"
```

---

## Summary

This plan implements product synchronization between MyEInvoice backend and POS Flutter app.

**Tasks completed:**
1. Update Product model to match backend (unit_price, is_active)
2. Update database schema with new fields and indexes
3. Add incremental sync support to ProductApi
4. Implement ProductSyncService with full and incremental sync
5. Create SyncManager for automatic hourly sync

**Key features:**
- Initial full sync on device pairing
- Hourly incremental sync using updated_since parameter
- Offline operation with local SQLite database
- Product search and barcode lookup
- Server-wins conflict resolution

**Estimated time:** 3-4 hours
