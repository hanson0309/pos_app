// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PosSettings _$PosSettingsFromJson(Map<String, dynamic> json) => PosSettings(
      tenantId: json['tenant_id'] as String,
      modules: ModuleSettings.fromJson(json['modules'] as Map<String, dynamic>),
      businessType: json['business_type'] as String,
      invoiceSettings: InvoiceSettings.fromJson(
          json['invoice_settings'] as Map<String, dynamic>),
      hardware:
          HardwareSettings.fromJson(json['hardware'] as Map<String, dynamic>),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PosSettingsToJson(PosSettings instance) =>
    <String, dynamic>{
      'tenant_id': instance.tenantId,
      'modules': instance.modules,
      'business_type': instance.businessType,
      'invoice_settings': instance.invoiceSettings,
      'hardware': instance.hardware,
      'updated_at': instance.updatedAt.toIso8601String(),
    };

ModuleSettings _$ModuleSettingsFromJson(Map<String, dynamic> json) =>
    ModuleSettings(
      appointment: json['appointment'] as bool,
      inventory: json['inventory'] as bool,
      multiCashier: json['multi_cashier'] as bool,
      customerManagement: json['customer_management'] as bool,
    );

Map<String, dynamic> _$ModuleSettingsToJson(ModuleSettings instance) =>
    <String, dynamic>{
      'appointment': instance.appointment,
      'inventory': instance.inventory,
      'multi_cashier': instance.multiCashier,
      'customer_management': instance.customerManagement,
    };

InvoiceSettings _$InvoiceSettingsFromJson(Map<String, dynamic> json) =>
    InvoiceSettings(
      autoCreateOnPayment: json['auto_create_on_payment'] as bool,
      defaultInvoiceType: json['default_invoice_type'] as String,
      requireCustomerForInvoice: json['require_customer_for_invoice'] as bool,
    );

Map<String, dynamic> _$InvoiceSettingsToJson(InvoiceSettings instance) =>
    <String, dynamic>{
      'auto_create_on_payment': instance.autoCreateOnPayment,
      'default_invoice_type': instance.defaultInvoiceType,
      'require_customer_for_invoice': instance.requireCustomerForInvoice,
    };

HardwareSettings _$HardwareSettingsFromJson(Map<String, dynamic> json) =>
    HardwareSettings(
      receiptPrinterEnabled: json['receipt_printer_enabled'] as bool,
      barcodeScannerEnabled: json['barcode_scanner_enabled'] as bool,
      cashDrawerEnabled: json['cash_drawer_enabled'] as bool,
      labelPrinterEnabled: json['label_printer_enabled'] as bool,
    );

Map<String, dynamic> _$HardwareSettingsToJson(HardwareSettings instance) =>
    <String, dynamic>{
      'receipt_printer_enabled': instance.receiptPrinterEnabled,
      'barcode_scanner_enabled': instance.barcodeScannerEnabled,
      'cash_drawer_enabled': instance.cashDrawerEnabled,
      'label_printer_enabled': instance.labelPrinterEnabled,
    };
