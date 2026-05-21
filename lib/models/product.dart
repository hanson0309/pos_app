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

  @JsonKey(name: 'classification_code')
  final String? classificationCode;

  final String? unit;

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
    this.classificationCode,
    this.unit,
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
    String? classificationCode,
    String? unit,
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
      classificationCode: classificationCode ?? this.classificationCode,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
