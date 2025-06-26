-- fmapp Database Setup Script
-- Copy and run this in your Supabase SQL Editor
-- This script sets up the complete database schema for the Ethiopian Personal Finance & Loan Manager

-- Step 1: Enable Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Step 2: Create Enums
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'transaction_type') THEN
        CREATE TYPE transaction_type AS ENUM ('Income/Credit', 'Expense/Debit');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'loan_debt_type') THEN
        CREATE TYPE loan_debt_type AS ENUM ('LoanGivenToFriend', 'DebtOwedToFriend');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'loan_debt_status') THEN
        CREATE TYPE loan_debt_status AS ENUM ('Active', 'PartiallyPaid', 'PaidOff');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_direction') THEN
        CREATE TYPE payment_direction AS ENUM ('UserToFriend', 'FriendToUser');
    END IF;
END $$;

-- Step 3: Create Tables

-- User Profiles Table
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    phone_number TEXT,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- SIM Card Records Table
CREATE TABLE IF NOT EXISTS sim_card_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    sim_nickname TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    telecom_provider TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_phone_number CHECK (phone_number ~ '^(\+251|0)[97]\d{8}$'),
    CONSTRAINT valid_telecom_provider CHECK (telecom_provider IN ('Ethio Telecom', 'Safaricom Ethiopia'))
);

-- Financial Account Records Table
CREATE TABLE IF NOT EXISTS financial_account_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    linked_sim_id UUID NOT NULL REFERENCES sim_card_records(id) ON DELETE CASCADE,
    account_name TEXT NOT NULL,
    account_number TEXT,
    account_type TEXT NOT NULL,
    initial_balance DECIMAL(15,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_account_type CHECK (account_type IN ('Bank Account', 'Mobile Wallet', 'Online Money', 'Mobile Money', 'Digital Wallet', 'Telecom Account')),
    CONSTRAINT positive_initial_balance CHECK (initial_balance >= 0)
);

-- Transaction Records Table
CREATE TABLE IF NOT EXISTS transaction_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    affected_account_id UUID NOT NULL REFERENCES financial_account_records(id) ON DELETE CASCADE,
    transaction_type transaction_type NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    description_notes TEXT NOT NULL,
    payer_payee_info TEXT,
    reference_number TEXT,
    ocr_confidence_score DECIMAL(3,2),
    ocr_raw_text TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT positive_amount CHECK (amount > 0),
    CONSTRAINT valid_confidence_score CHECK (ocr_confidence_score IS NULL OR (ocr_confidence_score >= 0 AND ocr_confidence_score <= 1))
);

-- Friend Records Table
CREATE TABLE IF NOT EXISTS friend_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    friend_name TEXT NOT NULL,
    friend_phone_number TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_friend_phone CHECK (friend_phone_number IS NULL OR friend_phone_number ~ '^(\+251|0)[97]\d{8}$'),
    CONSTRAINT non_empty_friend_name CHECK (LENGTH(TRIM(friend_name)) > 0)
);

-- Loan Debt Items Table
CREATE TABLE IF NOT EXISTS loan_debt_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    associated_friend_id UUID NOT NULL REFERENCES friend_records(id) ON DELETE CASCADE,
    type loan_debt_type NOT NULL,
    initial_amount DECIMAL(15,2) NOT NULL,
    outstanding_amount DECIMAL(15,2) NOT NULL,
    date_initiated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    due_date TIMESTAMPTZ,
    description TEXT NOT NULL,
    status loan_debt_status DEFAULT 'Active',
    initial_transaction_method TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT positive_amounts CHECK (initial_amount > 0 AND outstanding_amount >= 0),
    CONSTRAINT outstanding_not_exceed_initial CHECK (outstanding_amount <= initial_amount),
    CONSTRAINT valid_due_date CHECK (due_date IS NULL OR due_date > date_initiated),
    CONSTRAINT non_empty_description CHECK (LENGTH(TRIM(description)) > 0)
);

-- Loan Debt Payments Table
CREATE TABLE IF NOT EXISTS loan_debt_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    parent_loan_debt_id UUID NOT NULL REFERENCES loan_debt_items(id) ON DELETE CASCADE,
    amount DECIMAL(15,2) NOT NULL,
    payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    paid_by payment_direction NOT NULL,
    payment_transaction_method TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT positive_payment_amount CHECK (amount > 0)
);

