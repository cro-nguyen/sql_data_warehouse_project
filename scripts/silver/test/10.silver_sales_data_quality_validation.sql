-- ===============================================================
-- Silver Layer Sales Data Quality Validation Script
-- ===============================================================
-- Purpose: Validate data quality in silver.crm_sales_details after transformation
-- Checks: Spaces, referential integrity, date logic, calculated fields validation
-- Author: Hung Nguyen
-- Date: July 25, 2025
-- ===============================================================

-- Sample data review after transformation
-- Purpose: Visual inspection of cleaned and transformed sales data
SELECT * FROM silver.crm_sales_details;

-- Check for unwanted spaces in order numbers
-- Purpose: Verify order numbers are clean (should be same as bronze since no TRIM applied)
SELECT * FROM silver.crm_sales_details
   WHERE sls_ord_num != TRIM(sls_ord_num)

-- Check for orphaned product keys (referential integrity)
-- Purpose: Verify all product keys exist in silver product table after transformation
SELECT * FROM silver.crm_sales_details
   WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

-- Check for orphaned customer IDs (referential integrity)
-- Purpose: Verify all customer IDs exist in silver customer table after transformation
SELECT * FROM silver.crm_sales_details
   WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

-- Check for invalid date logic (order sequence)
-- Purpose: Verify date conversion and logic - order date should be before ship/due dates
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check for sales calculation validation
-- Purpose: Verify transformation fixed sales calculation and handled NULL values correctly
SELECT DISTINCT
   sls_sales AS old_sls_sales,
   sls_quantity,
   sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_price * sls_quantity
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL;
