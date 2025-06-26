// Stub file for web compatibility - Isar not supported on web

// Empty stub classes for web compilation
class IsarUserProfileSchema {}
class IsarSimCardRecordSchema {}
class IsarFinancialAccountRecordSchema {}
class IsarTransactionRecordSchema {}
class IsarFriendRecordSchema {}
class IsarLoanDebtItemSchema {}
class IsarLoanDebtPaymentSchema {}
class IsarSyncQueueSchema {}

// Stub entities for web compatibility
class IsarUserProfile {
  late String userId;
  late String fullName;
  late String email;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool synced = false;
  bool pendingDelete = false;
}

class IsarSimCardRecord {
  late String recordId;
  late String userId;
  late String phoneNumber;
  late String simNickname;
  late String telecomProvider;
  late String officialRegisteredName;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool synced = false;
  bool pendingDelete = false;
}

class IsarFinancialAccountRecord {
  late String recordId;
  late String userId;
  late String accountName;
  late String accountIdentifier;
  late String accountType;
  late String linkedSimId;
  late double initialBalance;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool synced = false;
  bool pendingDelete = false;
}

class IsarTransactionRecord {
  late String recordId;
  late String userId;
  late String affectedAccountId;
  late String descriptionNotes;
  late double amount;
  late String transactionType;
  late DateTime transactionDate;
  bool isInternalTransfer = false;
  String? recipientAccountId;
  String? ocrImagePath;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool synced = false;
  bool pendingDelete = false;
}

class IsarFriendRecord {
  late String recordId;
  late String userId;
  late String friendName;
  late String phoneNumber;
  String? email;
  String? notes;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool synced = false;
  bool pendingDelete = false;
}

class IsarLoanDebtItem {
  late String recordId;
  late String userId;
  late String friendId;
  late String title;
  late String description;
  late double amount;
  late String type;
  late String status;
  late DateTime dueDate;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool synced = false;
  bool pendingDelete = false;
}

class IsarLoanDebtPayment {
  late String recordId;
  late String loanDebtId;
  late double amount;
  late DateTime paymentDate;
  String? notes;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool synced = false;
  bool pendingDelete = false;
}

class IsarSyncQueue {
  late String recordId;
  late String tableName;
  late String entityId;
  late String operation;
  late String data;
  late DateTime createdAt;
  bool synced = false;
}