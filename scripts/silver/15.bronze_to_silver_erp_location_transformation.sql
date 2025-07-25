-- ===============================================================
-- Bronze to Silver Transformation - ERP Location Data
-- ===============================================================
-- Purpose: Transform and clean ERP location data from bronze to silver layer
-- Source: bronze.erp_loc_a101
-- Target: silver.erp_loc_a101
-- Transformations: Clean customer IDs, standardize country codes, handle missing values
-- Author: Hung Nguyen
-- Date: July 25, 2025
-- ===============================================================

-- Transform ERP location data with cleaning and standardization
-- 1. Clean customer ID by removing dashes for consistent format with CRM data
-- 2. Standardize country codes (DE→Germany, US/USA→United State)
-- 3. Handle empty/NULL country values by setting to 'n/a'
-- 4. Trim whitespace from country names for data consistency
INSERT INTO silver.erp_loc_a101(cid, cntry)
SELECT
   REPLACE(cid, '-', '') cid,
   CASE WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
        WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United State'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
        ELSE TRIM(cntry)
   END AS cntry
FROM bronze.erp_loc_a101;
