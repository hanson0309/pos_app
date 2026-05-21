import 'package:json_annotation/json_annotation.dart';

part 'print_job.g.dart';

enum PrintJobStatus {
  pending,
  printing,
  success,
  failed,
}

@JsonSerializable()
class PrintJob {
  @JsonKey(name: '_id')
  final String? id;

  @JsonKey(name: 'tenant_id')
  final String tenantId;

  @JsonKey(name: 'transaction_id')
  final String transactionId;

  @JsonKey(name: 'transaction_number')
  final String transactionNumber;

  @JsonKey(name: 'receipt_data')
  final Map<String, dynamic> receiptData;

  final PrintJobStatus status;

  @JsonKey(name: 'retry_count')
  final int retryCount;

  @JsonKey(name: 'error_message')
  final String? errorMessage;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @JsonKey(name: 'printed_at')
  final DateTime? printedAt;

  PrintJob({
    this.id,
    required this.tenantId,
    required this.transactionId,
    required this.transactionNumber,
    required this.receiptData,
    this.status = PrintJobStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.printedAt,
  });

  factory PrintJob.fromJson(Map<String, dynamic> json) =>
      _$PrintJobFromJson(json);

  Map<String, dynamic> toJson() => _$PrintJobToJson(this);

  PrintJob copyWith({
    String? id,
    String? tenantId,
    String? transactionId,
    String? transactionNumber,
    Map<String, dynamic>? receiptData,
    PrintJobStatus? status,
    int? retryCount,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? printedAt,
  }) {
    return PrintJob(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      transactionId: transactionId ?? this.transactionId,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      receiptData: receiptData ?? this.receiptData,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      printedAt: printedAt ?? this.printedAt,
    );
  }
}
