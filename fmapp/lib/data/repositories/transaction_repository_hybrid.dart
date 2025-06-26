import '../../domain/entities/transaction_record.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../services/supabase_service.dart';
import '../../services/isar_service.dart';
import '../local/isar_schemas.dart';
import '../models/transaction_record_model.dart';

class TransactionRepositoryHybrid implements TransactionRepository {
  final SupabaseService _supabaseService;
  final IsarService _isarService;

  TransactionRepositoryHybrid(this._supabaseService, this._isarService);

  @override
  Future<List<TransactionRecord>> getAllTransactions(String userId) async {
    final isar = await _isarService.database;
    
    // Get from local database first
    final localTransactions = await _isarService.getAll(isar.isarTransactionRecords);
    
    // Convert Isar entities to domain entities
    final transactions = localTransactions
        .where((transaction) => transaction.userId == userId)
        .map((isarTransaction) => _fromIsarEntity(isarTransaction))
        .toList();

    // If online, try to sync from Supabase
    if (await _isarService.isOnline) {
      try {
        final remoteData = await _supabaseService.getRecordsByCondition(
          table: 'transaction_records',
          conditions: {'user_id': userId},
        );
        
        // Update local database with remote data
        await isar.writeTxn(() async {
          for (final data in remoteData) {
            final isarTransaction = _toIsarEntity(
              TransactionRecordModel.fromJson(data).toEntity(),
            );
            await isar.isarTransactionRecords.put(isarTransaction);
          }
        });
        
        // Return updated local data
        final updatedTransactions = await _isarService.getAll(isar.isarTransactionRecords);
        return updatedTransactions
            .where((transaction) => transaction.userId == userId)
            .map((isarTransaction) => _fromIsarEntity(isarTransaction))
            .toList();
      } catch (e) {
        // Return local data if sync fails
        return transactions;
      }
    }
    
    return transactions;
  }

  @override
  Future<TransactionRecord?> getTransactionById(String id) async {
    final isar = await _isarService.database;
    
    final isarTransaction = await isar.isarTransactionRecords
        .where()
        .recordIdEqualTo(id)
        .findFirst();
    
    if (isarTransaction != null && !isarTransaction.pendingDelete) {
      return _fromIsarEntity(isarTransaction);
    }
    
    return null;
  }

  @override
  Future<TransactionRecord> createTransaction(TransactionRecord transaction) async {
    final isar = await _isarService.database;
    
    // Convert to Isar entity
    final isarTransaction = _toIsarEntity(transaction);
    isarTransaction.synced = false;
    
    // Write to local database first
    await isar.writeTxn(() async {
      await isar.isarTransactionRecords.put(isarTransaction);
    });
    
    // Queue for sync to Supabase
    await _isarService.create(
      isarTransaction,
      tableName: 'transaction_records',
      getId: (entity) => entity.recordId,
      toJson: (entity) => _entityToJson(_fromIsarEntity(entity)),
    );
    
    return _fromIsarEntity(isarTransaction);
  }

  @override
  Future<TransactionRecord> updateTransaction(TransactionRecord transaction) async {
    final isar = await _isarService.database;
    
    // Convert to Isar entity
    final isarTransaction = _toIsarEntity(transaction);
    isarTransaction.synced = false;
    isarTransaction.updatedAt = DateTime.now();
    
    // Update local database first
    await isar.writeTxn(() async {
      await isar.isarTransactionRecords.put(isarTransaction);
    });
    
    // Queue for sync to Supabase
    await _isarService.update(
      isarTransaction,
      tableName: 'transaction_records',
      getId: (entity) => entity.recordId,
      toJson: (entity) => _entityToJson(_fromIsarEntity(entity)),
    );
    
    return _fromIsarEntity(isarTransaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final isar = await _isarService.database;
    
    // Mark as pending delete in local database
    await _isarService.delete(
      id,
      tableName: 'transaction_records',
      collection: isar.isarTransactionRecords,
    );
  }

  @override
  Future<List<TransactionRecord>> getTransactionsByAccount(String accountId) async {
    final isar = await _isarService.database;
    
    final localTransactions = await isar.isarTransactionRecords
        .where()
        .affectedAccountIdEqualTo(accountId)
        .findAll();
    
    return localTransactions
        .where((transaction) => !transaction.pendingDelete)
        .map((isarTransaction) => _fromIsarEntity(isarTransaction))
        .toList();
  }

  @override
  Future<List<TransactionRecord>> getTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final isar = await _isarService.database;
    
    final localTransactions = await isar.isarTransactionRecords
        .where()
        .userIdEqualTo(userId)
        .findAll();
    
    // Filter by date range in application layer
    return localTransactions
        .where((transaction) => 
            !transaction.pendingDelete &&
            transaction.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            transaction.transactionDate.isBefore(endDate.add(const Duration(days: 1))))
        .map((isarTransaction) => _fromIsarEntity(isarTransaction))
        .toList();
  }

