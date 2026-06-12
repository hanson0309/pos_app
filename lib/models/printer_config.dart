import 'package:json_annotation/json_annotation.dart';

part 'printer_config.g.dart';

enum PrinterType {
  bluetooth,
  usb,
  network,
  /// Saves ESC/POS to file; use with on-screen receipt preview for testing.
  virtual,
}

@JsonSerializable()
class PrinterConfig {
  @JsonKey(name: '_id')
  final String? id;

  @JsonKey(name: 'tenant_id')
  final String tenantId;

  final String name;
  @JsonKey(name: 'printer_type')
  final PrinterType type;
  final String address;
  @JsonKey(name: 'paper_width')
  final int paperWidth;
  @JsonKey(name: 'is_default')
  final bool isDefault;
  @JsonKey(name: 'last_connected')
  final DateTime? lastConnected;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  PrinterConfig({
    this.id,
    required this.tenantId,
    required this.name,
    required this.type,
    required this.address,
    this.paperWidth = 80,
    this.isDefault = false,
    this.lastConnected,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrinterConfig.fromJson(Map<String, dynamic> json) =>
      _$PrinterConfigFromJson(json);

  Map<String, dynamic> toJson() => _$PrinterConfigToJson(this);

  PrinterConfig copyWith({
    String? id,
    String? tenantId,
    String? name,
    PrinterType? type,
    String? address,
    int? paperWidth,
    bool? isDefault,
    DateTime? lastConnected,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrinterConfig(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      paperWidth: paperWidth ?? this.paperWidth,
      isDefault: isDefault ?? this.isDefault,
      lastConnected: lastConnected ?? this.lastConnected,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
