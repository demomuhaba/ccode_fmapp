import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'supabase_service.dart';

// Conditional imports for platform compatibility
import 'package:isar/isar.dart' if (dart.library.html) '../data/local/isar_schemas_stub.dart';
import 'package:path_provider/path_provider.dart' if (dart.library.html) '../data/local/isar_schemas_stub.dart';
import '../data/local/isar_schemas.dart' if (dart.library.html) '../data/local/isar_schemas_stub.dart';

class IsarService {
  static IsarService? _instance;
  static IsarService get instance => _instance ??= IsarService._internal();
  IsarService._internal();

  Isar? _isar;
  final SupabaseService _supabaseService = SupabaseService.instance;

  Future<Isar> get database async {
    _isar ??= await _initializeIsar();
    return _isar!;
  }

  Future<Isar> _initializeIsar() async {
    // For web platform, Isar is not supported, fallback to Supabase-only mode
    if (kIsWeb) {
      throw UnsupportedError('Isar is not supported on web platform. Using Supabase-only mode.');
    }
    
    final dir = await getApplicationDocumentsDirectory();
    
    return await Isar.open(
      [
        IsarUserProfileSchema,
        IsarSimCardRecordSchema,
        IsarFinancialAccountRecordSchema,
        IsarTransactionRecordSchema,
        IsarFriendRecordSchema,
        IsarLoanDebtItemSchema,
        IsarLoanDebtPaymentSchema,
        IsarSyncQueueSchema,
      ],
      directory: dir.path,
      name: 'fmapp_db',
    );
  }

