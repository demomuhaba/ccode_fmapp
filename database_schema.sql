-- fmapp Database Schema
-- Complete database schema for Personal Multi-SIM Finance & Loan Manager
-- Designed for Supabase with Row Level Security (RLS)
-- ETB Currency Focus for Ethiopian Users

-- Enable UUID extension for primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==================================================
-- 1. USER PROFILES TABLE
-- ==================================================
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    full_name TEXT,
    preferences JSONB DEFAULT '{}'::jsonb
);

-- RLS for user_profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON user_profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- ==================================================
-- 2. SIM CARD RECORDS TABLE
-- ==================================================
CREATE TABLE sim_card_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    phone_number TEXT NOT NULL,
    sim_nickname TEXT NOT NULL,
    telecom_provider TEXT NOT NULL,
    official_registered_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure phone number is unique per user
    CONSTRAINT unique_phone_per_user UNIQUE (user_id, phone_number)
);

-- RLS for sim_card_records
ALTER TABLE sim_card_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own SIM cards" ON sim_card_records FOR ALL USING (auth.uid() = user_id);

-- Index for performance
CREATE INDEX idx_sim_card_records_user_id ON sim_card_records(user_id);

-- ==================================================
-- 3. FINANCIAL ACCOUNT RECORDS TABLE
-- ==================================================
CREATE TABLE financial_account_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    account_name TEXT NOT NULL,
    account_identifier TEXT NOT NULL,
    account_type TEXT NOT NULL CHECK (account_type IN ('Bank Account', 'Mobile Wallet', 'Online Money')),
    linked_sim_id UUID NOT NULL REFERENCES sim_card_records(id) ON DELETE RESTRICT,
    initial_balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    date_added TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure account identifier is unique per user
    CONSTRAINT unique_account_per_user UNIQUE (user_id, account_identifier)
);

-- RLS for financial_account_records
ALTER TABLE financial_account_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own financial accounts" ON financial_account_records FOR ALL USING (auth.uid() = user_id);

-- Indexes for performance
CREATE INDEX idx_financial_account_records_user_id ON financial_account_records(user_id);
CREATE INDEX idx_financial_account_records_linked_sim_id ON financial_account_records(linked_sim_id);

-- ==================================================
-- 4. TRANSACTION RECORDS TABLE
-- ==================================================
CREATE TABLE transaction_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    affected_account_id UUID NOT NULL REFERENCES financial_account_records(id) ON DELETE RESTRICT,
    transaction_date TIMESTAMP WITH TIME ZONE NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('Income/Credit', 'Expense/Debit')),
    currency TEXT NOT NULL DEFAULT 'ETB',
    description_notes TEXT,
    payer_sender_raw TEXT,
    payee_receiver_raw TEXT,
    reference_number TEXT,
    is_internal_transfer BOOLEAN DEFAULT FALSE,
    counterparty_account_id UUID REFERENCES financial_account_records(id),
    receipt_file_link TEXT,
    ocr_extracted_raw_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for transaction_records
ALTER TABLE transaction_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own transactions" ON transaction_records FOR ALL USING (auth.uid() = user_id);

-- Indexes for performance
CREATE INDEX idx_transaction_records_user_id ON transaction_records(user_id);
CREATE INDEX idx_transaction_records_affected_account_id ON transaction_records(affected_account_id);
CREATE INDEX idx_transaction_records_date ON transaction_records(transaction_date DESC);
CREATE INDEX idx_transaction_records_internal_transfer ON transaction_records(is_internal_transfer) WHERE is_internal_transfer = TRUE;

-- ==================================================
-- 5. FRIEND RECORDS TABLE
-- ==================================================
CREATE TABLE friend_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    friend_name TEXT NOT NULL,
    friend_phone_number TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for friend_records
ALTER TABLE friend_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own friends" ON friend_records FOR ALL USING (auth.uid() = user_id);

-- Index for performance
CREATE INDEX idx_friend_records_user_id ON friend_records(user_id);