-- Step 4: Create Indexes
CREATE INDEX IF NOT EXISTS idx_sim_card_records_user_id ON sim_card_records(user_id);
CREATE INDEX IF NOT EXISTS idx_financial_account_records_user_id ON financial_account_records(user_id);
CREATE INDEX IF NOT EXISTS idx_transaction_records_user_id ON transaction_records(user_id);
CREATE INDEX IF NOT EXISTS idx_transaction_records_date ON transaction_records(transaction_date);
CREATE INDEX IF NOT EXISTS idx_friend_records_user_id ON friend_records(user_id);
CREATE INDEX IF NOT EXISTS idx_loan_debt_items_user_id ON loan_debt_items(user_id);
CREATE INDEX IF NOT EXISTS idx_loan_debt_payments_user_id ON loan_debt_payments(user_id);

-- Step 5: Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE sim_card_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_account_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_debt_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_debt_payments ENABLE ROW LEVEL SECURITY;

-- Step 6: Create RLS Policies (only if they don't exist)
DO $$
BEGIN
    -- User Profiles Policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_profiles' AND policyname = 'Users can view own profile') THEN
        CREATE POLICY "Users can view own profile" ON user_profiles FOR SELECT USING (auth.uid() = id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_profiles' AND policyname = 'Users can update own profile') THEN
        CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (auth.uid() = id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_profiles' AND policyname = 'Users can insert own profile') THEN
        CREATE POLICY "Users can insert own profile" ON user_profiles FOR INSERT WITH CHECK (auth.uid() = id);
    END IF;

    -- SIM Card Records Policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sim_card_records' AND policyname = 'Users can manage own SIM cards') THEN
        CREATE POLICY "Users can manage own SIM cards" ON sim_card_records FOR ALL USING (auth.uid() = user_id);
    END IF;

    -- Financial Account Records Policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'financial_account_records' AND policyname = 'Users can manage own accounts') THEN
        CREATE POLICY "Users can manage own accounts" ON financial_account_records FOR ALL USING (auth.uid() = user_id);
    END IF;

    -- Transaction Records Policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'transaction_records' AND policyname = 'Users can manage own transactions') THEN
        CREATE POLICY "Users can manage own transactions" ON transaction_records FOR ALL USING (auth.uid() = user_id);
    END IF;

    -- Friend Records Policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'friend_records' AND policyname = 'Users can manage own friends') THEN
        CREATE POLICY "Users can manage own friends" ON friend_records FOR ALL USING (auth.uid() = user_id);
    END IF;

    -- Loan Debt Items Policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'loan_debt_items' AND policyname = 'Users can manage own loan/debt items') THEN
        CREATE POLICY "Users can manage own loan/debt items" ON loan_debt_items FOR ALL USING (auth.uid() = user_id);
    END IF;

    -- Loan Debt Payments Policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'loan_debt_payments' AND policyname = 'Users can manage own payments') THEN
        CREATE POLICY "Users can manage own payments" ON loan_debt_payments FOR ALL USING (auth.uid() = user_id);
    END IF;
END $$;

-- Step 7: Create Storage Buckets
INSERT INTO storage.buckets (id, name, public) 
VALUES ('ocr-documents', 'ocr-documents', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('profile-images', 'profile-images', false)
ON CONFLICT (id) DO NOTHING;

-- Step 8: Create Storage Policies
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'Users can upload own documents') THEN
        CREATE POLICY "Users can upload own documents" ON storage.objects
            FOR INSERT WITH CHECK (bucket_id = 'ocr-documents' AND auth.uid()::text = (storage.foldername(name))[1]);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'Users can view own documents') THEN
        CREATE POLICY "Users can view own documents" ON storage.objects
            FOR SELECT USING (bucket_id = 'ocr-documents' AND auth.uid()::text = (storage.foldername(name))[1]);
    END IF;
END $$;

-- Verification Query
SELECT 'Setup completed successfully! Tables created:' as status;
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('user_profiles', 'sim_card_records', 'financial_account_records', 'transaction_records', 'friend_records', 'loan_debt_items', 'loan_debt_payments')
ORDER BY table_name;