-- Ethiopian Personal Finance & Loan Manager (fmapp) Database Schema
-- Supabase PostgreSQL Database Setup

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- Create custom types
CREATE TYPE transaction_type AS ENUM ('Income/Credit', 'Expense/Debit');
CREATE TYPE loan_debt_type AS ENUM ('LoanGivenToFriend', 'DebtOwedToFriend');
CREATE TYPE loan_debt_status AS ENUM ('Active', 'PartiallyPaid', 'PaidOff');
CREATE TYPE payment_direction AS ENUM ('UserToFriend', 'FriendToUser');

-- User Profiles Table
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    phone_number TEXT,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- SIM Card Records Table
CREATE TABLE sim_card_records (
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
CREATE TABLE financial_account_records (
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
CREATE TABLE transaction_records (
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
CREATE TABLE friend_records (
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
CREATE TABLE loan_debt_items (
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
CREATE TABLE loan_debt_payments (
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

-- Create indexes for better performance
CREATE INDEX idx_sim_card_records_user_id ON sim_card_records(user_id);
CREATE INDEX idx_sim_card_records_phone_number ON sim_card_records(phone_number);
CREATE INDEX idx_financial_account_records_user_id ON financial_account_records(user_id);
CREATE INDEX idx_financial_account_records_sim_id ON financial_account_records(linked_sim_id);
CREATE INDEX idx_transaction_records_user_id ON transaction_records(user_id);
CREATE INDEX idx_transaction_records_account_id ON transaction_records(affected_account_id);
CREATE INDEX idx_transaction_records_date ON transaction_records(transaction_date);
CREATE INDEX idx_friend_records_user_id ON friend_records(user_id);
CREATE INDEX idx_loan_debt_items_user_id ON loan_debt_items(user_id);
CREATE INDEX idx_loan_debt_items_friend_id ON loan_debt_items(associated_friend_id);
CREATE INDEX idx_loan_debt_items_status ON loan_debt_items(status);
CREATE INDEX idx_loan_debt_items_due_date ON loan_debt_items(due_date);
CREATE INDEX idx_loan_debt_payments_user_id ON loan_debt_payments(user_id);
CREATE INDEX idx_loan_debt_payments_loan_debt_id ON loan_debt_payments(parent_loan_debt_id);

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('ocr-documents', 'ocr-documents', false);
INSERT INTO storage.buckets (id, name, public) VALUES ('profile-images', 'profile-images', false);

-- Enable Row Level Security (RLS)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE sim_card_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_account_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_debt_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_debt_payments ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies

-- User Profiles - Users can only access their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- SIM Card Records - Users can only access their own SIM cards
CREATE POLICY "Users can view own SIM cards" ON sim_card_records
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own SIM cards" ON sim_card_records
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own SIM cards" ON sim_card_records
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own SIM cards" ON sim_card_records
    FOR DELETE USING (auth.uid() = user_id);

-- Financial Account Records - Users can only access their own accounts
CREATE POLICY "Users can view own accounts" ON financial_account_records
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own accounts" ON financial_account_records
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own accounts" ON financial_account_records
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own accounts" ON financial_account_records
    FOR DELETE USING (auth.uid() = user_id);

-- Transaction Records - Users can only access their own transactions
CREATE POLICY "Users can view own transactions" ON transaction_records
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions" ON transaction_records
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own transactions" ON transaction_records
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own transactions" ON transaction_records
    FOR DELETE USING (auth.uid() = user_id);

-- Friend Records - Users can only access their own friends
CREATE POLICY "Users can view own friends" ON friend_records
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own friends" ON friend_records
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own friends" ON friend_records
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own friends" ON friend_records
    FOR DELETE USING (auth.uid() = user_id);

-- Loan Debt Items - Users can only access their own loan/debt records
CREATE POLICY "Users can view own loan/debt items" ON loan_debt_items
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own loan/debt items" ON loan_debt_items
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own loan/debt items" ON loan_debt_items
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own loan/debt items" ON loan_debt_items
    FOR DELETE USING (auth.uid() = user_id);

-- Loan Debt Payments - Users can only access their own payments
CREATE POLICY "Users can view own payments" ON loan_debt_payments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own payments" ON loan_debt_payments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own payments" ON loan_debt_payments
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own payments" ON loan_debt_payments
    FOR DELETE USING (auth.uid() = user_id);

-- Storage Policies
CREATE POLICY "Users can upload own documents" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'ocr-documents' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view own documents" ON storage.objects
    FOR SELECT USING (bucket_id = 'ocr-documents' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own documents" ON storage.objects
    FOR DELETE USING (bucket_id = 'ocr-documents' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can upload own profile images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'profile-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view own profile images" ON storage.objects
    FOR SELECT USING (bucket_id = 'profile-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own profile images" ON storage.objects
    FOR DELETE USING (bucket_id = 'profile-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Create functions for automatic balance calculation
CREATE OR REPLACE FUNCTION calculate_account_balance(account_id UUID)
RETURNS DECIMAL(15,2) AS $$
DECLARE
    initial_balance DECIMAL(15,2);
    transactions_sum DECIMAL(15,2);
BEGIN
    -- Get initial balance
    SELECT initial_balance INTO initial_balance
    FROM financial_account_records
    WHERE id = account_id;
    
    -- Calculate sum of transactions
    SELECT COALESCE(SUM(
        CASE 
            WHEN transaction_type = 'Income/Credit' THEN amount
            WHEN transaction_type = 'Expense/Debit' THEN -amount
            ELSE 0
        END
    ), 0) INTO transactions_sum
    FROM transaction_records
    WHERE affected_account_id = account_id;
    
    RETURN COALESCE(initial_balance, 0) + COALESCE(transactions_sum, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to update loan debt status and outstanding amount
CREATE OR REPLACE FUNCTION update_loan_debt_status()
RETURNS TRIGGER AS $$
DECLARE
    total_payments DECIMAL(15,2);
    initial_amount DECIMAL(15,2);
    new_outstanding DECIMAL(15,2);
    new_status loan_debt_status;
BEGIN
    -- Get initial amount and calculate total payments
    SELECT ld.initial_amount INTO initial_amount
    FROM loan_debt_items ld
    WHERE ld.id = NEW.parent_loan_debt_id;
    
    SELECT COALESCE(SUM(amount), 0) INTO total_payments
    FROM loan_debt_payments
    WHERE parent_loan_debt_id = NEW.parent_loan_debt_id;
    
    -- Calculate new outstanding amount
    new_outstanding := initial_amount - total_payments;
    
    -- Determine new status
    IF new_outstanding <= 0 THEN
        new_status := 'PaidOff';
        new_outstanding := 0;
    ELSIF total_payments > 0 THEN
        new_status := 'PartiallyPaid';
    ELSE
        new_status := 'Active';
    END IF;
    
    -- Update loan debt item
    UPDATE loan_debt_items
    SET 
        outstanding_amount = new_outstanding,
        status = new_status,
        updated_at = NOW()
    WHERE id = NEW.parent_loan_debt_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for loan debt status updates
CREATE TRIGGER trigger_update_loan_debt_status
    AFTER INSERT OR UPDATE OR DELETE ON loan_debt_payments
    FOR EACH ROW
    EXECUTE FUNCTION update_loan_debt_status();

-- Create function to automatically update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at columns
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sim_card_records_updated_at
    BEFORE UPDATE ON sim_card_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_financial_account_records_updated_at
    BEFORE UPDATE ON financial_account_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transaction_records_updated_at
    BEFORE UPDATE ON transaction_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_friend_records_updated_at
    BEFORE UPDATE ON friend_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_loan_debt_items_updated_at
    BEFORE UPDATE ON loan_debt_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_loan_debt_payments_updated_at
    BEFORE UPDATE ON loan_debt_payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create views for dashboard analytics
CREATE VIEW dashboard_summary AS
SELECT 
    u.id as user_id,
    COUNT(DISTINCT s.id) as total_sim_cards,
    COUNT(DISTINCT a.id) as total_accounts,
    COUNT(DISTINCT t.id) as total_transactions,
    COUNT(DISTINCT f.id) as total_friends,
    COUNT(DISTINCT ld.id) as total_loan_debts,
    COALESCE(SUM(
        CASE 
            WHEN t.transaction_type = 'Income/Credit' THEN t.amount
            WHEN t.transaction_type = 'Expense/Debit' THEN -t.amount
            ELSE 0
        END
    ), 0) as total_transaction_flow
FROM user_profiles u
LEFT JOIN sim_card_records s ON u.id = s.user_id
LEFT JOIN financial_account_records a ON u.id = a.user_id
LEFT JOIN transaction_records t ON u.id = t.user_id
LEFT JOIN friend_records f ON u.id = f.user_id
LEFT JOIN loan_debt_items ld ON u.id = ld.user_id
GROUP BY u.id;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;