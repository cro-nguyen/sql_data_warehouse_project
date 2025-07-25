-- ===============================================================
-- Silver Layer Data Quality Validation Script
-- ===============================================================
-- Purpose: Validate data quality in silver.crm_cust_info after transformation
-- Checks: Sample data, duplicates, nulls, spaces, standardization results
-- Author: Hung Nguyen
-- Date: July 24, 2025
-- ===============================================================

-- Sample data review after transformation
-- Purpose: Visual inspection of cleaned and standardized data
SELECT TOP 100 * FROM silver.crm_cust_info;

-- Check for Null or Duplicates in Primary Key
-- Expectation: No Result
-- Purpose: Verify deduplication worked and no null customer IDs remain
SELECT cst_id,
      COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for unwanted spaces
-- Expectation: No result
-- Purpose: Verify TRIM() transformation removed all leading/trailing spaces
SELECT cst_firstname
   FROM silver.crm_cust_info
   WHERE cst_firstname != TRIM(cst_firstname);

-- Data Standardization & Consistency
-- Purpose: Verify gender standardization (should show: Female, Male, n/a)
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;

-- Purpose: Verify marital status standardization (should show: Single, Married, n/a)
SELECT DISTINCT cst_material_status
FROM silver.crm_cust_info;
