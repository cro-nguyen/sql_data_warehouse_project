-- ===============================================================
-- Bronze Layer ERP Location Data Quality Validation Script
-- ===============================================================
-- Purpose: Validate data quality in bronze.erp_loc_a101 before silver transformation
-- Checks: Customer ID format, referential integrity, country standardization
-- Author: Hung Nguyen
-- Date: July 25, 2025
-- ===============================================================

-- Sample data review
-- Purpose: Visual inspection of ERP location data structure and content
SELECT TOP 100 * FROM bronze.erp_loc_a101;

-- Customer key reference data review
-- Purpose: Review CRM customer keys for comparison with ERP location customer IDs
SELECT TOP 100 cst_key FROM silver.crm_cust_info;

-- Check for orphaned customer IDs (referential integrity)
-- Purpose: Find ERP location records with customer IDs that don't match CRM customer keys (after removing dashes)
SELECT TOP 100
   REPLACE(cid, '-', '') cid,
   cntry
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN (SELECT cst_key FROM silver.crm_cust_info)

-- Data Standardization & Consistency
-- Purpose: Preview country value standardization (DE→Germany, US/USA→United State, empty→n/a)
SELECT
DISTINCT cntry AS old_cntry,
CASE WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
   WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United State'
   WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
   ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101;
