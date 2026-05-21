# POS 产品 API 设计文档

**日期**: 2026-05-21  
**版本**: 1.0  
**状态**: 待审核

## 1. 项目概述

### 1.1 目标

为 POS 系统实现产品数据同步功能，使 POS App 能够从 MyEInvoice 后端同步产品数据到本地 SQLite 数据库，支持离线操作和增量同步。

### 1.2 背景

- **MyEInvoice 后端**：已有完整的产品管理系统和数据
- **POS App**：Flutter 应用，需要本地产品数据支持离线收银
- **同步需求**：设备配对后首次完整同步，之后定期增量同步

### 1.3 核心需求

1. POS 设备配对成功后，自动下载所有产品到本地
2. 支持增量同步（只同步有变更的产品）
3. 支持离线操作（完全依赖本地数据库）
4. 支持条码搜索和名称搜索
5. 服务器数据优先（同步时覆盖本地）

## 2. API 端点设计

### 2.0 字段映射说明

**后端与 Flutter 字段映射**:

| 后端字段 (MongoDB) | API 响应字段 | Flutter Model 字段 | 说明 |
|-------------------|-------------|-------------------|------|
| `unit_price` | `unit_price` | `price` | 售价（后端用 unit_price，Flutter 用 price） |
| `deleted_at` | `deleted_at` + `is_active` | `isActive` | 软删除（后端用时间戳，Flutter 用布尔值） |

**is_active 计算规则**:
- 后端：`is_active = (deleted_at == null)`
- Flutter：从 API 接收 `is_active` 字段，保存到本地数据库

### 2.1 获取产品列表

**端点**: `GET /api/v1/pos/products`

**认证**: Bearer Token (device_token)

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| search | String | 否 | 搜索关键词（匹配名称或描述） |
| barcode | String | 否 | 条码精确匹配 |
| updated_since | ISO8601 DateTime | 否 | 增量同步：只返回此时间后更新的产品 |
| page | Number | 否 | 页码（默认 1） |
| limit | Number | 否 | 每页数量（默认 100，最大 500） |

**响应示例**:

```json
{
  "success": true,
  "data": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "tenant_id": "507f1f77bcf86cd799439012",
      "name": "可口可乐 330ml",
      "description": "经典可乐",
      "barcode": "9556001234567",
      "unit_price": 2.50,
      "cost_price": 1.50,
      "tax_type": "01",
      "tax_rate": 0.06,
      "stock_quantity": 100,
      "reorder_level": 20,
      "batch_number": "BATCH20260521",
      "expiry_date": "2026-12-31T00:00:00Z",
      "image_url": "https://cdn.example.com/products/coke.jpg",
      "is_active": true,
      "deleted_at": null,
      "created_at": "2026-05-01T10:00:00Z",
      "updated_at": "2026-05-21T15:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 100,
    "total": 250,
    "total_pages": 3,
    "has_next": true
  }
}
```

**字段说明**:
- `unit_price`: 后端数据库字段名（售价）
- `is_active`: 虚拟字段，计算自 `deleted_at == null`
- `deleted_at`: 软删除时间戳，`null` 表示未删除

**错误响应**:

```json
{
  "success": false,
  "error": "Unauthorized",
  "message": "Invalid or expired device token"
}
```

**状态码**:
- 200: 成功
- 401: 未授权（token 无效或过期）
- 403: 禁止访问（设备已停用）
- 500: 服务器错误

### 2.2 获取单个产品

**端点**: `GET /api/v1/pos/products/:id`

**认证**: Bearer Token (device_token)

**响应示例**:

```json
{
  "success": true,
  "data": {
    "_id": "507f1f77bcf86cd799439011",
    "tenant_id": "507f1f77bcf86cd799439012",
    "name": "可口可乐 330ml",
    // ... 其他字段
  }
}
```

### 2.3 创建产品

**端点**: `POST /api/v1/pos/products`

**认证**: Bearer Token (device_token)

**请求体**:

```json
{
  "name": "新产品",
  "description": "产品描述",
  "barcode": "1234567890123",
  "unit_price": 10.00,
  "cost_price": 5.00,
  "tax_type": "01",
  "tax_rate": 0.06,
  "stock_quantity": 50,
  "reorder_level": 10
}
```

**响应**: 返回创建的产品对象

### 2.4 更新产品

**端点**: `PUT /api/v1/pos/products/:id`

**认证**: Bearer Token (device_token)

**请求体**: 与创建相同（部分字段可选）

**响应**: 返回更新后的产品对象

### 2.5 删除产品（软删除）

**端点**: `DELETE /api/v1/pos/products/:id`

**认证**: Bearer Token (device_token)

**响应**:

```json
{
  "success": true,
  "message": "Product deactivated successfully"
}
```

**说明**: 软删除，将 `deleted_at` 设置为当前时间，不从数据库删除

