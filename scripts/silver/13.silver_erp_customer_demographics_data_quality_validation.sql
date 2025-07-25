-- ===============================================================
-- Silver Layer ERP Customer Demographics Data Quality Validation Script
-- ===============================================================
-- Purpose: Validate data quality in silver.erp_cust_az12 after transformation
-- Checks: ID cleaning results, referential integrity, birth date validation, gender standardization
-- Author: Hung Nguyen
-- Date: July 25, 2025
-- ===============================================================

-- Sample data review after transformation
-- Purpose: Visual inspection of cleaned and transformed ERP customer demographics data
SELECT TOP 100 * FROM silver.erp_cust_az12;

-- Customer ID transformation verification
-- Purpose: Verify 'NAS' prefix removal worked correctly (should show no more 'NAS' prefixes)
SELECT
   cid,
   CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
       ELSE cid
   END AS cid,
   bdate,
   gen
   FROM silver.erp_cust_az12;

-- Check for orphaned customer IDs (referential integrity)
-- Purpose: Verify all ERP customer IDs have matching records in silver CRM customer table
SELECT
   cid,
   CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
       ELSE cid
   END AS cid,
   bdate,
   gen
   FROM silver.erp_cust_az12
   WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
       ELSE cid END NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- Check for invalid birth dates after transformation
-- Purpose: Verify birth date validation worked (future dates should be NULL, old dates flagged)
SELECT
   DISTINCT bdate
   FROM silver.erp_cust_az12
   WHERE bdate < '1925-01-01' OR bdate > GETDATE();

-- Gender standardization verification
-- Purpose: Verify gender standardization worked (should show: Female, Male, n/a only)
SELECT
   DISTINCT gen
   FROM silver.erp_cust_az12;
