// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Receipt _$ReceiptFromJson(Map<String, dynamic> json) => Receipt(
      transactionNumber: json['transaction_number'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      storeName: json['store_name'] as String? ?? 'POS System',
      storeAddress: json['store_address'] as String?,
      storePhone: json['store_phone'] as String?,
      taxNumber: json['tax_number'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      discountLabel: json['discount_label'] as String? ?? '',
      tax: (json['tax'] as num).toDouble(),
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 6.0,
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      receivedAmount: (json['received_amount'] as num?)?.toDouble() ?? 0,
      changeAmount: (json['change_amount'] as num?)?.toDouble() ?? 0,
      customerName: json['customer_name'] as String?,
      cashierName: json['cashier_name'] as String?,
    );

Map<String, dynamic> _$ReceiptToJson(Receipt instance) => <String, dynamic>{
      'transaction_number': instance.transactionNumber,
      'transaction_date': instance.transactionDate.toIso8601String(),
      'store_name': instance.storeName,
      'store_address': instance.storeAddress,
      'store_phone': instance.storePhone,
      'tax_number': instance.taxNumber,
      'items': instance.items,
      'subtotal': instance.subtotal,
      'discount': instance.discount,
      'discount_label': instance.discountLabel,
      'tax': instance.tax,
      'tax_rate': instance.taxRate,
      'total': instance.total,
      'payment_method': instance.paymentMethod,
      'received_amount': instance.receivedAmount,
      'change_amount': instance.changeAmount,
      'customer_name': instance.customerName,
      'cashier_name': instance.cashierName,
    };

ReceiptItem _$ReceiptItemFromJson(Map<String, dynamic> json) => ReceiptItem(
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      lineTotal: (json['line_total'] as num).toDouble(),
      note: json['note'] as String? ?? '',
    );

Map<String, dynamic> _$ReceiptItemToJson(ReceiptItem instance) =>
    <String, dynamic>{
      'name': instance.name,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'line_total': instance.lineTotal,
      'note': instance.note,
    };
