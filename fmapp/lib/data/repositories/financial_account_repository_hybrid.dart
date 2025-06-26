import '../../domain/entities/financial_account_record.dart';
import '../../domain/repositories/financial_account_repository.dart';
import '../../services/supabase_service.dart';
import '../../services/isar_service.dart';
import '../local/isar_schemas.dart';
import '../models/financial_account_record_model.dart';

class FinancialAccountRepositoryHybrid implements FinancialAccountRepository {
  final SupabaseService _supabaseService;
  final IsarService _isarService;

  FinancialAccountRepositoryHybrid(this._supabaseService, this._isarService);

  @override
  Future<List<FinancialAccountRecord>> getAllAccounts(String userId) async {
    final isar = await _isarService.database;
    
    // Get from local database first
    final localAccounts = await _isarService.getAll(isar.isarFinancialAccountRecords);
    
    // Convert Isar entities to domain entities
    final accounts = localAccounts
        .where((account) => account.userId == userId)
        .map((isarAccount) => _fromIsarEntity(isarAccount))
        .toList();

    // If online, try to sync from Supabase
    if (await _isarService.isOnline) {
      try {
        final remoteData = await _supabaseService.getRecordsByCondition(
          table: 'financial_account_records',
          conditions: {'user_id': userId},
        );
        
        // Update local database with remote data
        await isar.writeTxn(() async {
          for (final data in remoteData) {
            final isarAccount = _toIsarEntity(
              FinancialAccountRecordModel.fromJson(data).toEntity(),
            );
            await isar.isarFinancialAccountRecords.put(isarAccount);
          }
        });
        
        // Return updated local data
        final updatedAccounts = await _isarService.getAll(isar.isarFinancialAccountRecords);
        return updatedAccounts
            .where((account) => account.userId == userId)
            .map((isarAccount) => _fromIsarEntity(isarAccount))
            .toList();
      } catch (e) {
        // Return local data if sync fails
        return accounts;
      }
    }
    
    return accounts;
  }

  @override
  Future<FinancialAccountRecord?> getAccountById(String id) async {
    final isar = await _isarService.database;
    
    final isarAccount = await isar.isarFinancialAccountRecords
        .getByRecordId(id);
    
    if (isarAccount != null && !isarAccount.pendingDelete) {
      return _fromIsarEntity(isarAccount);
    }
    
    return null;
  }

  @override
  Future<FinancialAccountRecord> createAccount(FinancialAccountRecord account) async {
    final isar = await _isarService.database;
    
    // Convert to Isar entity
    final isarAccount = _toIsarEntity(account);
    isarAccount.synced = false;
    
    // Write to local database first
    await isar.writeTxn(() async {
      await isar.isarFinancialAccountRecords.put(isarAccount);
    });
    
    // Queue for sync to Supabase
    await _isarService.create(
      isarAccount,
      tableName: 'financial_account_records',
      getId: (entity) => entity.recordId,
      toJson: (entity) => _entityToJson(_fromIsarEntity(entity)),
    );
    
    return _fromIsarEntity(isarAccount);
  }

  @override
  Future<FinancialAccountRecord> updateAccount(FinancialAccountRecord account) async {
    final isar = await _isarService.database;
    
    // Convert to Isar entity
    final isarAccount = _toIsarEntity(account);
    isarAccount.synced = false;
    isarAccount.updatedAt = DateTime.now();
    
    // Update local database first
    await isar.writeTxn(() async {
      await isar.isarFinancialAccountRecords.put(isarAccount);
    });
    
    // Queue for sync to Supabase
    await _isarService.update(
      isarAccount,
      tableName: 'financial_account_records',
      getId: (entity) => entity.recordId,
      toJson: (entity) => _entityToJson(_fromIsarEntity(entity)),
    );
    
    return _fromIsarEntity(isarAccount);
  }

  @override
  Future<void> deleteAccount(String id) async {
    final isar = await _isarService.database;
    
    // Mark as pending delete in local database
    await _isarService.delete(
      id,
      tableName: 'financial_account_records',
      collection: isar.isarFinancialAccountRecords,
    );
  }

  @override
  Future<List<FinancialAccountRecord>> getAccountsBySimId(String simId) async {
    final isar = await _isarService.database;
    
    final localAccounts = await isar.isarFinancialAccountRecords
        .where()
        .linkedSimIdEqualTo(simId)
        .findAll();
    
    return localAccounts
        .where((account) => !account.pendingDelete)
        .map((isarAccount) => _fromIsarEntity(isarAccount))
        .toList();
  }

  @override
  Future<double> calculateCurrentBalance(String accountId) async {
    // For now, delegate to Supabase service for balance calculation
    // In a full implementation, this would calculate from local transactions
    try {
      return await _supabaseService.calculateAccountBalance(accountId);
    } catch (e) {
      // Return 0.0 if calculation fails
      return 0.0;
    }
  }

  @override
  Future<Map<String, double>> calculateAllBalances(String userId) async {
    // For now, delegate to Supabase service
    // In a full implementation, this would calculate from local data
    try {
      return await _supabaseService.calculateAllAccountBalances();
    } catch (e) {
      return {};
    }
  }

  @override
  Future<double> getSimTotalBalance(String simId) async {
    // For now, delegate to Supabase service
    // In a full implementation, this would calculate from local data
    try {
      return await _supabaseService.calculateSimTotalBalance(simId);
    } catch (e) {
      return 0.0;
    }
  }

  // Helper methods to convert between domain entities and Isar entities
  IsarFinancialAccountRecord _toIsarEntity(FinancialAccountRecord domain) {
    return IsarFinancialAccountRecord()
      ..recordId = domain.id
      ..userId = domain.userId
      ..accountName = domain.accountName
      ..accountIdentifier = domain.accountIdentifier
      ..accountType = domain.accountType
      ..linkedSimId = domain.linkedSimId
      ..initialBalance = domain.initialBalance
      ..dateAdded = domain.dateAdded
      ..createdAt = domain.createdAt
      ..updatedAt = domain.updatedAt;
  }

  FinancialAccountRecord _fromIsarEntity(IsarFinancialAccountRecord isar) {
    return FinancialAccountRecord(
      id: isar.recordId,
      userId: isar.userId,
      accountName: isar.accountName,
      accountIdentifier: isar.accountIdentifier,
      accountType: isar.accountType,
      linkedSimId: isar.linkedSimId,
      initialBalance: isar.initialBalance,
      dateAdded: isar.dateAdded ?? DateTime.now(),
      createdAt: isar.createdAt ?? DateTime.now(),
      updatedAt: isar.updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _entityToJson(FinancialAccountRecord entity) {
    return FinancialAccountRecordModel.fromEntity(entity).toJsonForInsert();
  }
}