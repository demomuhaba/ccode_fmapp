-- SQL functions for transaction locking and balance validation
-- These should be executed in Supabase to support the transaction locking features

-- Function to calculate account balance with row-level locking
CREATE OR REPLACE FUNCTION calculate_account_balance_locked(
  account_id_param UUID,
  user_id_param UUID
) RETURNS DECIMAL AS $$
DECLARE
  initial_balance DECIMAL;
  transactions_sum DECIMAL := 0;
  transaction_record RECORD;
BEGIN
  -- Get initial balance with row lock
  SELECT initial_balance INTO initial_balance
  FROM financial_account_records
  WHERE id = account_id_param AND user_id = user_id_param
  FOR UPDATE;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Account not found or access denied';
  END IF;
  
  -- Calculate sum of all transactions for this account
  FOR transaction_record IN
    SELECT amount, transaction_type
    FROM transaction_records
    WHERE affected_account_id = account_id_param AND user_id = user_id_param
    ORDER BY transaction_date ASC
  LOOP
    IF transaction_record.transaction_type = 'Income/Credit' THEN
      transactions_sum := transactions_sum + transaction_record.amount;
    ELSIF transaction_record.transaction_type = 'Expense/Debit' THEN
      transactions_sum := transactions_sum - transaction_record.amount;
    END IF;
  END LOOP;
  
  RETURN initial_balance + transactions_sum;
END;
$$ LANGUAGE plpgsql;

-- Function to create transaction with balance validation
CREATE OR REPLACE FUNCTION create_transaction_with_balance_check(
  transaction_data_param JSONB,
  account_id_param UUID,
  amount_param DECIMAL,
  transaction_type_param TEXT,
  user_id_param UUID
) RETURNS JSONB AS $$
DECLARE
  current_balance DECIMAL;
  new_transaction_id UUID;
  result JSONB;
BEGIN
  -- Start transaction
  BEGIN
    -- Calculate current balance with lock
    current_balance := calculate_account_balance_locked(account_id_param, user_id_param);
    
    -- For debit transactions, check if sufficient balance exists
    IF transaction_type_param = 'Expense/Debit' AND current_balance < amount_param THEN
      RAISE EXCEPTION 'Insufficient balance. Current: %, Required: %', current_balance, amount_param;
    END IF;
    
    -- Create the transaction
    INSERT INTO transaction_records (
      id,
      user_id,
      affected_account_id,
      transaction_date,
      amount,
      transaction_type,
      currency,
      description_notes,
      payer_sender_raw,
      payee_receiver_raw,
      reference_number,
      is_internal_transfer,
      counterparty_account_id,
      receipt_file_link,
      ocr_extracted_raw_text,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      user_id_param,
      account_id_param,
      COALESCE((transaction_data_param->>'transaction_date')::TIMESTAMP, NOW()),
      amount_param,
      transaction_type_param,
      COALESCE(transaction_data_param->>'currency', 'ETB'),
      transaction_data_param->>'description_notes',
      transaction_data_param->>'payer_sender_raw',
      transaction_data_param->>'payee_receiver_raw',
      transaction_data_param->>'reference_number',
      COALESCE((transaction_data_param->>'is_internal_transfer')::BOOLEAN, FALSE),
      transaction_data_param->>'counterparty_account_id',
      transaction_data_param->>'receipt_file_link',
      transaction_data_param->>'ocr_extracted_raw_text',
      NOW(),
      NOW()
    ) RETURNING id INTO new_transaction_id;
    
    -- Return the created transaction
    SELECT row_to_json(t.*) INTO result
    FROM transaction_records t
    WHERE t.id = new_transaction_id;
    
    RETURN result;
    
  EXCEPTION
    WHEN OTHERS THEN
      RAISE;
  END;
END;
$$ LANGUAGE plpgsql;

-- Function to create internal transfer atomically
CREATE OR REPLACE FUNCTION create_internal_transfer(
  from_account_id_param UUID,
  to_account_id_param UUID,
  amount_param DECIMAL,
  transaction_data_param JSONB,
  user_id_param UUID
) RETURNS JSONB[] AS $$
DECLARE
  from_balance DECIMAL;
  debit_transaction_id UUID;
  credit_transaction_id UUID;
  result JSONB[];
BEGIN
  -- Start transaction
  BEGIN
    -- Validate both accounts belong to user
    IF NOT EXISTS (
      SELECT 1 FROM financial_account_records 
      WHERE id = from_account_id_param AND user_id = user_id_param
    ) THEN
      RAISE EXCEPTION 'Source account not found or access denied';
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM financial_account_records 
      WHERE id = to_account_id_param AND user_id = user_id_param
    ) THEN
      RAISE EXCEPTION 'Destination account not found or access denied';
    END IF;
    
    -- Check source account balance with lock
    from_balance := calculate_account_balance_locked(from_account_id_param, user_id_param);
    
    IF from_balance < amount_param THEN
      RAISE EXCEPTION 'Insufficient balance in source account. Current: %, Required: %', from_balance, amount_param;
    END IF;
    
    -- Create debit transaction (from account)
    INSERT INTO transaction_records (
      id, user_id, affected_account_id, transaction_date, amount, transaction_type,
      currency, description_notes, is_internal_transfer, counterparty_account_id,
      created_at, updated_at
    ) VALUES (
      gen_random_uuid(), user_id_param, from_account_id_param,
      COALESCE((transaction_data_param->>'transaction_date')::TIMESTAMP, NOW()),
      amount_param, 'Expense/Debit', 'ETB',
      COALESCE(transaction_data_param->>'description_notes', 'Internal Transfer'),
      TRUE, to_account_id_param, NOW(), NOW()
    ) RETURNING id INTO debit_transaction_id;
    
    -- Create credit transaction (to account)
    INSERT INTO transaction_records (
      id, user_id, affected_account_id, transaction_date, amount, transaction_type,
      currency, description_notes, is_internal_transfer, counterparty_account_id,
      created_at, updated_at
    ) VALUES (
      gen_random_uuid(), user_id_param, to_account_id_param,
      COALESCE((transaction_data_param->>'transaction_date')::TIMESTAMP, NOW()),
      amount_param, 'Income/Credit', 'ETB',
      COALESCE(transaction_data_param->>'description_notes', 'Internal Transfer'),
      TRUE, from_account_id_param, NOW(), NOW()
    ) RETURNING id INTO credit_transaction_id;
    
    -- Return both transactions
    SELECT ARRAY[
      (SELECT row_to_json(t.*) FROM transaction_records t WHERE t.id = debit_transaction_id),
      (SELECT row_to_json(t.*) FROM transaction_records t WHERE t.id = credit_transaction_id)
    ] INTO result;
    
    RETURN result;
    
  EXCEPTION
    WHEN OTHERS THEN
      RAISE;
  END;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION calculate_account_balance_locked TO authenticated;
GRANT EXECUTE ON FUNCTION create_transaction_with_balance_check TO authenticated;
GRANT EXECUTE ON FUNCTION create_internal_transfer TO authenticated;