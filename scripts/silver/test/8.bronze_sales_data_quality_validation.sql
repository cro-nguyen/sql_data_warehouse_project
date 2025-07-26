-- ===============================================================
-- Bronze Layer Sales Data Quality Validation Script
-- ===============================================================
-- Purpose: Validate data quality in bronze.crm_sales_details before silver transformation
-- Checks: Spaces, referential integrity, date formats, date logic, calculated fields
-- Author: Hung Nguyen
-- Date: July 25, 2025
-- ===============================================================

-- Sample data review
-- Purpose: Visual inspection of sales transaction data structure and content
SELECT * FROM bronze.crm_sales_details;

-- Check for unwanted spaces in order numbers
-- Purpose: Identify records with leading/trailing spaces in order numbers
SELECT * FROM bronze.crm_sales_details
   WHERE sls_ord_num != TRIM(sls_ord_num)

-- Check for orphaned product keys (referential integrity)
-- Purpose: Find sales records with product keys that don't exist in silver product table
SELECT * FROM bronze.crm_sales_details
   WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

-- Check for orphaned customer IDs (referential integrity)
-- Purpose: Find sales records with customer IDs that don't exist in silver customer table
SELECT * FROM bronze.crm_sales_details
   WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

-- Check for invalid order dates (zero or negative)
-- Purpose: Identify records with invalid order date values
SELECT sls_order_dt FROM bronze.crm_sales_details
   WHERE sls_order_dt <= 0;

-- Check for invalid order dates (format and range validation)
-- Purpose: Validate order date format (YYYYMMDD) and reasonable date ranges
SELECT
   NULLIF(sls_order_dt, 0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0
OR LEN(sls_order_dt) != 8
OR sls_order_dt > 20500101
OR sls_order_dt < 19900101;

-- Check for invalid due dates (format and range validation)
-- Purpose: Validate due date format (YYYYMMDD) and reasonable date ranges
SELECT
   NULLIF(sls_due_dt, 0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0
OR LEN(sls_due_dt) != 8
OR sls_due_dt > 20500101
OR sls_due_dt < 19900101;

-- Check for invalid ship dates (format and range validation)
-- Purpose: Validate ship date format (YYYYMMDD) and reasonable date ranges
SELECT
   NULLIF(sls_ship_dt, 0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0
OR LEN(sls_ship_dt) != 8
OR sls_ship_dt > 20500101
OR sls_ship_dt < 19900101;

-- Check for invalid date logic (order sequence)
-- Purpose: Identify records where order date is after ship date or due date (business logic error)
SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check for sales calculation errors
-- Purpose: Validate that sales amount equals price × quantity, identify NULL values
SELECT DISTINCT
   sls_sales AS old_sls_sales,
   sls_quantity,
   sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_price * sls_quantity
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL;
