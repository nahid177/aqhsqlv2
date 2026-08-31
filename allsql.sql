//donation

CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    logo TEXT,
    image TEXT,
    type VARCHAR(100) NOT NULL,
    unique_number VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    website TEXT,
    phone VARCHAR(30),
    email VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE organization_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_id UUID NOT NULL
        REFERENCES organization_types(id)
        ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    logo TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);


CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL
        REFERENCES categories(id)
        ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    short_description VARCHAR(500),
    description TEXT,
    image TEXT,
    video_url TEXT,
    goal_amount NUMERIC(14,2) NOT NULL
        CHECK (goal_amount >= 0),
    raised_amount NUMERIC(14,2) NOT NULL DEFAULT 0
        CHECK (raised_amount >= 0),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (end_date >= start_date),
    CHECK (raised_amount <= goal_amount)
); 


CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(30) UNIQUE,
    password TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'inactive')),
    email_verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);




CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL
        CHECK (type IN ('HOME', 'OFFICE', 'OTHER')),
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL DEFAULT 'Bangladesh',
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);




CREATE TABLE user_roles (
    user_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,
    role_id UUID NOT NULL
        REFERENCES roles(id)
        ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);





CREATE TABLE donor_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE
        REFERENCES users(id)
        ON DELETE CASCADE,
    organization_id UUID
        REFERENCES organizations(id)
        ON DELETE CASCADE,
    dob DATE,
    gender VARCHAR(20),
    nid_passport VARCHAR(100),
    occupation VARCHAR(150),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);



CREATE TABLE donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donor_id UUID NOT NULL
        REFERENCES donor_profiles(id)
        ON DELETE CASCADE,
    campaign_id UUID NOT NULL
        REFERENCES campaigns(id)
        ON DELETE CASCADE,
    amount NUMERIC(14,2) NOT NULL
        CHECK (amount > 0),
    message TEXT,
    note TEXT,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'completed',
                'cancelled',
                'refunded'
            )
        ),
    donated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donation_id UUID NOT NULL
        REFERENCES donations(id)
        ON DELETE CASCADE,
    payment_method VARCHAR(50) NOT NULL,
    transaction_id VARCHAR(255) UNIQUE,
    gateway_transaction_id VARCHAR(255),
    amount NUMERIC(14,2) NOT NULL
        CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'processing',
                'paid',
                'failed',
                'refunded'
            )
        ),
    paid_at TIMESTAMPTZ,
    gateway_response TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE donation_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donation_id UUID NOT NULL UNIQUE
        REFERENCES donations(id)
        ON DELETE CASCADE,
    receipt_number VARCHAR(100) NOT NULL UNIQUE,
    donor_name VARCHAR(255) NOT NULL,
    donor_email VARCHAR(255),
    donor_phone VARCHAR(30),
    campaign_name VARCHAR(255) NOT NULL,
    amount NUMERIC(14,2) NOT NULL
        CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',
    receipt_url TEXT,
    issued_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE refunds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id UUID NOT NULL
        REFERENCES payments(id)
        ON DELETE CASCADE,
    donation_id UUID NOT NULL
        REFERENCES donations(id)
        ON DELETE CASCADE,
    amount NUMERIC(14,2) NOT NULL
        CHECK (amount > 0),
    reason TEXT,
    refund_method VARCHAR(50),
    refund_transaction_id VARCHAR(255) UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'processing',
                'completed',
                'failed',
                'cancelled'
            )
        ),
    requested_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE campaign_switches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donation_id UUID NOT NULL
        REFERENCES donations(id)
        ON DELETE CASCADE,
    from_campaign_id UUID NOT NULL
        REFERENCES campaigns(id)
        ON DELETE RESTRICT,
    to_campaign_id UUID NOT NULL
        REFERENCES campaigns(id)
        ON DELETE RESTRICT,
    amount NUMERIC(14,2) NOT NULL
        CHECK (amount > 0),
    reason TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'approved',
                'completed',
                'rejected',
                'cancelled'
            )
        ),
    requested_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (from_campaign_id <> to_campaign_id)
);




CREATE TABLE campaign_donation_totals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID NOT NULL UNIQUE
        REFERENCES campaigns(id)
        ON DELETE CASCADE,
    total_donations INTEGER NOT NULL DEFAULT 0
        CHECK (total_donations >= 0),
    total_amount NUMERIC(14,2) NOT NULL DEFAULT 0
        CHECK (total_amount >= 0),
    last_donation_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);









CREATE TABLE funds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE RESTRICT,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(50) NOT NULL,
    description TEXT,
    fund_type VARCHAR(30) NOT NULL DEFAULT 'general'
        CHECK (
            fund_type IN (
                'general',
                'restricted',
                'campaign',
                'emergency',
                'zakat',
                'other'
            )
        ),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (organization_id, code)
);




CREATE TABLE chart_of_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE RESTRICT,
    parent_id UUID
        REFERENCES chart_of_accounts(id)
        ON DELETE RESTRICT,
    account_code VARCHAR(30) NOT NULL,

    account_name VARCHAR(150) NOT NULL,

    account_type VARCHAR(30) NOT NULL
        CHECK (
            account_type IN (
                'asset',
                'liability',
                'equity',
                'income',
                'expense'
            )
        ),

    normal_balance VARCHAR(10) NOT NULL
        CHECK (
            normal_balance IN (
                'debit',
                'credit'
            )
        ),

    description TEXT,

    is_system_account BOOLEAN NOT NULL DEFAULT FALSE,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (organization_id, account_code)
);





