// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'printer_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrinterConfig _$PrinterConfigFromJson(Map<String, dynamic> json) =>
    PrinterConfig(
      id: json['_id'] as String?,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$PrinterTypeEnumMap, json['printer_type']),
      address: json['address'] as String,
      paperWidth: (json['paper_width'] as num?)?.toInt() ?? 80,
      isDefault: json['is_default'] as bool? ?? false,
      lastConnected: json['last_connected'] == null
          ? null
          : DateTime.parse(json['last_connected'] as String),
      protocol:
          $enumDecodeNullable(_$PrinterProtocolEnumMap, json['protocol']) ??
              PrinterProtocol.escPos,
      autoPrintReceipt: json['auto_print_receipt'] as bool? ?? false,
      textSize: $enumDecodeNullable(_$PrinterTextSizeEnumMap, json['text_size']) ??
          PrinterTextSize.normal,
      printSound: json['print_sound'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PrinterConfigToJson(PrinterConfig instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'tenant_id': instance.tenantId,
      'name': instance.name,
      'printer_type': _$PrinterTypeEnumMap[instance.type]!,
      'address': instance.address,
      'paper_width': instance.paperWidth,
      'is_default': instance.isDefault,
      'last_connected': instance.lastConnected?.toIso8601String(),
      'protocol': _$PrinterProtocolEnumMap[instance.protocol]!,
      'auto_print_receipt': instance.autoPrintReceipt,
      'text_size': _$PrinterTextSizeEnumMap[instance.textSize]!,
      'print_sound': instance.printSound,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$PrinterTypeEnumMap = {
  PrinterType.bluetooth: 'bluetooth',
  PrinterType.usb: 'usb',
  PrinterType.network: 'network',
  PrinterType.virtual: 'virtual',
};

const _$PrinterProtocolEnumMap = {
  PrinterProtocol.escPos: 'escPos',
  PrinterProtocol.tsplLabel: 'tsplLabel',
};

const _$PrinterTextSizeEnumMap = {
  PrinterTextSize.small: 'small',
  PrinterTextSize.normal: 'normal',
  PrinterTextSize.large: 'large',
};
