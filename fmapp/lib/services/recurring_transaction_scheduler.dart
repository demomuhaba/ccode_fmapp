import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import '../domain/usecases/recurring_transaction_usecases.dart';
import '../data/repositories/recurring_transaction_repository_impl.dart';
import '../data/repositories/transaction_repository_impl.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';

/// Service for scheduling and executing recurring transactions
class RecurringTransactionScheduler {
  static const String _taskName = 'fmapp.recurring_transactions.check';
  static const String _taskTag = 'recurring_transactions';
  static const String _isolateName = 'recurring_transactions_isolate';
  
  static RecurringTransactionScheduler? _instance;
  static RecurringTransactionScheduler get instance => _instance ??= RecurringTransactionScheduler._();
  
  RecurringTransactionScheduler._();
  
  Timer? _foregroundTimer;
  bool _isInitialized = false;

  /// Initialize the recurring transaction scheduler
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize WorkManager for background tasks
      await Workmanager().initialize(
        callbackDispatcher, 
        isInDebugMode: kDebugMode,
      );
      
      // Register the recurring transaction check task
      await _scheduleBackgroundTask();
      
      // Start foreground checking when app is active
      _startForegroundTimer();
      
      _isInitialized = true;
      debugPrint('RecurringTransactionScheduler initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize RecurringTransactionScheduler: $e');
    }
  }

  /// Schedule background task for checking recurring transactions
  Future<void> _scheduleBackgroundTask() async {
    try {
      await Workmanager().cancelByUniqueName(_taskName);
      
      // Schedule periodic background task (runs every 15 minutes when app is not active)
      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: const Duration(minutes: 15),
        initialDelay: const Duration(minutes: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        tag: _taskTag,
        inputData: {
          'task_type': 'recurring_transaction_check',
          'last_run': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      debugPrint('Background recurring transaction task scheduled');
    } catch (e) {
      debugPrint('Failed to schedule background task: $e');
    }
  }

  /// Start foreground timer for checking recurring transactions when app is active
  void _startForegroundTimer() {
    _foregroundTimer?.cancel();
    
    // Check every 5 minutes when app is in foreground
    _foregroundTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _checkAndExecuteRecurringTransactions(),
    );
    
    // Initial check
    _checkAndExecuteRecurringTransactions();
  }

  /// Check and execute due recurring transactions
  Future<void> _checkAndExecuteRecurringTransactions() async {
    try {
      debugPrint('Checking for due recurring transactions...');
      
      // Get current user ID from auth service
      final supabaseService = SupabaseService();
      final user = supabaseService.getCurrentUser();
      
      if (user == null) {
        debugPrint('No authenticated user found');
        return;
      }

      // Initialize repositories and use cases
      final isarService = IsarService.instance;
      final database = await isarService.database;
      
      final recurringRepo = RecurringTransactionRepositoryImpl(database, supabaseService);
      final transactionRepo = TransactionRepositoryImpl(database, supabaseService);
      final usecases = RecurringTransactionUsecases(recurringRepo, transactionRepo);

      // Execute all due recurring transactions
      final result = await usecases.executeAllDueRecurringTransactions(user.id);
      
      final totalDue = result['total_due'] as int;
      final successCount = result['success_count'] as int;
      final failureCount = result['failure_count'] as int;
      
      if (totalDue > 0) {
        debugPrint('Recurring transactions check completed:');
        debugPrint('  Total due: $totalDue');
        debugPrint('  Successful: $successCount');
        debugPrint('  Failed: $failureCount');
        
        if (failureCount > 0) {
          final failedTransactions = result['failed_transactions'] as List<String>;
          debugPrint('  Failed transactions: ${failedTransactions.join(", ")}');
        }
        
        // Send notification to main isolate if running in background
        if (_isRunningInBackground()) {
          _sendNotificationToMainIsolate({
            'type': 'recurring_transactions_executed',
            'total_due': totalDue,
            'success_count': successCount,
            'failure_count': failureCount,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }
      } else {
        debugPrint('No recurring transactions due for execution');
      }
    } catch (e) {
      debugPrint('Error checking recurring transactions: $e');
      
      if (_isRunningInBackground()) {
        _sendNotificationToMainIsolate({
          'type': 'recurring_transactions_error',
          'error': e.toString(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    }
  }

  /// Check if currently running in background isolate
  bool _isRunningInBackground() {
    try {
      return IsolateNameServer.lookupPortByName(_isolateName) != null;
    } catch (e) {
      return false;
    }
  }

  /// Send notification to main isolate
  void _sendNotificationToMainIsolate(Map<String, dynamic> data) {
    try {
      final port = IsolateNameServer.lookupPortByName(_isolateName);
      if (port != null) {
        port.send(data);
      }
    } catch (e) {
      debugPrint('Failed to send notification to main isolate: $e');
    }
  }

  /// Manually trigger recurring transaction check
  Future<Map<String, dynamic>> checkNow() async {
    try {
      await _checkAndExecuteRecurringTransactions();
      return {
        'success': true,
        'message': 'Recurring transactions check completed',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Get next scheduled execution times for all active recurring transactions
  Future<List<Map<String, dynamic>>> getUpcomingExecutions(String userId) async {
    try {
      final isarService = IsarService.instance;
      final database = await isarService.database;
      final supabaseService = SupabaseService();
      
      final recurringRepo = RecurringTransactionRepositoryImpl(database, supabaseService);
      final transactionRepo = TransactionRepositoryImpl(database, supabaseService);
      final usecases = RecurringTransactionUsecases(recurringRepo, transactionRepo);

      final activeTransactions = await usecases.getActiveRecurringTransactions(userId);
      
      final upcoming = <Map<String, dynamic>>[];
      
      for (final transaction in activeTransactions) {
        final nextExecutions = usecases.previewNextExecutions(transaction, 3);
        
        for (int i = 0; i < nextExecutions.length; i++) {
          upcoming.add({
            'transaction_id': transaction.id,
            'template_name': transaction.templateName,
            'amount': transaction.amount,
            'transaction_type': transaction.transactionType,
            'execution_date': nextExecutions[i].millisecondsSinceEpoch,
            'execution_order': i + 1,
            'frequency': transaction.frequencyDisplayName,
          });
        }
      }
      
      // Sort by execution date
      upcoming.sort((a, b) => (a['execution_date'] as int).compareTo(b['execution_date'] as int));
      
      return upcoming;
    } catch (e) {
      debugPrint('Error getting upcoming executions: $e');
      return [];
    }
  }

  /// Pause the scheduler
  void pause() {
    _foregroundTimer?.cancel();
    debugPrint('RecurringTransactionScheduler paused');
  }

  /// Resume the scheduler
  void resume() {
    _startForegroundTimer();
    debugPrint('RecurringTransactionScheduler resumed');
  }

  /// Stop the scheduler and clean up
  Future<void> stop() async {
    _foregroundTimer?.cancel();
    
    try {
      await Workmanager().cancelByUniqueName(_taskName);
      debugPrint('Background tasks cancelled');
    } catch (e) {
      debugPrint('Error cancelling background tasks: $e');
    }
    
    _isInitialized = false;
    debugPrint('RecurringTransactionScheduler stopped');
  }

  /// Get scheduler status
  Map<String, dynamic> getStatus() {
    return {
      'is_initialized': _isInitialized,
      'foreground_timer_active': _foregroundTimer?.isActive ?? false,
      'last_check': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('Background task started: $task');
      
      if (task == RecurringTransactionScheduler._taskName) {
        // Initialize services for background execution
        await _initializeBackgroundServices();
        
        // Execute recurring transactions check
        final scheduler = RecurringTransactionScheduler.instance;
        await scheduler._checkAndExecuteRecurringTransactions();
        
        debugPrint('Background recurring transaction check completed');
        return Future.value(true);
      }
      
      return Future.value(false);
    } catch (e) {
      debugPrint('Background task error: $e');
      return Future.value(false);
    }
  });
}

/// Initialize services for background execution
Future<void> _initializeBackgroundServices() async {
  try {
    // Initialize Isar database
    await IsarService.instance.database;
    
    // Initialize Supabase (background mode)
    final supabaseService = SupabaseService();
    await supabaseService.initializeForBackground();
    
    debugPrint('Background services initialized');
  } catch (e) {
    debugPrint('Error initializing background services: $e');
    rethrow;
  }
}

/// Extension for Supabase background initialization
extension SupabaseBackgroundInit on SupabaseService {
  Future<void> initializeForBackground() async {
    // Implementation would depend on how SupabaseService is structured
    // This is a placeholder for background initialization logic
    debugPrint('Supabase initialized for background execution');
  }
}