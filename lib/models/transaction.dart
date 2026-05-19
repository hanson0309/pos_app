import 'package:json_annotation/json_annotation.dart';

part 'transaction.g.dart';

@JsonSerializable()
class PosTransaction {
  @JsonKey(name: 'transaction_id')
  final String transactionId;

  @JsonKey(name: 'tenant_id')
  final String tenantId;

  @JsonKey(name: 'transaction_number')
  final String transactionNumber;

  @JsonKey(name: 'transaction_date')
  final DateTime transactionDate;

  @JsonKey(name: 'cashier_id')
  final String cashierId;

  @JsonKey(name: 'customer_id')
  final String? customerId;

  final List<TransactionItem> items;

  final double subtotal;

  @JsonKey(name: 'tax_amount')
  final double taxAmount;

  @JsonKey(name: 'total_amount')
  final double totalAmount;

  @JsonKey(name: 'payment_method')
  final String paymentMethod;

  @JsonKey(name: 'payment_status')
  final String paymentStatus;

  @JsonKey(name: 'invoice_id')
  final String? invoiceId;

  @JsonKey(name: 'device_id')
  final String deviceId;

  @JsonKey(name: 'synced_at')
  final DateTime? syncedAt;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  PosTransaction({
    required this.transactionId,
    required this.tenantId,
    required this.transactionNumber,
    required this.transactionDate,
    required this.cashierId,
    this.customerId,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.invoiceId,
    required this.deviceId,
    this.syncedAt,
    required this.createdAt,
  });

  factory PosTransaction.fromJson(Map<String, dynamic> json) =>
      _$PosTransactionFromJson(json);

  Map<String, dynamic> toJson() => _$PosTransactionToJson(this);

  bool get isSynced => syncedAt != null;

  PosTransaction copyWith({
    String? transactionId,
    String? tenantId,
    String? transactionNumber,
    DateTime? transactionDate,
    String? cashierId,
    String? customerId,
    List<TransactionItem>? items,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    String? paymentMethod,
    String? paymentStatus,
    String? invoiceId,
    String? deviceId,
    DateTime? syncedAt,
    DateTime? createdAt,
  }) {
    return PosTransaction(
      transactionId: transactionId ?? this.transactionId,
      tenantId: tenantId ?? this.tenantId,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      transactionDate: transactionDate ?? this.transactionDate,
      cashierId: cashierId ?? this.cashierId,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      invoiceId: invoiceId ?? this.invoiceId,
      deviceId: deviceId ?? this.deviceId,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@JsonSerializable()
class TransactionItem {
  @JsonKey(name: 'product_id')
  final String productId;

  final String description;
  final int quantity;

  @JsonKey(name: 'unit_price')
  final double unitPrice;

  @JsonKey(name: 'tax_type')
  final String taxType;

  @JsonKey(name: 'tax_rate')
  final double taxRate;

  @JsonKey(name: 'tax_amount')
  final double taxAmount;

  @JsonKey(name: 'line_total')
  final double lineTotal;

  TransactionItem({
    required this.productId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxType,
    required this.taxRate,
    required this.taxAmount,
    required this.lineTotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      _$TransactionItemFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionItemToJson(this);

  TransactionItem copyWith({
    String? productId,
    String? description,
    int? quantity,
    double? unitPrice,
    String? taxType,
    double? taxRate,
    double? taxAmount,
    double? lineTotal,
  }) {
    return TransactionItem(
      productId: productId ?? this.productId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxType: taxType ?? this.taxType,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }
}
