-- ===============================================================
-- Bronze to Silver Transformation - Product Data
-- ===============================================================
-- Purpose: Transform and clean product data from bronze to silver layer
-- Source: bronze.crm_prd_info
-- Target: silver.crm_prd_info
-- Transformations: Extract category ID, clean product key, standardize product lines, fix date logic
-- Author: Hung Nguyen
-- Date: July 24, 2025
-- ===============================================================

-- Transform product data with complex business logic
-- 1. Extract category ID from first 5 characters of product key (replace - with _)
-- 2. Clean product key by removing category prefix (substring from position 7)
-- 3. Handle NULL product codes with COALESCE (default to 0)
-- 4. Standardize product line codes (M→Mountain, R→Road, S→Other Sales, T→Touring)
-- 5. Cast start date to proper DATE format
-- 6. Calculate end date using LEAD() function (next product start date - 1 day)

TRUNCATE TABLE silver.crm_prd_info;   -- Remove all existing records from silver table for clean reload
INSERT INTO silver.crm_prd_info(prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
SELECT
   prd_id,
   REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
   SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
   prd_nm,
   COALESCE(prd_code, 0) AS prd_cost,
   CASE UPPER(TRIM(prd_line))
        WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
   END AS prd_line,
   CAST(prd_start_dt AS DATE) AS prd_start_dt,
   CAST(LEAD(prd_start_dt) OVER ( PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS DATE) AS prd_end_dt
FROM bronze.crm_prd_info
