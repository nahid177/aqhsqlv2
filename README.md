# Savings Management System

## 1. Overview

এই project একটি standalone PostgreSQL-based Savings Management System। এর লক্ষ্য হলো customer onboarding থেকে শুরু করে savings product, account opening, deposit, withdrawal, transfer, account hold, Mudaraba profit calculation/distribution, fee এবং double-entry accounting পর্যন্ত পুরো savings lifecycle পরিচালনা করা।

### মূল business flow

```text
Organization
    |
    +-- Branch
    |     |
    |     +-- Users / Roles
    |
    +-- Customers
    |     |
    |     +-- Addresses
    |     +-- Documents / KYC
    |
    +-- Savings Products
    |     |
    |     +-- Profit Rules
    |
    +-- Savings Accounts
          |
          +-- Account Holders
          +-- Nominees
          +-- Holds
          +-- Transactions
          |     +-- Deposits
          |     +-- Withdrawals
          |     +-- Transfers
          |     +-- Profit
          |     +-- Fees
          |
          +-- Mudaraba Profit
          |     +-- Profit Pools
          |     +-- Contributions
          |     +-- Calculations
          |     +-- Distributions
          |
          +-- Accounting
                +-- Accounting Accounts
                +-- Journal Entries
                +-- Journal Entry Lines

Transactions
    |
    +-- Approvals
    |
    +-- Audit Logs
```

---

## 2. Design Principles

### 2.1 PostgreSQL

এই schema PostgreSQL-এর জন্য তৈরি। UUID-এর জন্য `gen_random_uuid()` এবং JSON audit data-এর জন্য `JSONB` ব্যবহার করা হয়েছে।

### 2.2 Master বনাম Transaction Data

**Master data**
- organizations
- branches
- users
- roles
- customers
- savings_products
- savings_product_profit_rules
- fee_types
- accounting_accounts

**Transactional data**
- savings_accounts
- savings_transactions
- savings_deposits
- savings_withdrawals
- savings_transfers
- profit_pools
- profit_pool_contributions
- profit_calculations
- profit_distributions
- account_fees
- journal_entries
- journal_entry_lines
- transaction_approvals
- account_holds

### 2.3 Financial Records Delete করা উচিত নয়

Financial transaction সাধারণভাবে hard-delete না করে reversal/void mechanism দিয়ে correct করা উচিত। Schema-তে foreign key `RESTRICT` ব্যবহারের একটি বড় কারণ এটিই।

---

# 3. Table-by-Table বিস্তারিত

## 3.1 `organizations`

### কাজ
Savings system-এর মূল organization/financial institution-এর তথ্য রাখে।

### গুরুত্বপূর্ণ columns
- `id` — primary key
- `name` — organization name
- `code` — unique organization code
- `status` — active/inactive

### Relation
```text
organizations 1 ---- N branches
organizations 1 ---- N savings_products
```

এক organization-এর অনেক branch এবং অনেক savings product থাকতে পারে।

---

## 3.2 `branches`

### কাজ
Organization-এর branch/office তথ্য রাখে।

### Relation
```text
organizations 1 ---- N branches
branches 1 ---- N users
branches 1 ---- N savings_accounts
```

`organization_id` হলো foreign key।

---

## 3.3 `users`

### কাজ
System-এর internal users/employee/operator-এর তথ্য রাখে।

Customer এবং system user এক জিনিস নয়। `users` হলো application/operator side-এর identity।

### Relation
```text
branches 1 ---- N users
users N ---- N roles
users 1 ---- N customer_documents (verified_by)
users 1 ---- N savings_transactions (created_by)
users 1 ---- N savings_withdrawals (requested_by)
users 1 ---- N savings_withdrawals (approved_by)
users 1 ---- N profit_calculations (approved_by)
users 1 ---- N journal_entries (created_by)
users 1 ---- N transaction_approvals
users 1 ---- N audit_logs
```

---

## 3.4 `roles`

### কাজ
System permission-এর logical role define করে।

