// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PosTransaction _$PosTransactionFromJson(Map<String, dynamic> json) =>
    PosTransaction(
      transactionId: json['transaction_id'] as String,
      tenantId: json['tenant_id'] as String,
      transactionNumber: json['transaction_number'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      cashierId: json['cashier_id'] as String,
      customerId: json['customer_id'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String,
      invoiceId: json['invoice_id'] as String?,
      deviceId: json['device_id'] as String,
      syncedAt: json['synced_at'] == null
          ? null
          : DateTime.parse(json['synced_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PosTransactionToJson(PosTransaction instance) =>
    <String, dynamic>{
      'transaction_id': instance.transactionId,
      'tenant_id': instance.tenantId,
      'transaction_number': instance.transactionNumber,
      'transaction_date': instance.transactionDate.toIso8601String(),
      'cashier_id': instance.cashierId,
      'customer_id': instance.customerId,
      'items': instance.items,
      'subtotal': instance.subtotal,
      'tax_amount': instance.taxAmount,
      'total_amount': instance.totalAmount,
      'payment_method': instance.paymentMethod,
      'payment_status': instance.paymentStatus,
      'invoice_id': instance.invoiceId,
      'device_id': instance.deviceId,
      'synced_at': instance.syncedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

TransactionItem _$TransactionItemFromJson(Map<String, dynamic> json) =>
    TransactionItem(
      productId: json['product_id'] as String,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      taxType: json['tax_type'] as String,
      taxRate: (json['tax_rate'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      lineTotal: (json['line_total'] as num).toDouble(),
    );

Map<String, dynamic> _$TransactionItemToJson(TransactionItem instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'description': instance.description,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'tax_type': instance.taxType,
      'tax_rate': instance.taxRate,
      'tax_amount': instance.taxAmount,
      'line_total': instance.lineTotal,
    };