CREATE TABLE accounting_periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE RESTRICT,
    name VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'open'
        CHECK (
            status IN (
                'open',
                'closed'
            )
        ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    closed_at TIMESTAMPTZ,

    CHECK (end_date >= start_date),

    UNIQUE (organization_id, start_date, end_date)
);



CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE RESTRICT,
    accounting_period_id UUID
        REFERENCES accounting_periods(id)
        ON DELETE RESTRICT,
    reference_number VARCHAR(100) NOT NULL,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    transaction_type VARCHAR(40) NOT NULL
        CHECK (
            transaction_type IN (
                'donation',
                'payment',
                'refund',
                'payment_fee',
                'campaign_expense',
                'general_expense',
                'adjustment',
                'transfer'
            )
        ),
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'posted'
        CHECK (
            status IN (
                'draft',
                'posted',
                'voided'
            )
        ),
    created_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (organization_id, reference_number)
);




CREATE TABLE journal_entry_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journal_entry_id UUID NOT NULL
        REFERENCES journal_entries(id)
        ON DELETE CASCADE,
    account_id UUID NOT NULL
        REFERENCES chart_of_accounts(id)
        ON DELETE RESTRICT,
    fund_id UUID
        REFERENCES funds(id)
        ON DELETE RESTRICT,
    description TEXT,
    debit NUMERIC(14,2) NOT NULL DEFAULT 0
        CHECK (debit >= 0),
    credit NUMERIC(14,2) NOT NULL DEFAULT 0
        CHECK (credit >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (
        NOT (debit > 0 AND credit > 0)
    ),
    CHECK (
        debit > 0 OR credit > 0
    )
);





CREATE TABLE financial_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE RESTRICT,
    account_id UUID NOT NULL
        REFERENCES chart_of_accounts(id)
        ON DELETE RESTRICT,
    account_name VARCHAR(150) NOT NULL,
    account_type VARCHAR(30) NOT NULL
        CHECK (
            account_type IN (
                'cash',
                'bank',
                'mobile_wallet',
                'other'
            )
        ),
    bank_name VARCHAR(150),

    account_number VARCHAR(255),

    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',

    opening_balance NUMERIC(14,2) NOT NULL DEFAULT 0,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);











// investment

CREATE TABLE investor_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    logo TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE investment_categories (id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
organization_id UUID NOT NULL
    REFERENCES organizations(id)
    ON DELETE CASCADE,
investor_type_id UUID NOT NULL
    REFERENCES investor_types(id)
    ON DELETE CASCADE,
name VARCHAR(100) NOT NULL,
description TEXT,
logo TEXT,
is_active BOOLEAN NOT NULL DEFAULT TRUE,
created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);




CREATE TABLE investment_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    investment_category_id UUID NOT NULL
        REFERENCES investment_categories(id)
        ON DELETE CASCADE,
    subtitle VARCHAR(255),
    description TEXT,
    image TEXT,
    video_url TEXT,
    pdf_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);




CREATE TABLE investment_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE CASCADE,
    investment_category_id UUID NOT NULL
        REFERENCES investment_categories(id)
        ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    short_description VARCHAR(500),
    description TEXT,
    image TEXT,
    video_url TEXT,
    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',
    minimum_amount NUMERIC(14,2) NOT NULL
        CHECK (minimum_amount > 0),
    maximum_amount NUMERIC(14,2)
        CHECK (
            maximum_amount IS NULL
            OR maximum_amount >= minimum_amount
        ),
    duration_months INTEGER
        CHECK (
            duration_months IS NULL
            OR duration_months > 0
        ),
    expected_return_rate NUMERIC(7,4)
        CHECK (
            expected_return_rate IS NULL
            OR expected_return_rate >= 0
        ),
    total_limit NUMERIC(14,2)
        CHECK (
            total_limit IS NULL
            OR total_limit >= 0
        ),
    available_amount NUMERIC(14,2)
        CHECK (
            available_amount IS NULL
            OR available_amount >= 0
        ),
    status VARCHAR(20) NOT NULL DEFAULT 'draft'
        CHECK (
            status IN (
                'draft',
                'pending',
                'active',
                'inactive',
                'completed',
                'cancelled'
            )
        ),
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INTEGER NOT NULL DEFAULT 0,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (
        end_date IS NULL
        OR start_date IS NULL
        OR end_date >= start_date
    )
);