### Example
```text
ADMIN
MANAGER
CASHIER
ACCOUNT_OFFICER
AUDITOR
```

### Relation
```text
users N ---- N roles
```

এই many-to-many relation `user_roles` table দিয়ে পরিচালিত হয়।

---

## 3.5 `user_roles`

### কাজ
কোন user-এর কোন role আছে তা সংরক্ষণ করে।

### Relation
```text
users 1 ---- N user_roles N ---- 1 roles
```

`user_id + role_id` composite primary key হওয়ায় একই role একই user-কে duplicate করা যাবে না।

---

# 4. Customer Module

## 4.1 `customers`

### কাজ
Savings customer-এর মূল profile।

### গুরুত্বপূর্ণ তথ্য
- customer number
- name
- date of birth
- gender
- phone
- email
- NID
- occupation
- nationality
- customer status
- KYC status

### Relation
```text
customers 1 ---- N customer_addresses
customers 1 ---- N customer_documents
customers 1 ---- N savings_accounts
customers 1 ---- N savings_account_holders
```

একজন customer-এর একাধিক savings account থাকতে পারে।

---

## 4.2 `customer_addresses`

### কাজ
Customer-এর একাধিক address রাখে।

### Address type
```text
present
permanent
office
other
```

### Relation
```text
customers 1 ---- N customer_addresses
```

---

## 4.3 `customer_documents`

### কাজ
KYC/document information রাখে।

### Supported document type
```text
nid
passport
birth_certificate
driving_license
other
```

### Relation
```text
customers 1 ---- N customer_documents
users 1 ---- N customer_documents (verified_by)
```

---

# 5. Savings Product Module

## 5.1 `savings_products`

### কাজ
Savings account কী ধরনের product-এর অধীনে চলবে তা define করে।

### Example
```text
Mudaraba Savings
Mudaraba DPS
Mudaraba Term Deposit
Wadiah-based product
```

### Important concepts

`product_type`:
```text
savings
dps
term_deposit
```

`contract_type`:
```text
mudaraba
wadiah
```

### Relation
```text
organizations 1 ---- N savings_products
savings_products 1 ---- N savings_product_profit_rules
savings_products 1 ---- N savings_accounts
```

---

## 5.2 `savings_product_profit_rules`

### কাজ
Product-এর profit-sharing rule-এর historical/effective configuration রাখে।

### Important fields
- `effective_from`
- `effective_to`
- `depositor_profit_share`
- `bank_profit_share`
- `status`

### Relation
```text
savings_products 1 ---- N savings_product_profit_rules
```

উদাহরণ:

```text
2026:
Depositor = 70%
Bank = 30%

2027:
Depositor = 75%
Bank = 25%
```

পুরোনো rule হারিয়ে না গিয়ে effective period অনুযায়ী রাখা যায়।

---

# 6. Savings Account Module

## 6.1 `savings_accounts`

### কাজ
এটাই customer-এর actual savings account।

### গুরুত্বপূর্ণ তথ্য
- account number
- customer
- product
- branch
- account name
- currency
- opening date
- maturity date
- ledger balance
- available balance
- blocked amount
- status

### Relation
```text
customers 1 ---- N savings_accounts
savings_products 1 ---- N savings_accounts
branches 1 ---- N savings_accounts
users 1 ---- N savings_accounts (created_by)
```

### Balance concepts

**Ledger Balance**
Account-এর recorded balance।

**Blocked Amount**
যে amount hold/block করা হয়েছে।

**Available Balance**
যে amount customer ব্যবহার করতে পারবে।

Conceptually:

```text
Available Balance <= Ledger Balance
```

---

## 6.2 `savings_account_holders`

### কাজ
একটি account-এর holder information রাখে এবং future joint account support করে।

### Relation
```text
savings_accounts 1 ---- N savings_account_holders
customers 1 ---- N savings_account_holders
```

এটি একটি junction table হিসেবেও কাজ করে।

---

## 6.3 `savings_account_nominees`

