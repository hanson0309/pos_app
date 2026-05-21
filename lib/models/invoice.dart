import 'package:json_annotation/json_annotation.dart';

part 'invoice.g.dart';

@JsonSerializable()
class Invoice {
  @JsonKey(name: 'invoice_id')
  final String? invoiceId;

  @JsonKey(name: 'invoice_number')
  final String? invoiceNumber;

  final String source;

  @JsonKey(name: 'pos_transaction_id')
  final String posTransactionId;

  @JsonKey(name: 'invoice_type')
  final String invoiceType;

  @JsonKey(name: 'customer_id', includeIfNull: false)
  final String? customerId;

  @JsonKey(name: 'issue_date', includeIfNull: false)
  final String? issueDate;

  final List<InvoiceItem> items;

  @JsonKey(name: 'payment_method')
  final String paymentMethod;

  final String status;

  @JsonKey(name: 'subtotal')
  final double subtotal;

  @JsonKey(name: 'tax_amount')
  final double taxAmount;

  @JsonKey(name: 'total_amount')
  final double totalAmount;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  Invoice({
    this.invoiceId,
    this.invoiceNumber,
    required this.source,
    required this.posTransactionId,
    required this.invoiceType,
    this.customerId,
    this.issueDate,
    required this.items,
    required this.paymentMethod,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceToJson(this);

  // Factory method to create invoice from POS transaction
  factory Invoice.fromTransaction({
    required String transactionId,
    required String transactionNumber,
    required String invoiceType,
    String? customerId,
    required DateTime issueDate, // Keep parameter for compatibility but don't use it
    required List<InvoiceItem> items,
    required String paymentMethod,
    required double subtotal,
    required double taxAmount,
    required double totalAmount,
  }) {
    return Invoice(
      source: 'pos',
      invoiceNumber: transactionNumber, // Use transaction number as invoice number
      posTransactionId: transactionId,
      invoiceType: invoiceType,
      customerId: customerId, // Will be excluded if null
      issueDate: null, // Let backend use server date to avoid timezone issues
      items: items,
      paymentMethod: paymentMethod,
      status: 'draft',
      subtotal: subtotal,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
    );
  }
}

@JsonSerializable()
class InvoiceItem {
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

  InvoiceItem({
    required this.productId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxType,
    required this.taxRate,
    required this.taxAmount,
    required this.lineTotal,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) =>
      _$InvoiceItemFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceItemToJson(this);
}
