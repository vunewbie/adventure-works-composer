-- =============================================================
-- Production.BillOfMaterials
-- =============================================================
DROP TABLE IF EXISTS production.bill_of_materials;
CREATE TABLE production.bill_of_materials (
    bill_of_materials_id BIGSERIAL PRIMARY KEY,
    product_assembly_id INTEGER,
    component_id INTEGER NOT NULL,
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    unit_measure_code CHAR(3) NOT NULL,
    bom_level SMALLINT NOT NULL DEFAULT 0,
    per_assembly_qty NUMERIC(8,2) NOT NULL DEFAULT 1.00,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.Culture
-- =============================================================
DROP TABLE IF EXISTS production.culture;
CREATE TABLE production.culture (
    culture_id CHAR(6) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.Document
-- =============================================================
DROP TABLE IF EXISTS production.document;
CREATE TABLE production.document (
    document_node BYTEA PRIMARY KEY,
    document_level SMALLINT,
    title VARCHAR(50) NOT NULL,
    owner_id INTEGER NOT NULL,
    folder_flag BOOLEAN NOT NULL DEFAULT FALSE,
    file_name VARCHAR(400) NOT NULL,
    file_extension VARCHAR(8),
    revision CHAR(5) NOT NULL,
    change_number INTEGER NOT NULL DEFAULT 0,
    status SMALLINT NOT NULL DEFAULT 1,
    document_summary TEXT,
    document_content BYTEA,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.Illustration
-- =============================================================
DROP TABLE IF EXISTS production.illustration;
CREATE TABLE production.illustration (
    illustration_id BIGSERIAL PRIMARY KEY,
    diagram TEXT,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.Location
-- =============================================================
DROP TABLE IF EXISTS production.location;
CREATE TABLE production.location (
    location_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    cost_rate NUMERIC(10,4) NOT NULL DEFAULT 0,
    availability NUMERIC(8,2) NOT NULL DEFAULT 0,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.Product
-- =============================================================
DROP TABLE IF EXISTS production.product;
CREATE TABLE production.product (
    product_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    product_number VARCHAR(25) NOT NULL,
    make_flag BOOLEAN NOT NULL DEFAULT TRUE,
    finished_goods_flag BOOLEAN NOT NULL DEFAULT TRUE,
    color VARCHAR(15),
    safety_stock_level SMALLINT NOT NULL DEFAULT 0,
    reorder_point SMALLINT NOT NULL DEFAULT 0,
    standard_cost NUMERIC(19,4) NOT NULL DEFAULT 0,
    list_price NUMERIC(19,4) NOT NULL DEFAULT 0,
    size VARCHAR(5),
    size_unit_measure_code CHAR(3),
    weight_unit_measure_code CHAR(3),
    weight NUMERIC(8,2),
    days_to_manufacture INTEGER NOT NULL DEFAULT 0,
    product_line CHAR(2),
    class CHAR(2),
    style CHAR(2),
    product_subcategory_id INTEGER,
    product_model_id INTEGER,
    sell_start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    sell_end_date DATE,
    discontinued_date DATE,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.ProductCategory
-- =============================================================
DROP TABLE IF EXISTS production.product_category;
CREATE TABLE production.product_category (
    product_category_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.ProductCostHistory
-- =============================================================
DROP TABLE IF EXISTS production.product_cost_history;
CREATE TABLE production.product_cost_history (
    product_id BIGINT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    standard_cost NUMERIC(19,4) NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (product_id, start_date)
);

-- =============================================================
-- Production.ProductDescription
-- =============================================================
DROP TABLE IF EXISTS production.product_description;
CREATE TABLE production.product_description (
    product_description_id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.ProductDocument
-- =============================================================
DROP TABLE IF EXISTS production.product_document;
CREATE TABLE production.product_document (
    product_id BIGINT NOT NULL,
    document_node BYTEA NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (product_id, document_node)
);

-- =============================================================
-- Production.ProductInventory
-- =============================================================
DROP TABLE IF EXISTS production.product_inventory;
CREATE TABLE production.product_inventory (
    product_id BIGINT NOT NULL,
    location_id INTEGER NOT NULL,
    shelf VARCHAR(10) NOT NULL,
    bin SMALLINT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (product_id, location_id, shelf, bin)
);

-- =============================================================
-- Production.ProductListPriceHistory
-- =============================================================
DROP TABLE IF EXISTS production.product_list_price_history;
CREATE TABLE production.product_list_price_history (
    product_id BIGINT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    list_price NUMERIC(19,4) NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (product_id, start_date)
);

-- =============================================================
-- Production.ProductModel
-- =============================================================
DROP TABLE IF EXISTS production.product_model;
CREATE TABLE production.product_model (
    product_model_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    catalog_description XML,
    instructions XML,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.ProductModelIllustration
-- =============================================================
DROP TABLE IF EXISTS production.product_model_illustration;
CREATE TABLE production.product_model_illustration (
    product_model_id INTEGER NOT NULL,
    illustration_id INTEGER NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (product_model_id, illustration_id)
);

-- =============================================================
-- Production.ProductModelProductDescriptionCulture
-- =============================================================
DROP TABLE IF EXISTS production.product_model_product_description_culture;
CREATE TABLE production.product_model_product_description_culture (
    product_model_id INTEGER NOT NULL,
    product_description_id INTEGER NOT NULL,
    culture_id CHAR(6) NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (product_model_id, product_description_id, culture_id)
);

-- =============================================================
-- Production.ProductPhoto
-- =============================================================
DROP TABLE IF EXISTS production.product_photo;
CREATE TABLE production.product_photo (
    product_photo_id BIGSERIAL PRIMARY KEY,
    thumbnail_photo BYTEA,
    thumbnail_photo_file_name VARCHAR(50),
    large_photo BYTEA,
    large_photo_file_name VARCHAR(50),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.ProductProductPhoto
-- =============================================================
DROP TABLE IF EXISTS production.product_product_photo;
CREATE TABLE production.product_product_photo (
    product_id BIGINT NOT NULL,
    product_photo_id BIGINT NOT NULL,
    primary_photo_flag BOOLEAN NOT NULL DEFAULT FALSE,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (product_id, product_photo_id)
);

-- =============================================================
-- Production.ProductReview
-- =============================================================
DROP TABLE IF EXISTS production.product_review;
CREATE TABLE production.product_review (
    product_review_id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    reviewer_name VARCHAR(50) NOT NULL,
    review_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    email_address VARCHAR(50) NOT NULL,
    rating SMALLINT NOT NULL,
    comments TEXT,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.ProductSubcategory
-- =============================================================
DROP TABLE IF EXISTS production.product_subcategory;
CREATE TABLE production.product_subcategory (
    product_subcategory_id SERIAL PRIMARY KEY,
    product_category_id INTEGER NOT NULL,
    name VARCHAR(50) NOT NULL,
    rowguid UUID NOT NULL DEFAULT gen_random_uuid(),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.ScrapReason
-- =============================================================
DROP TABLE IF EXISTS production.scrap_reason;
CREATE TABLE production.scrap_reason (
    scrap_reason_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.TransactionHistory
-- =============================================================
DROP TABLE IF EXISTS production.transaction_history;
CREATE TABLE production.transaction_history (
    transaction_id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    reference_order_id BIGINT NOT NULL,
    reference_order_line_id INTEGER NOT NULL,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    transaction_type CHAR(1) NOT NULL,
    quantity INTEGER NOT NULL,
    actual_cost NUMERIC(19,4) NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.TransactionHistoryArchive
-- =============================================================
DROP TABLE IF EXISTS production.transaction_history_archive;
CREATE TABLE production.transaction_history_archive (
    transaction_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    reference_order_id BIGINT NOT NULL,
    reference_order_line_id INTEGER NOT NULL,
    transaction_date DATE NOT NULL,
    transaction_type CHAR(1) NOT NULL,
    quantity INTEGER NOT NULL,
    actual_cost NUMERIC(19,4) NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.UnitMeasure
-- =============================================================
DROP TABLE IF EXISTS production.unit_measure;
CREATE TABLE production.unit_measure (
    unit_measure_code CHAR(3) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.WorkOrder
-- =============================================================
DROP TABLE IF EXISTS production.work_order;
CREATE TABLE production.work_order (
    work_order_id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    order_qty INTEGER NOT NULL,
    stocked_qty INTEGER NOT NULL DEFAULT 0,
    scrap_qty INTEGER NOT NULL DEFAULT 0,
    start_date DATE NOT NULL,
    end_date DATE,
    due_date DATE NOT NULL,
    scrap_reason_id INTEGER,
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- Production.WorkOrderRouting
-- =============================================================
DROP TABLE IF EXISTS production.work_order_routing;
CREATE TABLE production.work_order_routing (
    work_order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    operation_sequence SMALLINT NOT NULL,
    location_id INTEGER NOT NULL,
    scheduled_start_date TIMESTAMPTZ NOT NULL,
    scheduled_end_date TIMESTAMPTZ NOT NULL,
    actual_start_date TIMESTAMPTZ,
    actual_end_date TIMESTAMPTZ,
    actual_resource_hrs NUMERIC(9,4),
    planned_cost NUMERIC(19,4),
    actual_cost NUMERIC(19,4),
    modified_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (work_order_id, product_id, operation_sequence)
);