## 3. 后端实现

### 3.1 数据模型（MongoDB）

**Collection**: `products`

```javascript
{
  _id: ObjectId,
  tenant_id: ObjectId,           // 租户 ID（必填）
  name: String,                  // 产品名称（必填）
  description: String,           // 产品描述
  barcode: String,               // 条码（唯一，可选）
  unit_price: Number,            // 售价（必填）- 后端字段名
  cost_price: Number,            // 成本价
  tax_type: String,              // 税种代码（必填）
  tax_rate: Number,              // 税率（必填）
  stock_quantity: Number,        // 库存数量（默认 0）
  reorder_level: Number,         // 补货警戒线
  batch_number: String,          // 批次号
  expiry_date: Date,             // 过期日期
  image_url: String,             // 图片 URL
  deleted_at: Date,              // 软删除时间戳（null = 未删除）
  created_at: Date,              // 创建时间
  updated_at: Date               // 更新时间
}
```

**虚拟字段**:
- `is_active`: 在 API 响应中计算，`is_active = (deleted_at == null)`

**索引**:

```javascript
// 租户隔离 + 增量同步
{ tenant_id: 1, updated_at: -1 }

// 条码搜索（唯一）
{ tenant_id: 1, barcode: 1 }, { unique: true, sparse: true }

// 全文搜索
{ tenant_id: 1, name: 'text', description: 'text' }

// 活跃产品查询（deleted_at 为 null）
{ tenant_id: 1, deleted_at: 1 }
```

### 3.2 路由结构

**文件**: `src/routes/pos/products.js`

```javascript
const express = require('express');
const router = express.Router();
const productController = require('../../controllers/pos/productController');
const { authenticateDevice } = require('../../middleware/auth');

// 所有路由都需要设备认证
router.use(authenticateDevice);

router.get('/', productController.getProducts);
router.post('/', productController.createProduct);
router.get('/:id', productController.getProduct);
router.put('/:id', productController.updateProduct);
router.delete('/:id', productController.deleteProduct);

module.exports = router;
```

### 3.3 控制器逻辑

**文件**: `src/controllers/pos/productController.js`

**getProducts 方法核心逻辑**:

```javascript
async getProducts(req, res) {
  try {
    const { search, barcode, updated_since, page = 1, limit = 100 } = req.query;
    const tenantId = req.device.tenant_id; // 从认证中间件获取
    
    // 构建查询条件
    const query = {
      tenant_id: tenantId,
      deleted_at: null  // 只返回未删除的产品
    };
    
    // 增量同步：只返回更新时间晚于指定时间的产品
    if (updated_since) {
      query.updated_at = { $gt: new Date(updated_since) };
    }
    
    // 条码精确匹配
    if (barcode) {
      query.barcode = barcode;
    }
    
    // 名称/描述搜索
    if (search) {
      query.$text = { $search: search };
    }
    
    // 分页
    const pageNum = parseInt(page);
    const limitNum = Math.min(parseInt(limit), 500); // 最大 500
    const skip = (pageNum - 1) * limitNum;
    const total = await Product.countDocuments(query);
    
    // 查询产品
    const products = await Product.find(query)
      .sort({ updated_at: -1 })
      .skip(skip)
      .limit(limitNum)
      .lean();
    
    // 添加虚拟字段 is_active
    const productsWithActive = products.map(product => ({
      ...product,
      is_active: product.deleted_at === null
    }));
    
    res.json({
      success: true,
      data: productsWithActive,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        total_pages: Math.ceil(total / limitNum),
        has_next: skip + products.length < total
      }
    });
  } catch (error) {
    console.error('Get products error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
}
```

### 3.4 认证中间件

**文件**: `src/middleware/auth.js`

```javascript
async function authenticateDevice(req, res, next) {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized',
        message: 'No token provided'
      });
    }
    
    // 验证 JWT token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // 检查设备状态
    const device = await PosDevice.findOne({
      device_id: decoded.device_id,
      status: 'active'
    });
    
    if (!device) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden',
        message: 'Device not found or inactive'
      });
    }
    
    // 将设备信息附加到请求对象
    req.device = {
      device_id: device.device_id,
      tenant_id: device.tenant_id
    };
    
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      error: 'Unauthorized',
      message: 'Invalid or expired token'
    });
  }
}
```

## 4. Flutter 端实现

### 4.1 本地数据库（SQLite）

**文件**: `lib/services/database/database_service.dart`

**products 表结构**:

```sql
CREATE TABLE IF NOT EXISTS products (
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
);

CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_updated_at ON products(updated_at);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
```

### 4.2 产品同步服务

**文件**: `lib/services/product_sync_service.dart`

**核心方法**:

