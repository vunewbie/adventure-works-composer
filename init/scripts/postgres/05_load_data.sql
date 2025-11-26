-- =============================================================
-- Load Operations Data (Production, Purchasing, Sales)
-- Source CSVs: /init/data/postgresql
-- =============================================================

DO $$
BEGIN
    RAISE NOTICE 'Loading Production schema data...';
END $$;

-- Production: Base tables
COPY production.unit_measure FROM '/init/data/postgresql/Production_UnitMeasure.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.culture FROM '/init/data/postgresql/Production_Culture.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.location FROM '/init/data/postgresql/Production_Location.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.scrap_reason FROM '/init/data/postgresql/Production_ScrapReason.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.product_category FROM '/init/data/postgresql/Production_ProductCategory.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.product_model FROM '/init/data/postgresql/Production_ProductModel.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.illustration FROM '/init/data/postgresql/Production_Illustration.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.product_description FROM '/init/data/postgresql/Production_ProductDescription.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.product_photo FROM '/init/data/postgresql/Production_ProductPhoto.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.document FROM '/init/data/postgresql/Production_Document.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- Production: Dependent tables
COPY production.product_subcategory FROM '/init/data/postgresql/Production_ProductSubcategory.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.product FROM '/init/data/postgresql/Production_Product.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.product_cost_history FROM '/init/data/postgresql/Production_ProductCostHistory.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.product_list_price_history FROM '/init/data/postgresql/Production_ProductListPriceHistory.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.product_inventory FROM '/init/data/postgresql/Production_ProductInventory.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.product_document FROM '/init/data/postgresql/Production_ProductDocument.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.product_product_photo FROM '/init/data/postgresql/Production_ProductProductPhoto.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.product_review FROM '/init/data/postgresql/Production_ProductReview.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.product_model_illustration FROM '/init/data/postgresql/Production_ProductModelIllustration.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.product_model_product_description_culture FROM '/init/data/postgresql/Production_ProductModelProductDescriptionCulture.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.bill_of_materials FROM '/init/data/postgresql/Production_BillOfMaterials.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.work_order FROM '/init/data/postgresql/Production_WorkOrder.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.work_order_routing FROM '/init/data/postgresql/Production_WorkOrderRouting.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.transaction_history FROM '/init/data/postgresql/Production_TransactionHistory.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY production.transaction_history_archive FROM '/init/data/postgresql/Production_TransactionHistoryArchive.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- Production sequences
SELECT setval(pg_get_serial_sequence('production.bill_of_materials', 'bill_of_materials_id'), COALESCE((SELECT MAX(bill_of_materials_id) FROM production.bill_of_materials), 1), true);
SELECT setval(pg_get_serial_sequence('production.illustration', 'illustration_id'), COALESCE((SELECT MAX(illustration_id) FROM production.illustration), 1), true);
SELECT setval(pg_get_serial_sequence('production.location', 'location_id'), COALESCE((SELECT MAX(location_id) FROM production.location), 1), true);
SELECT setval(pg_get_serial_sequence('production.product', 'product_id'), COALESCE((SELECT MAX(product_id) FROM production.product), 1), true);
SELECT setval(pg_get_serial_sequence('production.product_category', 'product_category_id'), COALESCE((SELECT MAX(product_category_id) FROM production.product_category), 1), true);
SELECT setval(pg_get_serial_sequence('production.product_description', 'product_description_id'), COALESCE((SELECT MAX(product_description_id) FROM production.product_description), 1), true);
SELECT setval(pg_get_serial_sequence('production.product_model', 'product_model_id'), COALESCE((SELECT MAX(product_model_id) FROM production.product_model), 1), true);
SELECT setval(pg_get_serial_sequence('production.product_photo', 'product_photo_id'), COALESCE((SELECT MAX(product_photo_id) FROM production.product_photo), 1), true);
SELECT setval(pg_get_serial_sequence('production.product_review', 'product_review_id'), COALESCE((SELECT MAX(product_review_id) FROM production.product_review), 1), true);
SELECT setval(pg_get_serial_sequence('production.product_subcategory', 'product_subcategory_id'), COALESCE((SELECT MAX(product_subcategory_id) FROM production.product_subcategory), 1), true);
SELECT setval(pg_get_serial_sequence('production.scrap_reason', 'scrap_reason_id'), COALESCE((SELECT MAX(scrap_reason_id) FROM production.scrap_reason), 1), true);
SELECT setval(pg_get_serial_sequence('production.work_order', 'work_order_id'), COALESCE((SELECT MAX(work_order_id) FROM production.work_order), 1), true);
SELECT setval(pg_get_serial_sequence('production.transaction_history', 'transaction_id'), COALESCE((SELECT MAX(transaction_id) FROM production.transaction_history), 1), true);

