// Supabase service configuration for fmapp
// Handles database connection, authentication, and core API interactions

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();
  
  /// Supabase client instance
  SupabaseClient get client => Supabase.instance.client;
  
  /// Current authenticated user
  User? get currentUser => client.auth.currentUser;
  
  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
  
  /// Initialize Supabase with project configuration
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: false, // Set to true for development debugging
    );
  }
  
  /// Sign up new user with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
      
      // Create user profile record if sign up successful
      if (response.user != null) {
        await _createUserProfile(
          userId: response.user!.id,
          email: email,
          fullName: fullName,
        );
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Sign in existing user with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Sign out current user
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Reset password for email
  Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (!isAuthenticated) return null;
    
    try {
      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user profile by ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Create user profile
  Future<Map<String, dynamic>> createUserProfile(Map<String, dynamic> data) async {
    try {
      final response = await client
          .from('user_profiles')
          .insert(data)
          .select()
          .single();
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    try {
      await client
          .from('user_profiles')
          .delete()
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update current user profile
  Future<void> updateUserProfile({
    String? fullName,
    Map<String, dynamic>? preferences,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (fullName != null) updateData['full_name'] = fullName;
      if (preferences != null) updateData['preferences'] = preferences;
      
      await client
          .from('user_profiles')
          .update(updateData)
          .eq('id', currentUser!.id);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Listen to authentication state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  /// Create user profile record in database
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    String? fullName,
  }) async {
    try {
      await client.from('user_profiles').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'preferences': <String, dynamic>{},
      });
    } catch (e) {
      // Log error but don't throw to avoid blocking sign up process
      print('Error creating user profile: $e');
    }
  }
  
  /// Generic database query helper
  Future<List<Map<String, dynamic>>> query({
    required String table,
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      dynamic query = client.from(table).select(select ?? '*');
      
      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }
      
      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }
      
      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }
      
      return await query;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Generic database insert helper
  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      // Add user_id to data if not present
      if (!data.containsKey('user_id')) {
        data['user_id'] = currentUser!.id;
      }
      
      // Add timestamps
      final now = DateTime.now().toIso8601String();
      data['created_at'] = now;
      data['updated_at'] = now;
      
      final response = await client
          .from(table)
          .insert(data)
          .select()
          .single();
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Generic database update helper
  Future<Map<String, dynamic>> update({
    required String table,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      // Add updated timestamp
      data['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await client
          .from(table)
          .update(data)
          .eq('id', id)
          .eq('user_id', currentUser!.id) // Ensure user can only update their own data
          .select()
          .single();
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Generic database delete helper
  Future<void> delete({
    required String table,
    required String id,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      await client
          .from(table)
          .delete()
          .eq('id', id)
          .eq('user_id', currentUser!.id); // Ensure user can only delete their own data
    } catch (e) {
      rethrow;
    }
  }
  
  /// Calculate current balance for a financial account with optional transaction locking
  Future<double> calculateAccountBalance(String accountId, {bool withLock = false}) async {
    try {
      if (withLock) {
        // Use transaction for consistency
        return await client.rpc('calculate_account_balance_locked', params: {
          'account_id_param': accountId,
          'user_id_param': currentUser!.id,
        });
      }
      
      // Get initial balance
      final accountResponse = await client
          .from('financial_account_records')
          .select('initial_balance')
          .eq('id', accountId)
          .eq('user_id', currentUser!.id)
          .single();
      
      final initialBalance = (accountResponse['initial_balance'] as num).toDouble();
      
      // Get all transactions for this account
      final transactionsResponse = await client
          .from('transaction_records')
          .select('amount, transaction_type')
          .eq('affected_account_id', accountId)
          .eq('user_id', currentUser!.id);
      
      double transactionsSum = 0.0;
      for (final transaction in transactionsResponse) {
        final amount = (transaction['amount'] as num).toDouble();
        final type = transaction['transaction_type'] as String;
        
        if (type == AppConstants.transactionTypeCredit) {
          transactionsSum += amount;
        } else if (type == AppConstants.transactionTypeDebit) {
          transactionsSum -= amount;
        }
      }
      
      return initialBalance + transactionsSum;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get SIM total balance (sum of all linked accounts)
  Future<double> calculateSimTotalBalance(String simId) async {
    try {
      // Get all accounts linked to this SIM
      final accountsResponse = await client
          .from('financial_account_records')
          .select('id')
          .eq('linked_sim_id', simId)
          .eq('user_id', currentUser!.id);
      
      double totalBalance = 0.0;
      for (final account in accountsResponse) {
        final accountBalance = await calculateAccountBalance(account['id']);
        totalBalance += accountBalance;
      }
      
      return totalBalance;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Upload file to Supabase Storage
  Future<String> uploadFile({
    required String bucket,
    required String filePath,
    required List<int> fileBytes,
    String? fileName,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      final actualFileName = fileName ?? 'file_${DateTime.now().millisecondsSinceEpoch}';
      final fullPath = '${currentUser!.id}/$actualFileName';
      
      await client.storage.from(bucket).uploadBinary(
        fullPath,
        Uint8List.fromList(fileBytes),
      );
      
      return fullPath;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get signed URL for file
  Future<String> getFileUrl({
    required String bucket,
    required String filePath,
  }) async {
    try {
      return client.storage.from(bucket).getPublicUrl(filePath);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all records from a table for the current user
  Future<List<Map<String, dynamic>>> getAllRecords({
    required String table,
    String? select,
    String? orderBy,
    bool ascending = true,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      dynamic query = client.from(table).select(select ?? '*');
      query = query.eq('user_id', currentUser!.id);
      
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }
      
      return await query;
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single record by ID for the current user
  Future<Map<String, dynamic>?> getRecordById({
    required String table,
    required String id,
    String? select,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      final response = await client
          .from(table)
          .select(select ?? '*')
          .eq('id', id)
          .eq('user_id', currentUser!.id)
          .maybeSingle();
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new record in a table
  Future<Map<String, dynamic>> createRecord({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    return await insert(table: table, data: data);
  }

  /// Create transaction with balance validation and locking
  Future<Map<String, dynamic>> createTransactionWithBalanceCheck({
    required Map<String, dynamic> transactionData,
    required String accountId,
    required double amount,
    required String transactionType,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      // Use Supabase transaction for atomicity
      return await client.rpc('create_transaction_with_balance_check', params: {
        'transaction_data_param': transactionData,
        'account_id_param': accountId,
        'amount_param': amount,
        'transaction_type_param': transactionType,
        'user_id_param': currentUser!.id,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Create internal transfer with dual balance updates
  Future<List<Map<String, dynamic>>> createInternalTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required Map<String, dynamic> transactionData,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      // Use stored procedure for atomic internal transfer
      final result = await client.rpc('create_internal_transfer', params: {
        'from_account_id_param': fromAccountId,
        'to_account_id_param': toAccountId,
        'amount_param': amount,
        'transaction_data_param': transactionData,
        'user_id_param': currentUser!.id,
      });
      
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      rethrow;
    }
  }

  /// Update a record in a table
  Future<Map<String, dynamic>> updateRecord({
    required String table,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    return await update(table: table, id: id, data: data);
  }

  /// Delete a record from a table
  Future<void> deleteRecord({
    required String table,
    required String id,
  }) async {
    return await delete(table: table, id: id);
  }

  /// Get records by condition for the current user
  Future<List<Map<String, dynamic>>> getRecordsByCondition({
    required String table,
    required Map<String, dynamic> conditions,
    String? select,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      dynamic query = client.from(table).select(select ?? '*');
      query = query.eq('user_id', currentUser!.id);
      
      // Apply conditions
      conditions.forEach((key, value) {
        query = query.eq(key, value);
      });
      
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      return await query;
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate balances for all accounts for the current user
  Future<Map<String, double>> calculateAllAccountBalances() async {
    if (!isAuthenticated) throw Exception('User not authenticated');
    
    try {
      final accountsResponse = await client
          .from('financial_account_records')
          .select('id')
          .eq('user_id', currentUser!.id);
      
      final balances = <String, double>{};
      
      for (final account in accountsResponse) {
        final accountId = account['id'] as String;
        final balance = await calculateAccountBalance(accountId);
        balances[accountId] = balance;
      }
      
      return balances;
    } catch (e) {
      rethrow;
    }
  }
}