CREATE TABLE investor_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE
        REFERENCES users(id)
        ON DELETE CASCADE,
    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE RESTRICT,
    investor_type_id UUID NOT NULL
        REFERENCES investor_types(id)
        ON DELETE RESTRICT,
    profile_type VARCHAR(30) NOT NULL DEFAULT 'individual'
        CHECK (
            profile_type IN (
                'individual',
                'business',
                'institutional'
            )
        ),
    business_type VARCHAR(100),
    date_of_birth DATE,
    gender VARCHAR(20)
        CHECK (
            gender IN (
                'male',
                'female',
                'other'
            )
        ),
    occupation VARCHAR(150),
    nid_passport VARCHAR(100),
    company_name VARCHAR(255),
    profile_image TEXT,
    bio TEXT,
    -- Financial information
    annual_income NUMERIC(14,2)
        CHECK (
            annual_income IS NULL
            OR annual_income >= 0
        ),
    net_worth NUMERIC(14,2)
        CHECK (
            net_worth IS NULL
            OR net_worth >= 0
        ),
    -- Investment profile
    investment_experience VARCHAR(30)
        CHECK (
            investment_experience IN (
                'none',
                'beginner',
                'intermediate',
                'experienced',
                'expert'
            )
        ),
    risk_profile VARCHAR(30)
        CHECK (
            risk_profile IN (
                'conservative',
                'moderate',
                'aggressive'
            )
        ),
    investment_objective VARCHAR(50)
        CHECK (
            investment_objective IN (
                'capital_growth',
                'income',
                'wealth_preservation',
                'retirement',
                'business_growth',
                'social_impact',
                'other'
            )
        ),
    profit_preference VARCHAR(30)
        CHECK (
            profit_preference IN (
                'reinvest',
                'withdraw',
                'both'
            )
        ),
    -- KYC
    kyc_status VARCHAR(30) NOT NULL DEFAULT 'pending'
        CHECK (
            kyc_status IN (
                'pending',
                'under_review',
                'verified',
                'rejected',
                'expired'
            )
        ),
    kyc_verified_at TIMESTAMPTZ,
    kyc_rejection_reason TEXT,
    -- Account status
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    verified_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE investment_product_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    investment_product_id UUID NOT NULL
        REFERENCES investment_products(id)
        ON DELETE CASCADE,
    unit_name VARCHAR(100) NOT NULL DEFAULT 'Unit',
    unit_price NUMERIC(14,2) NOT NULL
        CHECK (unit_price > 0),
    minimum_units NUMERIC(14,4) NOT NULL DEFAULT 1
        CHECK (minimum_units > 0),
    maximum_units NUMERIC(14,4)
        CHECK (
            maximum_units IS NULL
            OR maximum_units >= minimum_units
        ),
    total_units NUMERIC(18,4)
        CHECK (
            total_units IS NULL
            OR total_units >= 0
        ),
    available_units NUMERIC(18,4)
        CHECK (
            available_units IS NULL
            OR available_units >= 0
        ),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);



CREATE TABLE investments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    investment_product_id UUID NOT NULL
        REFERENCES investment_products(id)
        ON DELETE RESTRICT,
    investment_product_unit_id UUID
        REFERENCES investment_product_units(id)
        ON DELETE RESTRICT,
    investment_number VARCHAR(50) NOT NULL UNIQUE,
    units NUMERIC(18,4) NOT NULL
        CHECK (units > 0),
    unit_price NUMERIC(14,2) NOT NULL
        CHECK (unit_price > 0),
    amount NUMERIC(14,2) NOT NULL
        CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',
    agreed_return_rate NUMERIC(7,4)
        CHECK (
            agreed_return_rate IS NULL
            OR agreed_return_rate >= 0
        ),
    investment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    maturity_date DATE,
    status VARCHAR(30) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'active',
                'matured',
                'completed',
                'cancelled',
                'defaulted'
            )
        ),
    payment_status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            payment_status IN (
                'pending',
                'partial',
                'paid',
                'failed',
                'refunded'
            )
        ),
    notes TEXT,

    approved_at TIMESTAMPTZ,

    activated_at TIMESTAMPTZ,

    completed_at TIMESTAMPTZ,

    cancelled_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CHECK (
        maturity_date IS NULL
        OR maturity_date >= investment_date
    )
);



CREATE TABLE investment_unit_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    investment_id UUID NOT NULL
        REFERENCES investments(id)
        ON DELETE RESTRICT,
    transaction_type VARCHAR(30) NOT NULL
        CHECK (
            transaction_type IN (
                'purchase',
                'additional_purchase',
                'sell',
                'transfer_in',
                'transfer_out',
                'bonus',
                'adjustment'
            )
        ),
    units NUMERIC(18,4) NOT NULL
        CHECK (units > 0),
    unit_price NUMERIC(14,2)
        CHECK (
            unit_price IS NULL
            OR unit_price > 0
        ),
    amount NUMERIC(14,2)
        CHECK (
            amount IS NULL
            OR amount >= 0
        ),
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    reference_number VARCHAR(100) UNIQUE,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);



CREATE TABLE investment_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    investment_id UUID NOT NULL
        REFERENCES investments(id)
        ON DELETE RESTRICT,
    amount NUMERIC(14,2) NOT NULL
        CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',
    payment_method VARCHAR(50) NOT NULL,
    transaction_id VARCHAR(255) UNIQUE,
    gateway_transaction_id VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'processing',
                'paid',
                'failed',
                'refunded'
            )
        ),
    paid_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE investment_returns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    investment_id UUID NOT NULL
        REFERENCES investments(id)
        ON DELETE RESTRICT,
    return_type VARCHAR(30) NOT NULL
        CHECK (
            return_type IN (
                'profit',
                'dividend',
                'loss',
                'principal'
            )
        ),
    amount NUMERIC(14,2) NOT NULL
        CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',
    return_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'approved',
                'completed',
                'cancelled'
            )
        ),
    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);




CREATE TABLE investment_withdrawals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    investment_id UUID NOT NULL
        REFERENCES investments(id)
        ON DELETE RESTRICT,
    amount NUMERIC(14,2) NOT NULL
        CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',
    withdrawal_method VARCHAR(50),
    transaction_id VARCHAR(255) UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'processing',
                'completed',
                'failed',
                'cancelled'
            )
        ),
    requested_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    processed_at TIMESTAMPTZ,

    reason TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);



