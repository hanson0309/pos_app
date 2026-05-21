// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invoice _$InvoiceFromJson(Map<String, dynamic> json) => Invoice(
      invoiceId: json['invoice_id'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      source: json['source'] as String,
      posTransactionId: json['pos_transaction_id'] as String,
      invoiceType: json['invoice_type'] as String,
      customerId: json['customer_id'] as String?,
      issueDate: json['issue_date'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentMethod: json['payment_method'] as String,
      status: json['status'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$InvoiceToJson(Invoice instance) {
  final val = <String, dynamic>{
    'invoice_id': instance.invoiceId,
    'invoice_number': instance.invoiceNumber,
    'source': instance.source,
    'pos_transaction_id': instance.posTransactionId,
    'invoice_type': instance.invoiceType,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('customer_id', instance.customerId);
  val['issue_date'] = instance.issueDate;
  val['items'] = instance.items;
  val['payment_method'] = instance.paymentMethod;
  val['status'] = instance.status;
  val['subtotal'] = instance.subtotal;
  val['tax_amount'] = instance.taxAmount;
  val['total_amount'] = instance.totalAmount;
  val['created_at'] = instance.createdAt?.toIso8601String();
  return val;
}

InvoiceItem _$InvoiceItemFromJson(Map<String, dynamic> json) => InvoiceItem(
      productId: json['product_id'] as String,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      taxType: json['tax_type'] as String,
      taxRate: (json['tax_rate'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      classificationCode: json['classification_code'] as String?,
      lineTotal: (json['line_total'] as num).toDouble(),
    );

Map<String, dynamic> _$InvoiceItemToJson(InvoiceItem instance) {
  final val = <String, dynamic>{
    'product_id': instance.productId,
    'description': instance.description,
    'quantity': instance.quantity,
    'unit_price': instance.unitPrice,
    'tax_type': instance.taxType,
    'tax_rate': instance.taxRate,
    'tax_amount': instance.taxAmount,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('classification_code', instance.classificationCode);
  val['line_total'] = instance.lineTotal;
  return val;
}