### কাজ
Account-এর nominee information রাখে।

### Relation
```text
savings_accounts 1 ---- N savings_account_nominees
```

এক account-এ একাধিক nominee রাখা যায়। `percentage` দিয়ে nominee share configuration রাখা হয়।

---

# 7. Transaction Module

## 7.1 `savings_transactions`

### কাজ
Savings system-এর প্রধান transaction history table।

### Transaction types
```text
deposit
withdrawal
transfer_in
transfer_out
profit
fee
adjustment
reversal
```

### Relation
```text
savings_accounts 1 ---- N savings_transactions
users 1 ---- N savings_transactions (created_by)
```

### Balance snapshot

প্রতিটি transaction-এ:
- `balance_before`
- `amount`
- `balance_after`

রাখা হয়েছে।

Example:

```text
Before  = 40,000
Deposit = 10,000
After   = 50,000
```

---

## 7.2 `savings_deposits`

### কাজ
Deposit transaction-এর payment-specific information রাখে।

### Payment methods
```text
cash
bank_transfer
cheque
mobile_banking
card
```

### Relation
```text
savings_transactions 1 ---- 1 savings_deposits
```

---

## 7.3 `savings_withdrawals`

### কাজ
Withdrawal transaction-এর অতিরিক্ত তথ্য রাখে।

### Relation
```text
savings_transactions 1 ---- 1 savings_withdrawals

users 1 ---- N savings_withdrawals
       |          |
       |          +-- approved_by
       +------------- requested_by
```

Maker-checker workflow support করে।

---

## 7.4 `savings_transfers`

### কাজ
এক savings account থেকে অন্য savings account-এ transfer-এর master record।

### Relation
```text
savings_accounts 1 ---- N savings_transfers (from_account)
savings_accounts 1 ---- N savings_transfers (to_account)
users 1 ---- N savings_transfers (initiated_by)
```

---

# 8. Account Control

## 8.1 `account_holds`

### কাজ
Account-এর নির্দিষ্ট amount temporarily block/hold করে রাখা।

### Example
```text
Ledger Balance = 100,000
Hold           = 20,000
Available      = 80,000
```

### Relation
```text
savings_accounts 1 ---- N account_holds
```

### Hold status
```text
active
released
expired
cancelled
```

---

# 9. Mudaraba Profit Module

## 9.1 `profit_pools`

### কাজ
একটি নির্দিষ্ট profit period-এর Mudaraba pool-এর summary রাখে।

### Important fields
- period
- total funds
- gross profit
- expenses
- distributable profit
- status

---

## 9.2 `profit_pool_contributions`

### কাজ
কোন savings account profit pool-এ কত eligible balance/fund contribute করছে তা রাখে।

### Relation
```text
profit_pools 1 ---- N profit_pool_contributions
savings_accounts 1 ---- N profit_pool_contributions
```

---

## 9.3 `profit_calculations`

### কাজ
প্রতিটি account-এর জন্য calculated profit সংরক্ষণ করে।

### Relation
```text
profit_pools 1 ---- N profit_calculations
savings_accounts 1 ---- N profit_calculations
users 1 ---- N profit_calculations (approved_by)
```

### Important data
```text
eligible_balance
weight
profit_share_ratio
calculated_profit
status
```

---

## 9.4 `profit_distributions`

### কাজ
Calculated profit customer account-এ actual distribution/posting হওয়ার record রাখে।

### Relation
```text
profit_calculations 1 ---- 1 profit_distributions
savings_transactions 1 ---- N profit_distributions
```

---

# 10. Fee Module

## 10.1 `fee_types`

### কাজ
কোন ধরনের fee আছে এবং কীভাবে calculate হবে তা define করে।

### Calculation type
```text
fixed
percentage
```

---

## 10.2 `account_fees`

### কাজ
নির্দিষ্ট account-এর উপর actual charged fee record করে।

### Relation
```text
savings_accounts 1 ---- N account_fees
fee_types 1 ---- N account_fees
savings_transactions 1 ---- N account_fees
```