CREATE TABLE investment_documents_money (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    investment_id UUID NOT NULL
        REFERENCES investments(id)
        ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL
        CHECK (
            document_type IN (
                'agreement',
                'certificate',
                'invoice',
                'statement',
                'terms',
                'other'
            )
        ),
    title VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);



CREATE TABLE share_sell_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_investor_id UUID NOT NULL
        REFERENCES investor_profiles(id)
        ON DELETE RESTRICT,
    investment_id UUID NOT NULL
        REFERENCES investments(id)
       ON DELETE RESTRICT,
    investment_product_id UUID NOT NULL
        REFERENCES investment_products(id)
        ON DELETE RESTRICT,
    units_for_sale NUMERIC(18,4) NOT NULL
        CHECK (units_for_sale > 0),
    price_per_unit NUMERIC(14,2) NOT NULL
        CHECK (price_per_unit > 0),
    total_amount NUMERIC(14,2) NOT NULL
        CHECK (total_amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',
    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (
            status IN (
                'draft',
                'active',
                'partially_sold',
                'sold',
                'cancelled',
                'expired'
            )
        ),
    expires_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (
        total_amount = units_for_sale * price_per_unit
    )
);


CREATE TABLE share_purchase_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id UUID NOT NULL
        REFERENCES share_sell_listings(id)
        ON DELETE RESTRICT,
    buyer_investor_id UUID NOT NULL
        REFERENCES investor_profiles(id)
        ON DELETE RESTRICT,
    units NUMERIC(18,4) NOT NULL
        CHECK (units > 0),
    price_per_unit NUMERIC(14,2) NOT NULL
        CHECK (price_per_unit > 0),
    total_amount NUMERIC(14,2) NOT NULL
        CHECK (total_amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'accepted',
                'payment_pending',
                'paid',
                'completed',
                'rejected',
                'cancelled',
                'expired'
            )
        ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (
        total_amount = units * price_per_unit
    )
);


CREATE TABLE share_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_order_id UUID NOT NULL
        REFERENCES share_purchase_orders(id)
        ON DELETE RESTRICT,
    seller_investor_id UUID NOT NULL
        REFERENCES investor_profiles(id)
        ON DELETE RESTRICT,
    buyer_investor_id UUID NOT NULL
        REFERENCES investor_profiles(id)
        ON DELETE RESTRICT,
    investment_product_id UUID NOT NULL
        REFERENCES investment_products(id)
        ON DELETE RESTRICT,
    units NUMERIC(18,4) NOT NULL
        CHECK (units > 0),
    price_per_unit NUMERIC(14,2) NOT NULL
        CHECK (price_per_unit > 0),
    total_amount NUMERIC(14,2) NOT NULL
        CHECK (total_amount > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'processing',
                'completed',
                'failed',
                'cancelled'
            )
        ),
    transferred_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (
        seller_investor_id <> buyer_investor_id
    ),
    CHECK (
        total_amount = units * price_per_unit
    )
);



CREATE TABLE share_ownership_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    investor_id UUID NOT NULL
        REFERENCES investor_profiles(id)
        ON DELETE RESTRICT,
    investment_product_id UUID NOT NULL
        REFERENCES investment_products(id)
        ON DELETE RESTRICT,
    investment_id UUID
        REFERENCES investments(id)
        ON DELETE RESTRICT,
    transfer_id UUID
        REFERENCES share_transfers(id)
        ON DELETE RESTRICT,
    transaction_type VARCHAR(30) NOT NULL
        CHECK (
            transaction_type IN (
                'purchase',
                'transfer_in',
                'transfer_out',
                'bonus',
                'adjustment'
            )
        ),
    units NUMERIC(18,4) NOT NULL
        CHECK (units > 0),
    price_per_unit NUMERIC(14,2),
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reference_number VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);




CREATE TABLE investment_expense_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE RESTRICT,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(50) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (organization_id, code)
);







CREATE TABLE investment_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE RESTRICT,
    investment_product_id UUID NOT NULL
        REFERENCES investment_products(id)
        ON DELETE RESTRICT,
    investment_id UUID
        REFERENCES investments(id)
        ON DELETE RESTRICT,
    expense_category_id UUID NOT NULL
        REFERENCES investment_expense_categories(id)
        ON DELETE RESTRICT,
    financial_account_id UUID
        REFERENCES financial_accounts(id)
        ON DELETE RESTRICT,
    expense_number VARCHAR(50) NOT NULL,
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    amount NUMERIC(14,2) NOT NULL
        CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',
    payment_method VARCHAR(30)
        CHECK (
            payment_method IN (
                'cash',
                'bank',
                'mobile_wallet',
                'card',
                'other'
            )
        ),
    description TEXT,
    reference_number VARCHAR(100),
    journal_entry_id UUID,
    status VARCHAR(20) NOT NULL DEFAULT 'posted'
        CHECK (
            status IN (
                'draft',
                'posted',
                'cancelled'
            )
        ),
    created_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (organization_id, expense_number)
);







CREATE TABLE investment_income_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE RESTRICT,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(50) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (organization_id, code)
);





