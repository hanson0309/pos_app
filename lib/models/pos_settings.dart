import 'package:json_annotation/json_annotation.dart';

part 'pos_settings.g.dart';

@JsonSerializable()
class PosSettings {
  @JsonKey(name: 'tenant_id')
  final String tenantId;

  final ModuleSettings modules;

  @JsonKey(name: 'business_type')
  final String businessType;

  @JsonKey(name: 'invoice_settings')
  final InvoiceSettings invoiceSettings;

  final HardwareSettings hardware;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  PosSettings({
    required this.tenantId,
    required this.modules,
    required this.businessType,
    required this.invoiceSettings,
    required this.hardware,
    required this.updatedAt,
  });

  factory PosSettings.fromJson(Map<String, dynamic> json) =>
      _$PosSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$PosSettingsToJson(this);

  PosSettings copyWith({
    String? tenantId,
    ModuleSettings? modules,
    String? businessType,
    InvoiceSettings? invoiceSettings,
    HardwareSettings? hardware,
    DateTime? updatedAt,
  }) {
    return PosSettings(
      tenantId: tenantId ?? this.tenantId,
      modules: modules ?? this.modules,
      businessType: businessType ?? this.businessType,
      invoiceSettings: invoiceSettings ?? this.invoiceSettings,
      hardware: hardware ?? this.hardware,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class ModuleSettings {
  final bool appointment;
  final bool inventory;

  @JsonKey(name: 'multi_cashier')
  final bool multiCashier;

  @JsonKey(name: 'customer_management')
  final bool customerManagement;

  ModuleSettings({
    required this.appointment,
    required this.inventory,
    required this.multiCashier,
    required this.customerManagement,
  });

  factory ModuleSettings.fromJson(Map<String, dynamic> json) =>
      _$ModuleSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$ModuleSettingsToJson(this);
}

@JsonSerializable()
class InvoiceSettings {
  @JsonKey(name: 'auto_create_on_payment')
  final bool autoCreateOnPayment;

  @JsonKey(name: 'default_invoice_type')
  final String defaultInvoiceType;

  @JsonKey(name: 'require_customer_for_invoice')
  final bool requireCustomerForInvoice;

  InvoiceSettings({
    required this.autoCreateOnPayment,
    required this.defaultInvoiceType,
    required this.requireCustomerForInvoice,
  });

  factory InvoiceSettings.fromJson(Map<String, dynamic> json) =>
      _$InvoiceSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceSettingsToJson(this);
}

@JsonSerializable()
class HardwareSettings {
  @JsonKey(name: 'receipt_printer_enabled')
  final bool receiptPrinterEnabled;

  @JsonKey(name: 'barcode_scanner_enabled')
  final bool barcodeScannerEnabled;

  @JsonKey(name: 'cash_drawer_enabled')
  final bool cashDrawerEnabled;

  @JsonKey(name: 'label_printer_enabled')
  final bool labelPrinterEnabled;

  HardwareSettings({
    required this.receiptPrinterEnabled,
    required this.barcodeScannerEnabled,
    required this.cashDrawerEnabled,
    required this.labelPrinterEnabled,
  });

  factory HardwareSettings.fromJson(Map<String, dynamic> json) =>
      _$HardwareSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$HardwareSettingsToJson(this);
}
