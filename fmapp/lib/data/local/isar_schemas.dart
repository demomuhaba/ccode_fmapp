import 'package:isar/isar.dart';

part 'isar_schemas.g.dart';

@collection
class IsarUserProfile {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String userId;
  
  String? email;
  String? fullName;
  DateTime? createdAt;
  DateTime? updatedAt;
  
  // Sync status
  bool synced = false;
  DateTime? lastSyncAt;
}

@collection
class IsarSimCardRecord {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String recordId;
  
  late String userId;
  late String phoneNumber;
  String? simNickname;
  String? telecomProvider;
  String? officialRegisteredName;
  DateTime? dateAdded;
  DateTime? createdAt;
  DateTime? updatedAt;
  
  // Sync status
  bool synced = false;
  DateTime? lastSyncAt;
  bool pendingDelete = false;
}

@collection
class IsarFinancialAccountRecord {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String recordId;
  
  late String userId;
  late String accountName;
  late String accountIdentifier;
  late String accountType;
  late String linkedSimId;
  late double initialBalance;
  DateTime? dateAdded;
  DateTime? createdAt;
  DateTime? updatedAt;
  
  // Sync status
  bool synced = false;
  DateTime? lastSyncAt;
  bool pendingDelete = false;
}

@collection
class IsarTransactionRecord {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String recordId;
  
  late String userId;
  late String affectedAccountId;
  late DateTime transactionDate;
  late double amount;
  late String transactionType;
  String currency = 'ETB';
  late String descriptionNotes;
  String? payerSenderRaw;
  String? payeeReceiverRaw;
  String? referenceNumber;
  bool isInternalTransfer = false;
  String? counterpartyAccountId;
  String? receiptFileLink;
  String? ocrExtractedRawText;
  DateTime? createdAt;
  DateTime? updatedAt;
  
  // Sync status
  bool synced = false;
  DateTime? lastSyncAt;
  bool pendingDelete = false;
}

@collection
class IsarFriendRecord {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String recordId;
  
  late String userId;
  late String friendName;
  String? friendPhoneNumber;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;
  
  // Sync status
  bool synced = false;
  DateTime? lastSyncAt;
  bool pendingDelete = false;
}

@collection
class IsarLoanDebtItem {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String recordId;
  
  late String userId;
  late String associatedFriendId;
  late String type;
  late double initialAmount;
  late double outstandingAmount;
  String currency = 'ETB';
  late DateTime dateInitiated;
  DateTime? dueDate;
  late String description;
  late String status;
  late String initialTransactionMethod;
  DateTime? createdAt;
  DateTime? updatedAt;
  
  // Sync status
  bool synced = false;
  DateTime? lastSyncAt;
  bool pendingDelete = false;
}

@collection
class IsarLoanDebtPayment {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String recordId;
  
  late String parentLoanDebtId;
  late DateTime paymentDate;
  late double amountPaid;
  late String paidBy;
  String? notes;
  late String paymentTransactionMethod;
  DateTime? createdAt;
  DateTime? updatedAt;
  
  // Sync status
  bool synced = false;
  DateTime? lastSyncAt;
  bool pendingDelete = false;
}

@collection
class IsarSyncQueue {
  Id id = Isar.autoIncrement;
  
  late String tableName;
  late String recordId;
  late String operation; // 'CREATE', 'UPDATE', 'DELETE'
  late String jsonData;
  DateTime createdAt = DateTime.now();
  int retryCount = 0;
  String? errorMessage;
}