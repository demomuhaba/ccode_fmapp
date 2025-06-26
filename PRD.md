
fmapp - Personal Multi-SIM Finance & Loan Manager
High-Level Goal: To create a personal Android application for a single user. The app will enable comprehensive management of personal finances across multiple SIM cards, associated financial accounts (from banks and mobile money services), and allow tracking of personal loans/debts with friends. The application should be intuitive and utilize Optical Character Recognition (OCR) for quick transaction entry from various financial service transaction notifications or documents.
Target User Context: A single individual using local financial services.
Primary Currency: ETB
🛠️ Tech Stack
 * Framework: Flutter
 * Language: Dart
 * State Management: (e.g., Provider, BLoC/Cubit, Riverpod - to be decided)
 * Local Database: (e.g., sqflite, Hive, Isar - to be decided)
 * Backend Services (Optional): Supabase (Authentication, Firestore, Storage) or other BaaS.
 * UI Design: Material Design
1. Core Application Modules & User Stories
1.1. User Account & Security
 * User Story: As the app user, I need to create a secure personal account (e.g., using email and password) so that all my financial data is private, protected, and accessible to me even if I change or reinstall the app on a new device.
 * Functionality:
   * Secure user registration and login system.
   * Data persistence linked to the user's account, preferably using a cloud-based backend (e.g., Supabase) for reliable backup and synchronization.
