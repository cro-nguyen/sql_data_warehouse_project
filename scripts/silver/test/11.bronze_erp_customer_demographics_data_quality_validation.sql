-- ===============================================================
-- Bronze Layer ERP Customer Demographics Data Quality Validation Script
-- ===============================================================
-- Purpose: Validate data quality in bronze.erp_cust_az12 before silver transformation
-- Checks: Customer ID format, referential integrity, birth date ranges, gender standardization
-- Author: Hung Nguyen
-- Date: July 25, 2025
-- ===============================================================

-- Sample data review
-- Purpose: Visual inspection of ERP customer demographics data structure and content
SELECT TOP 100 * FROM bronze.erp_cust_az12;

-- Customer ID transformation preview
-- Purpose: Preview how customer IDs will be cleaned (remove 'NAS' prefix if present)
SELECT
   cid,
   CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
       ELSE cid
   END AS cid,
   bdate,
   gen
   FROM bronze.erp_cust_az12;

-- Check for orphaned customer IDs (referential integrity)
-- Purpose: Find ERP customer records that don't have matching records in silver CRM customer table
SELECT
   cid,
   CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
       ELSE cid
   END AS cid,
   bdate,
   gen
   FROM bronze.erp_cust_az12
   WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
       ELSE cid END NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- Check for invalid birth dates (unreasonable ranges)
-- Purpose: Identify birth dates that are too old (before 1925) or in the future
SELECT
   DISTINCT bdate
   FROM bronze.erp_cust_az12
   WHERE bdate < '1925-01-01' OR bdate > GETDATE();

-- Gender standardization preview
-- Purpose: Preview gender value standardization (F/Female→Female, M/Male→Male, other→n/a)
SELECT
   DISTINCT gen,
   CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
   END AS gen
   FROM bronze.erp_cust_az12;
