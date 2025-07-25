-- ===============================================================
-- Bronze Layer Data Quality Validation Script
-- ===============================================================
-- Purpose: Validate data quality in bronze.crm_cust_info before silver transformation
-- Checks: Sample data, duplicates, nulls, spaces, standardization
-- Author: [Your Name]
-- Date: July 24, 2025
-- ===============================================================

-- Sample data review
-- Purpose: Visual inspection of data structure and content
SELECT TOP 100 * FROM bronze.crm_cust_info;

-- Check for Null or Duplicates in Primary Key
-- Expectation: No Result
-- Purpose: Validate primary key integrity (cst_id should be unique and not null)
SELECT cst_id,
       COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for unwanted spaces
-- Expectation: No result
-- Purpose: Identify records with leading/trailing spaces in first name field
SELECT cst_firstname
    FROM bronze.crm_cust_info
    WHERE cst_firstname != TRIM(cst_firstname);

-- Data Standardization & Consistency
-- Purpose: Review gender values for standardization needs
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;

-- Purpose: Review marital status values for standardization needs
SELECT DISTINCT cst_material_status
FROM bronze.crm_cust_info;
