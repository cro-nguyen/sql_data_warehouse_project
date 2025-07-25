-- ===============================================================
-- Silver Layer Product Data Quality Validation Script
-- ===============================================================
-- Purpose: Validate data quality in silver.crm_prd_info after transformation
-- Checks: Duplicates, nulls, spaces, negative values, date logic, standardization results
-- Author: Hung Nguyen
-- Date: July 24, 2025
-- ===============================================================

-- Sample data review after transformation
-- Purpose: Visual inspection of cleaned and transformed product data
SELECT TOP 100 * FROM silver.crm_prd_info;

-- Check for Null or Duplicates in Primary Key
-- Expectation: No Result
-- Purpose: Verify product ID integrity remains intact after transformation
SELECT prd_id,
      COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for unwanted spaces
-- Expectation: No result
-- Purpose: Verify product names are clean (should be same as bronze since no TRIM applied)
SELECT prd_nm
   FROM silver.crm_prd_info
   WHERE prd_nm != TRIM(prd_nm);

-- Check for NULL or Negative Numbers
-- Expectation: No result
-- Purpose: Verify COALESCE transformation worked and no negative costs exist
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data Standardization & Consistency
-- Purpose: Verify product line standardization (should show: Mountain, Road, Other Sales, Touring, n/a)
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

-- Check for Invalid Date Orders
-- Purpose: Verify LEAD() date calculation logic worked correctly (end_dt should be >= start_dt)
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;
