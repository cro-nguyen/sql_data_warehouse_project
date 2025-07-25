-- ===============================================================
-- Bronze to Silver Transformation - ERP Customer Demographics
-- ===============================================================
-- Purpose: Transform and clean ERP customer demographics from bronze to silver layer
-- Source: bronze.erp_cust_az12
-- Target: silver.erp_cust_az12
-- Transformations: Clean customer IDs, validate birth dates, standardize gender values
-- Author: Hung Nguyen
-- Date: July 25, 2025
-- ===============================================================

-- Transform ERP customer demographics with data cleaning and standardization
-- 1. Clean customer ID by removing 'NAS' prefix if present (standardize ID format)
-- 2. Validate birth dates - set future dates to NULL (data quality rule)
-- 3. Standardize gender values (F/Female→Female, M/Male→Male, other→n/a)
-- 4. Maintain referential integrity with CRM customer data

TRUNCATE TABLE silver.erp_cust_az12;   -- Remove all existing records from silver table for clean reload
INSERT INTO silver.erp_cust_az12(cid, bdate, gen)
SELECT
   CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
       ELSE cid
   END AS cid,
   CASE WHEN bdate > GETDATE() THEN NULL
       ELSE bdate
   END AS bdate,
   CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
   END AS gen
   FROM bronze.erp_cust_az12;
