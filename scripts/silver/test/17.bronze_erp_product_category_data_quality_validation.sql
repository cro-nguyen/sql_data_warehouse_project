-- ===============================================================
-- Bronze Layer ERP Product Category Data Quality Validation Script
-- ===============================================================
-- Purpose: Validate data quality in bronze.erp_px_cat_g1v2 before silver transformation
-- Checks: Referential integrity, unwanted spaces, standardization needs
-- Author: Hung Nguyen
-- Date: July 25, 2025
-- ===============================================================

-- Sample data review
-- Purpose: Visual inspection of ERP product category data structure and content
SELECT TOP 100 * FROM bronze.erp_px_cat_g1v2;

-- Check for orphaned product category IDs (referential integrity)
-- Purpose: Find ERP product category records that don't have matching category IDs in silver product table
SELECT
    id
FROM bronze.erp_px_cat_g1v2
WHERE id NOT IN (SELECT cat_id FROM silver.crm_prd_info);

-- Review silver product category IDs for comparison
-- Purpose: Review existing category IDs in silver product table for reference
select cat_id
   from silver.crm_prd_info;

-- Check for unwanted spaces
-- Purpose: Identify records with leading/trailing spaces in category, subcategory, or maintenance fields
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance);

-- Check Standardization & Consistency
-- Purpose: Review unique category values for standardization needs
SELECT
   DISTINCT cat
FROM bronze.erp_px_cat_g1v2;

-- Purpose: Review unique subcategory values for standardization needs
SELECT
   DISTINCT subcat
FROM bronze.erp_px_cat_g1v2;

-- Purpose: Review unique maintenance values for standardization needs
SELECT
   DISTINCT maintenance
FROM bronze.erp_px_cat_g1v2;
