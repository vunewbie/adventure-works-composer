-- =============================================================
-- Purchasing.ProductVendor
-- =============================================================
DROP TABLE IF EXISTS purchasing.product_vendor;
CREATE TABLE purchasing.product_vendor (
    product_id BIGINT NOT NULL,
    business_entity_id BIGINT NOT NULL,
    average_lead_time INTEGER NOT NULL DEFAULT 0,
    standard_price NUMERIC(19,4) NOT NULL,
    last_receipt_cost NUMERIC(19,4),
    last_receipt_date DATE,
    min_order_qty INTEGER NOT NULL DEFAULT 0,
    max_order_qty INTEGER NOT NULL DEFAULT 0,
    on_order_qty INTEGER,
    unit_measure_code CHAR(3),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (product_id, business_entity_id)
);

-- =============================================================
-- Purchasing.PurchaseOrderDetail
-- =============================================================
DROP TABLE IF EXISTS purchasing.purchase_order_detail;
CREATE TABLE purchasing.purchase_order_detail (
    purchase_order_id BIGINT NOT NULL,
    purchase_order_detail_id BIGSERIAL,
    due_date TIMESTAMPTZ NOT NULL,
    order_qty SMALLINT NOT NULL,
    product_id BIGINT NOT NULL,
    unit_price NUMERIC(19,4) NOT NULL,
    line_total NUMERIC(19,4) NOT NULL DEFAULT 0,
    received_qty NUMERIC(8,2) NOT NULL DEFAULT 0,
    rejected_qty NUMERIC(8,2) NOT NULL DEFAULT 0,
    stocked_qty NUMERIC(8,2) NOT NULL DEFAULT 0,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (purchase_order_id, purchase_order_detail_id)
);

-- =============================================================
-- Purchasing.PurchaseOrderHeader
-- =============================================================
DROP TABLE IF EXISTS purchasing.purchase_order_header;
CREATE TABLE purchasing.purchase_order_header (
    purchase_order_id BIGSERIAL PRIMARY KEY,
    revision_number SMALLINT NOT NULL DEFAULT 0,
    status SMALLINT NOT NULL DEFAULT 1,
    employee_id BIGINT NOT NULL,
    vendor_id BIGINT NOT NULL,
    ship_method_id INTEGER NOT NULL,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    ship_date DATE,
    subtotal NUMERIC(19,4) NOT NULL DEFAULT 0,
    tax_amt NUMERIC(19,4) NOT NULL DEFAULT 0,
    freight NUMERIC(19,4) NOT NULL DEFAULT 0,
    total_due NUMERIC(19,4) NOT NULL DEFAULT 0,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Purchasing.ShipMethod
-- =============================================================
DROP TABLE IF EXISTS purchasing.ship_method;
CREATE TABLE purchasing.ship_method (
    ship_method_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    ship_base NUMERIC(19,4) NOT NULL DEFAULT 0,
    ship_rate NUMERIC(19,4) NOT NULL DEFAULT 0,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Purchasing.Vendor
-- =============================================================
DROP TABLE IF EXISTS purchasing.vendor;
CREATE TABLE purchasing.vendor (
    business_entity_id BIGINT PRIMARY KEY,
    account_number VARCHAR(15) NOT NULL,
    name VARCHAR(50) NOT NULL,
    credit_rating SMALLINT NOT NULL DEFAULT 1,
    preferred_vendor_status BOOLEAN NOT NULL DEFAULT TRUE,
    active_flag BOOLEAN NOT NULL DEFAULT TRUE,
    purchasing_web_service_url TEXT,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

