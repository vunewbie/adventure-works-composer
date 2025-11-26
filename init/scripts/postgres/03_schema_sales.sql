-- =============================================================
-- Sales.CountryRegionCurrency
-- =============================================================
DROP TABLE IF EXISTS sales.country_region_currency;
CREATE TABLE sales.country_region_currency (
    country_region_code VARCHAR(3) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (country_region_code, currency_code)
);

-- =============================================================
-- Sales.CreditCard
-- =============================================================
DROP TABLE IF EXISTS sales.credit_card;
CREATE TABLE sales.credit_card (
    credit_card_id BIGSERIAL PRIMARY KEY,
    card_type VARCHAR(50) NOT NULL,
    card_number VARCHAR(25) NOT NULL,
    exp_month SMALLINT NOT NULL,
    exp_year SMALLINT NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Sales.Currency
-- =============================================================
DROP TABLE IF EXISTS sales.currency;
CREATE TABLE sales.currency (
    currency_code CHAR(3) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Sales.CurrencyRate
-- =============================================================
DROP TABLE IF EXISTS sales.currency_rate;
CREATE TABLE sales.currency_rate (
    currency_rate_id BIGSERIAL PRIMARY KEY,
    currency_rate_date DATE NOT NULL,
    from_currency_code CHAR(3) NOT NULL,
    to_currency_code CHAR(3) NOT NULL,
    average_rate NUMERIC(19,4) NOT NULL,
    end_of_day_rate NUMERIC(19,4) NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Sales.Customer
-- =============================================================
DROP TABLE IF EXISTS sales.customer;
CREATE TABLE sales.customer (
    customer_id BIGSERIAL PRIMARY KEY,
    person_id BIGINT,
    store_id BIGINT,
    territory_id INTEGER,
    account_number VARCHAR(15) NOT NULL,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Sales.PersonCreditCard
-- =============================================================
DROP TABLE IF EXISTS sales.person_credit_card;
CREATE TABLE sales.person_credit_card (
    business_entity_id BIGINT NOT NULL,
    credit_card_id BIGINT NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (business_entity_id, credit_card_id)
);

-- =============================================================
-- Sales.SalesOrderDetail
-- =============================================================
DROP TABLE IF EXISTS sales.sales_order_detail;
CREATE TABLE sales.sales_order_detail (
    sales_order_id BIGINT NOT NULL,
    sales_order_detail_id BIGSERIAL,
    carrier_tracking_number VARCHAR(25),
    order_qty SMALLINT NOT NULL,
    product_id BIGINT NOT NULL,
    special_offer_id INTEGER NOT NULL,
    unit_price NUMERIC(19,4) NOT NULL,
    unit_price_discount NUMERIC(8,4) NOT NULL DEFAULT 0,
    line_total NUMERIC(19,4) NOT NULL DEFAULT 0,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (sales_order_id, sales_order_detail_id)
);

-- =============================================================
-- Sales.SalesOrderHeader
-- =============================================================
DROP TABLE IF EXISTS sales.sales_order_header;
CREATE TABLE sales.sales_order_header (
    sales_order_id BIGSERIAL PRIMARY KEY,
    revision_number SMALLINT NOT NULL DEFAULT 0,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    ship_date DATE,
    status SMALLINT NOT NULL DEFAULT 1,
    online_order_flag BOOLEAN NOT NULL DEFAULT TRUE,
    sales_order_number VARCHAR(25) NOT NULL,
    purchase_order_number VARCHAR(25),
    account_number VARCHAR(25),
    customer_id BIGINT NOT NULL,
    salesperson_id BIGINT,
    territory_id INTEGER,
    bill_to_address_id BIGINT NOT NULL,
    ship_to_address_id BIGINT NOT NULL,
    ship_method_id INTEGER NOT NULL,
    credit_card_id BIGINT,
    credit_card_approval_code VARCHAR(15),
    currency_rate_id BIGINT,
    subtotal NUMERIC(19,4) NOT NULL DEFAULT 0,
    tax_amt NUMERIC(19,4) NOT NULL DEFAULT 0,
    freight NUMERIC(19,4) NOT NULL DEFAULT 0,
    total_due NUMERIC(19,4) NOT NULL DEFAULT 0,
    comment TEXT,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Sales.SalesOrderHeaderSalesReason
-- =============================================================
DROP TABLE IF EXISTS sales.sales_order_header_sales_reason;
CREATE TABLE sales.sales_order_header_sales_reason (
    sales_order_id BIGINT NOT NULL,
    sales_reason_id INTEGER NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (sales_order_id, sales_reason_id)
);

-- =============================================================
-- Sales.SalesPerson
-- =============================================================
DROP TABLE IF EXISTS sales.sales_person;
CREATE TABLE sales.sales_person (
    business_entity_id BIGINT PRIMARY KEY,
    territory_id INTEGER,
    sales_quota NUMERIC(19,4),
    bonus NUMERIC(19,4) NOT NULL DEFAULT 0,
    commission_pct NUMERIC(10,4) NOT NULL DEFAULT 0,
    sales_ytd NUMERIC(19,4) NOT NULL DEFAULT 0,
    sales_last_year NUMERIC(19,4) NOT NULL DEFAULT 0,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Sales.SalesPersonQuotaHistory
-- =============================================================
DROP TABLE IF EXISTS sales.sales_person_quota_history;
CREATE TABLE sales.sales_person_quota_history (
    business_entity_id BIGINT NOT NULL,
    quota_date DATE NOT NULL,
    sales_quota NUMERIC(19,4) NOT NULL,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (business_entity_id, quota_date)
);

-- =============================================================
-- Sales.SalesReason
-- =============================================================
DROP TABLE IF EXISTS sales.sales_reason;
CREATE TABLE sales.sales_reason (
    sales_reason_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    reason_type VARCHAR(50) NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Sales.SalesTaxRate
-- =============================================================
DROP TABLE IF EXISTS sales.sales_tax_rate;
CREATE TABLE sales.sales_tax_rate (
    sales_tax_rate_id SERIAL PRIMARY KEY,
    state_province_id INTEGER NOT NULL,
    tax_type SMALLINT NOT NULL,
    tax_rate NUMERIC(10,4) NOT NULL,
    name VARCHAR(50),
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Sales.SalesTerritory
-- =============================================================
DROP TABLE IF EXISTS sales.sales_territory;
CREATE TABLE sales.sales_territory (
    territory_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    country_region_code VARCHAR(3) NOT NULL,
    group_name VARCHAR(50) NOT NULL,
    sales_ytd NUMERIC(19,4) NOT NULL DEFAULT 0,
    sales_last_year NUMERIC(19,4) NOT NULL DEFAULT 0,
    cost_ytd NUMERIC(19,4) NOT NULL DEFAULT 0,
    cost_last_year NUMERIC(19,4) NOT NULL DEFAULT 0,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Sales.SalesTerritoryHistory
-- =============================================================
DROP TABLE IF EXISTS sales.sales_territory_history;
CREATE TABLE sales.sales_territory_history (
    business_entity_id BIGINT NOT NULL,
    territory_id INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (business_entity_id, territory_id, start_date)
);

-- =============================================================
-- Sales.ShoppingCartItem
-- =============================================================
DROP TABLE IF EXISTS sales.shopping_cart_item;
CREATE TABLE sales.shopping_cart_item (
    shopping_cart_item_id BIGSERIAL PRIMARY KEY,
    shopping_cart_id VARCHAR(50) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    product_id BIGINT NOT NULL,
    date_created TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Sales.SpecialOffer
-- =============================================================
DROP TABLE IF EXISTS sales.special_offer;
CREATE TABLE sales.special_offer (
    special_offer_id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    discount_pct NUMERIC(10,4) NOT NULL DEFAULT 0,
    type VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    min_qty INTEGER NOT NULL DEFAULT 0,
    max_qty INTEGER,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Sales.SpecialOfferProduct
-- =============================================================
DROP TABLE IF EXISTS sales.special_offer_product;
CREATE TABLE sales.special_offer_product (
    special_offer_id INTEGER NOT NULL,
    product_id BIGINT NOT NULL,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (special_offer_id, product_id)
);

-- =============================================================
-- Sales.Store
-- =============================================================
DROP TABLE IF EXISTS sales.store;
CREATE TABLE sales.store (
    business_entity_id BIGINT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    sales_person_id BIGINT,
    demographics TEXT,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

