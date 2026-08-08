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
//account

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




//investing






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
    investor_id UUID NOT NULL
        REFERENCES investor_profiles(id)
        ON DELETE RESTRICT,
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