CREATE TABLE investment_income (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE RESTRICT,
    investment_product_id UUID NOT NULL
        REFERENCES investment_products(id)
        ON DELETE RESTRICT,
    investment_id UUID
        REFERENCES investments(id)
        ON DELETE RESTRICT,
    income_category_id UUID NOT NULL
        REFERENCES investment_income_categories(id)
        ON DELETE RESTRICT,
    financial_account_id UUID
        REFERENCES financial_accounts(id)
        ON DELETE RESTRICT,
    income_number VARCHAR(50) NOT NULL,
    income_date DATE NOT NULL DEFAULT CURRENT_DATE,
    amount NUMERIC(14,2) NOT NULL
        CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',
    payment_method VARCHAR(30)
        CHECK (
            payment_method IN (
                'cash',
                'bank',
                'mobile_wallet',
                'card',
                'other'
            )
        ),
    description TEXT,
    reference_number VARCHAR(100),
    journal_entry_id UUID,
    status VARCHAR(20) NOT NULL DEFAULT 'posted'
        CHECK (
            status IN (
                'draft',
                'posted',
                'cancelled'
            )
        ),

    created_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (organization_id, income_number)
);






CREATE TABLE investment_chart_of_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE RESTRICT,

    parent_id UUID
        REFERENCES chart_of_accounts(id)
        ON DELETE RESTRICT,

    account_code VARCHAR(30) NOT NULL,

    account_name VARCHAR(150) NOT NULL,

    account_type VARCHAR(30) NOT NULL
        CHECK (
            account_type IN (
                'asset',
                'liability',
                'equity',
                'income',
                'expense'
            )
        ),

    normal_balance VARCHAR(10) NOT NULL
        CHECK (
            normal_balance IN (
                'debit',
                'credit'
            )
        ),

    is_system_account BOOLEAN NOT NULL DEFAULT FALSE,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (organization_id, account_code)
);







CREATE TABLE investment_financial_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE RESTRICT,
    account_id UUID NOT NULL
        REFERENCES chart_of_accounts(id)
        ON DELETE RESTRICT,
    account_name VARCHAR(150) NOT NULL,
    account_type VARCHAR(30) NOT NULL
        CHECK (
            account_type IN (
                'cash',
                'bank',
                'mobile_wallet',
                'other'
            )
        ),
    bank_name VARCHAR(150),
    account_number VARCHAR(255),
    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',
    opening_balance NUMERIC(14,2) NOT NULL DEFAULT 0
        CHECK (opening_balance >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);



CREATE TABLE investment_journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE RESTRICT,

    reference_number VARCHAR(100) NOT NULL,

    transaction_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    transaction_type VARCHAR(40) NOT NULL
        CHECK (
            transaction_type IN (
                'investment',
                'investment_income',
                'investment_expense',
                'investment_payment',
                'investment_return',
                'withdrawal',
                'refund',
                'fee',
                'transfer',
                'adjustment'
            )
        ),

    description TEXT,

    status VARCHAR(20) NOT NULL DEFAULT 'posted'
        CHECK (
            status IN (
                'draft',
                'posted',
                'voided'
            )
        ),

    created_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (organization_id, reference_number)
);




CREATE TABLE investment_journal_entry_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    journal_entry_id UUID NOT NULL
        REFERENCES journal_entries(id)
        ON DELETE CASCADE,

    account_id UUID NOT NULL
        REFERENCES chart_of_accounts(id)
        ON DELETE RESTRICT,

    investment_product_id UUID
        REFERENCES investment_products(id)
        ON DELETE RESTRICT,

    investment_id UUID
        REFERENCES investments(id)
        ON DELETE RESTRICT,

    financial_account_id UUID
        REFERENCES financial_accounts(id)
        ON DELETE RESTRICT,

    description TEXT,

    debit NUMERIC(14,2) NOT NULL DEFAULT 0
        CHECK (debit >= 0),

    credit NUMERIC(14,2) NOT NULL DEFAULT 0
        CHECK (credit >= 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CHECK (
        NOT (debit > 0 AND credit > 0)
    ),

    CHECK (
        debit > 0 OR credit > 0
    )
);









//Savings Queryy

CREATE EXTENSION IF NOT EXISTS pgcrypto;

//Organization
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(200) NOT NULL,

    code VARCHAR(50) NOT NULL UNIQUE,

    description TEXT,

    phone VARCHAR(30),

    email VARCHAR(150),

    address TEXT,

    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (
            status IN ('active', 'inactive')
        ),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

