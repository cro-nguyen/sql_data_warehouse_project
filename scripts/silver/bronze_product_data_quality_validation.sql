-- ===============================================================
-- Bronze Layer Product Data Quality Validation Script
-- ===============================================================
-- Purpose: Validate data quality in bronze.crm_prd_info before silver transformation
-- Checks: Duplicates, nulls, spaces, negative values, date logic, standardization
-- Author: Hung Nguyen
-- Date: July 24, 2025
-- ===============================================================

-- Sample data review
-- Purpose: Visual inspection of product data structure and content
SELECT TOP 100 * FROM bronze.crm_prd_info;

-- Check for Null or Duplicates in Primary Key
-- Expectation: No Result
-- Purpose: Validate product ID integrity (should be unique and not null)
SELECT prd_id,
      COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for unwanted spaces
-- Expectation: No result
-- Purpose: Identify records with leading/trailing spaces in product names
SELECT prd_nm
   FROM bronze.crm_prd_info
   WHERE prd_nm != TRIM(prd_nm);

-- Check for NULL or Negative Numbers
-- Expectation: No result
-- Purpose: Validate product codes are positive integers (business rule)
SELECT prd_code
FROM bronze.crm_prd_info
WHERE prd_code < 0 OR prd_code IS NULL;

-- Data Standardization & Consistency
-- Purpose: Review product line values for standardization needs
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info;

-- Check for Invalid Date Orders
-- Purpose: Identify products where end date is before start date (data logic error)
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;
