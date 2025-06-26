// Data model for Financial Account Record
// Maps between domain entity and Supabase data structure

import '../../domain/entities/financial_account_record.dart';

class FinancialAccountRecordModel extends FinancialAccountRecord {
  const FinancialAccountRecordModel({
    required super.id,
    required super.userId,
    required super.accountName,
    required super.accountIdentifier,
    required super.accountType,
    required super.linkedSimId,
    required super.initialBalance,
    required super.dateAdded,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create FinancialAccountRecordModel from JSON (Supabase response)
  factory FinancialAccountRecordModel.fromJson(Map<String, dynamic> json) {
    _validateJsonInput(json);
    return FinancialAccountRecordModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountName: json['account_name'] as String,
      accountIdentifier: json['account_identifier'] as String,
      accountType: json['account_type'] as String,
      linkedSimId: json['linked_sim_id'] as String,
      initialBalance: (json['initial_balance'] as num).toDouble(),
      dateAdded: DateTime.parse(json['date_added'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Validates JSON input for required fields and business rules
  static void _validateJsonInput(Map<String, dynamic> json) {
    // Required field validation
    if (json['id'] == null || json['id'].toString().isEmpty) {
      throw ArgumentError('Account ID cannot be null or empty');
    }
    if (json['user_id'] == null || json['user_id'].toString().isEmpty) {
      throw ArgumentError('User ID cannot be null or empty');
    }
    if (json['account_name'] == null || json['account_name'].toString().isEmpty) {
      throw ArgumentError('Account name cannot be null or empty');
    }
    if (json['account_identifier'] == null || json['account_identifier'].toString().isEmpty) {
      throw ArgumentError('Account identifier cannot be null or empty');
    }
    if (json['account_type'] == null || json['account_type'].toString().isEmpty) {
      throw ArgumentError('Account type cannot be null or empty');
    }
    if (json['linked_sim_id'] == null || json['linked_sim_id'].toString().isEmpty) {
      throw ArgumentError('Linked SIM ID cannot be null or empty');
    }
    
    // Business rule validation
    final accountName = json['account_name'].toString();
    if (accountName.length < 2 || accountName.length > 100) {
      throw ArgumentError('Account name must be between 2 and 100 characters');
    }
    
    final accountType = json['account_type'].toString();
    const validTypes = ['Bank Account', 'Mobile Wallet', 'Online Money'];
    if (!validTypes.contains(accountType)) {
      throw ArgumentError('Invalid account type: $accountType. Must be one of: ${validTypes.join(', ')}');
    }
    
    final initialBalance = json['initial_balance'];
    if (initialBalance != null) {
      final balance = (initialBalance as num).toDouble();
      if (balance < -999999999.99 || balance > 999999999.99) {
        throw ArgumentError('Initial balance must be between -999,999,999.99 and 999,999,999.99 ETB');
      }
    }
  }

  /// Convert FinancialAccountRecordModel to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_name': accountName,
      'account_identifier': accountIdentifier,
      'account_type': accountType,
      'linked_sim_id': linkedSimId,
      'initial_balance': initialBalance,
      'date_added': dateAdded.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create FinancialAccountRecordModel from domain entity
  factory FinancialAccountRecordModel.fromEntity(FinancialAccountRecord entity) {
    return FinancialAccountRecordModel(
      id: entity.id,
      userId: entity.userId,
      accountName: entity.accountName,
      accountIdentifier: entity.accountIdentifier,
      accountType: entity.accountType,
      linkedSimId: entity.linkedSimId,
      initialBalance: entity.initialBalance,
      dateAdded: entity.dateAdded,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert to domain entity
  FinancialAccountRecord toEntity() {
    return FinancialAccountRecord(
      id: id,
      userId: userId,
      accountName: accountName,
      accountIdentifier: accountIdentifier,
      accountType: accountType,
      linkedSimId: linkedSimId,
      initialBalance: initialBalance,
      dateAdded: dateAdded,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create FinancialAccountRecordModel for new insert
  factory FinancialAccountRecordModel.forInsert({
    required String userId,
    required String accountName,
    required String accountIdentifier,
    required String accountType,
    required String linkedSimId,
    required double initialBalance,
    DateTime? dateAdded,
  }) {
    final now = DateTime.now();
    final addedDate = dateAdded ?? now;
    
    return FinancialAccountRecordModel(
      id: '', // Will be generated by Supabase
      userId: userId,
      accountName: accountName,
      accountIdentifier: accountIdentifier,
      accountType: accountType,
      linkedSimId: linkedSimId,
      initialBalance: initialBalance,
      dateAdded: addedDate,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create JSON for insert (excludes ID and includes current timestamps)
  Map<String, dynamic> toInsertJson() {
    final now = DateTime.now().toIso8601String();
    return {
      'user_id': userId,
      'account_name': accountName,
      'account_identifier': accountIdentifier,
      'account_type': accountType,
      'linked_sim_id': linkedSimId,
      'initial_balance': initialBalance,
      'date_added': dateAdded.toIso8601String(),
      'created_at': now,
      'updated_at': now,
    };
  }

  /// Create JSON for update (excludes ID, user_id, and preserves dateAdded)
  Map<String, dynamic> toUpdateJson() {
    return {
      'account_name': accountName,
      'account_identifier': accountIdentifier,
      'account_type': accountType,
      'linked_sim_id': linkedSimId,
      'initial_balance': initialBalance,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create JSON for insert (excludes ID and auto-generated fields)
  Map<String, dynamic> toJsonForInsert() {
    return {
      'user_id': userId,
      'account_name': accountName,
      'account_identifier': accountIdentifier,
      'account_type': accountType,
      'linked_sim_id': linkedSimId,
      'initial_balance': initialBalance,
      'date_added': dateAdded.toIso8601String(),
    };
  }

  /// Create FinancialAccountRecordModel for update
  FinancialAccountRecordModel copyWithUpdate({
    String? accountName,
    String? accountIdentifier,
    String? accountType,
    String? linkedSimId,
    double? initialBalance,
  }) {
    return FinancialAccountRecordModel(
      id: id,
      userId: userId,
      accountName: accountName ?? this.accountName,
      accountIdentifier: accountIdentifier ?? this.accountIdentifier,
      accountType: accountType ?? this.accountType,
      linkedSimId: linkedSimId ?? this.linkedSimId,
      initialBalance: initialBalance ?? this.initialBalance,
      dateAdded: dateAdded, // Preserve original date added
      createdAt: createdAt, // Preserve original created date
      updatedAt: DateTime.now(), // Update timestamp
    );
  }

  @override
  String toString() {
    return 'FinancialAccountRecordModel(id: $id, name: $accountName, type: $accountType, balance: $formattedInitialBalance)';
  }
}