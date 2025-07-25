-- ===============================================================
-- Silver Layer ERP Location Data Quality Validation Script
-- ===============================================================
-- Purpose: Validate data quality in silver.erp_loc_a101 after transformation
-- Checks: ID cleaning results, referential integrity, country standardization verification
-- Author: Hung Nguyen
-- Date: July 25, 2025
-- ===============================================================

-- Sample data review after transformation
-- Purpose: Visual inspection of cleaned and transformed ERP location data
SELECT TOP 100 * FROM silver.erp_loc_a101;

-- Customer key reference data review
-- Purpose: Review CRM customer keys for comparison validation
SELECT TOP 100 cst_key FROM silver.crm_cust_info;

-- Check for orphaned customer IDs (referential integrity)
-- Purpose: Verify all ERP location customer IDs match CRM customer keys after dash removal
SELECT TOP 100
   REPLACE(cid, '-', '') cid,
   cntry
FROM silver.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN (SELECT cst_key FROM silver.crm_cust_info)

-- Data Standardization verification
-- Purpose: Verify country standardization worked correctly (should show no more DE, US, USA codes)
SELECT
DISTINCT cntry AS old_cntry,
CASE WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
   WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United State'
   WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
   ELSE TRIM(cntry)
END AS cntry
FROM silver.erp_loc_a101;