DO $$
BEGIN
    RAISE NOTICE 'Loading Purchasing schema data...';
END $$;

COPY purchasing.ship_method FROM '/init/data/postgresql/Purchasing_ShipMethod.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY purchasing.vendor FROM '/init/data/postgresql/Purchasing_Vendor.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY purchasing.product_vendor FROM '/init/data/postgresql/Purchasing_ProductVendor.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY purchasing.purchase_order_header FROM '/init/data/postgresql/Purchasing_PurchaseOrderHeader.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY purchasing.purchase_order_detail FROM '/init/data/postgresql/Purchasing_PurchaseOrderDetail.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

SELECT setval(pg_get_serial_sequence('purchasing.ship_method', 'ship_method_id'), COALESCE((SELECT MAX(ship_method_id) FROM purchasing.ship_method), 1), true);
SELECT setval(pg_get_serial_sequence('purchasing.purchase_order_header', 'purchase_order_id'), COALESCE((SELECT MAX(purchase_order_id) FROM purchasing.purchase_order_header), 1), true);

DO $$
BEGIN
    RAISE NOTICE 'Loading Sales schema data...';
END $$;

COPY sales.currency FROM '/init/data/postgresql/Sales_Currency.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.sales_reason FROM '/init/data/postgresql/Sales_SalesReason.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.credit_card FROM '/init/data/postgresql/Sales_CreditCard.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.special_offer FROM '/init/data/postgresql/Sales_SpecialOffer.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

COPY sales.sales_territory FROM '/init/data/postgresql/Sales_SalesTerritory.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.sales_tax_rate FROM '/init/data/postgresql/Sales_SalesTaxRate.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.country_region_currency FROM '/init/data/postgresql/Sales_CountryRegionCurrency.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.currency_rate FROM '/init/data/postgresql/Sales_CurrencyRate.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.customer FROM '/init/data/postgresql/Sales_Customer.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.sales_person FROM '/init/data/postgresql/Sales_SalesPerson.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.store FROM '/init/data/postgresql/Sales_Store.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.person_credit_card FROM '/init/data/postgresql/Sales_PersonCreditCard.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.special_offer_product FROM '/init/data/postgresql/Sales_SpecialOfferProduct.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.sales_order_header FROM '/init/data/postgresql/Sales_SalesOrderHeader.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.sales_order_detail FROM '/init/data/postgresql/Sales_SalesOrderDetail.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.sales_order_header_sales_reason FROM '/init/data/postgresql/Sales_SalesOrderHeaderSalesReason.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.sales_person_quota_history FROM '/init/data/postgresql/Sales_SalesPersonQuotaHistory.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.sales_territory_history FROM '/init/data/postgresql/Sales_SalesTerritoryHistory.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');
COPY sales.shopping_cart_item FROM '/init/data/postgresql/Sales_ShoppingCartItem.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

SELECT setval(pg_get_serial_sequence('sales.credit_card', 'credit_card_id'), COALESCE((SELECT MAX(credit_card_id) FROM sales.credit_card), 1), true);
SELECT setval(pg_get_serial_sequence('sales.currency_rate', 'currency_rate_id'), COALESCE((SELECT MAX(currency_rate_id) FROM sales.currency_rate), 1), true);
SELECT setval(pg_get_serial_sequence('sales.customer', 'customer_id'), COALESCE((SELECT MAX(customer_id) FROM sales.customer), 1), true);
SELECT setval(pg_get_serial_sequence('sales.sales_reason', 'sales_reason_id'), COALESCE((SELECT MAX(sales_reason_id) FROM sales.sales_reason), 1), true);
SELECT setval(pg_get_serial_sequence('sales.sales_tax_rate', 'sales_tax_rate_id'), COALESCE((SELECT MAX(sales_tax_rate_id) FROM sales.sales_tax_rate), 1), true);
SELECT setval(pg_get_serial_sequence('sales.sales_territory', 'territory_id'), COALESCE((SELECT MAX(territory_id) FROM sales.sales_territory), 1), true);
SELECT setval(pg_get_serial_sequence('sales.special_offer', 'special_offer_id'), COALESCE((SELECT MAX(special_offer_id) FROM sales.special_offer), 1), true);
SELECT setval(pg_get_serial_sequence('sales.sales_order_header', 'sales_order_id'), COALESCE((SELECT MAX(sales_order_id) FROM sales.sales_order_header), 1), true);
SELECT setval(pg_get_serial_sequence('sales.shopping_cart_item', 'shopping_cart_item_id'), COALESCE((SELECT MAX(shopping_cart_item_id) FROM sales.shopping_cart_item), 1), true);

DO $$
BEGIN
    RAISE NOTICE 'Operations data loading completed!';
END $$;
