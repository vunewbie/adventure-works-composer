#!/bin/bash
# Convert CSV files with byte string literals to PostgreSQL hex format
# Normalize CSV files: convert float to integer for integer columns
# This script runs before data loading to prepare CSV files

set -e

DATA_DIR="/init/data/postgresql"
SCRIPT_DIR="/init/scripts/postgres"

echo "Preparing CSV files..."

# Files that contain BYTEA columns (based on schema analysis)
# Note: Only production documents/photos contain BYTEA columns
BYTEA_FILES=(
    "Production_ProductPhoto.csv"
    "Production_Document.csv"
)

# Files that need integer normalization (float values in integer columns)
INTEGER_NORMALIZE_FILES=(
    "Production_Product.csv:ProductSubcategoryID,ProductModelID"
    "Production_BillOfMaterials.csv:ProductAssemblyID,ComponentID,BOMLevel"
    "Production_WorkOrder.csv:ScrapReasonID"
    "Purchasing_ProductVendor.csv:AverageLeadTime,MinOrderQty,MaxOrderQty,OnOrderQty"
    "Sales_SpecialOffer.csv:MinQty,MaxQty"
    "Sales_Customer.csv:PersonID,StoreID,TerritoryID"
    "Sales_SalesPerson.csv:TerritoryID"
    "Sales_SalesOrderHeader.csv:SalesPersonID,TerritoryID,BillToAddressID,ShipToAddressID,ShipMethodID,CreditCardID,CurrencyRateID"
)

# Convert BYTEA files
echo "Converting CSV files with BYTEA columns..."
for file in "${BYTEA_FILES[@]}"; do
    if [ -f "${DATA_DIR}/${file}" ]; then
        echo "Converting ${file}..."
        python3 "${SCRIPT_DIR}/convert_bytea_csv.py" "${DATA_DIR}/${file}" "${DATA_DIR}/${file}.tmp"
        mv "${DATA_DIR}/${file}.tmp" "${DATA_DIR}/${file}"
        echo "Successfully converted ${file}"
    else
        echo "Warning: ${file} not found, skipping..."
    fi
done

# Normalize integer columns
echo "Normalizing integer columns in CSV files..."
for entry in "${INTEGER_NORMALIZE_FILES[@]}"; do
    IFS=':' read -r file columns <<< "$entry"
    if [ -f "${DATA_DIR}/${file}" ]; then
        echo "Normalizing ${file}..."
        IFS=',' read -ra COLS <<< "$columns"
        python3 "${SCRIPT_DIR}/normalize_csv.py" "${DATA_DIR}/${file}" "${DATA_DIR}/${file}.tmp" "${COLS[@]}"
        mv "${DATA_DIR}/${file}.tmp" "${DATA_DIR}/${file}"
        echo "Successfully normalized ${file}"
    else
        echo "Warning: ${file} not found, skipping..."
    fi
done

echo "CSV preparation completed!"

