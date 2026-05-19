import 'package:json_annotation/json_annotation.dart';

part 'customer.g.dart';

@JsonSerializable()
class Customer {
  @JsonKey(name: '_id')
  final String? id;

  @JsonKey(name: 'tenant_id')
  final String tenantId;

  final String name;
  final String? email;
  final String? phone;

  @JsonKey(name: 'customer_type')
  final String customerType; // 'individual' or 'business'

  final String? address;

  @JsonKey(name: 'tax_number')
  final String? taxNumber;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Customer({
    this.id,
    required this.tenantId,
    required this.name,
    this.email,
    this.phone,
    required this.customerType,
    this.address,
    this.taxNumber,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerToJson(this);

  Customer copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? email,
    String? phone,
    String? customerType,
    String? address,
    String? taxNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      customerType: customerType ?? this.customerType,
      address: address ?? this.address,
      taxNumber: taxNumber ?? this.taxNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
