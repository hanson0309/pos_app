// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'print_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrintJob _$PrintJobFromJson(Map<String, dynamic> json) => PrintJob(
      id: json['_id'] as String?,
      tenantId: json['tenant_id'] as String,
      transactionId: json['transaction_id'] as String,
      transactionNumber: json['transaction_number'] as String,
      receiptData: json['receipt_data'] as Map<String, dynamic>,
      status: $enumDecodeNullable(_$PrintJobStatusEnumMap, json['status']) ??
          PrintJobStatus.pending,
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      printedAt: json['printed_at'] == null
          ? null
          : DateTime.parse(json['printed_at'] as String),
    );

Map<String, dynamic> _$PrintJobToJson(PrintJob instance) => <String, dynamic>{
      '_id': instance.id,
      'tenant_id': instance.tenantId,
      'transaction_id': instance.transactionId,
      'transaction_number': instance.transactionNumber,
      'receipt_data': instance.receiptData,
      'status': _$PrintJobStatusEnumMap[instance.status]!,
      'retry_count': instance.retryCount,
      'error_message': instance.errorMessage,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'printed_at': instance.printedAt?.toIso8601String(),
    };

const _$PrintJobStatusEnumMap = {
  PrintJobStatus.pending: 'pending',
  PrintJobStatus.printing: 'printing',
  PrintJobStatus.success: 'success',
  PrintJobStatus.failed: 'failed',
};