//branches
CREATE TABLE branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE RESTRICT,

    branch_code VARCHAR(50) NOT NULL,

    name VARCHAR(150) NOT NULL,

    phone VARCHAR(30),

    email VARCHAR(150),

    address TEXT,

    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (
            status IN ('active', 'inactive')
        ),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (organization_id, branch_code)
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    branch_id UUID
        REFERENCES branches(id)
        ON DELETE SET NULL,

    name VARCHAR(150) NOT NULL,

    email VARCHAR(150) UNIQUE,

    phone VARCHAR(30) UNIQUE,

    username VARCHAR(100) NOT NULL UNIQUE,

    password_hash TEXT NOT NULL,

    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (
            status IN (
                'active',
                'inactive',
                'locked'
            )
        ),

    last_login_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(50) NOT NULL UNIQUE,

    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_roles (
    user_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    role_id UUID NOT NULL
        REFERENCES roles(id)
        ON DELETE CASCADE,

    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    customer_number VARCHAR(50) NOT NULL UNIQUE,

    first_name VARCHAR(100) NOT NULL,

    middle_name VARCHAR(100),

    last_name VARCHAR(100),

    date_of_birth DATE,

    gender VARCHAR(20)
        CHECK (
            gender IN (
                'male',
                'female',
                'other'
            )
        ),

    phone VARCHAR(30) NOT NULL,

    email VARCHAR(150),

    nid_number VARCHAR(100),

    occupation VARCHAR(150),

    nationality VARCHAR(100) NOT NULL DEFAULT 'Bangladeshi',

    status VARCHAR(30) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'active',
                'inactive',
                'blocked',
                'deceased'
            )
        ),

    kyc_status VARCHAR(30) NOT NULL DEFAULT 'pending'
        CHECK (
            kyc_status IN (
                'pending',
                'under_review',
                'verified',
                'rejected',
                'expired'
            )
        ),

    kyc_verified_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE customer_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    customer_id UUID NOT NULL
        REFERENCES customers(id)
        ON DELETE CASCADE,

    address_type VARCHAR(20) NOT NULL
        CHECK (
            address_type IN (
                'present',
                'permanent',
                'office',
                'other'
            )
        ),

    address_line_1 VARCHAR(255) NOT NULL,

    address_line_2 VARCHAR(255),

    village VARCHAR(150),

    post_office VARCHAR(150),

    upazila VARCHAR(150),

    district VARCHAR(150),

    division VARCHAR(150),

    postal_code VARCHAR(20),

    country VARCHAR(100) NOT NULL DEFAULT 'Bangladesh',

    is_primary BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customer_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    customer_id UUID NOT NULL
        REFERENCES customers(id)
        ON DELETE CASCADE,

    document_type VARCHAR(50) NOT NULL
        CHECK (
            document_type IN (
                'nid',
                'passport',
                'birth_certificate',
                'driving_license',
                'other'
            )
        ),

    document_number VARCHAR(100),

    document_url TEXT,

    is_verified BOOLEAN NOT NULL DEFAULT FALSE,

    verified_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    verified_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE savings_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id)
        ON DELETE RESTRICT,

    product_code VARCHAR(50) NOT NULL,

    product_name VARCHAR(150) NOT NULL,

    description TEXT,

    product_type VARCHAR(30) NOT NULL
        CHECK (
            product_type IN (
                'savings',
                'dps',
                'term_deposit'
            )
        ),

    contract_type VARCHAR(30) NOT NULL
        CHECK (
            contract_type IN (
                'mudaraba',
                'wadiah'
            )
        ),

    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',

    minimum_opening_amount NUMERIC(18,2) NOT NULL DEFAULT 0
        CHECK (minimum_opening_amount >= 0),

    minimum_balance NUMERIC(18,2) NOT NULL DEFAULT 0
        CHECK (minimum_balance >= 0),

    withdrawal_allowed BOOLEAN NOT NULL DEFAULT TRUE,

    profit_enabled BOOLEAN NOT NULL DEFAULT FALSE,

    duration_months INTEGER
        CHECK (
            duration_months IS NULL
            OR duration_months > 0
        ),

    installment_amount NUMERIC(18,2)
        CHECK (
            installment_amount IS NULL
            OR installment_amount > 0
        ),

    status VARCHAR(20) NOT NULL DEFAULT 'draft'
        CHECK (
            status IN (
                'draft',
                'active',
                'inactive',
                'closed'
            )
        ),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (organization_id, product_code)
);

CREATE TABLE savings_product_profit_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    savings_product_id UUID NOT NULL
        REFERENCES savings_products(id)
        ON DELETE RESTRICT,

    effective_from DATE NOT NULL,

    effective_to DATE,

    depositor_profit_share NUMERIC(7,4) NOT NULL
        CHECK (
            depositor_profit_share >= 0
            AND depositor_profit_share <= 100
        ),

    bank_profit_share NUMERIC(7,4) NOT NULL
        CHECK (
            bank_profit_share >= 0
            AND bank_profit_share <= 100
        ),

    description TEXT,

    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (
            status IN (
                'draft',
                'active',
                'expired',
                'cancelled'
            )
        ),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CHECK (
        effective_to IS NULL
        OR effective_to >= effective_from
    ),

    CHECK (
        depositor_profit_share + bank_profit_share = 100
    )
);

CREATE TABLE savings_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    account_number VARCHAR(50) NOT NULL UNIQUE,

    customer_id UUID NOT NULL
        REFERENCES customers(id)
        ON DELETE RESTRICT,

    savings_product_id UUID NOT NULL
        REFERENCES savings_products(id)
        ON DELETE RESTRICT,

    branch_id UUID NOT NULL
        REFERENCES branches(id)
        ON DELETE RESTRICT,

    account_name VARCHAR(255) NOT NULL,

    currency VARCHAR(3) NOT NULL DEFAULT 'BDT',

    opening_date DATE NOT NULL DEFAULT CURRENT_DATE,

    maturity_date DATE,

    ledger_balance NUMERIC(18,2) NOT NULL DEFAULT 0
        CHECK (ledger_balance >= 0),

    available_balance NUMERIC(18,2) NOT NULL DEFAULT 0
        CHECK (available_balance >= 0),

    blocked_amount NUMERIC(18,2) NOT NULL DEFAULT 0
        CHECK (blocked_amount >= 0),

    status VARCHAR(30) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'active',
                'dormant',
                'blocked',
                'closed'
            )
        ),

    closed_at TIMESTAMPTZ,

    closing_reason TEXT,

    created_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CHECK (
        available_balance <= ledger_balance
    ),

    CHECK (
        maturity_date IS NULL
        OR maturity_date >= opening_date
    )
);