1.2. SIM Card Management (User's Personal SIMs)
 * User Story: As the app user, I want to register all the SIM cards I use by their phone numbers and assign my own nicknames, so I can easily associate my various financial accounts and transactions with the correct SIM.
 * Functionality:
   * Allow the user to add, view, edit, and delete records of their SIM cards.
   * Data to Capture per SIM:
     * phoneNumber (String, unique within the user's data)
     * simNickname (String, user-defined for easy identification)
     * telecomProvider (String, e.g., "Ethio Telecom", "Safaricom Ethiopia" - user can input or select from a common list)
     * officialRegisteredName (String, optional, for user's reference or if needed for transaction matching)
1.3. Financial Account Management (User's Personal Accounts)
 * User Story: As the app user, I want to add all my financial accounts – including my bank accounts, mobile money accounts (like Telebirr, M-Pesa), and any virtual "Online Money" pools I manage – and link them to my respective SIM cards. I need to record their starting balances so the app can track their current financial status accurately.
 * Functionality:
   * Allow the user to add, view, edit, and delete records of their financial accounts.
   * Each financial account must be linkable to one of the user's registered SIM cards.
   * Account Types to Support:
     * "Bank Account"
     * "Mobile Wallet"
     * "Online Money" (These are virtual accounts defined by the user for managing internal fund movements between their other owned accounts).
   * Data to Capture per Financial Account:
     * accountName (String, user-defined for easy identification)
     * accountIdentifier (String, e.g., bank account number, mobile wallet phone number, or a user-defined ID for "Online Money" type)
     * accountType (String, selected from the supported types)
     * linkedSimId (Reference to one of the user's registered SIM cards)
     * initialBalance (Number, in ETB, at the time of adding the account)
     * dateAdded (Date)
   * The system must dynamically calculate and prominently display the Current Balance for each financial account. This balance is derived from its initialBalance and all subsequent transactions affecting it.
1.4. Transaction Management (User's Personal Transactions)
 * User Story (OCR-Assisted Entry): As the app user, to save time and reduce errors, I want to quickly add new transactions by uploading an image or a PDF file of my transaction confirmations. These could be SMS screenshots, e-receipts, or notifications from my bank or mobile money service. The app should then use OCR to extract the key details, let me review and correct them if needed, and then save the transaction.
 * User Story (Manual Entry): As the app user, I also need the option to manually enter all transaction details if I don't have a digital confirmation or if OCR is not suitable for a particular entry, ensuring all my financial activities can be recorded.
 * Functionality:
   * OCR-Assisted Transaction Entry:
     * Interface for the user to select/upload an image file (e.g., JPG, PNG) or a PDF file containing transaction information.
     * The system must employ Optical Character Recognition (OCR) to parse text from the provided file.
     * The OCR process should attempt to intelligently identify and extract relevant transaction details. This includes, but is not limited to:
       * Transaction Date and Time
       * Transaction Amount
       * Currency (default or confirm ETB)
       * Payer/Sender Information (name, account number, phone number)
       * Payee/Receiver Information (name, account number, phone number, merchant ID)
       * Transaction ID / Reference Number
       * Type of transaction if discernible (e.g., payment, transfer, withdrawal, deposit)
       * Any listed remaining balance after the transaction.
     * Scope of OCR: The OCR logic needs to be adaptable and effective for common formats of transaction notifications, e-receipts, and mini-statements issued by various financial institutions, including commercial banks and mobile money providers (e.g., Telebirr, M-Pesa).
     * After OCR, the extracted data must be presented to the user in an editable form for review, correction, and confirmation before the transaction is saved.
     * Provide an option to store the uploaded file (image/PDF) linked to the saved transaction record for future reference.
   * Manual Transaction Entry:
     * A comprehensive form allowing the user to manually input all necessary transaction details.
   * Data to Capture per Transaction:
     * affectedAccountId (Reference to the user's Financial Account this transaction impacts)
     * transactionDate (Date and Time)
     * amount (Number, ETB)
     * transactionType (String: "Income/Credit" or "Expense/Debit" relative to the affectedAccountId)
     * currency (String, defaulting to "ETB")
     * descriptionNotes (String, for user's own notes or details)
     * payerSenderRaw (String, captured Payer/Sender information, from OCR or manual entry)
     * payeeReceiverRaw (String, captured Payee/Receiver information, from OCR or manual entry)
     * referenceNumber (String, Transaction ID or other reference)
     * isInternalTransfer (Boolean, flag to indicate if it's a transfer between user's own accounts, see section 1.5)
     * counterpartyAccountId (String, optional, stores the ID of the other user-owned account involved if isInternalTransfer is true)
     * receiptFileLink (String, optional, link/path to the stored uploaded receipt file)
     * ocrExtractedRawText (String, optional, for storing the full text extracted by OCR for user reference or troubleshooting)
1.5. "Online Money" Accounts & Internal Transfers (User's Personal Funds)
 * User Story: As the app user, I want to use "Online Money" accounts as virtual holding places for my funds. This helps me track money I move between my own registered financial accounts (e.g., transferring from my bank account to an "Online Money for M-Pesa Top-up" placeholder before actually sending via M-Pesa). I need these internal movements to be clearly identifiable.
 * Functionality:
   * Transactions involving a user-defined "Online Money" account are always considered transfers between two of the user's own registered financial accounts (one "Online Money" account and another, e.g., Bank or Mobile Wallet).
   * These transactions must be automatically flagged or categorized as "Internal Transfers."
   * The system must ensure that an internal transfer correctly updates the balances of both user financial accounts involved (e.g., debiting one and crediting the other).
1.6. Friend & Loan/Debt Management
 * User Story (Friend Records): As the app user, I want to maintain a simple list of my friends (name and optionally, phone number), so I can easily associate loans I give them or debts I owe them.
 * User Story (Recording Loans/Debts): As the app user, I need to record instances where I lend money to a friend or borrow money from a friend. This record should include who the friend is, the amount, the date, and importantly, whether the initial transaction was made in "Cash" or by using one of my registered financial accounts (so my account balances stay correct).
 * User Story (Tracking Repayments): As the app user, I want to log when I make a repayment on a debt I owe, or when a friend makes a repayment on a loan I gave them. This includes partial or full repayments, and again, whether the repayment happened in "Cash" or affected one of my registered financial accounts. This ensures the outstanding amounts are always up-to-date.
 * Functionality:
   * Friend Management: Allow the user to Add, View, Edit, and Delete records for friends.
     * Data to Capture per Friend: friendName (String), friendPhoneNumber (String, optional), notes (String, optional).
   * Loan/Debt Tracking:
     * Allow creation of new loan/debt records.
     * Data to Capture per Loan/Debt Item:
       * associatedFriendId (Reference to a friend record)
       * type (String: "LoanGivenToFriend" / "DebtOwedToFriend")
       * initialAmount (Number, ETB)
       * outstandingAmount (Number, ETB, dynamically updated with payments)
       * currency (String, "ETB")
       * dateInitiated (Date, when the loan/debt was made)
       * dueDate (Date, optional)
       * description (String, e.g., "Loan for lunch," "Borrowed for supplies")
       * status (String, e.g., "Active", "PartiallyPaid", "PaidOff")
       * initialTransactionMethod (String: "Cash" OR userFinancialAccountId if the loan/debt initiation directly involved one of the user's registered financial accounts).
       * CRITICAL LINK: If initialTransactionMethod specifies a userFinancialAccountId, the system must automatically create a corresponding transaction record in the main transaction ledger (Module 1.4). For example, if a user gives a loan of 500 ETB to a friend from their bank account, this should create a "LoanGivenToFriend" record AND an "Expense/Debit" transaction of 500 ETB linked to that bank account.
   * Repayment Recording:
     * Allow the user to record payments made or received for an active loan/debt.
     * Data to Capture per Payment: paymentDate (Date), amountPaid (Number, ETB), paidBy (String: "UserToFriend" or "FriendToUser"), notes (String, optional).
     * paymentTransactionMethod (String: "Cash" OR userFinancialAccountId if the payment directly involved one of the user's registered financial accounts).
     * CRITICAL LINK: Similar to loan initiation, if paymentTransactionMethod specifies a userFinancialAccountId, the system must create a corresponding transaction in the main ledger. For example, if a friend repays a loan of 200 ETB directly to the user's mobile wallet, this records the payment against the loan AND creates an "Income/Credit" transaction for that mobile wallet account.
     * Payments must update the outstandingAmount and potentially the status of the parent loan/debt item.
1.7. Dashboard & Overview
 * User Story: As the app user, I want a main dashboard screen that gives me a quick, clear snapshot of my overall financial situation. This should include the total balances on my different SIM cards, a look at recent transactions, and a summary of money I've lent out versus money I owe.
 * Functionality (Dashboard to Display):
   * A list or summary of each registered SIM card, showing its current total balance. The total balance for a SIM is the sum of current balances of all financial accounts the user has linked to it. This could be sorted (e.g., highest balance first).
   * A section for recent personal transactions (e.g., last 3-5 transactions across all accounts), showing key details like amount, type, and affected account.
   * A visual highlight or summary for any "Internal Transfers."
   * A summary of total outstanding money lent to friends versus total outstanding money owed to friends.
   * A quick view or alert for 1-2 most urgent (e.g., upcoming due date) or oldest outstanding loans/debts.
1.8. Reporting & Analysis
 * User Story: As the app user, I want to be able to generate simple reports on my income and expenses from my personal accounts, with options to filter by date range, specific accounts, or by SIM card, so I can better understand my spending habits and financial flow. I also want to see reports specifically for my loans and debts with friends.
 * Functionality:
   * Personal Finance Reports:
     * Generate summaries of income, expenses, and net change for the user's personal financial accounts.
     * Filtering options: by date range, by one or more specific SIM cards, by one or more specific financial accounts, or by "Internal Transfers" only.
     * Option to view a list of individual transactions that make up the summary.
   * Loan/Debt Reports:
     * Generate lists of all active loans given by the user (showing friend, initial amount, outstanding amount, due date).
     * Generate lists of all active debts owed by the user (showing friend, initial amount, outstanding amount, due date).
     * Allow viewing the history of payments for a specific loan or debt.
     * Summary of paid-off loans/debts within a selected period.
2. Key Data Entities (Conceptual for No-Code Builder)
 * User_Profile: (Stores the single authenticated user's basic info like User ID, email).
 * SIM_Card_Records: (Stores user's SIMs: SIM ID, User ID, phone number, nickname, provider).
 * Financial_Account_Records: (User's bank/mobile money/online money accounts: Account ID, User ID, name, type, identifier like account number, linked SIM ID, initial balance, current balance calculated).
 * Transaction_Records: (For user's Financial Accounts: Transaction ID, User ID, affected Account ID, date, amount, type (income/expense), description, Payer/Payee info, reference, internal transfer flag, link to receipt file, etc.).
 * Friend_Records: (User's contacts for loan tracking: Friend ID, User ID, name, phone).
 * Loan_Debt_Items: (Record of money lent/borrowed: Loan/Debt ID, User ID, Friend ID, type (loan/debt), initial amount, outstanding amount, date, description, status, link to an initial financial transaction if not cash).
 * Loan_Debt_Payments: (Record of a payment against a Loan/Debt Item: Payment ID, Parent Loan/Debt ID, amount, date, notes, link to a financial transaction if not cash).
3. Important Considerations for the AI Builder
 * Target Platform: Android application.
 * Financial Context: The application must be designed with the user in mind. All monetary values should be handled in ETB currency throughout. Descriptions and examples should be contextually appropriate.
 * Single-User Focus: All data, features, and views are for the single, authenticated owner of the app. There is no data sharing or interaction between different app users.
 * Accurate Balance Calculations: This is critical.
   * CurrentBalance for each Financial_Account_Record must be accurately calculated by taking its initialBalance and applying all relevant Transaction_Records (including debits/credits linked from Loan_Debt_Items or Loan_Debt_Payments if they were not "Cash").
   * outstandingAmount for each Loan_Debt_Item must be accurately updated with every Loan_Debt_Payment recorded against it.
 * Clear Data Relationships: The no-code platform must support defining and using relationships between these data entities (e.g., a Financial Account is linked to a SIM Card; a Transaction is linked to a Financial Account; a Loan/Debt Item is linked to a Friend and potentially to initial/payment Transactions).
 * Flexible OCR: The OCR capability is a key feature for ease of use. It must be robust enough to work with a variety of transaction notification formats (images, PDFs) commonly encountered from different banks and mobile money services. The focus for the AI builder should be on enabling the extraction of the key data points listed in section 1.4, allowing user review and correction.
 * Offline Capability: The app should strive to be as functional as possible when the user is offline. This might involve local caching of data and queueing of new entries/uploads to be synced with the cloud backend when connectivity is restored. The no-code platform's capabilities in this area should be leveraged.
 * Intuitive User Interface (UI) / User Experience (UX): The app should be easy to navigate, with clear forms for data entry, and informative displays for balances and reports. Financial information should be presented in a way that is easy to understand at a glance.