  // Connectivity check
  Future<bool> get isOnline async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) ||
           connectivityResult.contains(ConnectivityResult.wifi) ||
           connectivityResult.contains(ConnectivityResult.ethernet);
  }

  // Generic CRUD operations with offline-first strategy
  Future<T> create<T>(
    T entity, {
    required String tableName,
    required String Function(T) getId,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    final isar = await database;
    
    // Write to local database first
    await isar.writeTxn(() async {
      await isar.collection<T>().put(entity);
    });

    // Queue for sync
    await _queueForSync(tableName, getId(entity), 'CREATE', toJson(entity));

    // Try immediate sync if online
    if (await isOnline) {
      await _syncNow();
    }

    return entity;
  }

  Future<T> update<T>(
    T entity, {
    required String tableName,
    required String Function(T) getId,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    final isar = await database;
    
    // Update local database first
    await isar.writeTxn(() async {
      await isar.collection<T>().put(entity);
    });

    // Queue for sync
    await _queueForSync(tableName, getId(entity), 'UPDATE', toJson(entity));

    // Try immediate sync if online
    if (await isOnline) {
      await _syncNow();
    }

    return entity;
  }

  Future<void> delete<T>(
    String id, {
    required String tableName,
    required IsarCollection<T> collection,
  }) async {
    final isar = await database;
    
    // Mark as pending delete in local database
    await isar.writeTxn(() async {
      final entity = await collection.where().filter().idEqualTo(id as int).findFirst();
      if (entity != null) {
        // Set pendingDelete flag instead of actual deletion
        if (entity is IsarSimCardRecord) {
          entity.pendingDelete = true;
          await collection.put(entity);
        } else if (entity is IsarFinancialAccountRecord) {
          entity.pendingDelete = true;
          await collection.put(entity);
        } else if (entity is IsarTransactionRecord) {
          entity.pendingDelete = true;
          await collection.put(entity);
        } else if (entity is IsarFriendRecord) {
          entity.pendingDelete = true;
          await collection.put(entity);
        } else if (entity is IsarLoanDebtItem) {
          entity.pendingDelete = true;
          await collection.put(entity);
        } else if (entity is IsarLoanDebtPayment) {
          entity.pendingDelete = true;
          await collection.put(entity);
        }
      }
    });

    // Queue for sync
    await _queueForSync(tableName, id, 'DELETE', {});

    // Try immediate sync if online
    if (await isOnline) {
      await _syncNow();
    }
  }

  Future<List<T>> getAll<T>(IsarCollection<T> collection) async {
    final isar = await database;
    
    // Filter out pending delete items
    final allItems = await collection.where().findAll();
    return allItems.where((item) {
      if (item is IsarSimCardRecord) return !item.pendingDelete;
      if (item is IsarFinancialAccountRecord) return !item.pendingDelete;
      if (item is IsarTransactionRecord) return !item.pendingDelete;
      if (item is IsarFriendRecord) return !item.pendingDelete;
      if (item is IsarLoanDebtItem) return !item.pendingDelete;
      if (item is IsarLoanDebtPayment) return !item.pendingDelete;
      return true;
    }).toList();
  }

  Future<T?> getById<T>(String id, IsarCollection<T> collection) async {
    final isar = await database;
    
    final item = await collection.where().filter().idEqualTo(id as int).findFirst();
    if (item != null) {
      // Check if pending delete
      if (item is IsarSimCardRecord && item.pendingDelete) return null;
      if (item is IsarFinancialAccountRecord && item.pendingDelete) return null;
      if (item is IsarTransactionRecord && item.pendingDelete) return null;
      if (item is IsarFriendRecord && item.pendingDelete) return null;
      if (item is IsarLoanDebtItem && item.pendingDelete) return null;
      if (item is IsarLoanDebtPayment && item.pendingDelete) return null;
    }
    
    return item;
  }

  // Sync queue operations
  Future<void> _queueForSync(String tableName, String recordId, String operation, Map<String, dynamic> data) async {
    final isar = await database;
    
    final syncItem = IsarSyncQueue()
      ..tableName = tableName
      ..recordId = recordId
      ..operation = operation
      ..jsonData = jsonEncode(data)
      ..createdAt = DateTime.now()
      ..retryCount = 0;

    await isar.writeTxn(() async {
      await isar.isarSyncQueues.put(syncItem);
    });
  }

  // Background sync process
  Future<void> _syncNow() async {
    if (!await isOnline) return;

    final isar = await database;
    final pendingItems = await isar.isarSyncQueues.where().findAll();

    for (final item in pendingItems) {
      try {
        bool success = false;
        
        switch (item.operation) {
          case 'CREATE':
            success = await _syncCreate(item);
            break;
          case 'UPDATE':
            success = await _syncUpdate(item);
            break;
          case 'DELETE':
            success = await _syncDelete(item);
            break;
        }

        if (success) {
          // Remove from sync queue
          await isar.writeTxn(() async {
            await isar.isarSyncQueues.delete(item.id);
          });
          
          // Update sync status in entity
          await _updateSyncStatus(item.tableName, item.recordId, true);
        } else {
          // Increment retry count
          item.retryCount++;
          await isar.writeTxn(() async {
            await isar.isarSyncQueues.put(item);
          });
        }
      } catch (e) {
        // Update error message and retry count
        item.errorMessage = e.toString();
        item.retryCount++;
        await isar.writeTxn(() async {
          await isar.isarSyncQueues.put(item);
        });
      }
    }
  }

  Future<bool> _syncCreate(IsarSyncQueue item) async {
    try {
      final data = _parseJsonData(item.jsonData);
      await _supabaseService.createRecord(table: item.tableName, data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _syncUpdate(IsarSyncQueue item) async {
    try {
      final data = _parseJsonData(item.jsonData);
      await _supabaseService.updateRecord(
        table: item.tableName,
        id: item.recordId,
        data: data,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _syncDelete(IsarSyncQueue item) async {
    try {
      await _supabaseService.deleteRecord(table: item.tableName, id: item.recordId);
      
      // Now actually delete from local database
      final isar = await database;
      await isar.writeTxn(() async {
        switch (item.tableName) {
          case 'sim_card_records':
            await isar.isarSimCardRecords.where().recordIdEqualTo(item.recordId).deleteAll();
            break;
          case 'financial_account_records':
            await isar.isarFinancialAccountRecords.where().recordIdEqualTo(item.recordId).deleteAll();
            break;
          case 'transaction_records':
            await isar.isarTransactionRecords.where().recordIdEqualTo(item.recordId).deleteAll();
            break;
          case 'friend_records':
            await isar.isarFriendRecords.where().recordIdEqualTo(item.recordId).deleteAll();
            break;
          case 'loan_debt_items':
            await isar.isarLoanDebtItems.where().recordIdEqualTo(item.recordId).deleteAll();
            break;
          case 'loan_debt_payments':
            await isar.isarLoanDebtPayments.where().recordIdEqualTo(item.recordId).deleteAll();
            break;
        }
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateSyncStatus(String tableName, String recordId, bool synced) async {
    final isar = await database;
    await isar.writeTxn(() async {
      switch (tableName) {
        case 'sim_card_records':
          final record = await isar.isarSimCardRecords.where().recordIdEqualTo(recordId).findFirst();
          if (record != null) {
            record.synced = synced;
            record.lastSyncAt = DateTime.now();
            await isar.isarSimCardRecords.put(record);
          }
          break;
        case 'financial_account_records':
          final record = await isar.isarFinancialAccountRecords.where().recordIdEqualTo(recordId).findFirst();
          if (record != null) {
            record.synced = synced;
            record.lastSyncAt = DateTime.now();
            await isar.isarFinancialAccountRecords.put(record);
          }
          break;
        case 'transaction_records':
          final record = await isar.isarTransactionRecords.where().recordIdEqualTo(recordId).findFirst();
          if (record != null) {
            record.synced = synced;
            record.lastSyncAt = DateTime.now();
            await isar.isarTransactionRecords.put(record);
          }
          break;
        case 'friend_records':
          final record = await isar.isarFriendRecords.where().recordIdEqualTo(recordId).findFirst();
          if (record != null) {
            record.synced = synced;
            record.lastSyncAt = DateTime.now();
            await isar.isarFriendRecords.put(record);
          }
          break;
        case 'loan_debt_items':
          final record = await isar.isarLoanDebtItems.where().recordIdEqualTo(recordId).findFirst();
          if (record != null) {
            record.synced = synced;
            record.lastSyncAt = DateTime.now();
            await isar.isarLoanDebtItems.put(record);
          }
          break;
        case 'loan_debt_payments':
          final record = await isar.isarLoanDebtPayments.where().recordIdEqualTo(recordId).findFirst();
          if (record != null) {
            record.synced = synced;
            record.lastSyncAt = DateTime.now();
            await isar.isarLoanDebtPayments.put(record);
          }
          break;
      }
    });
  }

  Map<String, dynamic> _parseJsonData(String jsonData) {
    try {
      if (jsonData.isEmpty) return {};
      
      // If it's already a proper JSON string, parse it
      if (jsonData.startsWith('{') && jsonData.endsWith('}')) {
        return Map<String, dynamic>.from(
          jsonDecode(jsonData)
        );
      }
      
      // If it's a string representation of a map, we need to handle it differently
      // For now, return empty map - in production you'd implement proper parsing
      return {};
    } catch (e) {
      debugPrint('Error parsing JSON data: $e');
      return {};
    }
  }

  // Background sync scheduler
  Future<void> startBackgroundSync() async {
    // Start periodic sync every 30 seconds when online
    Stream.periodic(const Duration(seconds: 30)).listen((_) async {
      if (await isOnline) {
        await _syncNow();
      }
    });
  }

  // Force sync all data
  Future<void> forceSyncAll() async {
    if (await isOnline) {
      await _syncNow();
    }
  }

  // Get sync statistics
  Future<Map<String, int>> getSyncStats() async {
    final isar = await database;
    final pendingCount = await isar.isarSyncQueues.count();
    
    return {
      'pendingSync': pendingCount,
      'totalRecords': await _getTotalRecordCount(),
    };
  }

  Future<int> _getTotalRecordCount() async {
    final isar = await database;
    final counts = await Future.wait([
      isar.isarUserProfiles.count(),
      isar.isarSimCardRecords.count(),
      isar.isarFinancialAccountRecords.count(),
      isar.isarTransactionRecords.count(),
      isar.isarFriendRecords.count(),
      isar.isarLoanDebtItems.count(),
      isar.isarLoanDebtPayments.count(),
    ]);
    
    return counts.reduce((a, b) => a + b);
  }

  // Close database
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}