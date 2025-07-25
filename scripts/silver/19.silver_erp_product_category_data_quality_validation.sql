-- ===============================================================
-- Silver Layer ERP Product Category Data Quality Validation Script
-- ===============================================================
-- Purpose: Validate data quality in silver.erp_px_cat_g1v2 after transformation
-- Checks: Referential integrity, unwanted spaces, standardization verification
-- Author: Hung Nguyen
-- Date: July 25, 2025
-- ===============================================================

-- Sample data review after transformation
-- Purpose: Visual inspection of transferred ERP product category data
SELECT TOP 100 * FROM silver.erp_px_cat_g1v2;

-- Check for orphaned product category IDs (referential integrity)
-- Purpose: Verify all ERP product category IDs have matching category IDs in silver product table
SELECT
    id
FROM silver.erp_px_cat_g1v2
WHERE id NOT IN (SELECT cat_id FROM silver.crm_prd_info);

-- Review silver product category IDs for comparison
-- Purpose: Review existing category IDs in silver product table for validation
select cat_id
   from silver.crm_prd_info;

-- Check for unwanted spaces
-- Purpose: Verify data transfer preserved original format (identify any space issues from bronze)
SELECT * FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance);

-- Check Standardization & Consistency
-- Purpose: Review unique category values after transfer (should match bronze values)
SELECT
   DISTINCT cat
FROM silver.erp_px_cat_g1v2;

-- Purpose: Review unique subcategory values after transfer
SELECT
   DISTINCT subcat
FROM silver.erp_px_cat_g1v2;

-- Purpose: Review unique maintenance values after transfer
SELECT
   DISTINCT maintenance
FROM silver.erp_px_cat_g1v2;