CREATE TABLE savings_account_holders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    savings_account_id UUID NOT NULL
        REFERENCES savings_accounts(id)
        ON DELETE RESTRICT,

    customer_id UUID NOT NULL
        REFERENCES customers(id)
        ON DELETE RESTRICT,

    holder_type VARCHAR(20) NOT NULL DEFAULT 'primary'
        CHECK (
            holder_type IN (
                'primary',
                'joint'
            )
        ),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (
        savings_account_id,
        customer_id
    )
);

CREATE TABLE savings_account_nominees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    savings_account_id UUID NOT NULL
        REFERENCES savings_accounts(id)
        ON DELETE RESTRICT,

    name VARCHAR(255) NOT NULL,

    relationship VARCHAR(100),

    date_of_birth DATE,

    nid_number VARCHAR(100),

    phone VARCHAR(30),

    address TEXT,

    percentage NUMERIC(7,4) NOT NULL
        CHECK (
            percentage > 0
            AND percentage <= 100
        ),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE savings_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    transaction_number VARCHAR(60) NOT NULL UNIQUE,

    savings_account_id UUID NOT NULL
        REFERENCES savings_accounts(id)
        ON DELETE RESTRICT,

    transaction_type VARCHAR(30) NOT NULL
        CHECK (
            transaction_type IN (
                'deposit',
                'withdrawal',
                'transfer_in',
                'transfer_out',
                'profit',
                'fee',
                'adjustment',
                'reversal'
            )
        ),

    channel VARCHAR(30) NOT NULL
        CHECK (
            channel IN (
                'branch',
                'atm',
                'mobile_app',
                'internet_banking',
                'agent',
                'system',
                'api'
            )
        ),

    amount NUMERIC(18,2) NOT NULL
        CHECK (amount > 0),

    balance_before NUMERIC(18,2) NOT NULL,

    balance_after NUMERIC(18,2) NOT NULL,

    reference_number VARCHAR(100),

    description TEXT,

    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'processing',
                'completed',
                'failed',
                'reversed',
                'cancelled'
            )
        ),

    transaction_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    created_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE savings_deposits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    transaction_id UUID NOT NULL UNIQUE
        REFERENCES savings_transactions(id)
        ON DELETE RESTRICT,

    payment_method VARCHAR(30) NOT NULL
        CHECK (
            payment_method IN (
                'cash',
                'bank_transfer',
                'cheque',
                'mobile_banking',
                'card'
            )
        ),

    cheque_number VARCHAR(100),

    bank_name VARCHAR(150),

    external_transaction_number VARCHAR(150),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE savings_withdrawals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    transaction_id UUID NOT NULL UNIQUE
        REFERENCES savings_transactions(id)
        ON DELETE RESTRICT,

    withdrawal_method VARCHAR(30) NOT NULL
        CHECK (
            withdrawal_method IN (
                'cash',
                'bank_transfer',
                'mobile_banking'
            )
        ),

    requested_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    approved_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    approved_at TIMESTAMPTZ,

    remarks TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE savings_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    reference_number VARCHAR(100) NOT NULL UNIQUE,

    from_account_id UUID NOT NULL
        REFERENCES savings_accounts(id)
        ON DELETE RESTRICT,

    to_account_id UUID NOT NULL
        REFERENCES savings_accounts(id)
        ON DELETE RESTRICT,

    amount NUMERIC(18,2) NOT NULL
        CHECK (amount > 0),

    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'processing',
                'completed',
                'failed',
                'reversed',
                'cancelled'
            )
        ),

    initiated_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    completed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CHECK (
        from_account_id <> to_account_id
    )
);

CREATE TABLE account_holds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    savings_account_id UUID NOT NULL
        REFERENCES savings_accounts(id)
        ON DELETE RESTRICT,

    amount NUMERIC(18,2) NOT NULL
        CHECK (amount > 0),

    reason TEXT,

    reference_number VARCHAR(100),

    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (
            status IN (
                'active',
                'released',
                'expired',
                'cancelled'
            )
        ),

    held_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    released_at TIMESTAMPTZ
);

CREATE TABLE profit_pools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    pool_number VARCHAR(60) NOT NULL UNIQUE,

    name VARCHAR(150) NOT NULL,

    description TEXT,

    period_start DATE NOT NULL,

    period_end DATE NOT NULL,

    total_funds NUMERIC(18,2) NOT NULL DEFAULT 0
        CHECK (total_funds >= 0),

    gross_profit NUMERIC(18,2) NOT NULL DEFAULT 0
        CHECK (gross_profit >= 0),

    expenses NUMERIC(18,2) NOT NULL DEFAULT 0
        CHECK (expenses >= 0),

    distributable_profit NUMERIC(18,2) NOT NULL DEFAULT 0
        CHECK (distributable_profit >= 0),

    status VARCHAR(20) NOT NULL DEFAULT 'open'
        CHECK (
            status IN (
                'open',
                'calculating',
                'calculated',
                'distributed',
                'closed'
            )
        ),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CHECK (
        period_end >= period_start
    )
);

