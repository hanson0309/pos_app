// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Appointment _$AppointmentFromJson(Map<String, dynamic> json) => Appointment(
      id: json['_id'] as String?,
      tenantId: json['tenant_id'] as String,
      customerId: json['customer_id'] as String,
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      serviceType: json['service_type'] as String,
      serviceItems: (json['service_items'] as List<dynamic>)
          .map((e) => ServiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      reminderSent: json['reminder_sent'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$AppointmentToJson(Appointment instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'tenant_id': instance.tenantId,
      'customer_id': instance.customerId,
      'appointment_date': instance.appointmentDate.toIso8601String(),
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'service_type': instance.serviceType,
      'service_items': instance.serviceItems,
      'status': instance.status,
      'notes': instance.notes,
      'reminder_sent': instance.reminderSent,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

ServiceItem _$ServiceItemFromJson(Map<String, dynamic> json) => ServiceItem(
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
    );

Map<String, dynamic> _$ServiceItemToJson(ServiceItem instance) =>
    <String, dynamic>{
      'description': instance.description,
      'price': instance.price,
    };
