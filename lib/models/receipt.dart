import 'package:json_annotation/json_annotation.dart';

part 'receipt.g.dart';

@JsonSerializable()
class Receipt {
  @JsonKey(name: 'transaction_number')
  final String transactionNumber;
  @JsonKey(name: 'transaction_date')
  final DateTime transactionDate;
  @JsonKey(name: 'store_name')
  final String storeName;
  @JsonKey(name: 'store_address')
  final String? storeAddress;
  @JsonKey(name: 'store_phone')
  final String? storePhone;
  @JsonKey(name: 'tax_number')
  final String? taxNumber;
  @JsonKey(name: 'store_logo_url')
  final String? storeLogoUrl;
  @JsonKey(name: 'service_tax')
  final double serviceTax;
  @JsonKey(name: 'service_tax_rate')
  final double serviceTaxRate;
  @JsonKey(name: 'einvoice_claim_url')
  final String? einvoiceClaimUrl;
  @JsonKey(name: 'invoice_id')
  final String? invoiceId;
  final List<ReceiptItem> items;
  final double subtotal;
  final double discount;
  @JsonKey(name: 'discount_label')
  final String discountLabel;
  final double tax;
  @JsonKey(name: 'tax_rate')
  final double taxRate;
  final double total;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'received_amount')
  final double receivedAmount;
  @JsonKey(name: 'change_amount')
  final double changeAmount;
  @JsonKey(name: 'customer_name')
  final String? customerName;
  @JsonKey(name: 'cashier_name')
  final String? cashierName;

  Receipt({
    required this.transactionNumber,
    required this.transactionDate,
    this.storeName = 'POS System',
    this.storeAddress,
    this.storePhone,
    this.taxNumber,
    this.storeLogoUrl,
    this.serviceTax = 0,
    this.serviceTaxRate = 0,
    this.einvoiceClaimUrl,
    this.invoiceId,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.discountLabel = '',
    required this.tax,
    this.taxRate = 6.0, // 6% as percentage
    required this.total,
    required this.paymentMethod,
    this.receivedAmount = 0,
    this.changeAmount = 0,
    this.customerName,
    this.cashierName,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) =>
      _$ReceiptFromJson(json);

  Map<String, dynamic> toJson() => _$ReceiptToJson(this);
}

@JsonSerializable()
class ReceiptItem {
  final String name;
  final int quantity;
  @JsonKey(name: 'unit_price')
  final double unitPrice;
  @JsonKey(name: 'line_total')
  final double lineTotal;
  final String note;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.note = '',
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) =>
      _$ReceiptItemFromJson(json);

  Map<String, dynamic> toJson() => _$ReceiptItemToJson(this);
}