---

# 11. Accounting Module

## 11.1 `accounting_accounts`

### কাজ
Chart of Accounts।

### Account types
```text
asset
liability
equity
income
expense
```

### Self relationship
```text
accounting_accounts 1 ---- N accounting_accounts
```

`parent_id` দিয়ে hierarchy তৈরি হয়।

Example:

```text
1000 Assets
 |
 +-- 1100 Cash
 +-- 1200 Bank

2000 Liabilities
 |
 +-- 2100 Customer Deposits
```

---

## 11.2 `journal_entries`

### কাজ
একটি accounting event-এর header/master record।

### Relation
```text
users 1 ---- N journal_entries
journal_entries 1 ---- N journal_entry_lines
```

`source_type` এবং `source_id` দিয়ে business transaction-এর সাথে link/reference রাখা যায়।

---

## 11.3 `journal_entry_lines`

### কাজ
Double-entry accounting-এর debit/credit lines।

### Relation
```text
journal_entries 1 ---- N journal_entry_lines
accounting_accounts 1 ---- N journal_entry_lines
```

প্রতিটি line হয় debit অথবা credit।

Core accounting rule:

```text
Total Debit = Total Credit
```

এই equality application/service layer-এ enforce করা উচিত; line-level check একা যথেষ্ট নয়।

---

# 12. Approval Module

## 12.1 `transaction_approvals`

### কাজ
Transaction-এর maker-checker approval workflow।

### Relation
```text
savings_transactions 1 ---- N transaction_approvals

users 1 ---- N transaction_approvals
       |
       +-- requested_by
       +-- approved_by
```

### Status
```text
pending
approved
rejected
cancelled
```

---

# 13. Audit Module

## 13.1 `audit_logs`

### কাজ
System-এ কে কী পরিবর্তন করেছে তার audit trail।

### Important fields
- `user_id`
- `action`
- `table_name`
- `record_id`
- `old_data`
- `new_data`
- `ip_address`
- `user_agent`
- `created_at`

### Relation
```text
users 1 ---- N audit_logs
```

---

# 14. Complete Relationship Map

```text
organizations
    |
    +----< branches
              |
              +----< users
              |
              +----< savings_accounts

organizations
    |
    +----< savings_products
              |
              +----< savings_product_profit_rules
              |
              +----< savings_accounts

customers
    |
    +----< customer_addresses
    |
    +----< customer_documents
    |
    +----< savings_accounts
    |
    +----< savings_account_holders
                    |
                    +----> savings_accounts

savings_accounts
    |
    +----< savings_account_nominees
    |
    +----< account_holds
    |
    +----< savings_transactions
    |          |
    |          +----< savings_deposits
    |          |
    |          +----< savings_withdrawals
    |          |
    |          +----< profit_distributions
    |          |
    |          +----< account_fees
    |
    +----< savings_transfers
          |
          +----> another savings_accounts

profit_pools
    |
    +----< profit_pool_contributions >---- savings_accounts
    |
    +----< profit_calculations >--------- savings_accounts
                 |
                 +----1 profit_distributions

fee_types
    |
    +----< account_fees >---- savings_accounts

accounting_accounts
    |
    +----< journal_entry_lines >---- journal_entries
                                      |
                                      +----< journal_entry_lines

users
    |
    +----< user_roles >---- roles
    +----< transaction_approvals
    +----< audit_logs
    +----< customer_documents
    +----< savings_transactions
    +----< savings_withdrawals
    +----< profit_calculations
    +----< journal_entries
```

---

# 15. Example: Deposit Flow

Customer ৳10,000 deposit করলে:

```text
Customer
   |
   ▼
Savings Account
   |
   ▼
savings_transactions
   |
   +-- type = deposit
   +-- amount = 10,000
   +-- balance_before = 40,000
   +-- balance_after = 50,000
   |
   ▼
savings_deposits
   |
   +-- payment_method = cash
   |
   ▼
journal_entries
   |
   +-- Debit  Cash
   +-- Credit Customer Deposit Liability
   |
   ▼
audit_logs
```