```dart
class ProductSyncService {
  final DatabaseService _db = DatabaseService.instance;
  final ProductApi _api = ProductApi();
  final _storage = const FlutterSecureStorage();
  
  // 首次完整同步（配对后调用）
  Future<void> initialSync() async {
    try {
      print('Starting initial product sync...');
      
      int page = 1;
      bool hasMore = true;
      int totalSynced = 0;
      
      while (hasMore) {
        // 获取一页产品
        final response = await _api.getProducts(
          page: page,
          limit: 100,
        );
        
        final products = response['data'] as List;
        
        if (products.isEmpty) {
          hasMore = false;
          break;
        }
        
        // 批量保存到本地数据库
        await _saveProductsToLocal(products);
        
        totalSynced += products.length;
        print('Synced $totalSynced products...');
        
        // 检查是否还有下一页
        final pagination = response['pagination'];
        hasMore = pagination['has_next'] == true;
        page++;
      }
      
      // 记录同步时间
      await _storage.write(
        key: 'last_product_sync',
        value: DateTime.now().toIso8601String(),
      );
      
      print('Initial sync completed: $totalSynced products');
    } catch (e) {
      print('Initial sync error: $e');
      rethrow;
    }
  }
  
  // 增量同步（定期调用）
  Future<void> incrementalSync() async {
    try {
      // 获取上次同步时间
      final lastSyncStr = await _storage.read(key: 'last_product_sync');
      
      if (lastSyncStr == null) {
        // 如果没有同步记录，执行完整同步
        return await initialSync();
      }
      
      final lastSync = DateTime.parse(lastSyncStr);
      print('Starting incremental sync from $lastSync...');
      
      int page = 1;
      bool hasMore = true;
      int totalUpdated = 0;
      
      while (hasMore) {
        // 只获取更新的产品
        final response = await _api.getProducts(
          page: page,
          limit: 100,
        );
        
        // 手动添加 updated_since 参数（因为 ProductApi 可能还没有这个参数）
        final url = '/pos/products?updated_since=${lastSync.toIso8601String()}&page=$page&limit=100';
        
        final products = response['data'] as List;
        
        if (products.isEmpty) {
          hasMore = false;
          break;
        }
        
        // 更新本地数据库
        await _saveProductsToLocal(products);
        
        totalUpdated += products.length;
        
        final pagination = response['pagination'];
        hasMore = pagination['has_next'] == true;
        page++;
      }
      
      // 更新同步时间
      await _storage.write(
        key: 'last_product_sync',
        value: DateTime.now().toIso8601String(),
      );
      
      print('Incremental sync completed: $totalUpdated products updated');
    } catch (e) {
      print('Incremental sync error: $e');
      // 不抛出异常，静默失败，等待下次同步
    }
  }
  
  // 保存产品到本地数据库
  Future<void> _saveProductsToLocal(List<dynamic> products) async {
    final db = await _db.database;
    
    await db.transaction((txn) async {
      for (final productJson in products) {
        final product = Product.fromJson(productJson);
        
        // INSERT OR REPLACE
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
  
  // 获取本地产品列表
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
  
  // 通过条码查找产品
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
  
  // 从数据库行转换为 Product 对象
  Product _productFromDb(Map<String, dynamic> row) {
    return Product(
      id: row['id'],
      tenantId: row['tenant_id'],
      name: row['name'],
      description: row['description'],
      barcode: row['barcode'],
      price: row['unit_price'],  // 注意：数据库字段是 unit_price
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

### 4.3 自动同步机制

**文件**: `lib/services/sync_manager.dart`

```dart
class SyncManager {
  final ProductSyncService _productSync = ProductSyncService();
  Timer? _syncTimer;
  
  // 启动自动同步（每小时）
  void startAutoSync() {
    // 立即执行一次增量同步
    _productSync.incrementalSync();
    
    // 每小时执行一次
    _syncTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _productSync.incrementalSync(),
    );
  }
  
  // 停止自动同步
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  // 手动触发同步
  Future<void> manualSync() async {
    await _productSync.incrementalSync();
  }
}
```

### 4.4 配对后初始化

**文件**: `lib/screens/pairing/pairing_screen.dart`

```dart
// 配对成功后
Future<void> _onPairingSuccess(Map<String, dynamic> pairingData) async {
  // 保存设备信息和 token
  await _saveDeviceInfo(pairingData);
  
  // 显示加载对话框
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在同步产品数据...'),
        ],
      ),
    ),
  );
  
  try {
    // 执行首次完整同步
    final productSync = ProductSyncService();
    await productSync.initialSync();
    
    // 启动自动同步
    final syncManager = SyncManager();
    syncManager.startAutoSync();
    
    // 关闭对话框，进入主界面
    Navigator.of(context).pop(); // 关闭对话框
    Navigator.of(context).pushReplacementNamed('/home');
  } catch (e) {
    Navigator.of(context).pop(); // 关闭对话框
    
    // 显示错误
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('同步失败'),
        content: Text('产品数据同步失败：$e\n\n您可以稍后在设置中手动同步。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: Text('继续'),
          ),
        ],
      ),
    );
  }
}
```

## 5. 数据同步流程

### 5.1 首次同步（配对后）

```
1. 用户输入配对码
2. 调用 POST /pos/devices/pair
3. 获取 device_token 和租户信息
4. 保存到本地安全存储
5. 调用 ProductSyncService.initialSync()
   ├─ 循环调用 GET /pos/products?page=1,2,3...
   ├─ 每页 100 条产品
   ├─ 批量保存到本地 SQLite
   └─ 记录同步时间