CREATE TABLE profit_pool_contributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    profit_pool_id UUID NOT NULL
        REFERENCES profit_pools(id)
        ON DELETE RESTRICT,

    savings_account_id UUID NOT NULL
        REFERENCES savings_accounts(id)
        ON DELETE RESTRICT,

    eligible_balance NUMERIC(18,2) NOT NULL
        CHECK (eligible_balance >= 0),

    weight NUMERIC(18,8) NOT NULL
        CHECK (weight >= 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (
        profit_pool_id,
        savings_account_id
    )
);

CREATE TABLE profit_calculations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    profit_pool_id UUID NOT NULL
        REFERENCES profit_pools(id)
        ON DELETE RESTRICT,

    savings_account_id UUID NOT NULL
        REFERENCES savings_accounts(id)
        ON DELETE RESTRICT,

    eligible_balance NUMERIC(18,2) NOT NULL
        CHECK (eligible_balance >= 0),

    weight NUMERIC(18,8) NOT NULL
        CHECK (weight >= 0),

    profit_share_ratio NUMERIC(7,4) NOT NULL
        CHECK (
            profit_share_ratio >= 0
            AND profit_share_ratio <= 100
        ),

    calculated_profit NUMERIC(18,2) NOT NULL
        CHECK (calculated_profit >= 0),

    status VARCHAR(20) NOT NULL DEFAULT 'calculated'
        CHECK (
            status IN (
                'calculated',
                'approved',
                'posted',
                'cancelled'
            )
        ),

    calculated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    approved_at TIMESTAMPTZ,

    approved_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL
);

CREATE TABLE profit_distributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    profit_calculation_id UUID NOT NULL UNIQUE
        REFERENCES profit_calculations(id)
        ON DELETE RESTRICT,

    savings_transaction_id UUID
        REFERENCES savings_transactions(id)
        ON DELETE RESTRICT,

    amount NUMERIC(18,2) NOT NULL
        CHECK (amount > 0),

    distribution_date DATE NOT NULL DEFAULT CURRENT_DATE,

    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'posted',
                'cancelled'
            )
        ),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE fee_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(100) NOT NULL,

    code VARCHAR(50) NOT NULL UNIQUE,

    description TEXT,

    calculation_type VARCHAR(20) NOT NULL
        CHECK (
            calculation_type IN (
                'fixed',
                'percentage'
            )
        ),

    amount NUMERIC(18,2)
        CHECK (
            amount IS NULL
            OR amount >= 0
        ),

    percentage NUMERIC(7,4)
        CHECK (
            percentage IS NULL
            OR (
                percentage >= 0
                AND percentage <= 100
            )
        ),

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE account_fees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    savings_account_id UUID NOT NULL
        REFERENCES savings_accounts(id)
        ON DELETE RESTRICT,

    fee_type_id UUID NOT NULL
        REFERENCES fee_types(id)
        ON DELETE RESTRICT,

    transaction_id UUID
        REFERENCES savings_transactions(id)
        ON DELETE RESTRICT,

    amount NUMERIC(18,2) NOT NULL
        CHECK (amount > 0),

    status VARCHAR(20) NOT NULL DEFAULT 'posted'
        CHECK (
            status IN (
                'pending',
                'posted',
                'cancelled'
            )
        ),

    charged_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE accounting_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    account_code VARCHAR(50) NOT NULL UNIQUE,

    account_name VARCHAR(150) NOT NULL,

    account_type VARCHAR(20) NOT NULL
        CHECK (
            account_type IN (
                'asset',
                'liability',
                'equity',
                'income',
                'expense'
            )
        ),

    parent_id UUID
        REFERENCES accounting_accounts(id)
        ON DELETE RESTRICT,

    is_system_account BOOLEAN NOT NULL DEFAULT FALSE,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    reference_number VARCHAR(100) NOT NULL UNIQUE,

    transaction_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    description TEXT,

    source_type VARCHAR(50),

    source_id UUID,

    status VARCHAR(20) NOT NULL DEFAULT 'posted'
        CHECK (
            status IN (
                'draft',
                'posted',
                'voided'
            )
        ),

    created_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE journal_entry_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    journal_entry_id UUID NOT NULL
        REFERENCES journal_entries(id)
        ON DELETE CASCADE,

    accounting_account_id UUID NOT NULL
        REFERENCES accounting_accounts(id)
        ON DELETE RESTRICT,

    description TEXT,

    debit NUMERIC(18,2) NOT NULL DEFAULT 0
        CHECK (debit >= 0),

    credit NUMERIC(18,2) NOT NULL DEFAULT 0
        CHECK (credit >= 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CHECK (
        NOT (
            debit > 0
            AND credit > 0
        )
    ),

    CHECK (
        debit > 0
        OR credit > 0
    )
);

CREATE TABLE transaction_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    transaction_id UUID NOT NULL
        REFERENCES savings_transactions(id)
        ON DELETE RESTRICT,

    requested_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    approved_by UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'approved',
                'rejected',
                'cancelled'
            )
        ),

    remarks TEXT,

    requested_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    approved_at TIMESTAMPTZ
);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    action VARCHAR(100) NOT NULL,

    table_name VARCHAR(100),

    record_id UUID,

    old_data JSONB,

    new_data JSONB,

    ip_address INET,

    user_agent TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

