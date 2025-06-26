// Supabase configuration for fmapp
// Contains environment-specific settings for database connection

class SupabaseConfig {
  // Production Supabase Configuration
  // Using provided Supabase project credentials
  static const String supabaseUrl = 'https://nremzwdmnmjcllftnmwz.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5yZW16d2Rtbm1qY2xsZnRubXd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk2ODg3NzUsImV4cCI6MjA2NTI2NDc3NX0.ysPvDLmblhqgZHVkKSRXAsQj3F5uXspjLQpj9yccP7g';
  
  // Development/Local Configuration
  static const String devSupabaseUrl = 'http://localhost:54321';
  static const String devSupabaseAnonKey = 'your-dev-anon-key-here';
  
  // Environment Detection
  static const bool isDevelopment = false; // Set to false for production
  
  // Get current environment URLs
  static String get currentUrl => isDevelopment ? devSupabaseUrl : supabaseUrl;
  static String get currentAnonKey => isDevelopment ? devSupabaseAnonKey : supabaseAnonKey;
  
  // Database Table Names
  static const String userProfilesTable = 'user_profiles';
  static const String simCardRecordsTable = 'sim_card_records';
  static const String financialAccountRecordsTable = 'financial_account_records';
  static const String transactionRecordsTable = 'transaction_records';
  static const String friendRecordsTable = 'friend_records';
  static const String loanDebtItemsTable = 'loan_debt_items';
  static const String loanDebtPaymentsTable = 'loan_debt_payments';
  
  // Storage Buckets
  static const String ocrDocumentsBucket = 'ocr-documents';
  static const String profileImagesBucket = 'profile-images';
  
  // RLS Policies
  static const bool enableRowLevelSecurity = true;
  
  // Connection Settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration queryTimeout = Duration(seconds: 15);
  static const int maxRetries = 3;
  
  // Real-time Settings
  static const bool enableRealtime = true;
  static const List<String> realtimeTables = [
    transactionRecordsTable,
    financialAccountRecordsTable,
    loanDebtItemsTable,
  ];
}