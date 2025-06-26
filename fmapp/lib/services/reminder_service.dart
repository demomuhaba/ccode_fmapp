import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/loan_debt_item.dart';
import '../domain/entities/friend_record.dart';

/// Service for managing loan repayment reminders
class ReminderService {
  static const String _remindersEnabledKey = 'reminders_enabled';
  static const String _reminderFrequencyKey = 'reminder_frequency';
  static const String _lastReminderCheckKey = 'last_reminder_check';

  Timer? _reminderTimer;
  final List<Function(List<LoanReminderItem>)> _reminderCallbacks = [];

  /// Check if reminders are enabled
  Future<bool> areRemindersEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_remindersEnabledKey) ?? true;
    } catch (e) {
      debugPrint('Error checking reminder settings: $e');
      return true;
    }
  }

  /// Enable or disable reminders
  Future<void> setRemindersEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_remindersEnabledKey, enabled);
      
      if (enabled) {
        startReminderService();
      } else {
        stopReminderService();
      }
    } catch (e) {
      debugPrint('Error setting reminder preference: $e');
    }
  }

  /// Get reminder frequency in hours
  Future<int> getReminderFrequency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_reminderFrequencyKey) ?? 24; // Default: daily
    } catch (e) {
      debugPrint('Error getting reminder frequency: $e');
      return 24;
    }
  }

  /// Set reminder frequency in hours
  Future<void> setReminderFrequency(int hours) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_reminderFrequencyKey, hours);
      
      // Restart the service with new frequency
      if (await areRemindersEnabled()) {
        startReminderService();
      }
    } catch (e) {
      debugPrint('Error setting reminder frequency: $e');
    }
  }

  /// Start the reminder service
  Future<void> startReminderService() async {
    stopReminderService(); // Stop existing timer
    
    final enabled = await areRemindersEnabled();
    if (!enabled) return;
    
    final frequency = await getReminderFrequency();
    
    _reminderTimer = Timer.periodic(
      Duration(hours: frequency),
      (_) => _checkForReminders(),
    );
    
    // Also check immediately
    _checkForReminders();
  }

  /// Stop the reminder service
  void stopReminderService() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
  }

  /// Add a callback for reminder notifications
  void addReminderCallback(Function(List<LoanReminderItem>) callback) {
    _reminderCallbacks.add(callback);
  }

  /// Remove a reminder callback
  void removeReminderCallback(Function(List<LoanReminderItem>) callback) {
    _reminderCallbacks.remove(callback);
  }

  /// Check for loans/debts that need reminders
  Future<void> _checkForReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_lastReminderCheckKey) ?? 0;
      final now = DateTime.now();
      
      // Only check once per hour to avoid spam
      if (now.millisecondsSinceEpoch - lastCheck < 3600000) {
        return;
      }
      
      await prefs.setInt(_lastReminderCheckKey, now.millisecondsSinceEpoch);
      
      // This would need to be connected to actual data repositories
      // For now, this is a placeholder for the reminder checking logic
      debugPrint('Checking for loan reminders at ${now.toString()}');
      
    } catch (e) {
      debugPrint('Error checking reminders: $e');
    }
  }

  /// Generate reminders for loans/debts
  List<LoanReminderItem> generateReminders({
    required List<LoanDebtItem> loans,
    required List<FriendRecord> friends,
  }) {
    final reminders = <LoanReminderItem>[];
    final now = DateTime.now();
    
    for (final loan in loans) {
      if (loan.status.toLowerCase() == 'paidoff') continue;
      
      final friend = friends.firstWhere(
        (f) => f.id == loan.associatedFriendId,
        orElse: () => FriendRecord(
          id: '',
          userId: '',
          friendName: 'Unknown Friend',
          friendPhoneNumber: null,
          notes: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      final reminderType = _getReminderType(loan, now);
      if (reminderType != null) {
        reminders.add(LoanReminderItem(
          loanId: loan.id,
          friendName: friend.friendName,
          friendPhone: friend.friendPhoneNumber,
          loanType: loan.type,
          amount: loan.outstandingAmount,
          dueDate: loan.dueDate,
          daysSinceCreated: now.difference(loan.dateInitiated).inDays,
          reminderType: reminderType,
          priority: _getReminderPriority(loan, now),
        ));
      }
    }
    
    // Sort by priority (high to low) and due date
    reminders.sort((a, b) {
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      
      return a.daysSinceCreated.compareTo(b.daysSinceCreated);
    });
    
    return reminders;
  }

  /// Get reminder type based on loan status and dates
  ReminderType? _getReminderType(LoanDebtItem loan, DateTime now) {
    if (loan.dueDate != null) {
      final daysUntilDue = loan.dueDate!.difference(now).inDays;
      
      if (daysUntilDue < 0) {
        return ReminderType.overdue;
      } else if (daysUntilDue <= 1) {
        return ReminderType.dueSoon;
      } else if (daysUntilDue <= 7) {
        return ReminderType.upcoming;
      }
    }
    
    // For loans without due dates, remind based on time since creation
    final daysSinceCreated = now.difference(loan.dateInitiated).inDays;
    
    if (daysSinceCreated >= 30) {
      return ReminderType.longOverdue;
    } else if (daysSinceCreated >= 14) {
      return ReminderType.followUp;
    }
    
    return null;
  }

  /// Get reminder priority
  ReminderPriority _getReminderPriority(LoanDebtItem loan, DateTime now) {
    if (loan.dueDate != null) {
      final daysUntilDue = loan.dueDate!.difference(now).inDays;
      
      if (daysUntilDue < 0) {
        return ReminderPriority.high;
      } else if (daysUntilDue <= 3) {
        return ReminderPriority.medium;
      }
    }
    
    // High priority for large amounts
    if (loan.outstandingAmount >= 1000) {
      return ReminderPriority.high;
    } else if (loan.outstandingAmount >= 500) {
      return ReminderPriority.medium;
    }
    
    return ReminderPriority.low;
  }

  /// Get reminder settings summary
  Future<Map<String, dynamic>> getReminderSettings() async {
    return {
      'enabled': await areRemindersEnabled(),
      'frequency': await getReminderFrequency(),
      'frequencyText': _getFrequencyText(await getReminderFrequency()),
    };
  }

  String _getFrequencyText(int hours) {
    if (hours == 1) return 'Every hour';
    if (hours == 6) return 'Every 6 hours';
    if (hours == 12) return 'Twice daily';
    if (hours == 24) return 'Daily';
    if (hours == 48) return 'Every 2 days';
    if (hours == 168) return 'Weekly';
    return 'Every $hours hours';
  }

  /// Dispose the service
  void dispose() {
    stopReminderService();
    _reminderCallbacks.clear();
  }
}

/// Data class for loan reminder items
class LoanReminderItem {
  final String loanId;
  final String friendName;
  final String? friendPhone;
  final String loanType;
  final double amount;
  final DateTime? dueDate;
  final int daysSinceCreated;
  final ReminderType reminderType;
  final ReminderPriority priority;

  const LoanReminderItem({
    required this.loanId,
    required this.friendName,
    this.friendPhone,
    required this.loanType,
    required this.amount,
    this.dueDate,
    required this.daysSinceCreated,
    required this.reminderType,
    required this.priority,
  });

  String get reminderMessage {
    switch (reminderType) {
      case ReminderType.overdue:
        return 'Loan from $friendName is overdue!';
      case ReminderType.dueSoon:
        return 'Loan from $friendName is due soon';
      case ReminderType.upcoming:
        return 'Loan from $friendName is due this week';
      case ReminderType.longOverdue:
        return 'Follow up on loan with $friendName (${daysSinceCreated} days ago)';
      case ReminderType.followUp:
        return 'Check in about loan with $friendName';
    }
  }

  String get priorityText {
    switch (priority) {
      case ReminderPriority.high:
        return 'High Priority';
      case ReminderPriority.medium:
        return 'Medium Priority';
      case ReminderPriority.low:
        return 'Low Priority';
    }
  }
}

enum ReminderType {
  overdue,
  dueSoon,
  upcoming,
  longOverdue,
  followUp,
}

enum ReminderPriority {
  high,
  medium,
  low,
}