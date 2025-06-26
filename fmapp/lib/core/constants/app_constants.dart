// Core application constants for fmapp
// Ethiopian Personal Finance & Loan Manager
// Includes Ethiopian-specific financial context

class AppConstants {
  // App Identity
  static const String appName = 'fmapp';
  static const String appTitle = 'Personal Finance Manager';
  static const String appVersion = '1.0.0';
  
  // Ethiopian Currency Context
  static const String defaultCurrency = 'ETB';
  static const String currencySymbol = 'Br';
  static const String currencyDisplayName = 'Ethiopian Birr';
  
  // Ethiopian Telecom Providers
  static const List<String> telecomProviders = [
    'Ethio Telecom',
    'Safaricom Ethiopia',
  ];
  
  // Financial Account Types
  static const String accountTypeBankAccount = 'Bank Account';
  static const String accountTypeMobileWallet = 'Mobile Wallet';
  static const String accountTypeOnlineMoney = 'Online Money';
  
  static const List<String> accountTypes = [
    accountTypeBankAccount,
    accountTypeMobileWallet,
    accountTypeOnlineMoney,
  ];
  
  // Transaction Types
  static const String transactionTypeCredit = 'Income/Credit';
  static const String transactionTypeDebit = 'Expense/Debit';
  
  static const List<String> transactionTypes = [
    transactionTypeCredit,
    transactionTypeDebit,
  ];
  
  // Loan/Debt Types
  static const String loanTypeLoanGiven = 'LoanGivenToFriend';
  static const String loanTypeDebtOwed = 'DebtOwedToFriend';
  
  static const List<String> loanDebtTypes = [
    loanTypeLoanGiven,
    loanTypeDebtOwed,
  ];
  
  // Loan/Debt Status
  static const String loanStatusActive = 'Active';
  static const String loanStatusPartiallyPaid = 'PartiallyPaid';
  static const String loanStatusPaidOff = 'PaidOff';
  
  static const List<String> loanStatuses = [
    loanStatusActive,
    loanStatusPartiallyPaid,
    loanStatusPaidOff,
  ];
  
  // Payment Types
  static const String paymentTypeUserToFriend = 'UserToFriend';
  static const String paymentTypeFriendToUser = 'FriendToUser';
  
  static const List<String> paymentTypes = [
    paymentTypeUserToFriend,
    paymentTypeFriendToUser,
  ];
  
  // Transaction Methods
  static const String transactionMethodCash = 'Cash';
  
  // Ethiopian Mobile Money Services
  static const List<String> mobileMoneyServices = [
    'Telebirr',
    'M-Pesa',
    'HelloCash',
    'CBE Birr',
  ];
  
  // Ethiopian Banks (Common ones for OCR recognition)
  static const List<String> ethiopianBanks = [
    'Commercial Bank of Ethiopia (CBE)',
    'Dashen Bank',
    'Bank of Abyssinia',
    'Awash Bank',
    'United Bank',
    'Nib International Bank',
    'Cooperative Bank of Oromia',
    'Lion International Bank',
    'Oromia International Bank',
    'Wegagen Bank',
    'Zemen Bank',
    'Bunna International Bank',
    'Berhan International Bank',
    'Abay Bank',
    'Addis International Bank',
    'Debub Global Bank',
    'Enat Bank',
    'Gadaa Bank',
    'Goh Betoch Bank',
    'Hijra Bank',
    'Shabelle Bank',
    'Siinqee Bank',
    'Tsehay Bank',
    'ZamZam Bank',
  ];
  
  // OCR Configuration
  static const int ocrMaxRetries = 3;
  static const int ocrTimeoutSeconds = 30;
  static const double ocrConfidenceThreshold = 0.7;
  
  // File Storage
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png'];
  static const List<String> supportedDocumentFormats = ['pdf'];
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB in bytes
  
  // Date Formats (Ethiopian Calendar Context)
  static const String dateFormatDisplay = 'MMM dd, yyyy';
  static const String dateFormatStorage = 'yyyy-MM-dd';
  static const String dateTimeFormatDisplay = 'MMM dd, yyyy HH:mm';
  static const String dateTimeFormatStorage = 'yyyy-MM-dd HH:mm:ss';
  
  // Ethiopian Number Formatting
  static const String numberFormatPattern = '#,##0.00';
  static const String currencyFormatPattern = 'Br #,##0.00';
  
  // Validation Constants
  static const int phoneNumberMinLength = 10;
  static const int phoneNumberMaxLength = 15;
  static const double minTransactionAmount = 0.01;
  static const double maxTransactionAmount = 999999999.99;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  
  // Performance Constants
  static const int transactionHistoryPageSize = 50;
  static const int dashboardRecentTransactions = 5;
  static const Duration cacheExpiry = Duration(hours: 1);
  
  // Error Messages (Ethiopian Context)
  static const String errorInvalidPhoneNumber = 'Please enter a valid Ethiopian phone number';
  static const String errorInvalidAmount = 'Please enter a valid amount in ETB';
  static const String errorInsufficientBalance = 'Insufficient balance for this transaction';
  static const String errorNetworkConnection = 'Please check your internet connection';
  static const String errorOcrProcessing = 'Unable to process the document. Please try again or enter manually';
  static const String errorFileSize = 'File size must be less than 10MB';
  static const String errorUnsupportedFormat = 'Unsupported file format. Please use JPG, PNG, or PDF';
  
  // Success Messages
  static const String successTransactionAdded = 'Transaction added successfully';
  static const String successLoanCreated = 'Loan/debt record created successfully';
  static const String successPaymentRecorded = 'Payment recorded successfully';
  static const String successAccountCreated = 'Account created successfully';
  static const String successSimAdded = 'SIM card added successfully';
  
  // Ethiopian Locale Settings
  static const String localeLanguageCode = 'en';
  static const String localeCountryCode = 'ET';
  
  // Database Constants
  static const String tablePrefixUser = 'user_';
  static const int dbConnectionTimeout = 30;
  static const int dbQueryTimeout = 15;
  
  // OCR Text Patterns for Ethiopian Financial Services
  static const List<String> ocrAmountPatterns = [
    r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*ETB',
    r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*Br',
    r'ETB\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)',
    r'Br\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)',
  ];
  
  static const List<String> ocrDatePatterns = [
    r'(\d{1,2}/\d{1,2}/\d{4})',
    r'(\d{1,2}-\d{1,2}-\d{4})',
    r'(\d{4}-\d{1,2}-\d{1,2})',
  ];
  
  static const List<String> ocrReferencePatterns = [
    r'(?:Ref|Reference|TxnRef|Transaction)\s*:?\s*([A-Z0-9]+)',
    r'(?:ID|TID|TransactionID)\s*:?\s*([A-Z0-9]+)',
  ];
}