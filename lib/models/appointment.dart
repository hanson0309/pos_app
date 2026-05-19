import 'package:json_annotation/json_annotation.dart';

part 'appointment.g.dart';

@JsonSerializable()
class Appointment {
  @JsonKey(name: '_id')
  final String? id;

  @JsonKey(name: 'tenant_id')
  final String tenantId;

  @JsonKey(name: 'customer_id')
  final String customerId;

  @JsonKey(name: 'appointment_date')
  final DateTime appointmentDate;

  @JsonKey(name: 'start_time')
  final String startTime;

  @JsonKey(name: 'end_time')
  final String endTime;

  @JsonKey(name: 'service_type')
  final String serviceType;

  @JsonKey(name: 'service_items')
  final List<ServiceItem> serviceItems;

  final String status;
  final String? notes;

  @JsonKey(name: 'reminder_sent')
  final bool reminderSent;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Appointment({
    this.id,
    required this.tenantId,
    required this.customerId,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.serviceType,
    required this.serviceItems,
    required this.status,
    this.notes,
    this.reminderSent = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) =>
      _$AppointmentFromJson(json);

  Map<String, dynamic> toJson() => _$AppointmentToJson(this);

  double get totalPrice {
    return serviceItems.fold(0.0, (sum, item) => sum + item.price);
  }

  Appointment copyWith({
    String? id,
    String? tenantId,
    String? customerId,
    DateTime? appointmentDate,
    String? startTime,
    String? endTime,
    String? serviceType,
    List<ServiceItem>? serviceItems,
    String? status,
    String? notes,
    bool? reminderSent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      customerId: customerId ?? this.customerId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      serviceType: serviceType ?? this.serviceType,
      serviceItems: serviceItems ?? this.serviceItems,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      reminderSent: reminderSent ?? this.reminderSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class ServiceItem {
  final String description;
  final double price;

  ServiceItem({
    required this.description,
    required this.price,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) =>
      _$ServiceItemFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceItemToJson(this);
}
