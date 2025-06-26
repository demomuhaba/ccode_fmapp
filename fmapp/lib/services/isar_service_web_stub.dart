// Web-compatible stub for IsarService since Isar doesn't support web
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'supabase_service.dart';

class IsarService {
  static IsarService? _instance;
  static IsarService get instance => _instance ??= IsarService._internal();
  IsarService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;

  // Mock database for web - just return a stub object
  Future<MockIsar> get database async {
    return MockIsar();
  }

  Future<bool> get isOnline async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<List<T>> getAll<T>(MockCollection<T> collection) async {
    // For web, return empty list - would need to fetch from Supabase
    return [];
  }

  Future<T?> getById<T>(String id, MockCollection<T> collection) async {
    // For web, return null - would need to fetch from Supabase
    return null;
  }

  Future<T> create<T>(
    T entity, {
    required String tableName,
    required String Function(T) getId,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    // For web, directly save to Supabase
    try {
      await _supabaseService.insertRecord(table: tableName, data: toJson(entity));
      return entity;
    } catch (e) {
      throw Exception('Failed to create record: $e');
    }
  }

  Future<T> update<T>(
    T entity, {
    required String tableName,
    required String Function(T) getId,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    // For web, directly update in Supabase
    try {
      await _supabaseService.updateRecord(
        table: tableName,
        id: getId(entity),
        data: toJson(entity),
      );
      return entity;
    } catch (e) {
      throw Exception('Failed to update record: $e');
    }
  }

  Future<void> delete<T>(
    String id, {
    required String tableName,
    required MockCollection<T> collection,
  }) async {
    // For web, directly delete from Supabase
    try {
      await _supabaseService.deleteRecord(table: tableName, id: id);
    } catch (e) {
      throw Exception('Failed to delete record: $e');
    }
  }
}

// Mock classes for web compatibility
class MockIsar {
  final isarUserProfiles = MockCollection<dynamic>();
  final isarSimCardRecords = MockCollection<dynamic>();
  final isarFinancialAccountRecords = MockCollection<dynamic>();
  final isarTransactionRecords = MockCollection<dynamic>();
  final isarFriendRecords = MockCollection<dynamic>();
  final isarLoanDebtItems = MockCollection<dynamic>();
  final isarLoanDebtPayments = MockCollection<dynamic>();
  final isarSyncQueues = MockCollection<dynamic>();

  Future<void> writeTxn(Future<void> Function() callback) async {
    await callback();
  }
}

class MockCollection<T> {
  List<T> getAll() => [];
  MockQueryBuilder<T> where() => MockQueryBuilder<T>();
  Future<void> put(T item) async {}
}

class MockQueryBuilder<T> {
  MockQueryBuilder<T> recordIdEqualTo(String id) => this;
  MockQueryBuilder<T> userIdEqualTo(String id) => this;
  MockQueryBuilder<T> phoneNumberEqualTo(String phone) => this;
  MockQueryBuilder<T> linkedSimIdEqualTo(String id) => this;
  MockQueryBuilder<T> and() => this;
  Future<T?> findFirst() async => null;
  Future<List<T>> findAll() async => [];
}