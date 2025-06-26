import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_record.dart';

class TransactionRecordModel extends Equatable {
  final String id;
  final String userId;
  final String affectedAccountId;
  final DateTime transactionDate;
  final double amount;
  final String transactionType;
  final String currency;
  final String? descriptionNotes;
  final String? payerSenderRaw;
  final String? payeeReceiverRaw;
  final String? referenceNumber;
  final bool isInternalTransfer;
  final String? counterpartyAccountId;
  final String? receiptFileLink;
  final String? ocrExtractedRawText;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionRecordModel({
    required this.id,
    required this.userId,
    required this.affectedAccountId,
    required this.transactionDate,
    required this.amount,
    required this.transactionType,
    required this.currency,
    this.descriptionNotes,
    this.payerSenderRaw,
    this.payeeReceiverRaw,
    this.referenceNumber,
    required this.isInternalTransfer,
    this.counterpartyAccountId,
    this.receiptFileLink,
    this.ocrExtractedRawText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionRecordModel.fromEntity(TransactionRecord entity) {
    return TransactionRecordModel(
      id: entity.id,
      userId: entity.userId,
      affectedAccountId: entity.affectedAccountId,
      transactionDate: entity.transactionDate,
      amount: entity.amount,
      transactionType: entity.transactionType,
      currency: entity.currency,
      descriptionNotes: entity.descriptionNotes,
      payerSenderRaw: entity.payerSenderRaw,
      payeeReceiverRaw: entity.payeeReceiverRaw,
      referenceNumber: entity.referenceNumber,
      isInternalTransfer: entity.isInternalTransfer,
      counterpartyAccountId: entity.counterpartyAccountId,
      receiptFileLink: entity.receiptFileLink,
      ocrExtractedRawText: entity.ocrExtractedRawText,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  TransactionRecord toEntity() {
    return TransactionRecord(
      id: id,
      userId: userId,
      affectedAccountId: affectedAccountId,
      transactionDate: transactionDate,
      amount: amount,
      transactionType: transactionType,
      currency: currency,
      descriptionNotes: descriptionNotes,
      payerSenderRaw: payerSenderRaw,
      payeeReceiverRaw: payeeReceiverRaw,
      referenceNumber: referenceNumber,
      isInternalTransfer: isInternalTransfer,
      counterpartyAccountId: counterpartyAccountId,
      receiptFileLink: receiptFileLink,
      ocrExtractedRawText: ocrExtractedRawText,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory TransactionRecordModel.fromJson(Map<String, dynamic> json) {
    return TransactionRecordModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      affectedAccountId: json['affected_account_id'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      amount: (json['amount'] as num).toDouble(),
      transactionType: json['transaction_type'] as String,
      currency: json['currency'] as String,
      descriptionNotes: json['description_notes'] as String,
      payerSenderRaw: json['payer_sender_raw'] as String?,
      payeeReceiverRaw: json['payee_receiver_raw'] as String?,
      referenceNumber: json['reference_number'] as String?,
      isInternalTransfer: json['is_internal_transfer'] as bool,
      counterpartyAccountId: json['counterparty_account_id'] as String?,
      receiptFileLink: json['receipt_file_link'] as String?,
      ocrExtractedRawText: json['ocr_extracted_raw_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'affected_account_id': affectedAccountId,
      'transaction_date': transactionDate.toIso8601String(),
      'amount': amount,
      'transaction_type': transactionType,
      'currency': currency,
      'description_notes': descriptionNotes,
      'payer_sender_raw': payerSenderRaw,
      'payee_receiver_raw': payeeReceiverRaw,
      'reference_number': referenceNumber,
      'is_internal_transfer': isInternalTransfer,
      'counterparty_account_id': counterpartyAccountId,
      'receipt_file_link': receiptFileLink,
      'ocr_extracted_raw_text': ocrExtractedRawText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForInsert() {
    final json = toJson();
    json.remove('id');
    json.remove('created_at');
    json.remove('updated_at');
    return json;
  }

  TransactionRecordModel copyWith({
    String? id,
    String? userId,
    String? affectedAccountId,
    DateTime? transactionDate,
    double? amount,
    String? transactionType,
    String? currency,
    String? descriptionNotes,
    String? payerSenderRaw,
    String? payeeReceiverRaw,
    String? referenceNumber,
    bool? isInternalTransfer,
    String? counterpartyAccountId,
    String? receiptFileLink,
    String? ocrExtractedRawText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionRecordModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      affectedAccountId: affectedAccountId ?? this.affectedAccountId,
      transactionDate: transactionDate ?? this.transactionDate,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      currency: currency ?? this.currency,
      descriptionNotes: descriptionNotes ?? this.descriptionNotes,
      payerSenderRaw: payerSenderRaw ?? this.payerSenderRaw,
      payeeReceiverRaw: payeeReceiverRaw ?? this.payeeReceiverRaw,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      isInternalTransfer: isInternalTransfer ?? this.isInternalTransfer,
      counterpartyAccountId: counterpartyAccountId ?? this.counterpartyAccountId,
      receiptFileLink: receiptFileLink ?? this.receiptFileLink,
      ocrExtractedRawText: ocrExtractedRawText ?? this.ocrExtractedRawText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedAmount {
    return 'ETB ${amount.toStringAsFixed(2)}';
  }

  String get formattedDate {
    return '${transactionDate.day}/${transactionDate.month}/${transactionDate.year}';
  }

  bool get isIncome {
    return transactionType.toLowerCase().contains('income') || 
           transactionType.toLowerCase().contains('credit');
  }

  bool get isExpense {
    return transactionType.toLowerCase().contains('expense') || 
           transactionType.toLowerCase().contains('debit');
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        affectedAccountId,
        transactionDate,
        amount,
        transactionType,
        currency,
        descriptionNotes,
        payerSenderRaw,
        payeeReceiverRaw,
        referenceNumber,
        isInternalTransfer,
        counterpartyAccountId,
        receiptFileLink,
        ocrExtractedRawText,
        createdAt,
        updatedAt,
      ];
}