-- ==================================================
-- 6. LOAN DEBT ITEMS TABLE
-- ==================================================
CREATE TABLE loan_debt_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    associated_friend_id UUID NOT NULL REFERENCES friend_records(id) ON DELETE RESTRICT,
    type TEXT NOT NULL CHECK (type IN ('LoanGivenToFriend', 'DebtOwedToFriend')),
    initial_amount DECIMAL(15,2) NOT NULL,
    outstanding_amount DECIMAL(15,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'ETB',
    date_initiated DATE NOT NULL,
    due_date DATE,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'PartiallyPaid', 'PaidOff')),
    initial_transaction_method TEXT NOT NULL, -- 'Cash' or UUID of financial account
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for loan_debt_items
ALTER TABLE loan_debt_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own loans/debts" ON loan_debt_items FOR ALL USING (auth.uid() = user_id);

-- Indexes for performance
CREATE INDEX idx_loan_debt_items_user_id ON loan_debt_items(user_id);
CREATE INDEX idx_loan_debt_items_friend_id ON loan_debt_items(associated_friend_id);
CREATE INDEX idx_loan_debt_items_status ON loan_debt_items(status);
CREATE INDEX idx_loan_debt_items_due_date ON loan_debt_items(due_date) WHERE due_date IS NOT NULL;

-- ==================================================
-- 7. LOAN DEBT PAYMENTS TABLE
-- ==================================================
CREATE TABLE loan_debt_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_loan_debt_id UUID NOT NULL REFERENCES loan_debt_items(id) ON DELETE CASCADE,
    payment_date DATE NOT NULL,
    amount_paid DECIMAL(15,2) NOT NULL,
    paid_by TEXT NOT NULL CHECK (paid_by IN ('UserToFriend', 'FriendToUser')),
    notes TEXT,
    payment_transaction_method TEXT NOT NULL, -- 'Cash' or UUID of financial account
    created_at TIMESTAMP WITH TIME ZE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for loan_debt_payments
ALTER TABLE loan_debt_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own loan/debt payments" ON loan_debt_payments 
FOR ALL USING (
    auth.uid() = (
        SELECT user_id FROM loan_debt_items WHERE id = parent_loan_debt_id
    )
);

-- Indexes for performance
CREATE INDEX idx_loan_debt_payments_parent_id ON loan_debt_payments(parent_loan_debt_id);
CREATE INDEX idx_loan_debt_payments_date ON loan_debt_payments(payment_date DESC);

-- ==================================================
-- FUNCTIONS FOR BUSINESS LOGIC
-- ==================================================

-- Function to calculate current balance for a financial account
CREATE OR REPLACE FUNCTION calculate_current_balance(account_id UUID)
RETURNS DECIMAL(15,2) AS $$
DECLARE
    initial_bal DECIMAL(15,2);
    transactions_sum DECIMAL(15,2);
    current_bal DECIMAL(15,2);
BEGIN
    -- Get initial balance
    SELECT initial_balance INTO initial_bal
    FROM financial_account_records
    WHERE id = account_id;
    
    -- Calculate sum of transactions (Income/Credit as positive, Expense/Debit as negative)
    SELECT COALESCE(
        SUM(CASE 
            WHEN transaction_type = 'Income/Credit' THEN amount
            WHEN transaction_type = 'Expense/Debit' THEN -amount
            ELSE 0
        END), 0
    ) INTO transactions_sum
    FROM transaction_records
    WHERE affected_account_id = account_id;
    
    current_bal := initial_bal + transactions_sum;
    
    RETURN current_bal;
END;
$$ LANGUAGE plpgsql;

-- Function to update outstanding amount for loan/debt items
CREATE OR REPLACE FUNCTION update_outstanding_amount(loan_debt_id UUID)
RETURNS DECIMAL(15,2) AS $$
DECLARE
    initial_amt DECIMAL(15,2);
    payments_sum DECIMAL(15,2);
    outstanding_amt DECIMAL(15,2);
    loan_type TEXT;
