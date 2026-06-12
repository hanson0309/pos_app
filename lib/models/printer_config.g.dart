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
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$PrinterTypeEnumMap = {
  PrinterType.bluetooth: 'bluetooth',
  PrinterType.usb: 'usb',
  PrinterType.network: 'network',
  PrinterType.virtual: 'virtual',
};
