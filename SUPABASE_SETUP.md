# Supabase Setup Guide for fmapp

This guide will help you connect your fmapp (Ethiopian Personal Finance & Loan Manager) to Supabase.

## ✅ Quick Setup (Already Configured!)

Your fmapp is **already connected** to a Supabase project! The configuration is complete:

- **Project ID**: nremzwdmnmjcllftnmwz
- **Region**: eu-central-1 (Europe Central)
- **Status**: Active and Healthy
- **Configuration**: Production-ready

## Step 1: ✅ Project Already Created

Your fmapp project is already connected to:
- **Project URL**: https://nremzwdmnmjcllftnmwz.supabase.co
- **Project Name**: amalnoha01@gmail.com's Project

## Step 2: ✅ Credentials Already Configured

The Flutter app is already configured with the correct credentials in `/lib/core/config/supabase_config.dart`:

```dart
static const String supabaseUrl = 'https://nremzwdmnmjcllftnmwz.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
static const bool isDevelopment = false; // Production mode
```

## Step 3: Set Up the Database Schema

**🚨 IMPORTANT: You need to set up the database schema first!**

1. Go to your Supabase dashboard: https://supabase.com/dashboard/project/nremzwdmnmjcllftnmwz
2. Navigate to **SQL Editor**
3. Click "New query"
4. Copy the entire contents of `/scripts/setup_database.sql` and paste it into the query editor
5. Click "Run" to execute the schema
6. Verify that all tables were created successfully in **Table Editor**

The setup script will create:
- 7 main tables (user_profiles, sim_card_records, etc.)
- Ethiopian-specific constraints and validations
- Row Level Security (RLS) policies
- Storage buckets for OCR documents
- Indexes for optimal performance

## Step 4: Configure Storage

The schema automatically creates the required storage buckets:
- `ocr-documents`: For storing OCR document images
- `profile-images`: For user profile pictures

Verify these buckets exist in **Storage** section of your dashboard.

## Step 6: Test the Connection

1. Run the Flutter app:
```bash
flutter run
```

2. Try creating a new account to test the authentication flow
3. Verify that user data appears in the `user_profiles` table

## Expected Database Tables

After running the schema, you should see these tables:

### Core Tables
- `user_profiles` - User account information
- `sim_card_records` - Ethiopian SIM card management
- `financial_account_records` - Bank accounts, mobile money, etc.
- `transaction_records` - All financial transactions
- `friend_records` - Friends for loan/debt tracking
- `loan_debt_items` - Loan and debt records
- `loan_debt_payments` - Payment history for loans/debts

### Features Enabled
- **Row Level Security (RLS)**: Users can only access their own data
- **Real-time subscriptions**: For live updates (optional)
- **Automatic triggers**: For updating loan statuses and timestamps
- **Ethiopian context**: Phone number validation, ETB currency support
- **OCR document storage**: Secure file uploads for financial documents

## Environment Variables (Optional)

For better security in production, consider using environment variables:

1. Create a `.env` file in the project root:
```bash
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

2. Add to `.gitignore`:
```
.env
.env.local
.env.production
```

3. Update the config to read from environment variables when available

## Troubleshooting

### Common Issues:

1. **Connection failed**: 
   - Verify URL and anon key are correct
   - Check internet connection
   - Ensure project is not paused (free tier limitation)

2. **RLS policy errors**:
   - Make sure user is authenticated
   - Verify RLS policies are correctly applied
   - Check that user_id matches auth.uid()

3. **Missing tables**:
   - Re-run the schema.sql file
   - Check for SQL errors in the query execution

4. **Storage upload fails**:
   - Verify storage buckets exist
   - Check storage policies are properly set
   - Ensure file size is within limits

### Getting Help

- Check Supabase documentation: [docs.supabase.com](https://docs.supabase.com)
- Join Supabase Discord community
- Review the app logs for specific error messages

## Production Considerations

1. **Database Backups**: Enable automatic backups in Supabase
2. **SSL**: Always use HTTPS in production
3. **Environment Separation**: Use separate projects for dev/staging/prod
4. **Monitoring**: Set up alerts for database usage and errors
5. **Performance**: Monitor query performance and add indexes as needed

## Ethiopian Banking Context

The database schema includes Ethiopian-specific features:

- **Phone Number Validation**: Ethiopian format (+251 or 0 followed by 9/7 and 8 digits)
- **Telecom Providers**: Ethio Telecom and Safaricom Ethiopia
- **Currency**: Ethiopian Birr (ETB) formatting
- **Banking**: Support for major Ethiopian banks and mobile money services
- **OCR**: Optimized for Ethiopian financial document recognition

Your fmapp is now ready to help Ethiopian users manage their multi-SIM finances!