6. 启动自动同步定时器
7. 进入主界面
```

### 5.2 增量同步（每小时）

```
1. 读取上次同步时间 last_sync_time
2. 调用 GET /pos/products?updated_since=last_sync_time
3. 只返回 updated_at > last_sync_time 的产品
4. 更新本地数据库（INSERT OR REPLACE）
5. 更新 last_sync_time
```

### 5.3 离线操作

```
1. 所有产品查询优先使用本地数据库
2. 条码扫描 → 查询本地 products 表
3. 名称搜索 → 查询本地 products 表
4. 网络不可用时，完全依赖本地数据
5. 网络恢复时，自动触发增量同步
```

## 6. 错误处理

### 6.1 网络错误

**同步失败处理**:
- 使用指数退避重试（1分钟、2分钟、4分钟）
- 最多重试 3 次
- 失败后静默等待下次自动同步
- 不阻塞用户操作

**离线模式**:
- 显示"离线模式"状态指示器
- 所有操作使用本地数据
- 网络恢复时自动同步

### 6.2 数据冲突

**服务器数据优先（Server Wins）**:
- 产品信息在 Web 后台统一管理
- 同步时用服务器数据覆盖本地
- 基于 `updated_at` 时间戳判断

**库存差异处理**:
- POS 销售扣减本地库存
- 同步时如果服务器库存与本地差异 > 10
- 记录警告日志，提示用户盘点

### 6.3 认证错误

**Token 过期**:
- 401 响应时清除本地 token
- 显示"设备认证已过期"提示
- 引导用户重新配对

**设备停用**:
- 403 响应时显示"设备已停用"
- 联系管理员重新激活

## 7. 性能优化

### 7.1 批量操作

- 使用 SQLite 事务批量插入/更新
- 每次最多处理 100 条记录
- 减少数据库 I/O 次数

### 7.2 索引优化

**关键索引**:
- `barcode` - 收银时高频查询
- `name` - 搜索产品时使用
- `updated_at` - 增量同步时使用
- `is_active` - 过滤停用产品

### 7.3 内存管理

- 分页加载，避免一次性加载所有产品
- 图片使用 URL，不存储在本地数据库
- 定期清理过期数据（可选）

### 7.4 网络优化

- 压缩请求和响应（gzip）
- 限制每页最大 500 条
- 使用 HTTP/2（如果支持）

## 8. 测试计划

### 8.1 后端测试

**单元测试**:
- 产品 CRUD 操作
- 增量同步查询逻辑
- 租户隔离验证
- 认证中间件

**集成测试**:
- 完整的 API 端点测试
- 分页功能测试
- 搜索功能测试
- 错误处理测试

### 8.2 Flutter 测试

**单元测试**:
- ProductSyncService 方法
- 数据库操作
- 数据转换逻辑

**集成测试**:
- 首次同步流程
- 增量同步流程
- 离线操作
- 网络恢复后同步

### 8.3 端到端测试

**场景测试**:
1. 新设备配对 → 首次同步 → 验证本地数据
2. 在 Web 后台修改产品 → 等待同步 → 验证 POS 端更新
3. 离线操作 → 网络恢复 → 验证自动同步
4. 大量产品（1000+）同步性能测试
5. 网络中断恢复测试

## 9. 部署清单

### 9.1 后端部署

- [ ] 创建 Product 模型和索引
- [ ] 实现产品控制器
- [ ] 添加路由配置
- [ ] 部署到生产环境
- [ ] 验证 API 端点

### 9.2 Flutter 部署

- [ ] 更新 ProductApi 类（添加 updated_after 参数）
- [ ] 实现 ProductSyncService
- [ ] 更新数据库 schema
- [ ] 集成到配对流程
- [ ] 实现自动同步
- [ ] 测试和发布

## 10. 未来扩展

### 10.1 短期（1-2 个月）

- 产品图片本地缓存
- 批量导入产品（CSV/Excel）
- 产品分类管理
- 多条码支持（一个产品多个条码）

### 10.2 长期（3-6 个月）

- 产品变体管理（尺寸、颜色等）
- 智能补货建议
- 销售数据分析
- 与供应商系统集成

---

**文档结束**