BEGIN
    -- Get initial amount and type
    SELECT initial_amount, type INTO initial_amt, loan_type
    FROM loan_debt_items
    WHERE id = loan_debt_id;
    
    -- Calculate sum of payments
    SELECT COALESCE(SUM(amount_paid), 0) INTO payments_sum
    FROM loan_debt_payments
    WHERE parent_loan_debt_id = loan_debt_id;
    
    outstanding_amt := initial_amt - payments_sum;
    
    -- Update the outstanding amount in the table
    UPDATE loan_debt_items
    SET outstanding_amount = outstanding_amt,
        status = CASE
            WHEN outstanding_amt <= 0 THEN 'PaidOff'
            WHEN outstanding_amt < initial_amt THEN 'PartiallyPaid'
            ELSE 'Active'
        END,
        updated_at = NOW()
    WHERE id = loan_debt_id;
    
    RETURN outstanding_amt;
END;
$$ LANGUAGE plpgsql;

-- ==================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ==================================================

-- Trigger to update outstanding amount when payments are added/modified
CREATE OR REPLACE FUNCTION trigger_update_outstanding_amount()
RETURNS TRIGGER AS $$
BEGIN
    -- Update outstanding amount for the related loan/debt item
    PERFORM update_outstanding_amount(COALESCE(NEW.parent_loan_debt_id, OLD.parent_loan_debt_id));
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_outstanding_amount_trigger
AFTER INSERT OR UPDATE OR DELETE ON loan_debt_payments
FOR EACH ROW EXECUTE FUNCTION trigger_update_outstanding_amount();

-- Trigger to update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to all tables
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_sim_card_records_updated_at BEFORE UPDATE ON sim_card_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_financial_account_records_updated_at BEFORE UPDATE ON financial_account_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transaction_records_updated_at BEFORE UPDATE ON transaction_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_friend_records_updated_at BEFORE UPDATE ON friend_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_loan_debt_items_updated_at BEFORE UPDATE ON loan_debt_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_loan_debt_payments_updated_at BEFORE UPDATE ON loan_debt_payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==================================================
-- VIEWS FOR COMMON QUERIES
-- ==================================================

-- View for account balances with calculated current balance
CREATE VIEW account_balances AS
SELECT 
    far.id,
    far.user_id,
    far.account_name,
    far.account_type,
    far.initial_balance,
    calculate_current_balance(far.id) AS current_balance,
    scr.sim_nickname,
    scr.phone_number
FROM financial_account_records far
JOIN sim_card_records scr ON far.linked_sim_id = scr.id;

-- View for SIM total balances
CREATE VIEW sim_total_balances AS
SELECT 
    scr.id AS sim_id,
    scr.user_id,
    scr.phone_number,
    scr.sim_nickname,
    COALESCE(SUM(calculate_current_balance(far.id)), 0) AS total_balance
FROM sim_card_records scr
LEFT JOIN financial_account_records far ON scr.id = far.linked_sim_id
GROUP BY scr.id, scr.user_id, scr.phone_number, scr.sim_nickname;

-- View for active loans and debts with outstanding amounts
CREATE VIEW active_loans_debts AS
SELECT 
    ldi.*,
    fr.friend_name,
    fr.friend_phone_number
FROM loan_debt_items ldi
JOIN friend_records fr ON ldi.associated_friend_id = fr.id
WHERE ldi.status IN ('Active', 'PartiallyPaid');

-- ==================================================
-- SAMPLE DATA FOR TESTING (OPTIONAL)
-- ==================================================

-- This section would contain sample data for testing
-- Commented out for production deployment

/*
-- Sample user (would be created through auth)
INSERT INTO user_profiles (id, email, full_name) VALUES 
('00000000-0000-0000-0000-000000000001', 'test@example.com', 'Test User');

-- Sample SIM cards
INSERT INTO sim_card_records (user_id, phone_number, sim_nickname, telecom_provider) VALUES
('00000000-0000-0000-0000-000000000001', '+251911123456', 'Main Phone', 'Ethio Telecom'),
('00000000-0000-0000-0000-000000000001', '+251922654321', 'Business Phone', 'Safaricom Ethiopia');
*/