  @override
  Future<List<TransactionRecord>> getRecentTransactions(String userId, {int limit = 10}) async {
    final isar = await _isarService.database;
    
    final localTransactions = await isar.isarTransactionRecords
        .where()
        .userIdEqualTo(userId)
        .findAll();
    
    // Sort by date and take recent ones
    final sortedTransactions = localTransactions
        .where((transaction) => !transaction.pendingDelete)
        .toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    
    return sortedTransactions
        .take(limit)
        .map((isarTransaction) => _fromIsarEntity(isarTransaction))
        .toList();
  }

  @override
  Future<List<TransactionRecord>> getInternalTransfers(String userId) async {
    final isar = await _isarService.database;
    
    final localTransactions = await isar.isarTransactionRecords
        .where()
        .userIdEqualTo(userId)
        .findAll();
    
    return localTransactions
        .where((transaction) => 
            !transaction.pendingDelete && 
            transaction.isInternalTransfer)
        .map((isarTransaction) => _fromIsarEntity(isarTransaction))
        .toList();
  }

  @override
  Future<double> getTotalIncomeForAccount(
    String accountId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final isar = await _isarService.database;
    
    final transactions = await isar.isarTransactionRecords
        .where()
        .affectedAccountIdEqualTo(accountId)
        .findAll();
    
    double total = 0.0;
    for (final transaction in transactions) {
      if (transaction.pendingDelete) continue;
      
      // Check date range if provided
      if (startDate != null && endDate != null) {
        if (!transaction.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) ||
            !transaction.transactionDate.isBefore(endDate.add(const Duration(days: 1)))) {
          continue;
        }
      }
      
      if (transaction.transactionType.toLowerCase().contains('income') ||
          transaction.transactionType.toLowerCase().contains('credit')) {
        total += transaction.amount;
      }
    }
    
    return total;
  }

  @override
  Future<double> getTotalExpenseForAccount(
    String accountId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final isar = await _isarService.database;
    
    final transactions = await isar.isarTransactionRecords
        .where()
        .affectedAccountIdEqualTo(accountId)
        .findAll();
    
    double total = 0.0;
    for (final transaction in transactions) {
      if (transaction.pendingDelete) continue;
      
      // Check date range if provided
      if (startDate != null && endDate != null) {
        if (!transaction.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) ||
            !transaction.transactionDate.isBefore(endDate.add(const Duration(days: 1)))) {
          continue;
        }
      }
      
      if (transaction.transactionType.toLowerCase().contains('expense') ||
          transaction.transactionType.toLowerCase().contains('debit')) {
        total += transaction.amount;
      }
    }
    
    return total;
  }

  // Helper methods to convert between domain entities and Isar entities
  IsarTransactionRecord _toIsarEntity(TransactionRecord domain) {
    return IsarTransactionRecord()
      ..recordId = domain.id
      ..userId = domain.userId
      ..affectedAccountId = domain.affectedAccountId
      ..transactionDate = domain.transactionDate
      ..amount = domain.amount
      ..transactionType = domain.transactionType
      ..currency = domain.currency
      ..descriptionNotes = domain.descriptionNotes
      ..payerSenderRaw = domain.payerSenderRaw
      ..payeeReceiverRaw = domain.payeeReceiverRaw
      ..referenceNumber = domain.referenceNumber
      ..isInternalTransfer = domain.isInternalTransfer
      ..counterpartyAccountId = domain.counterpartyAccountId
      ..receiptFileLink = domain.receiptFileLink
      ..ocrExtractedRawText = domain.ocrExtractedRawText
      ..createdAt = domain.createdAt
      ..updatedAt = domain.updatedAt;
  }

  TransactionRecord _fromIsarEntity(IsarTransactionRecord isar) {
    return TransactionRecord(
      id: isar.recordId,
      userId: isar.userId,
      affectedAccountId: isar.affectedAccountId,
      transactionDate: isar.transactionDate,
      amount: isar.amount,
      transactionType: isar.transactionType,
      currency: isar.currency,
      descriptionNotes: isar.descriptionNotes,
      payerSenderRaw: isar.payerSenderRaw,
      payeeReceiverRaw: isar.payeeReceiverRaw,
      referenceNumber: isar.referenceNumber,
      isInternalTransfer: isar.isInternalTransfer,
      counterpartyAccountId: isar.counterpartyAccountId,
      receiptFileLink: isar.receiptFileLink,
      ocrExtractedRawText: isar.ocrExtractedRawText,
      createdAt: isar.createdAt,
      updatedAt: isar.updatedAt,
    );
  }

  Map<String, dynamic> _entityToJson(TransactionRecord entity) {
    return TransactionRecordModel.fromEntity(entity).toJsonForInsert();
  }
}