Customer application-এ মূলত balance এবং transaction history দেখবে।

---

# 16. Example: Mudaraba Profit Flow

```text
Savings Accounts
       |
       ▼
Profit Pool
       |
       ▼
Eligible Balance
       |
       ▼
Weight
       |
       ▼
Distributable Profit
       |
       ▼
Profit Calculation
       |
       ▼
Approval
       |
       ▼
Profit Distribution
       |
       ▼
Savings Transaction
       |
       ▼
Customer Balance
       |
       ▼
Journal Entry
```

---

# 17. Table Creation Order

Foreign key dependency অনুযায়ী:

```text
1. pgcrypto

2. organizations
3. branches

4. users
5. roles
6. user_roles

7. customers
8. customer_addresses
9. customer_documents

10. savings_products
11. savings_product_profit_rules

12. savings_accounts
13. savings_account_holders
14. savings_account_nominees

15. savings_transactions
16. savings_deposits
17. savings_withdrawals
18. savings_transfers

19. account_holds

20. profit_pools
21. profit_pool_contributions
22. profit_calculations
23. profit_distributions

24. fee_types
25. account_fees

26. accounting_accounts
27. journal_entries
28. journal_entry_lines

29. transaction_approvals
30. audit_logs
```

---

# 18. Core Relationship Summary

| Parent | Child | Relation |
|---|---|---|
| organizations | branches | 1:N |
| organizations | savings_products | 1:N |
| branches | users | 1:N |
| branches | savings_accounts | 1:N |
| users | roles | N:N via `user_roles` |
| customers | customer_addresses | 1:N |
| customers | customer_documents | 1:N |
| customers | savings_accounts | 1:N |
| customers | savings_account_holders | 1:N |
| savings_products | savings_product_profit_rules | 1:N |
| savings_products | savings_accounts | 1:N |
| savings_accounts | savings_account_holders | 1:N |
| savings_accounts | savings_account_nominees | 1:N |
| savings_accounts | savings_transactions | 1:N |
| savings_transactions | savings_deposits | 1:1 |
| savings_transactions | savings_withdrawals | 1:1 |
| savings_accounts | savings_transfers | 1:N |
| savings_accounts | account_holds | 1:N |
| profit_pools | profit_pool_contributions | 1:N |
| profit_pools | profit_calculations | 1:N |
| savings_accounts | profit_calculations | 1:N |
| profit_calculations | profit_distributions | 1:1 |
| savings_accounts | account_fees | 1:N |
| fee_types | account_fees | 1:N |
| accounting_accounts | journal_entry_lines | 1:N |
| journal_entries | journal_entry_lines | 1:N |
| savings_transactions | transaction_approvals | 1:N |
| users | audit_logs | 1:N |

---

# 19. Development Roadmap

```text
Phase 1  Foundation
  Organization → Branch → Users → Roles

Phase 2  Customer & KYC
  Customer → Address → Documents

Phase 3  Product & Account
  Product → Profit Rules → Account

Phase 4  Transactions
  Deposit → Withdrawal → Transfer → Reversal

Phase 5  Mudaraba
  Pool → Contribution → Calculation → Distribution

Phase 6  Accounting
  Chart of Accounts → Journal → Journal Lines

Phase 7  Control
  Approval → Hold → Fees → Audit

Phase 8  Testing
  Unit → Transaction → Accounting Reconciliation
  → Profit Reconciliation → Concurrency
```

---

## Important

এই README বর্তমান proposed schema-এর documentation। Production banking system করার আগে applicable regulatory requirements, KYC/AML, Shariah governance, accounting policy, maker-checker, concurrency, idempotency এবং reconciliation rules আলাদাভাবে verify করতে হবে।

Mudaraba profit calculation-এর actual formula institution-এর approved Shariah policy অনুযায়ী নির্ধারণ করতে হবে; এই schema মূলত সেই calculation-এর data structure দেয়।
